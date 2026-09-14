CLASS lhc_MailJob DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
CONSTANTS:
  gc_frequency_on_demand TYPE zmig_e_frequency VALUE 'O',
  gc_frequency_daily     TYPE zmig_e_frequency VALUE 'D',
  gc_frequency_weekly    TYPE zmig_e_frequency VALUE 'W',
  gc_frequency_monthly   TYPE zmig_e_frequency VALUE 'M',
  gc_status_active       TYPE zmig_e_job_status VALUE 'A',
  gc_export_section_all  TYPE zmig_e_report_section VALUE 'ALL',
  gc_monday_anchor       TYPE d VALUE '19000101'.
" Declare methods validation"
   METHODS get_global_authorizations
  FOR GLOBAL AUTHORIZATION
  IMPORTING
    REQUEST requested_authorizations FOR MailJob
  RESULT result.

METHODS validateRequiredFields
  FOR VALIDATE ON SAVE
  IMPORTING keys FOR MailJob~validateRequiredFields.

METHODS validateSchedule
  FOR VALIDATE ON SAVE
  IMPORTING keys FOR MailJob~validateSchedule.

METHODS validateHasRecipient
  FOR VALIDATE ON SAVE
  IMPORTING keys FOR MailJob~validateHasRecipient.

METHODS calculateNextRunAt
  FOR DETERMINE ON MODIFY
  IMPORTING keys FOR MailJob~calculateNextRunAt.

METHODS sendNow
  FOR MODIFY
  IMPORTING keys FOR ACTION MailJob~sendNow
  RESULT result.

METHODS get_month_start
  IMPORTING
    iv_date         TYPE d
    iv_month_offset TYPE i
  RETURNING
    VALUE(rv_month_start) TYPE d.

METHODS get_monthly_run_date
  IMPORTING
    iv_base_date    TYPE d
    iv_day_of_month TYPE zmig_mail_job-day_of_month
  RETURNING
    VALUE(rv_run_date) TYPE d.


ENDCLASS.


CLASS lhc_MailJob IMPLEMENTATION.

  METHOD get_global_authorizations.

   " Mail BO does not currently enforce role-based authorization.
  " All supported CRUD operations are allowed.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.

  " Validate mandatory job fields.
  METHOD validateRequiredFields.

  TYPES:
    BEGIN OF ty_analysis_key,
      analysis_id TYPE zmig_anl_h-analysis_id,
      program_name TYPE zmig_anl_h-program_name,
    END OF ty_analysis_key,

    tt_analysis_key TYPE HASHED TABLE OF ty_analysis_key
      WITH UNIQUE KEY analysis_id program_name,

    tt_analysis_request TYPE SORTED TABLE OF ty_analysis_key
      WITH UNIQUE KEY analysis_id program_name.

  DATA:
    lt_analysis_request TYPE tt_analysis_request,
    lt_valid_analysis   TYPE tt_analysis_key,
    lv_has_error        TYPE abap_bool,
    lv_analysis_text    TYPE symsgv,
    lv_report_text      TYPE symsgv.


  " Read affected jobs once from RAP transactional buffer
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob
      FIELDS (
        AnalysisId
        JobName
        ReportType
        FileFormat
        Frequency
      )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_jobs).


  " Collect unique AnalysisId + ReportType pairs for batch lookup
  LOOP AT lt_jobs INTO DATA(ls_job).

    IF ls_job-AnalysisId IS NOT INITIAL
       AND ls_job-ReportType IS NOT INITIAL.

      INSERT VALUE #(
        analysis_id = ls_job-AnalysisId
        program_name = ls_job-ReportType
      ) INTO TABLE lt_analysis_request.

    ENDIF.

  ENDLOOP.


  " One database access for all affected jobs
  IF lt_analysis_request IS NOT INITIAL.

    SELECT
      analysis_id,
      program_name
      FROM zmig_anl_h
      FOR ALL ENTRIES IN @lt_analysis_request
      WHERE analysis_id = @lt_analysis_request-analysis_id
        AND program_name = @lt_analysis_request-program_name
      INTO TABLE @DATA(lt_valid_analysis_db).

    LOOP AT lt_valid_analysis_db INTO DATA(ls_valid_analysis).

      INSERT VALUE #(
        analysis_id = ls_valid_analysis-analysis_id
        program_name = ls_valid_analysis-program_name
      ) INTO TABLE lt_valid_analysis.

    ENDLOOP.

  ENDIF.


  " Validate jobs in memory only
  LOOP AT lt_jobs INTO ls_job.

    CLEAR:
      lv_has_error,
      lv_analysis_text,
      lv_report_text.

    lv_has_error = abap_false.


    IF ls_job-AnalysisId IS INITIAL.

      lv_has_error = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '038'
                 severity = if_abap_behv_message=>severity-error
               )
        %element-AnalysisId = if_abap_behv=>mk-on
      ) TO reported-MailJob.

    ENDIF.


    IF ls_job-JobName IS INITIAL.

      lv_has_error = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '009'
                 severity = if_abap_behv_message=>severity-error
               )
        %element-JobName = if_abap_behv=>mk-on
      ) TO reported-MailJob.

    ENDIF.


    IF ls_job-ReportType IS INITIAL.

      lv_has_error = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '010'
                 severity = if_abap_behv_message=>severity-error
               )
        %element-ReportType = if_abap_behv=>mk-on
      ) TO reported-MailJob.

    ENDIF.


    IF ls_job-FileFormat IS INITIAL.

      lv_has_error = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '011'
                 severity = if_abap_behv_message=>severity-error
               )
        %element-FileFormat = if_abap_behv=>mk-on
      ) TO reported-MailJob.

    ENDIF.


    IF ls_job-Frequency IS INITIAL.

      lv_has_error = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '012'
                 severity = if_abap_behv_message=>severity-error
               )
        %element-Frequency = if_abap_behv=>mk-on
      ) TO reported-MailJob.

    ENDIF.


    " AnalysisId must belong to the selected report
    IF ls_job-AnalysisId IS NOT INITIAL
       AND ls_job-ReportType IS NOT INITIAL.

      READ TABLE lt_valid_analysis
        WITH TABLE KEY
          analysis_id = ls_job-AnalysisId
          program_name = ls_job-ReportType
        TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.

        lv_has_error = abap_true.

        lv_analysis_text = |{ ls_job-AnalysisId }|.
        lv_report_text   = ls_job-ReportType.

        APPEND VALUE #(
          %tky = ls_job-%tky
          %msg = new_message(
                   id       = 'ZMIG_ANALYSIS'
                   number   = '039'
                   severity = if_abap_behv_message=>severity-error
                   v1       = lv_analysis_text
                   v2       = lv_report_text
                 )
          %element-AnalysisId = if_abap_behv=>mk-on
          %element-ReportType = if_abap_behv=>mk-on
        ) TO reported-MailJob.

      ENDIF.

    ENDIF.


    IF lv_has_error = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
      ) TO failed-MailJob.

    ENDIF.

  ENDLOOP.

