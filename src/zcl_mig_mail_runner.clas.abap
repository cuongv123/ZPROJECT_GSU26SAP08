CLASS zcl_mig_mail_runner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_due_job,
        job_id       TYPE sysuuid_x16,
        analysis_id  TYPE zmig_mail_job-analysis_id,
        job_name     TYPE zmig_mail_job-job_name,
        report_type  TYPE zmig_mail_job-report_type,
        file_format  TYPE zmig_e_file_format,
        frequency    TYPE zmig_e_frequency,
        timezone     TYPE zmig_mail_job-time_zone,
        day_of_month TYPE zmig_mail_job-day_of_month,
        next_run_at  TYPE timestampl,
      END OF ty_due_job,

      tt_due_job TYPE STANDARD TABLE OF ty_due_job
        WITH EMPTY KEY,

      BEGIN OF ty_run_result,
        job_id               TYPE sysuuid_x16,
        job_name             TYPE zmig_mail_job-job_name,
        success              TYPE abap_bool,
        run_id               TYPE sysuuid_x16,
        recipient_count      TYPE i,
        previous_next_run_at TYPE timestampl,
        new_next_run_at      TYPE timestampl,
        schedule_updated     TYPE abap_bool,
        message              TYPE string,
      END OF ty_run_result,

      tt_run_result TYPE STANDARD TABLE OF ty_run_result
        WITH EMPTY KEY.

    CLASS-METHODS get_due_jobs
      RETURNING
        VALUE(rt_due_jobs) TYPE tt_due_job.

    CLASS-METHODS run_due_jobs
      RETURNING
        VALUE(rt_results) TYPE tt_run_result.

  PRIVATE SECTION.

    CONSTANTS:
      gc_status_active       TYPE zmig_e_job_status
        VALUE 'A',

      gc_frequency_on_demand TYPE zmig_e_frequency
        VALUE 'O',

      gc_frequency_daily     TYPE zmig_e_frequency
        VALUE 'D',

      gc_frequency_weekly    TYPE zmig_e_frequency
        VALUE 'W',

      gc_frequency_monthly   TYPE zmig_e_frequency
        VALUE 'M',

      gc_trigger_scheduled   TYPE zmig_e_trigger_type
        VALUE 'S',

      gc_status_failed       TYPE zmig_e_run_status
        VALUE 'F',

      gc_export_section_all  TYPE zmig_e_report_section
        VALUE 'ALL',

      gc_max_schedule_steps  TYPE i
        VALUE 1200.

    CLASS-METHODS calculate_next_run_at
      IMPORTING
        is_due_job TYPE ty_due_job
      RETURNING
        VALUE(rv_next_run_at) TYPE timestampl.

    CLASS-METHODS get_next_monthly_date
      IMPORTING
        iv_base_date    TYPE d
        iv_day_of_month TYPE zmig_mail_job-day_of_month
      RETURNING
        VALUE(rv_next_date) TYPE d.

ENDCLASS.


CLASS zcl_mig_mail_runner IMPLEMENTATION.

  METHOD get_due_jobs.

  DATA:
    lv_current_timestamp TYPE timestampl,
    lv_initial_timestamp TYPE timestampl.

  GET TIME STAMP FIELD lv_current_timestamp.

  SELECT
    FROM zmig_mail_job
    FIELDS
      job_id,
      analysis_id,
      job_name,
      report_type,
      file_format,
      frequency,
      time_zone,
      day_of_month,
      next_run_at
    WHERE status      = @gc_status_active
      AND frequency   <> @gc_frequency_on_demand
      AND next_run_at <> @lv_initial_timestamp
      AND next_run_at <= @lv_current_timestamp
    ORDER BY next_run_at ASCENDING
    INTO TABLE @rt_due_jobs.

