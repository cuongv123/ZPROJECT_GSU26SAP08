CLASS zcl_mig_mail_template DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_context,
        job_name     TYPE zmig_mail_job-job_name,
        analysis_id  TYPE zmig_mail_job-analysis_id,
        report_type  TYPE zmig_mail_job-report_type,
        file_format  TYPE zmig_e_file_format,
        file_name    TYPE zmig_mail_log-file_name,
        generated_at TYPE timestampl,
      END OF ty_context,

      BEGIN OF ty_mail_content,
        subject TYPE so_obj_des,
        body    TYPE string,
      END OF ty_mail_content.

    CLASS-METHODS get_export_success
      IMPORTING
        is_context        TYPE ty_context
      RETURNING
        VALUE(rs_content) TYPE ty_mail_content.

  PRIVATE SECTION.

    CONSTANTS:
      gc_format_excel    TYPE zmig_e_file_format VALUE 'X',
      gc_format_pdf      TYPE zmig_e_file_format VALUE 'P',
      gc_format_csv      TYPE zmig_e_file_format VALUE 'C',
      gc_format_markdown TYPE zmig_e_file_format VALUE 'M',
      gc_review_limit    TYPE i VALUE 3.

    CLASS-METHODS html
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS table_row
      IMPORTING
        iv_label       TYPE string
        iv_value       TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS format_timestamp
      IMPORTING
        iv_timestamp   TYPE timestampl
      RETURNING
        VALUE(rv_text) TYPE string.

ENDCLASS.