ENDMETHOD.
" Validate scheduling configuration.
METHOD validateSchedule.

  DATA:
    lv_has_error TYPE abap_bool,
    lv_frequency TYPE symsgv.

  "----------------------------------------------------------
  " Read affected Mail Jobs
  "----------------------------------------------------------
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob
      FIELDS (
        Frequency
        JobTimeZone
        StartDate
        StartTime
        DayOfWeek
        DayOfMonth
      )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_jobs).


  "----------------------------------------------------------
  " Load valid SAP time zones ONCE.
  " Do not SELECT inside LOOP.
  "----------------------------------------------------------
  DATA lt_valid_time_zones
    TYPE HASHED TABLE OF ttzz-tzone
    WITH UNIQUE KEY table_line.

  SELECT FROM ttzz
    FIELDS tzone
    INTO TABLE @lt_valid_time_zones.


  "----------------------------------------------------------
  " Validate each Mail Job
  "----------------------------------------------------------
  LOOP AT lt_jobs INTO DATA(ls_job).

    CLEAR:
      lv_has_error,
      lv_frequency.

    lv_has_error = abap_false.


    "--------------------------------------------------------
    " Frequency mandatory validation is handled by
    " validateRequiredFields.
    " Avoid duplicate messages here.
    "--------------------------------------------------------
    IF ls_job-Frequency IS INITIAL.
      CONTINUE.
    ENDIF.


    "--------------------------------------------------------
    " Validate supported frequency
    "
    " O = On Demand
    " D = Daily
    " W = Weekly
    " M = Monthly
    "--------------------------------------------------------
    IF ls_job-Frequency <> gc_frequency_on_demand
       AND ls_job-Frequency <> gc_frequency_daily
       AND ls_job-Frequency <> gc_frequency_weekly
       AND ls_job-Frequency <> gc_frequency_monthly.

      lv_has_error = abap_true.

      lv_frequency =
        CONV symsgv( ls_job-Frequency ).

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '019'
                 severity = if_abap_behv_message=>severity-error
                 v1       = lv_frequency
               )
        %element-Frequency = if_abap_behv=>mk-on
      ) TO reported-MailJob.


    "--------------------------------------------------------
    " Scheduled jobs: Daily / Weekly / Monthly
    "--------------------------------------------------------
    ELSEIF ls_job-Frequency <> gc_frequency_on_demand.


      "------------------------------------------------------
      " Time zone is mandatory for scheduled jobs.
      "------------------------------------------------------
      IF ls_job-JobTimeZone IS INITIAL.

        lv_has_error = abap_true.

        APPEND VALUE #(
          %tky = ls_job-%tky
          %msg = new_message(
                   id       = 'ZMIG_ANALYSIS'
                   number   = '040'
                   severity = if_abap_behv_message=>severity-error
                 )
          %element-JobTimeZone = if_abap_behv=>mk-on
        ) TO reported-MailJob.

      ELSE.

        "----------------------------------------------------
        " Validate that JobTimeZone exists in SAP TTZZ.
        "----------------------------------------------------
        DATA(lv_time_zone) =
          CONV ttzz-tzone( ls_job-JobTimeZone ).

        IF NOT line_exists(
          lt_valid_time_zones[
            table_line = lv_time_zone
          ]
        ).

          lv_has_error = abap_true.

          APPEND VALUE #(
            %tky = ls_job-%tky
            %msg = new_message(
                     id       = 'ZMIG_ANALYSIS'
                     number   = '041'
                     severity = if_abap_behv_message=>severity-error
                     v1       = CONV symsgv(
                                  ls_job-JobTimeZone
                                )
                   )
            %element-JobTimeZone = if_abap_behv=>mk-on
          ) TO reported-MailJob.

        ENDIF.

      ENDIF.


      "------------------------------------------------------
      " Scheduled jobs require StartDate.
      "
      " Do NOT reject historical StartDate.
      " Recurring jobs naturally keep their original
      " configured start date.
      "------------------------------------------------------
      IF ls_job-StartDate IS INITIAL.

        lv_has_error = abap_true.

        APPEND VALUE #(
          %tky = ls_job-%tky
          %msg = new_message(
                   id       = 'ZMIG_ANALYSIS'
                   number   = '014'
                   severity = if_abap_behv_message=>severity-error
                 )
          %element-StartDate = if_abap_behv=>mk-on
        ) TO reported-MailJob.

      ENDIF.


      "------------------------------------------------------
      " StartTime is intentionally NOT validated using
      " IS INITIAL.
      "
      " ABAP TIMS 000000 represents 00:00:00 and is also
      " the type's initial value.
      "
      " Midnight is therefore valid.
      "------------------------------------------------------


      "------------------------------------------------------
      " Weekly schedule
      "
      " DayOfWeek:
      " 1 = Monday
      " ...
      " 7 = Sunday
      "------------------------------------------------------
      IF ls_job-Frequency = gc_frequency_weekly.

        IF ls_job-DayOfWeek < '1'
           OR ls_job-DayOfWeek > '7'.

          lv_has_error = abap_true.

          APPEND VALUE #(
            %tky = ls_job-%tky
            %msg = new_message(
                     id       = 'ZMIG_ANALYSIS'
                     number   = '017'
                     severity = if_abap_behv_message=>severity-error
                   )
            %element-DayOfWeek = if_abap_behv=>mk-on
          ) TO reported-MailJob.

        ENDIF.

      ENDIF.


      "------------------------------------------------------
      " Monthly schedule
      "
      " Valid DayOfMonth = 01 ... 31
      "------------------------------------------------------
      IF ls_job-Frequency = gc_frequency_monthly.

        IF ls_job-DayOfMonth < '01'
           OR ls_job-DayOfMonth > '31'.

          lv_has_error = abap_true.

          APPEND VALUE #(
            %tky = ls_job-%tky
            %msg = new_message(
                     id       = 'ZMIG_ANALYSIS'
                     number   = '018'
                     severity = if_abap_behv_message=>severity-error
                   )
            %element-DayOfMonth = if_abap_behv=>mk-on
          ) TO reported-MailJob.

        ENDIF.

      ENDIF.

    ENDIF.


    "--------------------------------------------------------
    " Mark Mail Job as failed when any schedule validation
    " failed.
    "--------------------------------------------------------
    IF lv_has_error = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
      ) TO failed-MailJob.

    ENDIF.

  ENDLOOP.

