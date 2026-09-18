REPORT zrmig_legacy_worker.

PARAMETERS p_limit TYPE i DEFAULT 10.
"One-time job created by ZRMIG_JOB_DISPATCH; empty keeps manual/periodic mode.
PARAMETERS p_reqid TYPE sysuuid_c32.

START-OF-SELECTION.
  WRITE: / 'Legacy worker user:', sy-uname, 'Client:', sy-mandt,
           'P_REQID:', p_reqid.
  IF p_limit < 1 OR p_limit > 100.
    MESSAGE 'P_LIMIT must be between 1 and 100.' TYPE 'E'.
  ENDIF.
  DATA lv_request_id TYPE sysuuid_x16.
  IF p_reqid IS NOT INITIAL.
    TRY.
        cl_system_uuid=>convert_uuid_c32_static(
          EXPORTING uuid = p_reqid IMPORTING uuid_x16 = lv_request_id ).
      CATCH cx_uuid_error.
        WRITE: / 'Invalid P_REQID; expected UUID with 32 hexadecimal characters:',
                 p_reqid.
        RETURN.
    ENDTRY.
  ENDIF.

  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING tabname = 'ZMIG_LEGACY_JOB' _scope = '1'
    EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
  IF sy-subrc <> 0.
    WRITE / 'Another legacy capture worker is active.'.
    RETURN.
  ENDIF.

  "A terminated worker may have left a request RUNNING. Review it before retrying.
  SELECT SINGLE request_id FROM zmig_legacy_job
    WHERE status = 'RUNNING' AND requested_by = @sy-uname
    INTO @DATA(lv_running).
  IF sy-subrc = 0.
    WRITE: / 'Review RUNNING capture request before continuing:', lv_running.
  ELSE.
    DATA lt_jobs TYPE STANDARD TABLE OF zmig_legacy_job WITH EMPTY KEY.
    IF p_reqid IS INITIAL.
      SELECT * FROM zmig_legacy_job
        WHERE status = 'QUEUED' AND requested_by = @sy-uname
        ORDER BY created_at, request_id
        INTO TABLE @lt_jobs UP TO @p_limit ROWS.
    ELSE.
      SELECT * FROM zmig_legacy_job
        WHERE request_id = @lv_request_id AND requested_by = @sy-uname
          AND ( status = 'DISPATCHING' OR status = 'SCHEDULED' )
        INTO TABLE @lt_jobs.
    ENDIF.

    IF lt_jobs IS INITIAL.
      WRITE: / 'No eligible legacy capture requests for user', sy-uname.
    ENDIF.

    LOOP AT lt_jobs INTO DATA(ls_job).
      GET TIME STAMP FIELD ls_job-updated_at.
      IF p_reqid IS INITIAL.
        UPDATE zmig_legacy_job
          SET status = 'RUNNING', updated_at = @ls_job-updated_at
          WHERE request_id = @ls_job-request_id AND status = 'QUEUED'.
      ELSE.
        UPDATE zmig_legacy_job
          SET status = 'RUNNING', updated_at = @ls_job-updated_at
          WHERE request_id = @lv_request_id AND requested_by = @sy-uname
            AND ( status = 'DISPATCHING' OR status = 'SCHEDULED' ).
      ENDIF.
      IF sy-dbcnt <> 1.
        WRITE: / 'Request was not claimed; inspect current status:',
                 ls_job-request_id.
        CONTINUE.
      ENDIF.
      COMMIT WORK AND WAIT.

      CLEAR: ls_job-rows_json, ls_job-message, ls_job-row_count.
      TRY.
          DATA(ls_result) = zcl_mig_legacy_capture_api=>run(
            iv_analysis_id = ls_job-analysis_id
            iv_selection_json = ls_job-selection_json ).
          ls_job-row_count = ls_result-row_count.
          ls_job-rows_json = ls_result-rows_json.
          "The same UPDATE below persists both payload and CAPTURED status.
          ls_job-status = 'CAPTURED'.
          ls_job-message = 'Original report ALV rows captured.'.
        CATCH cx_root INTO DATA(lx_error).
          ROLLBACK WORK.
          ls_job-status = 'FAILED'.
          CLEAR: ls_job-rows_json, ls_job-row_count.
          ls_job-message = lx_error->get_text( ).
      ENDTRY.

      GET TIME STAMP FIELD ls_job-updated_at.
      UPDATE zmig_legacy_job
        SET status = @ls_job-status, row_count = @ls_job-row_count,
            rows_json = @ls_job-rows_json, message = @ls_job-message,
            updated_at = @ls_job-updated_at
        WHERE request_id = @ls_job-request_id AND status = 'RUNNING'.
      IF sy-dbcnt <> 1.
        ROLLBACK WORK.
        WRITE: / 'Could not persist capture result:', ls_job-request_id.
        EXIT.
      ENDIF.
      COMMIT WORK AND WAIT.
      WRITE: / ls_job-request_id, ls_job-status, ls_job-row_count,
               ls_job-message.
    ENDLOOP.
  ENDIF.

  CALL FUNCTION 'DEQUEUE_E_TABLE'
    EXPORTING tabname = 'ZMIG_LEGACY_JOB' _scope = '1'.
