REPORT zrmig_job_dispatch.
"One periodic job dispatches at most one request of each kind per run.
"Run outside RAP as the user allowed to schedule steps for request owners.
PARAMETERS p_exec TYPE abap_bool AS CHECKBOX DEFAULT abap_false.

START-OF-SELECTION.
  IF p_exec = abap_false.
    WRITE / 'Dry run: set P_EXEC = X only after checking the queued requests.'.
    SELECT request_id, requested_by FROM zmig_gen_job
      WHERE status = 'QUEUED'
      ORDER BY created_at, request_id
      INTO TABLE @DATA(lt_preview_gen) UP TO 1 ROWS.
    IF lt_preview_gen IS NOT INITIAL.
      WRITE: / 'Generation:', lt_preview_gen[ 1 ]-request_id,
               lt_preview_gen[ 1 ]-requested_by.
    ENDIF.
    SELECT request_id, requested_by FROM zmig_legacy_job
      WHERE status = 'QUEUED'
      ORDER BY created_at, request_id
      INTO TABLE @DATA(lt_preview_legacy) UP TO 1 ROWS.
    IF lt_preview_legacy IS NOT INITIAL.
      WRITE: / 'Capture:', lt_preview_legacy[ 1 ]-request_id,
               lt_preview_legacy[ 1 ]-requested_by.
    ENDIF.
    RETURN.
  ENDIF.

  PERFORM dispatch_generation.
  PERFORM dispatch_capture.

FORM dispatch_generation.
  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING tabname = 'ZMIG_GEN_JOB' _scope = '1'
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0.
    WRITE / 'Generation queue is busy; try on the next dispatcher run.'.
    RETURN.
  ENDIF.

  "There is a single shared service binding. Never start a second XCO PUT
  "while a preceding child job has not finished or needs manual review.
  SELECT SINGLE request_id FROM zmig_gen_job
    WHERE status = 'DISPATCHING' OR status = 'SCHEDULED' OR status = 'RUNNING'
    INTO @DATA(lv_active).
  IF sy-subrc = 0.
    WRITE: / 'Generation request already active:', lv_active.
    CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_GEN_JOB' _scope = '1'.
    RETURN.
  ENDIF.

  SELECT * FROM zmig_gen_job
    WHERE status = 'QUEUED'
    ORDER BY created_at, request_id
    INTO TABLE @DATA(lt_jobs) UP TO 1 ROWS.
  IF lt_jobs IS INITIAL.
    WRITE / 'No generation requests awaiting dispatch.'.
    CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_GEN_JOB' _scope = '1'.
    RETURN.
  ENDIF.
  DATA(ls_job) = lt_jobs[ 1 ].
  GET TIME STAMP FIELD ls_job-updated_at.
  UPDATE zmig_gen_job
    SET status = 'DISPATCHING', updated_at = @ls_job-updated_at,
        message = 'Dispatcher is creating a job for the request owner.'
    WHERE request_id = @ls_job-request_id AND status = 'QUEUED'.
  IF sy-dbcnt <> 1.
    ROLLBACK WORK.
    CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_GEN_JOB' _scope = '1'.
    RETURN.
  ENDIF.
  COMMIT WORK AND WAIT.
  CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_GEN_JOB' _scope = '1'.

  DATA lv_ok TYPE abap_bool.
  DATA lv_info TYPE string.
  PERFORM submit_child USING 'ZRMIG_GEN_WORKER' 'ZRMIG_GEN_ONE'
    ls_job-request_id ls_job-requested_by CHANGING lv_ok lv_info.
  GET TIME STAMP FIELD ls_job-updated_at.
  IF lv_ok = abap_true.
    "A fast child may already have changed DISPATCHING to RUNNING.
    UPDATE zmig_gen_job
      SET status = 'SCHEDULED', updated_at = @ls_job-updated_at,
          message = @lv_info
      WHERE request_id = @ls_job-request_id AND status = 'DISPATCHING'.
  ELSE.
    "Never reschedule an uncertain JOB_OPEN/JOB_CLOSE outcome automatically.
    UPDATE zmig_gen_job
      SET status = 'DISPATCH_FAILED', updated_at = @ls_job-updated_at,
          message = @lv_info
      WHERE request_id = @ls_job-request_id AND status = 'DISPATCHING'.
  ENDIF.
  COMMIT WORK AND WAIT.
  WRITE: / ls_job-request_id, ls_job-requested_by, lv_info.
ENDFORM.