ENDMETHOD.
" Ensure active jobs have at least one recipient.
METHOD validateHasRecipient.

  "Read affected Mail Jobs from the RAP transactional buffer.
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob
      FIELDS (
        Status
      )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_jobs)
    FAILED DATA(lt_read_failed).

  IF lt_read_failed-MailJob IS NOT INITIAL.
    RETURN.
  ENDIF.

  "Only Active Mail Jobs require at least one recipient.
  DELETE lt_jobs WHERE Status <> gc_status_active.

  IF lt_jobs IS INITIAL.
    RETURN.
  ENDIF.

  "Read recipients belonging to the affected Mail Jobs.
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob BY \_Recipients
      FIELDS (
        RecipientId
      )
      WITH CORRESPONDING #( lt_jobs )
    RESULT DATA(lt_recipients).

  "Store JobIds that already have at least one recipient.
  TYPES tt_job_id TYPE HASHED TABLE OF sysuuid_x16
    WITH UNIQUE KEY table_line.

  DATA lt_jobs_with_recipient TYPE tt_job_id.

  LOOP AT lt_recipients INTO DATA(ls_recipient).

    INSERT ls_recipient-JobId
      INTO TABLE lt_jobs_with_recipient.

  ENDLOOP.

  LOOP AT lt_jobs INTO DATA(ls_job).

    IF line_exists(
      lt_jobs_with_recipient[
        table_line = ls_job-JobId
      ]
    ).
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      %tky = ls_job-%tky
    ) TO failed-MailJob.

    APPEND VALUE #(
      %tky            = ls_job-%tky
      %msg            = new_message(
                          id       = 'ZMIG_ANALYSIS'
                          number   = '026'
                          severity = if_abap_behv_message=>severity-error )
      %element-Status = if_abap_behv=>mk-on
    ) TO reported-MailJob.

  ENDLOOP.

ENDMETHOD.

 METHOD get_month_start.

  DATA:
    lv_year       TYPE i,
    lv_month      TYPE i,
    lv_year_text  TYPE n LENGTH 4,
    lv_month_text TYPE n LENGTH 2.

  lv_year  = iv_date+0(4).
  lv_month = iv_date+4(2).

  lv_month = lv_month + iv_month_offset.

  WHILE lv_month > 12.
    lv_month = lv_month - 12.
    lv_year  = lv_year + 1.
  ENDWHILE.

  lv_year_text  = lv_year.
  lv_month_text = lv_month.

  rv_month_start+0(4) = lv_year_text.
  rv_month_start+4(2) = lv_month_text.
  rv_month_start+6(2) = '01'.

ENDMETHOD.

METHOD get_monthly_run_date.

  DATA:
    lv_month_start     TYPE d,
    lv_next_month      TYPE d,
    lv_last_day        TYPE d,
    lv_requested_day   TYPE i,
    lv_last_day_number TYPE i.

  lv_month_start = get_month_start(
    iv_date         = iv_base_date
    iv_month_offset = 0
  ).

  lv_next_month = get_month_start(
    iv_date         = iv_base_date
    iv_month_offset = 1
  ).

  lv_last_day = lv_next_month - 1.

  lv_requested_day   = iv_day_of_month.
  lv_last_day_number = lv_last_day+6(2).

 " If the requested day does not exist in the month,
" use the month's last calendar day.
  IF lv_requested_day > lv_last_day_number.
    lv_requested_day = lv_last_day_number.
  ENDIF.

  rv_run_date = lv_month_start + lv_requested_day - 1.

