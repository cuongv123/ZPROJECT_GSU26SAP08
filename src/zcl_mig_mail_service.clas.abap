CLASS zcl_mig_mail_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_attachment,
        content     TYPE xstring,
        file_name   TYPE zmig_mail_log-file_name,
        file_type   TYPE soodk-objtp,
        file_format TYPE zmig_e_file_format,
      END OF ty_attachment,

      BEGIN OF ty_mail_content,
        subject TYPE so_obj_des,
        body    TYPE string,
      END OF ty_mail_content,

      BEGIN OF ty_send_result,
        request_created TYPE abap_bool,
        accepted_all    TYPE abap_bool,
        recipient_count TYPE i,
        message         TYPE string,
        run_id          TYPE sysuuid_x16,
      END OF ty_send_result.

    CLASS-METHODS send_job
      IMPORTING
        iv_job_id        TYPE sysuuid_x16
        iv_trigger_type  TYPE zmig_e_trigger_type OPTIONAL
        is_mail_content  TYPE ty_mail_content OPTIONAL
        is_attachment    TYPE ty_attachment OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_send_result.


  PRIVATE SECTION.

    CLASS-METHODS finish_execution_log
      IMPORTING
        iv_job_id          TYPE sysuuid_x16
        iv_status          TYPE zmig_e_run_status
        iv_file_name       TYPE zmig_mail_log-file_name
        iv_file_format     TYPE zmig_e_file_format
        iv_file_size       TYPE zmig_mail_log-file_size
        iv_recipient_count TYPE zmig_mail_log-recipient_count
      CHANGING
        cs_result          TYPE ty_send_result.

ENDCLASS.



