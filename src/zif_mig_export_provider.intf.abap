INTERFACE zif_mig_export_provider
  PUBLIC.

  TYPES:
    ty_export_section TYPE c LENGTH 20,

    BEGIN OF ty_export_result,
      success     TYPE abap_bool,
      content     TYPE xstring,
      file_name   TYPE zmig_mail_log-file_name,
      file_type   TYPE soodk-objtp,
      file_format TYPE zmig_e_file_format,
      mime_type   TYPE string,
      message     TYPE string,
    END OF ty_export_result.

  METHODS generate
    IMPORTING
      iv_job_id         TYPE sysuuid_x16
      iv_report_type    TYPE zmig_mail_job-report_type
      iv_file_format    TYPE zmig_e_file_format
      iv_export_section TYPE ty_export_section DEFAULT 'ALL'
    RETURNING
      VALUE(rs_result) TYPE ty_export_result.

ENDINTERFACE.