ENDMETHOD.

METHOD calculateNextRunAt.

  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob
      FIELDS (
        Frequency
        JobTimeZone
        StartDate
        StartTime
        DayOfWeek
        DayOfMonth
        Status
        NextRunAt
      )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_jobs).

  DATA lv_now TYPE timestampl.

  GET TIME STAMP FIELD lv_now.

  DATA lt_job_updates
    TYPE TABLE FOR UPDATE zi_mig_mail_job.

  LOOP AT lt_jobs INTO DATA(ls_job).

    DATA:
      lv_today             TYPE d,
      lv_current_time      TYPE t,
      lv_next_run          TYPE timestampl,
      lv_candidate_date    TYPE d,
      lv_candidate_ts      TYPE timestampl,
      lv_base_date         TYPE d,
      lv_days_from_anchor  TYPE i,
      lv_current_weekday   TYPE i,
      lv_target_weekday    TYPE i,
      lv_day_offset        TYPE i.

    CLEAR:
      lv_today,
      lv_current_time,
      lv_next_run,
      lv_candidate_date,
      lv_candidate_ts,
      lv_base_date,
      lv_days_from_anchor,
      lv_current_weekday,
      lv_target_weekday,
      lv_day_offset.

    "Only active recurring jobs have NextRunAt
    IF ls_job-Status = gc_status_active
       AND ls_job-Frequency <> gc_frequency_on_demand
       AND ls_job-StartDate IS NOT INITIAL.

      "A scheduled job must have its own time zone.
      IF ls_job-JobTimeZone IS NOT INITIAL.

        "Convert UTC now to THIS JOB's local calendar date/time.
        CONVERT TIME STAMP lv_now
          TIME ZONE ls_job-JobTimeZone
          INTO DATE lv_today
               TIME lv_current_time.

        CASE ls_job-Frequency.

          "------------------------------------------------------
          " DAILY
          "------------------------------------------------------
          WHEN gc_frequency_daily.

            IF ls_job-StartDate > lv_today.
              lv_candidate_date = ls_job-StartDate.
            ELSE.
              lv_candidate_date = lv_today.
            ENDIF.

            CONVERT DATE lv_candidate_date
                    TIME ls_job-StartTime
              INTO TIME STAMP lv_candidate_ts
              TIME ZONE ls_job-JobTimeZone.

            "Today's occurrence has already passed.
            IF lv_candidate_ts <= lv_now.

              lv_candidate_date = lv_candidate_date + 1.

              CONVERT DATE lv_candidate_date
                      TIME ls_job-StartTime
                INTO TIME STAMP lv_candidate_ts
                TIME ZONE ls_job-JobTimeZone.

            ENDIF.

            lv_next_run = lv_candidate_ts.


          "------------------------------------------------------
          " WEEKLY
          "------------------------------------------------------
          WHEN gc_frequency_weekly.

            IF ls_job-DayOfWeek IS NOT INITIAL.

              IF ls_job-StartDate > lv_today.
                lv_base_date = ls_job-StartDate.
              ELSE.
                lv_base_date = lv_today.
              ENDIF.

              "1 = Monday ... 7 = Sunday
              lv_days_from_anchor =
                lv_base_date - gc_monday_anchor.

              lv_current_weekday =
                ( lv_days_from_anchor MOD 7 ) + 1.

              lv_target_weekday = ls_job-DayOfWeek.

              lv_day_offset =
                lv_target_weekday - lv_current_weekday.

              IF lv_day_offset < 0.
                lv_day_offset = lv_day_offset + 7.
              ENDIF.

              lv_candidate_date =
                lv_base_date + lv_day_offset.

              CONVERT DATE lv_candidate_date
                      TIME ls_job-StartTime
                INTO TIME STAMP lv_candidate_ts
                TIME ZONE ls_job-JobTimeZone.

              "This week's occurrence already passed.
              IF lv_candidate_ts <= lv_now.

                lv_candidate_date =
                  lv_candidate_date + 7.

                CONVERT DATE lv_candidate_date
                        TIME ls_job-StartTime
                  INTO TIME STAMP lv_candidate_ts
                  TIME ZONE ls_job-JobTimeZone.

              ENDIF.

              lv_next_run = lv_candidate_ts.

            ENDIF.


          "------------------------------------------------------
          " MONTHLY
          "------------------------------------------------------
          WHEN gc_frequency_monthly.

            IF ls_job-DayOfMonth IS NOT INITIAL.

              IF ls_job-StartDate > lv_today.
                lv_base_date = ls_job-StartDate.
              ELSE.
                lv_base_date = lv_today.
              ENDIF.

              lv_candidate_date = get_monthly_run_date(
                iv_base_date    = lv_base_date
                iv_day_of_month = ls_job-DayOfMonth
              ).

              CONVERT DATE lv_candidate_date
                      TIME ls_job-StartTime
                INTO TIME STAMP lv_candidate_ts
                TIME ZONE ls_job-JobTimeZone.

              "Move to next month if this occurrence passed
              "or falls before configured StartDate.
              IF lv_candidate_date < ls_job-StartDate
                 OR lv_candidate_ts <= lv_now.

                lv_base_date = get_month_start(
                  iv_date         = lv_base_date
                  iv_month_offset = 1
                ).

                lv_candidate_date = get_monthly_run_date(
                  iv_base_date    = lv_base_date
                  iv_day_of_month = ls_job-DayOfMonth
                ).

                CONVERT DATE lv_candidate_date
                        TIME ls_job-StartTime
                  INTO TIME STAMP lv_candidate_ts
                  TIME ZONE ls_job-JobTimeZone.

              ENDIF.

              lv_next_run = lv_candidate_ts.

            ENDIF.


          WHEN OTHERS.
            CLEAR lv_next_run.

        ENDCASE.

      ENDIF.

    ENDIF.

    APPEND VALUE #(
      %tky               = ls_job-%tky
      NextRunAt          = lv_next_run
      %control-NextRunAt = if_abap_behv=>mk-on
    ) TO lt_job_updates.

  ENDLOOP.

  IF lt_job_updates IS NOT INITIAL.

    MODIFY ENTITIES OF zi_mig_mail_job IN LOCAL MODE
      ENTITY MailJob
        UPDATE FIELDS (
          NextRunAt
        )
        WITH lt_job_updates.

  ENDIF.

