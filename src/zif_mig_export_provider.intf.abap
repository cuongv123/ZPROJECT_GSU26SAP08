INTERFACE zif_mig_export_provider
  PUBLIC.

  TYPES:
    ty_export_section TYPE c LENGTH 100,

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
      iv_job_id             TYPE sysuuid_x16
      iv_analysis_id        TYPE sysuuid_x16
      iv_report_type        TYPE zmig_mail_job-report_type
      iv_file_format        TYPE zmig_e_file_format
      iv_export_section     TYPE ty_export_section DEFAULT 'ALL'
      iv_selected_fields    TYPE string DEFAULT ''
      iv_pdf_header         TYPE string OPTIONAL
      iv_pdf_footer         TYPE string OPTIONAL
      iv_split_multi_value  TYPE abap_bool OPTIONAL
      " === MỚI: 4 tham số PDF cua Buoc 2, optional -> khong breaking change
      iv_paper_size         TYPE char10 OPTIONAL
      iv_orientation        TYPE char1  OPTIONAL
      iv_font_size          TYPE i      OPTIONAL
      iv_fit_to_page        TYPE abap_bool OPTIONAL
    RETURNING
      VALUE(rs_result)      TYPE ty_export_result.

ENDINTERFACE.