CLASS zcl_mig_mail_service IMPLEMENTATION.


  METHOD finish_execution_log.

    DATA:
      ls_finish_result TYPE zcl_mig_mail_log_service=>ty_finish_result,
      lv_log_message   TYPE string.


    IF cs_result-run_id IS INITIAL.
      RETURN.
    ENDIF.


    ls_finish_result =
      zcl_mig_mail_log_service=>finish_run(
        iv_job_id          = iv_job_id
        iv_run_id          = cs_result-run_id
        iv_status          = iv_status
        iv_file_name       = iv_file_name
        iv_file_format     = iv_file_format
        iv_file_size       = iv_file_size
        iv_recipient_count = iv_recipient_count
        iv_log_message     = cs_result-message
      ).


    IF ls_finish_result-success = abap_false.

      MESSAGE e035(zmig_analysis)
        WITH ls_finish_result-message
        INTO lv_log_message.

      IF cs_result-message IS INITIAL.

        cs_result-message = lv_log_message.

      ELSE.

        cs_result-message =
          |{ cs_result-message } { lv_log_message }|.

      ENDIF.

    ENDIF.

  ENDMETHOD.



  METHOD send_job.

    CONSTANTS:
      lc_recipient_to       TYPE zmig_e_recip_type  VALUE 'T',
      lc_recipient_cc       TYPE zmig_e_recip_type  VALUE 'C',
      lc_recipient_bcc      TYPE zmig_e_recip_type  VALUE 'B',
      lc_trigger_manual     TYPE zmig_e_trigger_type VALUE 'M',
      lc_status_success     TYPE zmig_e_run_status   VALUE 'S',
      lc_status_failed      TYPE zmig_e_run_status   VALUE 'F',
      lc_document_type_raw  TYPE so_obj_tp            VALUE 'RAW',
      lc_document_type_html TYPE so_obj_tp            VALUE 'HTM'.


    TYPES:
      BEGIN OF ty_job_config,
        mail_subject TYPE zmig_mail_job-mail_subject,
        mail_body    TYPE zmig_mail_job-mail_body,
        file_format  TYPE zmig_mail_job-file_format,
      END OF ty_job_config,

      BEGIN OF ty_recipient,
        recipient_type TYPE zmig_mail_recip-recipient_type,
        sap_user       TYPE zmig_mail_recip-sap_user,
        email_address  TYPE zmig_mail_recip-email_address,
      END OF ty_recipient,

      tt_recipient TYPE STANDARD TABLE OF ty_recipient
        WITH EMPTY KEY.


    DATA:
      ls_job                 TYPE ty_job_config,
      ls_start_result        TYPE zcl_mig_mail_log_service=>ty_start_result,
      ls_recipient_check     TYPE ty_recipient,
      ls_recipient           TYPE ty_recipient,

      lt_recipients          TYPE tt_recipient,
      lt_mail_body           TYPE soli_tab,
      lt_attachment_hex      TYPE solix_tab,
      lt_attachment_header   TYPE soli_tab,

      lv_trigger_type        TYPE zmig_e_trigger_type,
      lv_log_file_format     TYPE zmig_e_file_format,
      lv_attachment_name     TYPE zmig_mail_log-file_name,
      lv_attachment_size     TYPE zmig_mail_log-file_size,

      lv_mail_subject        TYPE so_obj_des,
      lv_mail_body           TYPE string,
      lv_document_type       TYPE so_obj_tp,

      lv_bcs_attachment_size TYPE so_obj_len,
      lv_is_copy             TYPE abap_bool,
      lv_is_blind_copy       TYPE abap_bool.


    " Resolve trigger type
    lv_trigger_type = iv_trigger_type.

    IF lv_trigger_type IS INITIAL.
      lv_trigger_type = lc_trigger_manual.
    ENDIF.


    " Read Mail Job configuration
    SELECT SINGLE
      FROM zmig_mail_job
      FIELDS
        mail_subject,
        mail_body,
        file_format
      WHERE job_id = @iv_job_id
      INTO @ls_job.


    IF sy-subrc <> 0.

      MESSAGE e029(zmig_analysis)
        WITH iv_job_id
        INTO rs_result-message.

      RETURN.

    ENDIF.


    " Prepare log metadata before starting the execution log
    lv_log_file_format = ls_job-file_format.

    IF is_attachment-content IS NOT INITIAL.

      lv_attachment_name =
        is_attachment-file_name.

      lv_attachment_size =
        xstrlen( is_attachment-content ).

      IF is_attachment-file_format IS NOT INITIAL.

        lv_log_file_format =
          is_attachment-file_format.

      ENDIF.

    ENDIF.


    " Start execution log before validations that may fail
    ls_start_result =
      zcl_mig_mail_log_service=>start_run(
        iv_job_id       = iv_job_id
        iv_trigger_type = lv_trigger_type
        iv_file_format  = lv_log_file_format
      ).


    IF ls_start_result-success = abap_false.

      rs_result-message =
        ls_start_result-message.

      RETURN.

    ENDIF.


    rs_result-run_id =
      ls_start_result-run_id.

"------------------------------------------------------------
" Resolve mail content
"
" Generated HTML template has priority.
" Database subject/body is only a fallback.
"------------------------------------------------------------
IF is_mail_content-subject IS NOT INITIAL
   AND is_mail_content-body IS NOT INITIAL.

  lv_mail_subject =
    is_mail_content-subject.

  lv_mail_body =
    is_mail_content-body.

  lv_document_type =
    lc_document_type_html.

ELSEIF ls_job-mail_subject IS NOT INITIAL
       AND ls_job-mail_body IS NOT INITIAL.

  lv_mail_subject =
    CONV so_obj_des( ls_job-mail_subject ).

  lv_mail_body =
    ls_job-mail_body.

  lv_document_type =
    lc_document_type_raw.

ELSE.

  CLEAR:
    lv_mail_subject,
    lv_mail_body,
    lv_document_type.

