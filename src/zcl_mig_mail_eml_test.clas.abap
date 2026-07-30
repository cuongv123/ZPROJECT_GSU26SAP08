CLASS zcl_mig_mail_eml_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_mig_mail_eml_test IMPLEMENTATION.

METHOD if_oo_adt_classrun~main.

  "Find one Mail Job that already has a recipient.
  SELECT SINGLE
    FROM zmig_mail_recip
    FIELDS job_id
    INTO @DATA(lv_job_id).

  IF sy-subrc <> 0.
    out->write( 'No Mail Job with Recipient was found.' ).
    RETURN.
  ENDIF.


  "Save original scheduling and file configuration.
  SELECT SINGLE
    FROM zmig_mail_job
    FIELDS
      status,
      frequency,
      file_format,
      next_run_at
    WHERE job_id = @lv_job_id
    INTO @DATA(ls_original_job).

  IF sy-subrc <> 0.
    out->write( 'Mail Job was not found.' ).
    RETURN.
  ENDIF.


  "Ensure no other Job is currently due.
  DATA(lt_existing_due_jobs) =
    zcl_mig_mail_runner=>get_due_jobs( ).

  IF lt_existing_due_jobs IS NOT INITIAL.

    out->write(
      |Safety stop: { lines( lt_existing_due_jobs ) } Job(s) are already due.|
    ).

    RETURN.

  ENDIF.


  DATA lv_current_timestamp TYPE timestampl.

  GET TIME STAMP FIELD lv_current_timestamp.


  "Temporarily configure the selected Job for CSV scheduled execution.
  UPDATE zmig_mail_job
    SET
      status      = 'A',
      frequency   = 'D',
      file_format = 'C',
      next_run_at = @lv_current_timestamp
    WHERE job_id = @lv_job_id.

  IF sy-subrc <> 0.

    out->write( 'Could not prepare the scheduled Job.' ).
    ROLLBACK WORK.
    RETURN.

  ENDIF.


  "Verify exactly one due Job was prepared.
  DATA(lt_due_jobs) =
    zcl_mig_mail_runner=>get_due_jobs( ).

  out->write(
    |Due job count before execution: { lines( lt_due_jobs ) }|
  ).

  IF lines( lt_due_jobs ) <> 1.

    out->write( 'Safety stop: expected exactly one due Job.' ).
    ROLLBACK WORK.
    RETURN.

  ENDIF.


  READ TABLE lt_due_jobs
    INDEX 1
    INTO DATA(ls_due_job).

  IF sy-subrc <> 0
     OR ls_due_job-job_id <> lv_job_id.

    out->write( 'Safety stop: unexpected due Job was selected.' ).
    ROLLBACK WORK.
    RETURN.

  ENDIF.


  "Export CSV, send mail and update NextRunAt.
  DATA(lt_results) =
    zcl_mig_mail_runner=>run_due_jobs( ).


  "Restore original Job configuration.
  UPDATE zmig_mail_job
    SET
      status      = @ls_original_job-status,
      frequency   = @ls_original_job-frequency,
      file_format = @ls_original_job-file_format,
      next_run_at = @ls_original_job-next_run_at
    WHERE job_id = @lv_job_id.

  IF sy-subrc <> 0.

    out->write( 'Could not restore original Job configuration.' ).
    ROLLBACK WORK.
    RETURN.

  ENDIF.


  LOOP AT lt_results INTO DATA(ls_result).

    out->write(
      |Job name: { ls_result-job_name }|
    ).

    out->write(
      |Success: { ls_result-success }|
    ).

    out->write(
      |Recipient count: { ls_result-recipient_count }|
    ).

    out->write(
      |Message: { ls_result-message }|
    ).

    out->write(
      |Run ID: { ls_result-run_id }|
    ).

    out->write(
      |Previous NextRunAt: { ls_result-previous_next_run_at }|
    ).

    out->write(
      |New NextRunAt: { ls_result-new_next_run_at }|
    ).

    out->write(
      |Schedule updated: { ls_result-schedule_updated }|
    ).

  ENDLOOP.


  COMMIT WORK AND WAIT.

  out->write(
    'Export, mail and execution log committed successfully.'
  ).

ENDMETHOD.
ENDCLASS.
