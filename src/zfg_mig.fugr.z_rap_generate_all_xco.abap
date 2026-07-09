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
  DATA: lt_tables     TYPE string_table,
        lt_fms        TYPE string_table,
        lt_entities   TYPE string_table,
        lt_dummy_filt TYPE zcl_parser_types=>tt_ui_filter,
        lv_success    TYPE boole_d,
        lv_msg        TYPE string.

  " 1. Tách chuỗi thành mảng
  SPLIT iv_tables_str AT ',' INTO TABLE lt_tables.
  SPLIT iv_fms_str AT ',' INTO TABLE lt_fms.

  DATA(lo_generator) = NEW zcl_rap_artifact_generator( ).

  " ====================================================================
  " 2. Sinh toàn bộ Table (Quay lại phương pháp Chuỗi Siêu bền)
  " ====================================================================
  LOOP AT lt_tables INTO DATA(lv_tab).
    CHECK lv_tab IS NOT INITIAL.

    " --- 2.A. Sinh Base CDS ---
    DATA(lv_base_name) = |ZI_GEN_{ lv_tab }|.
    DATA(lt_base_code) = lo_generator->generate_base_cds( iv_table_name = lv_tab ). " <-- Dùng hàm chuỗi gốc

    lo_generator->publish_cds_view(
      EXPORTING iv_view_name = lv_base_name
                it_source    = lt_base_code
                iv_package   = iv_package
                iv_transport = iv_transport
      IMPORTING ev_success   = lv_success ).

    " BẢN VÁ QUAN TRỌNG: Chỉ chạy tiếp nếu Base sinh thành công
      IF lv_success = abap_true.
*      APPEND lv_base_name TO lt_entities.

      " --- 2.B. Sinh Projection CDS ---
      DATA(lv_proj_name) = |ZC_GEN_{ lv_tab }|.
      DATA(lt_proj_code) = lo_generator->generate_projection_cds( iv_table_name = lv_tab it_ui_filters = lt_dummy_filt ).

      lo_generator->publish_cds_view(
        EXPORTING iv_view_name = lv_proj_name
                  it_source    = lt_proj_code
                  iv_package   = iv_package
                  iv_transport = iv_transport
        IMPORTING ev_success   = lv_success ).

      IF lv_success = abap_true.
        APPEND lv_proj_name TO lt_entities.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " ====================================================================
  " 3. Sinh toàn bộ Function Module (Custom Entity)
  " ====================================================================
  LOOP AT lt_fms INTO DATA(lv_fm).
    CHECK lv_fm IS NOT INITIAL.

    DATA(lv_cust_name) = |ZCE_GEN_{ lv_fm }|.

    " BẢN VÁ: Gọt tên File tối đa 30 ký tự trước khi lưu
    IF strlen( lv_cust_name ) > 30.
      lv_cust_name = substring( val = lv_cust_name off = 0 len = 30 ).
    ENDIF.

    DATA(lt_cust_code) = lo_generator->generate_custom_entity( iv_entity_name = lv_fm iv_structure_name = lv_fm it_ui_filters = lt_dummy_filt ).

    lo_generator->publish_cds_view(
      EXPORTING iv_view_name = lv_cust_name
                it_source    = lt_cust_code
                iv_package   = iv_package
                iv_transport = iv_transport
      IMPORTING ev_success   = lv_success ).

    IF lv_success = abap_true.
      APPEND lv_cust_name TO lt_entities.
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

    " 4.A Sinh Service Definition
    lo_generator->generate_sd_via_xco(
      EXPORTING iv_service_name = lv_sd_name
                it_entities     = lt_entities
                iv_package      = iv_package
                iv_transport    = iv_transport
      IMPORTING ev_success      = lv_success ).

    " 4.B Nếu Service Definition thành công, đẻ luôn Service Binding
    IF lv_success = abap_true.
      DATA(lv_raw_sb_name) = |ZSB_GEN_{ iv_report_id }|.
      IF strlen( lv_raw_sb_name ) > 30.
        lv_raw_sb_name = substring( val = lv_raw_sb_name off = 0 len = 30 ).
      ENDIF.

      DATA(lv_sb_name) = CONV sxco_srvb_object_name( lv_raw_sb_name ).

      lo_generator->generate_sb_via_xco(
        EXPORTING iv_binding_name = lv_sb_name
                  iv_service_name = lv_sd_name
                  iv_package      = iv_package
                  iv_transport    = iv_transport
      ).
    ENDIF.
  ENDIF.

ENDFUNCTION.
