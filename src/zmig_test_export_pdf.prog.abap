REPORT zmig_test_export_pdf.

PARAMETERS: p_prog TYPE zmig_mail_job-report_type DEFAULT 'ZTEST_ABAP_PARSER_V2'.

START-OF-SELECTION.
  DATA(lo_engine) = NEW zcl_mig_export_engine( ).

  DATA(ls_result) = lo_engine->zif_mig_export_provider~generate(
    iv_job_id      = cl_system_uuid=>create_uuid_x16_static( )
    iv_report_type = p_prog
    iv_file_format = 'P' ).

  IF ls_result-success = abap_false.
    WRITE: / 'LOI:', ls_result-message.
  ELSE.
    WRITE: / 'Thanh cong. Ten file:', ls_result-file_name.
    WRITE: / 'Kich thuoc:', xstrlen( ls_result-content ).

    DATA(lv_server_path) = '/usr/sap/S40/D00/work/upload_dir/test_export.pdf'.

    OPEN DATASET lv_server_path FOR OUTPUT IN BINARY MODE.
    IF sy-subrc = 0.
      TRANSFER ls_result-content TO lv_server_path.
      CLOSE DATASET lv_server_path.
      WRITE: / 'Da ghi len Application Server tai:', lv_server_path.
    ELSE.
      WRITE: / 'Khong the mo file tren server, sy-subrc =', sy-subrc.
    ENDIF.
  ENDIF.