ENDMETHOD.

METHOD sendNow.

  CONSTANTS:
    lc_trigger_manual TYPE zmig_e_trigger_type VALUE 'M',
    lc_status_failed  TYPE zmig_e_run_status   VALUE 'F'.

  DATA:
    lo_export_provider TYPE REF TO zif_mig_export_provider,

    ls_export_result   TYPE zif_mig_export_provider=>ty_export_result,
    ls_attachment      TYPE zcl_mig_mail_service=>ty_attachment,
    ls_template_context TYPE zcl_mig_mail_template=>ty_context,
    ls_template_result TYPE zcl_mig_mail_template=>ty_mail_content,
    ls_mail_content    TYPE zcl_mig_mail_service=>ty_mail_content,
    ls_send_result     TYPE zcl_mig_mail_service=>ty_send_result,

    ls_log_start       TYPE zcl_mig_mail_log_service=>ty_start_result,
    ls_log_finish      TYPE zcl_mig_mail_log_service=>ty_finish_result,

    lv_generated_at    TYPE timestampl,
    lv_file_size       TYPE zmig_mail_log-file_size,
    lv_success         TYPE abap_bool,
    lv_result_message  TYPE string,
    lv_log_message     TYPE string,
    lv_message_variable TYPE symsgv.


  "------------------------------------------------------------
  " Read selected Mail Jobs from RAP transactional buffer
  "------------------------------------------------------------
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob
      ALL FIELDS
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_jobs)
    FAILED DATA(lt_read_failed)
    REPORTED DATA(lt_read_reported).


  "------------------------------------------------------------
  " Forward read errors
  "------------------------------------------------------------
  IF lt_read_failed-MailJob IS NOT INITIAL.

    APPEND LINES OF lt_read_failed-MailJob
      TO failed-MailJob.

  ENDIF.

  IF lt_read_reported-MailJob IS NOT INITIAL.

    APPEND LINES OF lt_read_reported-MailJob
      TO reported-MailJob.

  ENDIF.


  "------------------------------------------------------------
  " Export engine
  "------------------------------------------------------------
  CREATE OBJECT lo_export_provider
    TYPE zcl_mig_export_engine.


  LOOP AT lt_jobs INTO DATA(ls_job).

    CLEAR:
      ls_export_result,
      ls_attachment,
      ls_template_context,
      ls_template_result,
      ls_mail_content,
      ls_send_result,
      ls_log_start,
      ls_log_finish,
      lv_generated_at,
      lv_file_size,
      lv_success,
      lv_result_message,
      lv_log_message,
      lv_message_variable.


    "----------------------------------------------------------
    " 1. Generate report file
    "----------------------------------------------------------
    ls_export_result =
      lo_export_provider->generate(
        iv_job_id         = ls_job-JobId
        iv_analysis_id    = ls_job-AnalysisId
        iv_report_type    = ls_job-ReportType
        iv_file_format    = ls_job-FileFormat
        iv_export_section = gc_export_section_all
      ).


    "----------------------------------------------------------
    " 2. Export successful
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
      " Build template context
      "--------------------------------------------------------
      GET TIME STAMP FIELD lv_generated_at.

      ls_template_context-job_name =
        ls_job-JobName.

      ls_template_context-analysis_id =
        ls_job-AnalysisId.

      ls_template_context-report_type =
        ls_job-ReportType.

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
      " 3. Send mail with generated attachment
      "--------------------------------------------------------
      ls_send_result =
        zcl_mig_mail_service=>send_job(
          iv_job_id       = ls_job-JobId
          iv_trigger_type = lc_trigger_manual
          is_mail_content = ls_mail_content
          is_attachment   = ls_attachment
        ).


      IF ls_send_result-request_created = abap_true
         AND ls_send_result-accepted_all = abap_true.

        lv_success = abap_true.

      ELSE.

        lv_success = abap_false.

      ENDIF.

      lv_result_message =
        ls_send_result-message.


    "----------------------------------------------------------
    " 4. Export failed before Mail Service was called
    "----------------------------------------------------------
    ELSE.

      lv_success = abap_false.

      lv_result_message =
        ls_export_result-message.


      IF lv_result_message IS INITIAL.

        MESSAGE ID 'ZMIG_ANALYSIS'
          TYPE 'E'
          NUMBER '031'
          INTO lv_result_message.

      ENDIF.


      "--------------------------------------------------------
      " Because Mail Service was never called,
      " create the failed execution log here.
      "--------------------------------------------------------
      ls_log_start =
        zcl_mig_mail_log_service=>start_run(
          iv_job_id       = ls_job-JobId
          iv_trigger_type = lc_trigger_manual
          iv_file_format  = ls_job-FileFormat
        ).


      IF ls_log_start-success = abap_true.

        lv_file_size =
          xstrlen( ls_export_result-content ).

        ls_log_finish =
          zcl_mig_mail_log_service=>finish_run(
            iv_job_id          = ls_job-JobId
            iv_run_id          = ls_log_start-run_id
            iv_status          = lc_status_failed
            iv_file_name       = ls_export_result-file_name
            iv_file_format     = ls_job-FileFormat
            iv_file_size       = lv_file_size
            iv_recipient_count = 0
            iv_log_message     = lv_result_message
          ).


        IF ls_log_finish-success = abap_false.

          MESSAGE ID 'ZMIG_ANALYSIS'
            TYPE 'E'
            NUMBER '035'
            WITH ls_log_finish-message
            INTO lv_log_message.

          lv_result_message =
            |{ lv_result_message } { lv_log_message }|.

        ENDIF.


      ELSE.

        MESSAGE ID 'ZMIG_ANALYSIS'
          TYPE 'E'
          NUMBER '034'
          WITH ls_log_start-message
          INTO lv_log_message.

        lv_result_message =
          |{ lv_result_message } { lv_log_message }|.

      ENDIF.

    ENDIF.


    "----------------------------------------------------------
    " 5. Return RAP message
    "----------------------------------------------------------
    IF lv_success = abap_true.

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '027'
                 severity = if_abap_behv_message=>severity-success
               )
      ) TO reported-MailJob.


    ELSE.

      lv_message_variable =
        CONV symsgv( lv_result_message ).

      APPEND VALUE #(
        %tky = ls_job-%tky
        %msg = new_message(
                 id       = 'ZMIG_ANALYSIS'
                 number   = '028'
                 severity = if_abap_behv_message=>severity-warning
                 v1       = lv_message_variable
               )
      ) TO reported-MailJob.

    ENDIF.


    "----------------------------------------------------------
    " Action result [1] $self
    "----------------------------------------------------------
    APPEND VALUE #(
      %tky   = ls_job-%tky
      %param = ls_job
    ) TO result.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.

