REPORT zrmig_gen_worker.
"Standard ABAP. Schedule under the same developer user that queues requests.
"XCO performs commits: never execute this worker from a RAP behavior handler.
PARAMETERS p_limit TYPE i DEFAULT 10.

START-OF-SELECTION.
  IF p_limit < 1 OR p_limit > 100.
    MESSAGE 'P_LIMIT must be between 1 and 100.' TYPE 'E'.
  ENDIF.

  "Dialog-owner enqueue survives XCO commits; serializes the shared binding.
  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING tabname = 'ZMIG_GEN_JOB' _scope = '1'
    EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
  IF sy-subrc <> 0.
    WRITE / 'Another generation worker is active. Try again later.'.
    RETURN.
  ENDIF.

  "Do not replay a possibly partially committed request after a worker crash.
  SELECT SINGLE request_id FROM zmig_gen_job
    WHERE status = 'RUNNING' INTO @DATA(lv_running).
  IF sy-subrc = 0.
    WRITE: / 'A RUNNING request needs review before generation can continue:', lv_running.
  ELSE.
    SELECT * FROM zmig_gen_job
      WHERE status = 'QUEUED' AND requested_by = @sy-uname
      ORDER BY created_at, request_id
      INTO TABLE @DATA(lt_jobs) UP TO @p_limit ROWS.
    LOOP AT lt_jobs INTO DATA(ls_job).
      GET TIME STAMP FIELD ls_job-updated_at.
      UPDATE zmig_gen_job SET status = 'RUNNING', updated_at = @ls_job-updated_at
        WHERE request_id = @ls_job-request_id AND status = 'QUEUED'.
      IF sy-dbcnt <> 1.
        CONTINUE.
      ENDIF.
      COMMIT WORK AND WAIT.

      CLEAR: ls_job-result_json, ls_job-message.
      TRY.
          DATA ls_request TYPE zif_mig_odata_gen_svc=>ty_request.
          CLEAR ls_request.
          /ui2/cl_json=>deserialize( EXPORTING json = ls_job-request_json CHANGING data = ls_request ).
          ls_request-execute = abap_true.
          "Generation re-runs its preflight immediately before repository writes.
          DATA(ls_result) = zcl_mig_gen_api=>run( ls_request ).
          ls_job-status = ls_result-status.
          ls_job-message = ls_result-message.
          ls_job-result_json = /ui2/cl_json=>serialize( data = ls_result
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
        CATCH cx_xco_gen_put_exception INTO DATA(lx_xco).
          ROLLBACK WORK.
          ls_job-status = 'FAILED'.
          ls_job-message = lx_xco->get_text( ).
          LOOP AT lx_xco->if_xco_news~get_messages( ) INTO DATA(lo_message).
            ls_job-message = ls_job-message && cl_abap_char_utilities=>newline && lo_message->get_text( ).
          ENDLOOP.
        CATCH cx_root INTO DATA(lx_error).
          ROLLBACK WORK.
          ls_job-status = 'FAILED'.
          ls_job-message = lx_error->get_text( ).
      ENDTRY.
      GET TIME STAMP FIELD ls_job-updated_at.
      UPDATE zmig_gen_job SET status = @ls_job-status, message = @ls_job-message,
        result_json = @ls_job-result_json, updated_at = @ls_job-updated_at
        WHERE request_id = @ls_job-request_id.
      COMMIT WORK AND WAIT.
      WRITE: / ls_job-request_id, ls_job-status, ls_job-message.
      IF ls_job-status = 'FAILED'.
        "Repository changes may have committed already. Do not auto-retry.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDIF.

  CALL FUNCTION 'DEQUEUE_E_TABLE'
    EXPORTING tabname = 'ZMIG_GEN_JOB' _scope = '1'.
