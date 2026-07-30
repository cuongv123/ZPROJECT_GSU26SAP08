CLASS zcl_mig_mail_log_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_start_result,
        success TYPE abap_bool,
        run_id  TYPE sysuuid_x16,
        message TYPE string,
      END OF ty_start_result,

      BEGIN OF ty_finish_result,
        success TYPE abap_bool,
        message TYPE string,
      END OF ty_finish_result.

    CLASS-METHODS start_run
      IMPORTING
        iv_job_id       TYPE sysuuid_x16
        iv_trigger_type TYPE zmig_e_trigger_type
        iv_file_format  TYPE zmig_e_file_format OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_start_result.

    CLASS-METHODS finish_run
      IMPORTING
        iv_job_id          TYPE sysuuid_x16
        iv_run_id          TYPE sysuuid_x16
        iv_status          TYPE zmig_e_run_status
        iv_file_name       TYPE zmig_mail_log-file_name OPTIONAL
        iv_file_format     TYPE zmig_e_file_format OPTIONAL
        iv_file_size       TYPE zmig_mail_log-file_size OPTIONAL
        iv_recipient_count TYPE zmig_mail_log-recipient_count OPTIONAL
        iv_log_message     TYPE string OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_finish_result.

ENDCLASS.


CLASS zcl_mig_mail_log_service IMPLEMENTATION.

  METHOD start_run.

  DATA lv_started_at TYPE timestampl.

  GET TIME STAMP FIELD lv_started_at.

  TRY.

      DATA(lv_run_id) =
        cl_system_uuid=>create_uuid_x16_static( ).

      DATA(ls_log) = VALUE zmig_mail_log(
        job_id          = iv_job_id
        run_id          = lv_run_id
        trigger_type    = iv_trigger_type
        status          = 'R'
        started_at      = lv_started_at
        file_format     = iv_file_format
        recipient_count = 0
        log_message     = 'Mail execution started'
        created_by      = sy-uname
        created_at      = lv_started_at
      ).

      INSERT zmig_mail_log FROM @ls_log.

      IF sy-subrc = 0.

        rs_result-success = abap_true.
        rs_result-run_id  = lv_run_id.
        rs_result-message = 'Execution log started successfully.'.

      ELSE.

        rs_result-success = abap_false.
        rs_result-message = 'Execution log could not be inserted.'.

      ENDIF.

    CATCH cx_uuid_error INTO DATA(lx_uuid).

      rs_result-success = abap_false.
      rs_result-message = lx_uuid->get_text( ).

  ENDTRY.

ENDMETHOD.


 METHOD finish_run.

  DATA:
    lv_finished_at TYPE timestampl,
    lv_log_message TYPE zmig_mail_log-log_message.

  GET TIME STAMP FIELD lv_finished_at.

  "Convert STRING to the database field CHAR(500).
  lv_log_message = iv_log_message.

  UPDATE zmig_mail_log
    SET
      status          = @iv_status,
      finished_at     = @lv_finished_at,
      file_name       = @iv_file_name,
      file_format     = @iv_file_format,
      file_size       = @iv_file_size,
      recipient_count = @iv_recipient_count,
      log_message     = @lv_log_message
    WHERE job_id = @iv_job_id
      AND run_id = @iv_run_id.

  IF sy-subrc = 0.

    rs_result-success = abap_true.
    rs_result-message = 'Execution log finished successfully.'.

  ELSE.

    rs_result-success = abap_false.
    rs_result-message =
      'Execution log was not found or could not be updated.'.

  ENDIF.

ENDMETHOD.

ENDCLASS.
