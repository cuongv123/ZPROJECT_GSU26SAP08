  FUNCTION z_rap_generate_all_xco.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TABLES_STR) TYPE  STRING
*"     VALUE(IV_FMS_STR) TYPE  STRING
*"     VALUE(IV_REPORT_ID) TYPE  STRING
*"     VALUE(IV_PACKAGE) TYPE  DEVCLASS
*"     VALUE(IV_TRANSPORT) TYPE  TRKORR
*"----------------------------------------------------------------------
*  "----------------------------------------------------------------------
*  "*"Local Interface:
*  "  IMPORTING
*  "     VALUE(IV_TABLES_STR) TYPE  STRING
*  "     VALUE(IV_FMS_STR) TYPE  STRING
*  "     VALUE(IV_REPORT_ID) TYPE  STRING
*  "     VALUE(IV_PACKAGE) TYPE  DEVCLASS
*  "     VALUE(IV_TRANSPORT) TYPE  TRKORR
*  "----------------------------------------------------------------------
    DATA: lt_tables     TYPE string_table,
          lt_fms        TYPE string_table,
          lt_entities   TYPE string_table,
          lt_dummy_filt TYPE zcl_parser_types=>tt_ui_filter,
          lv_success    TYPE boole_d,
          lv_msg        TYPE string.

  DATA(lv_uuid_string) = |{ iv_report_id }|.
  REPLACE ALL OCCURRENCES OF '-' IN lv_uuid_string WITH ''.

  DATA(lv_len) = strlen( lv_uuid_string ).
  IF lv_len >= 5.
    DATA(lv_offset) = lv_len - 5.
    DATA(lv_prefix) = to_upper( substring( val = lv_uuid_string off = lv_offset len = 5 ) ).
  ELSE.
    lv_prefix = 'ABCDE'.
  ENDIF.
    " 1. Tách chuỗi thành mảng
    SPLIT iv_tables_str AT ',' INTO TABLE lt_tables.
    SPLIT iv_fms_str AT ',' INTO TABLE lt_fms.

    DATA(lo_generator) = NEW zcl_rap_artifact_generator( ).

   " ====================================================================
  " 2. Sinh toàn bộ Table (Kiến trúc Facade)
  " ====================================================================
  LOOP AT lt_tables INTO DATA(lv_tab_combined).
    DATA: lv_tab TYPE string, lv_fields TYPE string.
    SPLIT lv_tab_combined AT ':' INTO lv_tab lv_fields.
    lv_tab = condense( lv_tab ).
    CHECK lv_tab IS NOT INITIAL.

    IF lv_fields IS INITIAL AND lv_tab_combined NS ':'.
       lv_fields = '*'.
    ENDIF.

    " 2.A. Sinh Base CDS
    lo_generator->generate_base_cds_xco(
      EXPORTING iv_table_name = lv_tab iv_prefix = lv_prefix iv_selected_fields = lv_fields iv_package = iv_package iv_transport = iv_transport
      IMPORTING ev_success = lv_success ev_message = lv_msg ).

    " 2.B. Sinh Projection CDS
    IF lv_success = abap_true.
      lo_generator->generate_projection_cds(
        EXPORTING iv_table_name = lv_tab iv_prefix = lv_prefix iv_selected_fields = lv_fields it_ui_filters = lt_dummy_filt iv_package = iv_package iv_transport = iv_transport
        IMPORTING ev_success = lv_success ev_entity_name = DATA(lv_proj_name) ).

      IF lv_success = abap_true.
        APPEND lv_proj_name TO lt_entities.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " ====================================================================
  " 3. Sinh toàn bộ Function Module / ALV (Custom Entity ĐỘNG)
  " ====================================================================
  LOOP AT lt_fms INTO DATA(lv_fm_combined).
    DATA: lv_fm_name TYPE string, lv_struct_name TYPE string.
    SPLIT lv_fm_combined AT ':' INTO lv_fm_name lv_struct_name.
    lv_fm_name = condense( lv_fm_name ).
    CHECK lv_fm_name IS NOT INITIAL.

    IF lv_struct_name IS INITIAL.
      lv_struct_name = lv_fm_name.
    ENDIF.

    lo_generator->generate_custom_entity(
      EXPORTING iv_ce_name = lv_fm_name iv_prefix = lv_prefix iv_structure_name = lv_struct_name it_ui_filters = lt_dummy_filt iv_package = iv_package iv_transport = iv_transport
      IMPORTING ev_success = lv_success ev_entity_name = DATA(lv_ce_name) ).

    IF lv_success = abap_true.
      APPEND lv_ce_name TO lt_entities.
    ENDIF.
  ENDLOOP.

  " ====================================================================
  " 4. Gom tất cả đúc thành Service Definition & Service Binding
  " ====================================================================
  IF lt_entities IS NOT INITIAL.
    DATA(lv_raw_sd_name) = |ZUI_GEN_{ iv_report_id }|.
    IF strlen( lv_raw_sd_name ) > 30.
      lv_raw_sd_name = substring( val = lv_raw_sd_name off = 0 len = 30 ).
    ENDIF.
    DATA(lv_sd_name) = CONV sxco_srvd_object_name( lv_raw_sd_name ).

    lo_generator->generate_sd_via_xco(
      EXPORTING iv_service_name = lv_sd_name it_entities = lt_entities iv_package = iv_package iv_transport = iv_transport
      IMPORTING ev_success = lv_success ).

    IF lv_success = abap_true.
      DATA(lv_raw_sb_name) = |ZSB_GEN_{ iv_report_id }|.
      IF strlen( lv_raw_sb_name ) > 30.
        lv_raw_sb_name = substring( val = lv_raw_sb_name off = 0 len = 30 ).
      ENDIF.
      DATA(lv_sb_name) = CONV sxco_srvb_object_name( lv_raw_sb_name ).

      lo_generator->generate_sb_via_xco(
        EXPORTING iv_binding_name = lv_sb_name iv_service_name = lv_sd_name iv_package = iv_package iv_transport = iv_transport ).
    ENDIF.
  ENDIF.
  ENDFUNCTION.
