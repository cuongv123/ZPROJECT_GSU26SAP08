REPORT zmig_test_insert_header.

START-OF-SELECTION.
  DATA: ls_header TYPE zmig_anl_h.

  ls_header-analysis_id            = cl_system_uuid=>create_uuid_x16_static( ).
  ls_header-program_name           = 'ZTEST_ABAP_PARSER_V2'.
  ls_header-program_description    = 'Du lieu test cho Export Engine'.
  ls_header-status                 = 'COMPLETED'.
  ls_header-total_source_objects   = 5.
  ls_header-total_ui_filters       = 2.
  ls_header-total_database_objects = 1.
  ls_header-total_business_logic   = 4.
  ls_header-total_alv_outputs      = 1.
  ls_header-total_alv_columns      = 6.
  ls_header-total_recommendations  = 3.
  ls_header-complexity_score       = '58.33'.
  ls_header-readiness_score        = '75.00'.
  ls_header-parser_version         = 'V2'.
  ls_header-rule_version           = 'V1'.
  ls_header-created_by             = sy-uname.
  GET TIME STAMP FIELD ls_header-created_at.

  INSERT zmig_anl_h FROM ls_header.

  IF sy-subrc = 0.
    COMMIT WORK.
    WRITE: / 'Da tao du lieu test thanh cong.'.
    WRITE: / 'Analysis ID:', ls_header-analysis_id.
  ELSE.
    WRITE: / 'That bai, sy-subrc =', sy-subrc.
  ENDIF.