ENDIF.


    " Validate resolved mail subject
    IF lv_mail_subject IS INITIAL.

      MESSAGE e013(zmig_analysis)
        INTO rs_result-message.

      finish_execution_log(
        EXPORTING
          iv_job_id          = iv_job_id
          iv_status          = lc_status_failed
          iv_file_name       = lv_attachment_name
          iv_file_format     = lv_log_file_format
          iv_file_size       = lv_attachment_size
          iv_recipient_count = 0
        CHANGING
          cs_result          = rs_result
      ).

      RETURN.

    ENDIF.


    " Validate resolved mail body
    IF lv_mail_body IS INITIAL.

      MESSAGE e037(zmig_analysis)
        INTO rs_result-message.

      finish_execution_log(
        EXPORTING
          iv_job_id          = iv_job_id
          iv_status          = lc_status_failed
          iv_file_name       = lv_attachment_name
          iv_file_format     = lv_log_file_format
          iv_file_size       = lv_attachment_size
          iv_recipient_count = 0
        CHANGING
          cs_result          = rs_result
      ).

      RETURN.

    ENDIF.


    " Validate attachment metadata before BCS processing
    IF is_attachment-content IS NOT INITIAL
       AND
       ( is_attachment-file_name IS INITIAL
         OR is_attachment-file_type IS INITIAL ).

      MESSAGE e030(zmig_analysis)
        INTO rs_result-message.

      finish_execution_log(
        EXPORTING
          iv_job_id          = iv_job_id
          iv_status          = lc_status_failed
          iv_file_name       = lv_attachment_name
          iv_file_format     = lv_log_file_format
          iv_file_size       = lv_attachment_size
          iv_recipient_count = 0
        CHANGING
          cs_result          = rs_result
      ).

      RETURN.

    ENDIF.


    " Read all recipients in one database access
    SELECT
      FROM zmig_mail_recip
      FIELDS
        recipient_type,
        sap_user,
        email_address
      WHERE job_id = @iv_job_id
      INTO TABLE @lt_recipients.


    rs_result-recipient_count =
      lines( lt_recipients ).


    " At least one recipient is required
    IF lt_recipients IS INITIAL.

      MESSAGE e026(zmig_analysis)
        INTO rs_result-message.

      finish_execution_log(
        EXPORTING
          iv_job_id          = iv_job_id
          iv_status          = lc_status_failed
          iv_file_name       = lv_attachment_name
          iv_file_format     = lv_log_file_format
          iv_file_size       = lv_attachment_size
          iv_recipient_count = 0
        CHANGING
          cs_result          = rs_result
      ).

      RETURN.

    ENDIF.


    " Validate recipient data in memory
    LOOP AT lt_recipients INTO ls_recipient_check.

      IF ls_recipient_check-email_address IS INITIAL.

        MESSAGE e023(zmig_analysis)
          WITH ls_recipient_check-sap_user
          INTO rs_result-message.

        finish_execution_log(
          EXPORTING
            iv_job_id          = iv_job_id
            iv_status          = lc_status_failed
            iv_file_name       = lv_attachment_name
            iv_file_format     = lv_log_file_format
            iv_file_size       = lv_attachment_size
            iv_recipient_count = rs_result-recipient_count
          CHANGING
            cs_result          = rs_result
        ).

        RETURN.

      ENDIF.


      IF ls_recipient_check-recipient_type <> lc_recipient_to
         AND ls_recipient_check-recipient_type <> lc_recipient_cc
         AND ls_recipient_check-recipient_type <> lc_recipient_bcc.

        MESSAGE e024(zmig_analysis)
          WITH ls_recipient_check-recipient_type
          INTO rs_result-message.

        finish_execution_log(
          EXPORTING
            iv_job_id          = iv_job_id
            iv_status          = lc_status_failed
            iv_file_name       = lv_attachment_name
            iv_file_format     = lv_log_file_format
            iv_file_size       = lv_attachment_size
            iv_recipient_count = rs_result-recipient_count
          CHANGING
            cs_result          = rs_result
        ).

        RETURN.

      ENDIF.

    ENDLOOP.


    TRY.

        " Create persistent BCS request
        DATA(lo_send_request) =
          cl_bcs=>create_persistent( ).


        " Convert body text for BCS
        lt_mail_body =
          cl_document_bcs=>string_to_soli(
            ip_string = lv_mail_body
          ).


        " Create RAW or HTML mail document
        DATA(lo_document) =
          cl_document_bcs=>create_document(
            i_type    = lv_document_type
            i_text    = lt_mail_body
            i_subject = lv_mail_subject
          ).


        " Add optional attachment
        IF is_attachment-content IS NOT INITIAL.

          lt_attachment_hex =
            cl_bcs_convert=>xstring_to_solix(
              iv_xstring = is_attachment-content
            ).

          CLEAR lt_attachment_header.

          APPEND VALUE #(
            line = |&SO_FILENAME={ is_attachment-file_name }|
          ) TO lt_attachment_header.


          lv_bcs_attachment_size =
            CONV so_obj_len( lv_attachment_size ).


          lo_document->add_attachment(
            i_attachment_type    = is_attachment-file_type
            i_attachment_subject = CONV so_obj_des(
                                     is_attachment-file_name
                                   )
            i_attachment_size    = lv_bcs_attachment_size
            i_attachment_header  = lt_attachment_header
            i_att_content_hex    = lt_attachment_hex
          ).

        ENDIF.


        lo_send_request->set_document(
          i_document = lo_document
        ).


        " Current/background SAP user is the sender
        DATA(lo_sender) =
          cl_sapuser_bcs=>create(
            i_user = sy-uname
          ).

        lo_send_request->set_sender(
          i_sender = lo_sender
        ).


        " Add validated To / Cc / Bcc recipients
        LOOP AT lt_recipients INTO ls_recipient.

          DATA(lo_recipient) =
            cl_cam_address_bcs=>create_internet_address(
              i_address_string = ls_recipient-email_address
            ).


          lv_is_copy =
            xsdbool(
              ls_recipient-recipient_type = lc_recipient_cc
            ).


          lv_is_blind_copy =
            xsdbool(
              ls_recipient-recipient_type = lc_recipient_bcc
            ).


          lo_send_request->add_recipient(
            i_recipient  = lo_recipient
            i_express    = abap_false
            i_copy       = lv_is_copy
            i_blind_copy = lv_is_blind_copy
          ).

        ENDLOOP.


        " Send BCS request
        lo_send_request->set_send_immediately(
          i_send_immediately = abap_true
        ).


        rs_result-accepted_all =
          lo_send_request->send(
            i_with_error_screen = abap_false
          ).


        rs_result-request_created =
          abap_true.


        IF rs_result-accepted_all = abap_true.

          MESSAGE s027(zmig_analysis)
            INTO rs_result-message.

          finish_execution_log(
            EXPORTING
              iv_job_id          = iv_job_id
              iv_status          = lc_status_success
              iv_file_name       = lv_attachment_name
              iv_file_format     = lv_log_file_format
              iv_file_size       = lv_attachment_size
              iv_recipient_count = rs_result-recipient_count
            CHANGING
              cs_result          = rs_result
          ).

        ELSE.

          MESSAGE e036(zmig_analysis)
            INTO rs_result-message.

          finish_execution_log(
            EXPORTING
              iv_job_id          = iv_job_id
              iv_status          = lc_status_failed
              iv_file_name       = lv_attachment_name
              iv_file_format     = lv_log_file_format
              iv_file_size       = lv_attachment_size
              iv_recipient_count = rs_result-recipient_count
            CHANGING
              cs_result          = rs_result
          ).

        ENDIF.


      CATCH cx_bcs INTO DATA(lx_bcs).

        rs_result-request_created =
          abap_false.

        rs_result-accepted_all =
          abap_false.


        MESSAGE e028(zmig_analysis)
          WITH lx_bcs->get_text( )
          INTO rs_result-message.


        finish_execution_log(
          EXPORTING
            iv_job_id          = iv_job_id
            iv_status          = lc_status_failed
            iv_file_name       = lv_attachment_name
            iv_file_format     = lv_log_file_format
            iv_file_size       = lv_attachment_size
            iv_recipient_count = rs_result-recipient_count
          CHANGING
            cs_result          = rs_result
        ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