ENDMETHOD.


 METHOD run_due_jobs.

  DATA:
    lt_due_jobs          TYPE tt_due_job,
    ls_due_job           TYPE ty_due_job,
    ls_run_result        TYPE ty_run_result,

    lo_export_provider   TYPE REF TO zif_mig_export_provider,

    ls_export_result     TYPE zif_mig_export_provider=>ty_export_result,
    ls_attachment        TYPE zcl_mig_mail_service=>ty_attachment,
    ls_template_context  TYPE zcl_mig_mail_template=>ty_context,
    ls_template_result   TYPE zcl_mig_mail_template=>ty_mail_content,
    ls_mail_content      TYPE zcl_mig_mail_service=>ty_mail_content,
    ls_send_result       TYPE zcl_mig_mail_service=>ty_send_result,

    ls_start_result      TYPE zcl_mig_mail_log_service=>ty_start_result,
    ls_finish_result     TYPE zcl_mig_mail_log_service=>ty_finish_result,

    lv_execution_success TYPE abap_bool,
    lv_schedule_updated  TYPE abap_bool,
    lv_overall_success   TYPE abap_bool,

    lv_run_id            TYPE sysuuid_x16,
    lv_recipient_count   TYPE i,

    lv_result_message    TYPE string,
    lv_message_text      TYPE string,

    lv_generated_at      TYPE timestampl,
    lv_changed_at        TYPE timestampl,
    lv_new_next_run_at   TYPE timestampl,

    lv_export_file_size  TYPE zmig_mail_log-file_size.


  "------------------------------------------------------------
  " 1. Read jobs that are due
  "------------------------------------------------------------
  lt_due_jobs = get_due_jobs( ).

  IF lt_due_jobs IS INITIAL.
    RETURN.
  ENDIF.


  "------------------------------------------------------------
  " 2. Prepare Export Engine
  "------------------------------------------------------------
  CREATE OBJECT lo_export_provider
    TYPE zcl_mig_export_engine.


  LOOP AT lt_due_jobs INTO ls_due_job.

    CLEAR:
      ls_run_result,
      ls_export_result,
      ls_attachment,
      ls_template_context,
      ls_template_result,
      ls_mail_content,
      ls_send_result,
      ls_start_result,
      ls_finish_result,

      lv_execution_success,
      lv_schedule_updated,
      lv_overall_success,

      lv_run_id,
      lv_recipient_count,

      lv_result_message,
      lv_message_text,

      lv_generated_at,
      lv_changed_at,
      lv_new_next_run_at,

      lv_export_file_size.


    "----------------------------------------------------------
    " 3. Calculate next occurrence BEFORE sending
    "----------------------------------------------------------
    lv_new_next_run_at =
      calculate_next_run_at(
        is_due_job = ls_due_job
      ).


    IF lv_new_next_run_at IS INITIAL.

      MESSAGE e032(zmig_analysis)
        INTO lv_result_message.

      ls_run_result-job_id =
        ls_due_job-job_id.

      ls_run_result-job_name =
        ls_due_job-job_name.

      ls_run_result-success =
        abap_false.

      ls_run_result-previous_next_run_at =
        ls_due_job-next_run_at.

      ls_run_result-message =
        lv_result_message.

      APPEND ls_run_result TO rt_results.

      CONTINUE.

    ENDIF.


    "----------------------------------------------------------
    " 4. Claim this scheduled occurrence
    "
    " Atomic optimistic update:
    " only one runner can change the OLD NextRunAt value.
    "----------------------------------------------------------
    GET TIME STAMP FIELD lv_changed_at.

    UPDATE zmig_mail_job
      SET
        next_run_at           = @lv_new_next_run_at,
        last_changed_by       = @sy-uname,
        local_last_changed_at = @lv_changed_at,
        last_changed_at       = @lv_changed_at
      WHERE job_id      = @ls_due_job-job_id
        AND status      = @gc_status_active
        AND next_run_at = @ls_due_job-next_run_at.


    "----------------------------------------------------------
    " Another runner already claimed it, or job was deactivated.
    " Do NOT send the mail.
    "----------------------------------------------------------
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_schedule_updated = abap_true.


    "----------------------------------------------------------
    " 5. Generate report attachment
    "----------------------------------------------------------
    ls_export_result =
      lo_export_provider->generate(
        iv_job_id         = ls_due_job-job_id
        iv_analysis_id    = ls_due_job-analysis_id
        iv_report_type    = ls_due_job-report_type
        iv_file_format    = ls_due_job-file_format
        iv_export_section = gc_export_section_all
      ).


    "----------------------------------------------------------
    " 6. Export successful
    "----------------------------------------------------------
    IF ls_export_result-success = abap_true
       AND ls_export_result-content IS NOT INITIAL.


      "--------------------------------------------------------
      " Build attachment
      "--------------------------------------------------------
      ls_attachment-content =
        ls_export_result-content.

      ls_attachment-file_name =
        ls_export_result-file_name.

      ls_attachment-file_type =
        ls_export_result-file_type.

      ls_attachment-file_format =
        ls_export_result-file_format.


      "--------------------------------------------------------
      " Build mail template context
      "--------------------------------------------------------
      GET TIME STAMP FIELD lv_generated_at.

      ls_template_context-job_name =
        ls_due_job-job_name.

      ls_template_context-analysis_id =
        ls_due_job-analysis_id.

      ls_template_context-report_type =
        ls_due_job-report_type.

      ls_template_context-file_format =
        ls_export_result-file_format.

      ls_template_context-file_name =
        ls_export_result-file_name.

      ls_template_context-generated_at =
        lv_generated_at.


      "--------------------------------------------------------
      " Generate HTML mail template
      "--------------------------------------------------------
      ls_template_result =
        zcl_mig_mail_template=>get_export_success(
          is_context = ls_template_context
        ).

      ls_mail_content-subject =
        ls_template_result-subject.

      ls_mail_content-body =
        ls_template_result-body.


      "--------------------------------------------------------
      " Send through SAP BCS
      "--------------------------------------------------------
      ls_send_result =
        zcl_mig_mail_service=>send_job(
          iv_job_id       = ls_due_job-job_id
          iv_trigger_type = gc_trigger_scheduled
          is_mail_content = ls_mail_content
          is_attachment   = ls_attachment
        ).


      IF ls_send_result-request_created = abap_true
         AND ls_send_result-accepted_all = abap_true.

        lv_execution_success = abap_true.

      ELSE.

        lv_execution_success = abap_false.

      ENDIF.


      lv_run_id =
        ls_send_result-run_id.

      lv_recipient_count =
        ls_send_result-recipient_count.

      lv_result_message =
        ls_send_result-message.


    "----------------------------------------------------------
    " 7. Export failed before Mail Service was called
    "----------------------------------------------------------
    ELSE.

      lv_execution_success = abap_false.

      lv_result_message =
        ls_export_result-message.


      IF lv_result_message IS INITIAL.

        MESSAGE e031(zmig_analysis)
          INTO lv_result_message.

      ENDIF.


      "--------------------------------------------------------
      " Mail Service was not called, therefore create
      " the FAILED execution log here.
      "--------------------------------------------------------
      ls_start_result =
        zcl_mig_mail_log_service=>start_run(
          iv_job_id       = ls_due_job-job_id
          iv_trigger_type = gc_trigger_scheduled
          iv_file_format  = ls_due_job-file_format
        ).


      IF ls_start_result-success = abap_true.

        lv_run_id =
          ls_start_result-run_id.

        lv_export_file_size =
          xstrlen( ls_export_result-content ).


        ls_finish_result =
          zcl_mig_mail_log_service=>finish_run(
            iv_job_id          = ls_due_job-job_id
            iv_run_id          = lv_run_id
            iv_status          = gc_status_failed
            iv_file_name       = ls_export_result-file_name
            iv_file_format     = ls_due_job-file_format
            iv_file_size       = lv_export_file_size
            iv_recipient_count = 0
            iv_log_message     = lv_result_message
          ).


        IF ls_finish_result-success = abap_false.

          MESSAGE e035(zmig_analysis)
            WITH ls_finish_result-message
            INTO lv_message_text.

          lv_result_message =
            |{ lv_result_message } { lv_message_text }|.

        ENDIF.


      ELSE.

        MESSAGE e034(zmig_analysis)
          WITH ls_start_result-message
          INTO lv_message_text.

        lv_result_message =
          |{ lv_result_message } { lv_message_text }|.

      ENDIF.

    ENDIF.


    "----------------------------------------------------------
    " 8. Overall execution result
    "----------------------------------------------------------
    IF lv_execution_success = abap_true
       AND lv_schedule_updated = abap_true.

      lv_overall_success = abap_true.

    ELSE.

      lv_overall_success = abap_false.

    ENDIF.


    "----------------------------------------------------------
    " 9. Return runner result
    "----------------------------------------------------------
    ls_run_result-job_id =
      ls_due_job-job_id.

    ls_run_result-job_name =
      ls_due_job-job_name.

    ls_run_result-success =
      lv_overall_success.

    ls_run_result-run_id =
      lv_run_id.

    ls_run_result-recipient_count =
      lv_recipient_count.

    ls_run_result-previous_next_run_at =
      ls_due_job-next_run_at.

    ls_run_result-new_next_run_at =
      lv_new_next_run_at.

    ls_run_result-schedule_updated =
      lv_schedule_updated.

    ls_run_result-message =
      lv_result_message.


    APPEND ls_run_result TO rt_results.

  ENDLOOP.