CLASS zcl_mig_mail_template IMPLEMENTATION.

  METHOD html.

    rv_html = escape(
      val    = iv_text
      format = cl_abap_format=>e_html_text
    ).

  ENDMETHOD.


  METHOD table_row.

    rv_html =
      |<tr>| &&
      |<td style="border:1px solid #d9d9d9;padding:8px;">| &&
      |<b>{ html( iv_label ) }</b></td>| &&
      |<td style="border:1px solid #d9d9d9;padding:8px;">| &&
      |{ html( iv_value ) }</td>| &&
      |</tr>|.

  ENDMETHOD.


  METHOD format_timestamp.

    DATA:
      lv_date TYPE d,
      lv_time TYPE t.

    rv_text = `Not available`.

    IF iv_timestamp IS INITIAL.
      RETURN.
    ENDIF.

    CONVERT TIME STAMP iv_timestamp
      TIME ZONE 'UTC'
      INTO DATE lv_date
           TIME lv_time.

    IF sy-subrc = 0.
      rv_text =
        |{ lv_date DATE = ISO } { lv_time TIME = ISO } UTC|.
    ENDIF.

  ENDMETHOD.


  METHOD get_export_success.

    DATA:
      lv_format_text     TYPE string,
      lv_attachment_text TYPE string,
      lv_summary_html    TYPE string,
      lv_review_html     TYPE string,
      lv_review_items    TYPE string,
      lv_details_html    TYPE string.

    CASE is_context-file_format.

      WHEN gc_format_excel.
        lv_format_text = `Excel (.xlsx)`.
        lv_attachment_text =
          `Detailed analysis findings in an Excel workbook. ` &&
          `Review the extracted records and source references.`.

      WHEN gc_format_pdf.
        lv_format_text = `PDF (.pdf)`.
        lv_attachment_text =
          `Analysis findings in a readable PDF report. ` &&
          `Review the findings and recommendations included in the report.`.

      WHEN gc_format_csv.
        lv_format_text = `CSV (.csv)`.
        lv_attachment_text =
          `Raw analysis records in CSV format for filtering, ` &&
          `further processing or importing into other tools.`.

      WHEN gc_format_markdown.
        lv_format_text = `Technical Document (.md)`.
        lv_attachment_text =
          `Technical overview of the saved analysis, including ` &&
          `program flow, findings, recommendations and limitations. ` &&
          `Open it in a Markdown viewer or text editor.`.

      WHEN OTHERS.
        lv_format_text = `Other format - see attachment extension`.
        lv_attachment_text =
          `The generated analysis report is attached for your review.`.

    ENDCASE.

    " Read only the pinned snapshot. Never substitute the latest analysis.
    IF is_context-analysis_id IS NOT INITIAL.

      SELECT SINGLE *
        FROM zmig_anl_h
        WHERE analysis_id = @is_context-analysis_id
          AND program_name = @is_context-report_type
        INTO @DATA(ls_header).

      IF sy-subrc = 0.

        lv_summary_html =
          |<h3>Analysis summary</h3>| &&
          |<table cellpadding="0" cellspacing="0" width="100%" | &&
          |style="border-collapse:collapse;font-size:14px;">| &&
          table_row(
            iv_label = `Analysis status`
            iv_value = CONV string( ls_header-status )
          ) &&
          table_row(
            iv_label = `Snapshot created at`
            iv_value = format_timestamp( ls_header-created_at )
          ) &&
          table_row(
            iv_label = `Source objects`
            iv_value = |{ ls_header-total_source_objects }|
          ) &&
          table_row(
            iv_label = `Selection fields`
            iv_value = |{ ls_header-total_ui_filters }|
          ) &&
          table_row(
            iv_label = `Detected database objects`
            iv_value = |{ ls_header-total_database_objects }|
          ) &&
          table_row(
            iv_label = `Detected logic items`
            iv_value = |{ ls_header-total_business_logic }|
          ) &&
          table_row(
            iv_label = `ALV outputs`
            iv_value = |{ ls_header-total_alv_outputs }|
          ) &&
          table_row(
            iv_label = `ALV columns`
            iv_value = |{ ls_header-total_alv_columns }|
          ) &&
          |</table>| &&
          |<p style="font-size:12px;color:#6a6d70;">| &&
          |These counts describe the saved analysis snapshot. | &&
          |They do not establish full coverage of called implementations.| &&
          |</p>|.

        " Display a bounded selection of stored warnings and errors.
        SELECT message_no, message_text
          FROM zmig_anl_msg
          WHERE analysis_id = @is_context-analysis_id
            AND ( message_type = 'WARNING'
               OR message_type = 'ERROR'
               OR message_type = 'W'
               OR message_type = 'E' )
          ORDER BY message_no
          INTO TABLE @DATA(lt_messages)
          UP TO @gc_review_limit ROWS.

        LOOP AT lt_messages INTO DATA(ls_message).
          IF ls_message-message_text IS NOT INITIAL.
            lv_review_items =
              lv_review_items &&
              |<li>{ html(
             ls_message-message_text
              ) }</li>|.
          ENDIF.
        ENDLOOP.

        " Include stored recommendations explicitly requiring manual review.
        SELECT recommendation_id, title, display_text
          FROM zmig_anl_rec
          WHERE analysis_id = @is_context-analysis_id
            AND manual_review = @abap_true
          ORDER BY recommendation_id
          INTO TABLE @DATA(lt_recommendations)
          UP TO @gc_review_limit ROWS.

        LOOP AT lt_recommendations INTO DATA(ls_recommendation).

          DATA(lv_review_text) = ls_recommendation-display_text.

         IF lv_review_text IS INITIAL.
            lv_review_text = ls_recommendation-title.
         ENDIF.

          IF lv_review_text IS NOT INITIAL.
            lv_review_items =
              lv_review_items &&
              |<li>{ html( lv_review_text ) }</li>|.
          ENDIF.

        ENDLOOP.

        IF lv_review_items IS NOT INITIAL.
          lv_review_html =
            |<h3>Review required</h3>| &&
            |<ul style="padding-left:20px;line-height:1.6;">| &&
            lv_review_items &&
            |</ul>| &&
            |<p style="font-size:12px;color:#6a6d70;">| &&
            |Selected review items are shown above. | &&
            |Open the analysis for the complete list.| &&
            |</p>|.
        ENDIF.

      ENDIF.

    ENDIF.

    IF lv_summary_html IS INITIAL.
      lv_summary_html =
        |<p>Summary information for the selected snapshot | &&
        |is unavailable. Please review the attached report.</p>|.
    ENDIF.

    lv_details_html =
      table_row(
        iv_label = `Program Name`
        iv_value = CONV string( is_context-report_type )
      ) &&
      table_row(
        iv_label = `Job Name`
        iv_value = CONV string( is_context-job_name )
      ) &&
      table_row(
        iv_label = `File Format`
        iv_value = lv_format_text
      ) &&
      table_row(
        iv_label = `File Name`
        iv_value = CONV string( is_context-file_name )
      ) &&
      table_row(
        iv_label = `Report generated at`
        iv_value = format_timestamp( is_context-generated_at )
      ).

    IF is_context-analysis_id IS NOT INITIAL.
      lv_details_html =
        lv_details_html &&
        table_row(
          iv_label = `Analysis ID`
          iv_value = |{ is_context-analysis_id }|
        ).
    ENDIF.

    rs_content-subject =
      |Analysis Report - { is_context-report_type }|.

    rs_content-body =
      |<!DOCTYPE html><html><body | &&
      |style="margin:0;padding:0;background-color:#f4f6f8;| &&
      |font-family:Arial,sans-serif;color:#32363a;">| &&
      |<table role="presentation" align="center" | &&
      |cellpadding="0" cellspacing="0" width="600" | &&
      |style="max-width:100%;border-collapse:collapse;| &&
      |background-color:#ffffff;border-top:5px solid #0a6ed1;">| &&
      |<tr><td style="padding:28px 36px;font-size:14px;">| &&
      |<h2 style="margin-top:0;">Analysis Report</h2>| &&
      |<p><b>{ html(
        CONV string( is_context-report_type )
      ) }</b></p>| &&
      |<p style="line-height:1.6;">| &&
      |The analysis report is attached for your review.| &&
      |</p>| &&
      lv_summary_html &&
      lv_review_html &&
      |<h3>Attachment</h3>| &&
      |<p style="line-height:1.6;">| &&
      html( lv_attachment_text ) &&
      |</p>| &&
      |<table cellpadding="0" cellspacing="0" width="100%" | &&
      |style="border-collapse:collapse;font-size:14px;">| &&
      lv_details_html &&
      |</table>| &&
      |<h3>Next step</h3>| &&
      |<p style="line-height:1.6;">| &&
      |Review the findings and modernization recommendations | &&
      |in the attachment or the analysis detail page. | &&
      |Inspect unresolved dependencies before deciding | &&
      |how to reuse or replace their logic.| &&
      |</p>| &&
      |<p style="font-size:12px;color:#6a6d70;">| &&
      |Generating this report does not re-analyze the current source code.| &&
      |</p>| &&
      |<p style="font-size:12px;color:#6a6d70;margin-top:24px;">| &&
      |This is an automated email from the SAP Migration Cockpit. | &&
      |Please do not reply.| &&
      |</p>| &&
      |</td></tr></table></body></html>|.

  ENDMETHOD.

ENDCLASS.