CLASS lhc_Recipient DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

   CONSTANTS:
  gc_recipient_to  TYPE zmig_e_recip_type VALUE 'T',
  gc_recipient_cc  TYPE zmig_e_recip_type VALUE 'C',
  gc_recipient_bcc TYPE zmig_e_recip_type VALUE 'B',
  gc_status_active TYPE zmig_e_job_status  VALUE 'A'.

    TYPES:
      tt_sap_user TYPE SORTED TABLE OF xubname
        WITH UNIQUE KEY table_line,

      BEGIN OF ty_user_info,
        sap_user     TYPE xubname,
        email_address TYPE ad_smtpadr,
      END OF ty_user_info,

      tt_user_info TYPE HASHED TABLE OF ty_user_info
        WITH UNIQUE KEY sap_user.

    METHODS resolveEmail
      FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Recipient~resolveEmail.

    METHODS validateRecipient
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Recipient~validateRecipient.

    METHODS getUserInfo
      IMPORTING
        it_sap_users TYPE tt_sap_user
      RETURNING
        VALUE(rt_user_info) TYPE tt_user_info.

METHODS validateNoDuplicate
  FOR VALIDATE ON SAVE
  IMPORTING keys FOR Recipient~validateNoDuplicate.

METHODS validateParentHasRecipient
  FOR VALIDATE ON SAVE
  IMPORTING keys FOR Recipient~validateParentHasRecipient.

ENDCLASS.