ENDMETHOD.

METHOD calculate_next_run_at.

  DATA:
    lv_current_timestamp TYPE timestampl,
    lv_candidate         TYPE timestampl,
    lv_base_date         TYPE d,
    lv_base_time         TYPE t,
    lv_next_date         TYPE d.

  "----------------------------------------------------------
  " A recurring Mail Job must have its own time zone.
  "----------------------------------------------------------
  IF is_due_job-timezone IS INITIAL.
    CLEAR rv_next_run_at.
    RETURN.
  ENDIF.

  GET TIME STAMP FIELD lv_current_timestamp.

  " Start from the occurrence that has just been consumed.
  lv_candidate = is_due_job-next_run_at.

  DO gc_max_schedule_steps TIMES.

    "--------------------------------------------------------
    " Convert previous occurrence from UTC timestamp
    " into this Mail Job's local date/time.
    "--------------------------------------------------------
    CONVERT TIME STAMP lv_candidate
      TIME ZONE is_due_job-timezone
      INTO DATE lv_base_date
           TIME lv_base_time.

    IF sy-subrc <> 0.
      CLEAR rv_next_run_at.
      RETURN.
    ENDIF.


    "--------------------------------------------------------
    " Calculate following occurrence
    "--------------------------------------------------------
    CASE is_due_job-frequency.

      WHEN gc_frequency_daily.

        lv_next_date = lv_base_date + 1.

      WHEN gc_frequency_weekly.

        lv_next_date = lv_base_date + 7.

      WHEN gc_frequency_monthly.

        lv_next_date =
          get_next_monthly_date(
            iv_base_date    = lv_base_date
            iv_day_of_month = is_due_job-day_of_month
          ).

      WHEN OTHERS.

        CLEAR rv_next_run_at.
        RETURN.

    ENDCASE.


    IF lv_next_date IS INITIAL.
      CLEAR rv_next_run_at.
      RETURN.
    ENDIF.


    "--------------------------------------------------------
    " Convert next local occurrence back to UTC timestamp
    " using the Mail Job time zone.
    "--------------------------------------------------------
    CONVERT DATE lv_next_date
            TIME lv_base_time
      INTO TIME STAMP lv_candidate
      TIME ZONE is_due_job-timezone.

    IF sy-subrc <> 0.
      CLEAR rv_next_run_at.
      RETURN.
    ENDIF.


    "--------------------------------------------------------
    " Skip missed occurrences until a future timestamp
    " is found.
    "--------------------------------------------------------
    IF lv_candidate > lv_current_timestamp.

      rv_next_run_at = lv_candidate.
      RETURN.

    ENDIF.

  ENDDO.

  CLEAR rv_next_run_at.

