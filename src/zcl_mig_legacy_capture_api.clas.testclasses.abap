"Serialization tests use a typed ALV outtab; no report or worker is started.
CLASS ltc_legacy_capture_api DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_row,
        bukrs  TYPE c LENGTH 4,
        butxt  TYPE c LENGTH 25,
        waers  TYPE c LENGTH 5,
        amount TYPE p LENGTH 8 DECIMALS 2,
        number TYPE i,
        note   TYPE string,
      END OF ty_row,
      tt_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS teardown.
    METHODS blank_company_name_kept FOR TESTING RAISING cx_static_check.
    METHODS initial_numbers_kept FOR TESTING RAISING cx_static_check.
    METHODS each_row_has_same_columns FOR TESTING RAISING cx_static_check.
    METHODS empty_result_is_array FOR TESTING RAISING cx_static_check.
    METHODS queued_request_is_not_captured FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_legacy_capture_api IMPLEMENTATION.
  METHOD teardown.
    zcl_mig_legacy_capture_api=>clear_buffer( ).
  ENDMETHOD.

  METHOD blank_company_name_kept.
    DATA lt_rows TYPE tt_rows.
    APPEND VALUE #( bukrs = '9999' butxt = '' waers = 'EUR' ) TO lt_rows.
    DATA(lr_rows) = REF #( lt_rows ).
    DATA(ls_result) = zcl_mig_legacy_capture_api=>build_result( lr_rows ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = ls_result-row_count ).
    cl_abap_unit_assert=>assert_char_cp(
      exp = '*"BUKRS":"9999"*"BUTXT":""*"WAERS":"EUR"*'
      act = ls_result-rows_json ).
    DATA lt_readback TYPE tt_rows.
    /ui2/cl_json=>deserialize(
      EXPORTING json = ls_result-rows_json
      CHANGING data = lt_readback ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_readback ) ).
    cl_abap_unit_assert=>assert_equals( exp = space act = lt_readback[ 1 ]-butxt ).
  ENDMETHOD.

  METHOD initial_numbers_kept.
    DATA lt_rows TYPE tt_rows.
    APPEND VALUE #( bukrs = '9999' ) TO lt_rows.
    DATA(lr_rows) = REF #( lt_rows ).
    DATA(ls_result) = zcl_mig_legacy_capture_api=>build_result( lr_rows ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*"AMOUNT":*'
      act = ls_result-rows_json ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*"NUMBER":*'
      act = ls_result-rows_json ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*"NOTE":""*'
      act = ls_result-rows_json ).
    DATA lt_readback TYPE tt_rows.
    /ui2/cl_json=>deserialize(
      EXPORTING json = ls_result-rows_json
      CHANGING data = lt_readback ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = lt_readback[ 1 ]-amount ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = lt_readback[ 1 ]-number ).
  ENDMETHOD.

  METHOD each_row_has_same_columns.
    DATA lt_rows TYPE tt_rows.
    APPEND VALUE #( bukrs = '0001' butxt = 'First' waers = 'EUR' ) TO lt_rows.
    APPEND VALUE #( bukrs = '9999' butxt = '' waers = 'USD' ) TO lt_rows.
    DATA(lr_rows) = REF #( lt_rows ).
    DATA(ls_result) = zcl_mig_legacy_capture_api=>build_result( lr_rows ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = ls_result-row_count ).
    SPLIT ls_result-rows_json AT '"BUKRS":' INTO TABLE DATA(lt_bukrs).
    SPLIT ls_result-rows_json AT '"BUTXT":' INTO TABLE DATA(lt_butxt).
    SPLIT ls_result-rows_json AT '"WAERS":' INTO TABLE DATA(lt_waers).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt_bukrs ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt_butxt ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt_waers ) ).
    DATA lt_readback TYPE tt_rows.
    /ui2/cl_json=>deserialize(
      EXPORTING json = ls_result-rows_json
      CHANGING data = lt_readback ).
    cl_abap_unit_assert=>assert_equals(
      exp = ls_result-row_count act = lines( lt_readback ) ).
  ENDMETHOD.

  METHOD empty_result_is_array.
    DATA lt_rows TYPE tt_rows.
    DATA(lr_rows) = REF #( lt_rows ).
    DATA(ls_result) = zcl_mig_legacy_capture_api=>build_result( lr_rows ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = ls_result-row_count ).
    cl_abap_unit_assert=>assert_equals( exp = '[]' act = ls_result-rows_json ).
  ENDMETHOD.

  METHOD queued_request_is_not_captured.
    DATA(lv_analysis_id) = cl_system_uuid=>create_uuid_x16_static( ).
    DATA(lv_request_id) = cl_system_uuid=>create_uuid_x16_static( ).
    DATA(ls_queued) = zcl_mig_legacy_capture_api=>enqueue(
      iv_analysis_id = lv_analysis_id
      iv_request_id = lv_request_id
      iv_selection_json = '[]' ).
    DATA(ls_status) = zcl_mig_legacy_capture_api=>get_status(
      iv_analysis_id = lv_analysis_id
      iv_request_id = lv_request_id ).
    cl_abap_unit_assert=>assert_equals( exp = 'QUEUED' act = ls_queued-status ).
    cl_abap_unit_assert=>assert_equals( exp = 'QUEUED' act = ls_status-status ).
    cl_abap_unit_assert=>assert_initial( ls_status-rows_json ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = ls_status-row_count ).
  ENDMETHOD.
ENDCLASS.