"Implementaion for validation Recipient"
CLASS lhc_Recipient IMPLEMENTATION.

  METHOD getUserInfo.

    IF it_sap_users IS INITIAL.
      RETURN.
    ENDIF.

    "Read existing SAP users in one database access.
    SELECT FROM usr02
      FIELDS bname AS sap_user
      FOR ALL ENTRIES IN @it_sap_users
      WHERE bname = @it_sap_users-table_line
      INTO TABLE @DATA(lt_existing_users).

    LOOP AT lt_existing_users INTO DATA(ls_existing_user).

      INSERT VALUE #(
        sap_user = ls_existing_user-sap_user
      ) INTO TABLE rt_user_info.

    ENDLOOP.

    "Read all maintained email addresses in one database access.
    SELECT FROM usr21 AS user_address
      INNER JOIN adr6 AS email
        ON  email~addrnumber = user_address~addrnumber
        AND email~persnumber = user_address~persnumber
      FIELDS
        user_address~bname AS sap_user,
        email~smtp_addr    AS email_address,
        email~flgdefault   AS is_default
      FOR ALL ENTRIES IN @it_sap_users
      WHERE user_address~bname = @it_sap_users-table_line
        AND email~smtp_addr <> @space
      INTO TABLE @DATA(lt_email_candidates).

    "Default email is selected first when a user has several addresses.
    SORT lt_email_candidates BY
      sap_user
      is_default DESCENDING.

    LOOP AT lt_email_candidates INTO DATA(ls_email_candidate).

      READ TABLE rt_user_info
        ASSIGNING FIELD-SYMBOL(<ls_user_info>)
        WITH TABLE KEY
          sap_user = ls_email_candidate-sap_user.

      IF sy-subrc = 0
         AND <ls_user_info>-email_address IS INITIAL.

        <ls_user_info>-email_address =
          ls_email_candidate-email_address.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD resolveEmail.

    READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
      ENTITY Recipient
        FIELDS (
          SapUser
          EmailAddress
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_recipients).

    DATA lt_sap_users TYPE tt_sap_user.

    LOOP AT lt_recipients INTO DATA(ls_recipient).

      IF ls_recipient-SapUser IS NOT INITIAL.
        INSERT ls_recipient-SapUser
          INTO TABLE lt_sap_users.
      ENDIF.

    ENDLOOP.

    DATA(lt_user_info) = getUserInfo(
      it_sap_users = lt_sap_users
    ).

  DATA lt_recipient_updates
      TYPE TABLE FOR UPDATE zi_mig_mail_recip.

    LOOP AT lt_recipients INTO ls_recipient.

      DATA(lv_email_address) =
        VALUE ad_smtpadr(
          lt_user_info[
            sap_user = ls_recipient-SapUser
          ]-email_address OPTIONAL
        ).

      APPEND VALUE #(
        %tky                  = ls_recipient-%tky
        EmailAddress          = lv_email_address
        %control-EmailAddress = if_abap_behv=>mk-on
      ) TO lt_recipient_updates.

    ENDLOOP.

    IF lt_recipient_updates IS NOT INITIAL.

      MODIFY ENTITIES OF zi_mig_mail_job IN LOCAL MODE
        ENTITY Recipient
          UPDATE FIELDS (
            EmailAddress
          )
          WITH lt_recipient_updates.

    ENDIF.

  ENDMETHOD.


  METHOD validateRecipient.

    READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
      ENTITY Recipient
        FIELDS (
          RecipientType
          SapUser
          EmailAddress
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_recipients).

    DATA lt_sap_users TYPE tt_sap_user.

    LOOP AT lt_recipients INTO DATA(ls_recipient).

      IF ls_recipient-SapUser IS NOT INITIAL.
        INSERT ls_recipient-SapUser
          INTO TABLE lt_sap_users.
      ENDIF.

    ENDLOOP.

    DATA(lt_user_info) = getUserInfo(
      it_sap_users = lt_sap_users
    ).

    LOOP AT lt_recipients INTO ls_recipient.

      DATA(lv_has_error) = abap_false.

      "Recipient type is mandatory.
      IF ls_recipient-RecipientType IS INITIAL.

        lv_has_error = abap_true.

        APPEND VALUE #(
          %tky                   = ls_recipient-%tky
          %msg                   = new_message(
                                     id       = 'ZMIG_ANALYSIS'
                                     number   = '020'
                                     severity = if_abap_behv_message=>severity-error )
          %element-RecipientType = if_abap_behv=>mk-on
        ) TO reported-Recipient.

      ELSEIF ls_recipient-RecipientType <> gc_recipient_to
         AND ls_recipient-RecipientType <> gc_recipient_cc
         AND ls_recipient-RecipientType <> gc_recipient_bcc.

        lv_has_error = abap_true.

        APPEND VALUE #(
          %tky                   = ls_recipient-%tky
          %msg                   = new_message(
                                     id       = 'ZMIG_ANALYSIS'
                                     number   = '024'
                                     severity = if_abap_behv_message=>severity-error
                                     v1       = ls_recipient-RecipientType )
          %element-RecipientType = if_abap_behv=>mk-on
        ) TO reported-Recipient.

      ENDIF.

      "SAP user is mandatory.
      IF ls_recipient-SapUser IS INITIAL.

        lv_has_error = abap_true.

        APPEND VALUE #(
          %tky              = ls_recipient-%tky
          %msg              = new_message(
                                id       = 'ZMIG_ANALYSIS'
                                number   = '021'
                                severity = if_abap_behv_message=>severity-error )
          %element-SapUser  = if_abap_behv=>mk-on
        ) TO reported-Recipient.

      ELSE.

        READ TABLE lt_user_info
          INTO DATA(ls_user_info)
          WITH TABLE KEY
            sap_user = ls_recipient-SapUser.

        IF sy-subrc <> 0.

          lv_has_error = abap_true.

          APPEND VALUE #(
            %tky             = ls_recipient-%tky
            %msg             = new_message(
                                 id       = 'ZMIG_ANALYSIS'
                                 number   = '022'
                                 severity = if_abap_behv_message=>severity-error
                                 v1       = ls_recipient-SapUser )
            %element-SapUser = if_abap_behv=>mk-on
          ) TO reported-Recipient.

        ELSEIF ls_user_info-email_address IS INITIAL.

          lv_has_error = abap_true.

          APPEND VALUE #(
            %tky             = ls_recipient-%tky
            %msg             = new_message(
                                 id       = 'ZMIG_ANALYSIS'
                                 number   = '023'
                                 severity = if_abap_behv_message=>severity-error
                                 v1       = ls_recipient-SapUser )
            %element-SapUser = if_abap_behv=>mk-on
          ) TO reported-Recipient.

        ENDIF.

      ENDIF.

      IF lv_has_error = abap_true.

        APPEND VALUE #(
          %tky = ls_recipient-%tky
        ) TO failed-Recipient.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