ENDMETHOD.


  METHOD get_next_monthly_date.

    DATA:
      lv_month_start           TYPE d,
      lv_next_month_start      TYPE d,
      lv_following_month_start TYPE d,
      lv_last_day              TYPE d,
      lv_requested_day         TYPE i,
      lv_last_day_number       TYPE i,
      lv_day_numc              TYPE n LENGTH 2.

    lv_requested_day = CONV i( iv_day_of_month ).

    IF lv_requested_day < 1
       OR lv_requested_day > 31.

      CLEAR rv_next_date.
      RETURN.

    ENDIF.


    "----------------------------------------------------------
    " Determine first day of current month
    "----------------------------------------------------------
    lv_month_start = iv_base_date.
    lv_month_start+6(2) = '01'.


    "----------------------------------------------------------
    " Determine first day of next month
    "----------------------------------------------------------
    lv_next_month_start = lv_month_start + 31.
    lv_next_month_start+6(2) = '01'.


    "----------------------------------------------------------
    " Determine last day of next month
    "----------------------------------------------------------
    lv_following_month_start = lv_next_month_start + 31.
    lv_following_month_start+6(2) = '01'.

    lv_last_day = lv_following_month_start - 1.

    lv_last_day_number =
      CONV i( lv_last_day+6(2) ).


    "----------------------------------------------------------
    " Clamp requested day to last valid day of next month
    "----------------------------------------------------------
    IF lv_requested_day > lv_last_day_number.

      rv_next_date = lv_last_day.

    ELSE.

      lv_day_numc = lv_requested_day.

      rv_next_date = lv_next_month_start.
      rv_next_date+6(2) = lv_day_numc.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