FORM dispatch_capture.
  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING tabname = 'ZMIG_LEGACY_JOB' _scope = '1'
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0.
    WRITE / 'Capture queue is busy; try on the next dispatcher run.'.
    RETURN.
  ENDIF.

  "One capture child at a time: both worker reports lock this table.
  SELECT SINGLE request_id FROM zmig_legacy_job
    WHERE status = 'DISPATCHING' OR status = 'SCHEDULED' OR status = 'RUNNING'
    INTO @DATA(lv_active).
  IF sy-subrc = 0.
    WRITE: / 'Capture request already active:', lv_active.
    CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_LEGACY_JOB' _scope = '1'.
    RETURN.
  ENDIF.

  SELECT * FROM zmig_legacy_job
    WHERE status = 'QUEUED'
    ORDER BY created_at, request_id
    INTO TABLE @DATA(lt_jobs) UP TO 1 ROWS.
  IF lt_jobs IS INITIAL.
    WRITE / 'No capture requests awaiting dispatch.'.
    CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_LEGACY_JOB' _scope = '1'.
    RETURN.
  ENDIF.
  DATA(ls_job) = lt_jobs[ 1 ].
  GET TIME STAMP FIELD ls_job-updated_at.
  UPDATE zmig_legacy_job
    SET status = 'DISPATCHING', updated_at = @ls_job-updated_at,
        message = 'Dispatcher is creating a job for the request owner.'
    WHERE request_id = @ls_job-request_id AND status = 'QUEUED'.
  IF sy-dbcnt <> 1.
    ROLLBACK WORK.
    CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_LEGACY_JOB' _scope = '1'.
    RETURN.
  ENDIF.
  COMMIT WORK AND WAIT.
  CALL FUNCTION 'DEQUEUE_E_TABLE' EXPORTING tabname = 'ZMIG_LEGACY_JOB' _scope = '1'.

  DATA lv_ok TYPE abap_bool.
  DATA lv_info TYPE string.
  PERFORM submit_child USING 'ZRMIG_LEGACY_WORKER' 'ZRMIG_CAPTURE_ONE'
    ls_job-request_id ls_job-requested_by CHANGING lv_ok lv_info.
  GET TIME STAMP FIELD ls_job-updated_at.
  IF lv_ok = abap_true.
    UPDATE zmig_legacy_job
      SET status = 'SCHEDULED', updated_at = @ls_job-updated_at,
          message = @lv_info
      WHERE request_id = @ls_job-request_id AND status = 'DISPATCHING'.
  ELSE.
    UPDATE zmig_legacy_job
      SET status = 'DISPATCH_FAILED', updated_at = @ls_job-updated_at,
          message = @lv_info
      WHERE request_id = @ls_job-request_id AND status = 'DISPATCHING'.
  ENDIF.
  COMMIT WORK AND WAIT.
  WRITE: / ls_job-request_id, ls_job-requested_by, lv_info.
ENDFORM.

FORM submit_child USING iv_report TYPE syrepid iv_jobname TYPE btcjob
                        iv_request TYPE sysuuid_x16 iv_owner TYPE syuname
                  CHANGING cv_ok TYPE abap_bool cv_info TYPE string.
  CLEAR cv_ok.
  IF iv_owner IS INITIAL OR iv_request IS INITIAL.
    cv_info = 'Request owner or request ID is missing; no job was created.'.
    RETURN.
  ENDIF.
  DATA lv_request_c32 TYPE sysuuid_c32.
  TRY.
      cl_system_uuid=>convert_uuid_x16_static(
        EXPORTING uuid = iv_request IMPORTING uuid_c32 = lv_request_c32 ).
    CATCH cx_root INTO DATA(lx_uuid).
      cv_info = |Cannot convert RequestId: { lx_uuid->get_text( ) }|.
      RETURN.
  ENDTRY.
  DATA lv_count TYPE btcjobcnt.
  CALL FUNCTION 'JOB_OPEN'
    EXPORTING jobname = iv_jobname
    IMPORTING jobcount = lv_count
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0.
    cv_info = |JOB_OPEN failed ({ sy-subrc }) for { iv_owner }.|.
    RETURN.
  ENDIF.

  "This report runs OUTSIDE RAP. The worker executes as the request owner;
  "P_REQID prevents a child from reading another user's queue entry.
  TRY.
      SUBMIT (iv_report)
        WITH p_reqid = lv_request_c32
        USER iv_owner
        VIA JOB iv_jobname NUMBER lv_count
        AND RETURN.
      IF sy-subrc <> 0.
        cv_info = |SUBMIT failed ({ sy-subrc }) for job { iv_jobname }/{ lv_count }; inspect SM37.|.
        RETURN.
      ENDIF.

      CALL FUNCTION 'JOB_CLOSE'
        EXPORTING jobname = iv_jobname jobcount = lv_count strtimmed = abap_true
        EXCEPTIONS OTHERS = 1.
      IF sy-subrc <> 0.
        cv_info = |JOB_CLOSE failed ({ sy-subrc }) for job { iv_jobname }/{ lv_count }; inspect SM37.|.
        RETURN.
      ENDIF.
    CATCH cx_root INTO DATA(lx_job).
      cv_info = |Job { iv_jobname }/{ lv_count } could not be released: { lx_job->get_text( ) }; inspect SM37.|.
      RETURN.
  ENDTRY.
  cv_ok = abap_true.
  cv_info = |Scheduled { iv_jobname }/{ lv_count } as { iv_owner }.|.
ENDFORM.
