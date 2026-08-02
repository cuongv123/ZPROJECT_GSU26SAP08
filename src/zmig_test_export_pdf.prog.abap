
REPORT zmig_test_export_pdf LINE-SIZE 255.

PARAMETERS: p_prog TYPE zmig_mail_job-report_type DEFAULT 'ZTEST_ABAP_PARSER_V2'.

START-OF-SELECTION.
  DATA(lo_engine) = NEW zcl_mig_export_engine( ).

  DATA(ls_result) = lo_engine->zif_mig_export_provider~generate(
    iv_job_id      = cl_system_uuid=>create_uuid_x16_static( )
    iv_analysis_id = VALUE sysuuid_x16( )
    iv_report_type = p_prog
    iv_file_format = 'P' ).

  IF ls_result-success = abap_false.
    WRITE: / 'LOI:'.
    SPLIT ls_result-message AT space INTO TABLE DATA(lt_msg_lines).
    LOOP AT lt_msg_lines INTO DATA(lv_msg_line).
      WRITE: / lv_msg_line.
    ENDLOOP.
  ELSE.
    WRITE: / 'Thanh cong. Ten file:', ls_result-file_name.
    WRITE: / 'Kich thuoc:', xstrlen( ls_result-content ).

    DATA lv_hex TYPE x LENGTH 8.

lv_hex = ls_result-content(8).

WRITE: / lv_hex.
  ENDIF.