METHOD validateNoDuplicate.

  "Read recipients currently being created or updated.
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY Recipient
      FIELDS (
        JobId
        RecipientId
        SapUser
      )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_recipients).

  "Missing SAP user is handled by validateRecipient.
  DELETE lt_recipients WHERE SapUser IS INITIAL.

  IF lt_recipients IS INITIAL.
    RETURN.
  ENDIF.

  "Read existing recipients using one database access.
  SELECT FROM zmig_mail_recip
    FIELDS
      job_id,
      recipient_id,
      sap_user
    FOR ALL ENTRIES IN @lt_recipients
    WHERE job_id   = @lt_recipients-JobId
      AND sap_user = @lt_recipients-SapUser
    INTO TABLE @DATA(lt_existing_recipients).

  SORT lt_existing_recipients BY
    job_id
    sap_user.

  "Also detects duplicates created together in the same request.
  TYPES:
    BEGIN OF ty_seen_recipient,
      job_id       TYPE sysuuid_x16,
      sap_user     TYPE xubname,
      recipient_id TYPE sysuuid_x16,
    END OF ty_seen_recipient.

  DATA lt_seen_recipients
    TYPE HASHED TABLE OF ty_seen_recipient
    WITH UNIQUE KEY job_id sap_user.

  LOOP AT lt_recipients INTO DATA(ls_recipient).

    DATA(lv_is_duplicate) = abap_false.

    "Check against recipients already stored in the database.
    READ TABLE lt_existing_recipients
      INTO DATA(ls_existing_recipient)
      WITH KEY
        job_id   = ls_recipient-JobId
        sap_user = ls_recipient-SapUser
      BINARY SEARCH.

    IF sy-subrc = 0
       AND ls_existing_recipient-recipient_id
           <> ls_recipient-RecipientId.

      lv_is_duplicate = abap_true.

    ENDIF.

    "Check duplicates inside the current RAP request.
    INSERT VALUE #(
      job_id       = ls_recipient-JobId
      sap_user     = ls_recipient-SapUser
      recipient_id = ls_recipient-RecipientId
    ) INTO TABLE lt_seen_recipients.

    IF sy-subrc <> 0.
      lv_is_duplicate = abap_true.
    ENDIF.

    IF lv_is_duplicate = abap_true.

      APPEND VALUE #(
        %tky             = ls_recipient-%tky
        %msg             = new_message(
                             id       = 'ZMIG_ANALYSIS'
                             number   = '025'
                             severity = if_abap_behv_message=>severity-error
                             v1       = ls_recipient-SapUser )
        %element-SapUser = if_abap_behv=>mk-on
      ) TO reported-Recipient.

      APPEND VALUE #(
        %tky = ls_recipient-%tky
      ) TO failed-Recipient.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

METHOD validateParentHasRecipient.

  TYPES:
    tt_job_id TYPE HASHED TABLE OF sysuuid_x16
      WITH UNIQUE KEY table_line,

    BEGIN OF ty_delete_recipient,
      job_id       TYPE sysuuid_x16,
      recipient_id TYPE sysuuid_x16,
    END OF ty_delete_recipient,

    tt_delete_recipient TYPE HASHED TABLE OF ty_delete_recipient
      WITH UNIQUE KEY job_id recipient_id.

  DATA:
    lt_affected_job_ids   TYPE tt_job_id,
    lt_invalid_job_ids    TYPE tt_job_id,
    lt_jobs_with_recipient TYPE tt_job_id,
    lt_delete_recipients  TYPE tt_delete_recipient.


  " Collect affected jobs and recipients being deleted
  LOOP AT keys INTO DATA(ls_key).

    IF ls_key-JobId IS NOT INITIAL.

      INSERT ls_key-JobId
        INTO TABLE lt_affected_job_ids.

    ENDIF.

    IF ls_key-JobId IS NOT INITIAL
       AND ls_key-RecipientId IS NOT INITIAL.

      INSERT VALUE #(
        job_id       = ls_key-JobId
        recipient_id = ls_key-RecipientId
      ) INTO TABLE lt_delete_recipients.

    ENDIF.

  ENDLOOP.


  IF lt_affected_job_ids IS INITIAL.
    RETURN.
  ENDIF.


  " Read all affected parent jobs in one EML operation
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob
      FIELDS (
        Status
      )
      WITH VALUE #(
        FOR lv_job_id IN lt_affected_job_ids
        ( JobId = lv_job_id )
      )
    RESULT DATA(lt_jobs).


  " Only Active jobs require at least one recipient
  DELETE lt_jobs
    WHERE Status <> gc_status_active.


  IF lt_jobs IS INITIAL.
    RETURN.
  ENDIF.


  " Read recipients for all Active jobs in one EML operation
  READ ENTITIES OF zi_mig_mail_job IN LOCAL MODE
    ENTITY MailJob BY \_Recipients
      FIELDS (
        RecipientId
      )
      WITH CORRESPONDING #( lt_jobs )
    RESULT DATA(lt_recipients).


  " Determine which Active jobs still have a recipient
  LOOP AT lt_recipients INTO DATA(ls_recipient).

    " Explicitly ignore recipients being deleted in this request
    READ TABLE lt_delete_recipients
      WITH TABLE KEY
        job_id       = ls_recipient-JobId
        recipient_id = ls_recipient-RecipientId
      TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    INSERT ls_recipient-JobId
      INTO TABLE lt_jobs_with_recipient.

  ENDLOOP.


  " Identify Active jobs that would have zero recipients
  LOOP AT lt_jobs INTO DATA(ls_job).

    READ TABLE lt_jobs_with_recipient
      WITH TABLE KEY
        table_line = ls_job-JobId
      TRANSPORTING NO FIELDS.

    IF sy-subrc <> 0.

      INSERT ls_job-JobId
        INTO TABLE lt_invalid_job_ids.

    ENDIF.

  ENDLOOP.


  IF lt_invalid_job_ids IS INITIAL.
    RETURN.
  ENDIF.


  " Reject deletions that would leave an Active job without recipient
  LOOP AT keys INTO ls_key.

    READ TABLE lt_invalid_job_ids
      WITH TABLE KEY
        table_line = ls_key-JobId
      TRANSPORTING NO FIELDS.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.


    APPEND VALUE #(
      %tky = ls_key-%tky
    ) TO failed-Recipient.


    APPEND VALUE #(
      %tky = ls_key-%tky
      %msg = new_message(
               id       = 'ZMIG_ANALYSIS'
               number   = '026'
               severity = if_abap_behv_message=>severity-error
             )
    ) TO reported-Recipient.

  ENDLOOP.

ENDMETHOD.


ENDCLASS.
