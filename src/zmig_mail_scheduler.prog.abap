REPORT zmig_mail_scheduler.

DATA:
  lt_results TYPE zcl_mig_mail_runner=>tt_run_result,
  ls_result  TYPE zcl_mig_mail_runner=>ty_run_result.

START-OF-SELECTION.

  lt_results =
    zcl_mig_mail_runner=>run_due_jobs( ).

  COMMIT WORK AND WAIT.

  IF lt_results IS INITIAL.

    WRITE: / 'No due migration mail jobs found.'.

    RETURN.

  ENDIF.


  LOOP AT lt_results INTO ls_result.

    WRITE: / 'Job:',        ls_result-job_name.
    WRITE: / 'Success:',    ls_result-success.
    WRITE: / 'Recipients:', ls_result-recipient_count.
    WRITE: / 'Message:',    ls_result-message.

    SKIP.

  ENDLOOP.
