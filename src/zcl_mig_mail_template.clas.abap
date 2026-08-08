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

ENDCLASS.


CLASS zcl_mig_mail_template IMPLEMENTATION.

  METHOD get_export_success.

    DATA:
      lv_run_date TYPE d,
      lv_run_time TYPE t.

    CONVERT TIME STAMP is_context-generated_at
      TIME ZONE sy-zonlo
      INTO DATE lv_run_date
           TIME lv_run_time.

    rs_content-subject =
      |Migration Report - { is_context-job_name }|.

    rs_content-body =
      |<html>| &&
      |<body style="margin:0;padding:0;background-color:#f4f6f8;font-family:Arial,sans-serif;">| &&

      |<table align="center" cellpadding="0" cellspacing="0" width="600" | &&
      |style="border-collapse:collapse;background-color:#ffffff;margin-top:20px;border-top:5px solid #0a6ed1;">| &&

      |<tr>| &&
      |<td style="padding:28px 40px;">| &&

      |<h2 style="color:#32363a;margin-top:0;">| &&
      |Migration Report Generated Successfully| &&
      |</h2>| &&

      |<p style="font-size:14px;color:#32363a;line-height:1.6;">| &&
      |Your migration report has been generated successfully.| &&
      |</p>| &&

      |<table cellpadding="7" cellspacing="0" width="100%" | &&
      |style="border-collapse:collapse;font-size:14px;color:#32363a;">| &&

      |<tr>| &&
      |<td style="border:1px solid #d9d9d9;"><b>Job Name</b></td>| &&
      |<td style="border:1px solid #d9d9d9;">{ is_context-job_name }</td>| &&
      |</tr>| &&

      |<tr>| &&
      |<td style="border:1px solid #d9d9d9;"><b>Analysis ID</b></td>| &&
      |<td style="border:1px solid #d9d9d9;">{ is_context-analysis_id }</td>| &&
      |</tr>| &&

      |<tr>| &&
      |<td style="border:1px solid #d9d9d9;"><b>Report Type</b></td>| &&
      |<td style="border:1px solid #d9d9d9;">{ is_context-report_type }</td>| &&
      |</tr>| &&

      |<tr>| &&
      |<td style="border:1px solid #d9d9d9;"><b>File Format</b></td>| &&
      |<td style="border:1px solid #d9d9d9;">{ is_context-file_format }</td>| &&
      |</tr>| &&

      |<tr>| &&
      |<td style="border:1px solid #d9d9d9;"><b>File Name</b></td>| &&
      |<td style="border:1px solid #d9d9d9;">{ is_context-file_name }</td>| &&
      |</tr>| &&

      |<tr>| &&
      |<td style="border:1px solid #d9d9d9;"><b>Generated At</b></td>| &&
      |<td style="border:1px solid #d9d9d9;">| &&
      |{ lv_run_date DATE = USER } { lv_run_time TIME = USER }| &&
      |</td>| &&
      |</tr>| &&

      |</table>| &&

      |<p style="font-size:14px;color:#32363a;line-height:1.6;margin-top:20px;">| &&
      |The generated report is attached to this email.| &&
      |</p>| &&

      |<p style="font-size:12px;color:#6a6d70;margin-top:30px;">| &&
      |This is an automated email from the SAP Migration Cockpit. Please do not reply.| &&
      |</p>| &&

      |</td>| &&
      |</tr>| &&
      |</table>| &&

      |</body>| &&
      |</html>|.

  ENDMETHOD.

ENDCLASS.
