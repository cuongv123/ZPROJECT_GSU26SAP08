CLASS ltc_alv_sf_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_alv_sf_result
        RAISING
          zcx_mig_analysis,

      detect_two_sorts
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_descending_subtotal
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_two_filters
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_eq_filter
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_between_filter
        FOR TESTING
        RAISING zcx_mig_analysis,

      link_to_output
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_evidence
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_alv_sf_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_alv_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(lo_sf_analyzer) =
      NEW zcl_mig_alv_sf_analyzer( ).

    DATA(lt_source) =
      lo_source_repo->zif_mig_source_repo~read_program(
        iv_program_name = 'ZRMIG_SAMPLE_ALV'
      ).

    DATA(ls_scan_result) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object = 'ZRMIG_SAMPLE_ALV'
        it_source        = lt_source
      ).

    DATA(ls_normalized) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result = ls_scan_result
      ).

    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.

    APPEND VALUE #(
      source_object = VALUE #(
        object_name  = 'ZRMIG_SAMPLE_ALV'
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized
    ) TO lt_source_units.

    DATA(ls_alv_result) =
      lo_alv_analyzer->zif_mig_alv_analyzer~analyze(
        it_source_units = lt_source_units
      ).

    rs_result =
      lo_sf_analyzer->zif_mig_alv_sf_analyzer~analyze(
        it_source_units = lt_source_units
        it_alv_outputs  = ls_alv_result-alv_outputs
      ).

  ENDMETHOD.

    METHOD detect_two_sorts.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( ls_result-alv_sorts )
      msg = 'Phải phát hiện 2 ALV sort definitions'
    ).

  ENDMETHOD.


  METHOD map_descending_subtotal.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_sorts
      WITH KEY field_name = 'AMOUNT'
      INTO DATA(ls_sort).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện sort AMOUNT'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = ls_sort-position
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_sort-descending
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_sort-subtotal
    ).

  ENDMETHOD.


  METHOD detect_two_filters.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( ls_result-alv_filters )
      msg = 'Phải phát hiện 2 ALV filter definitions'
    ).

  ENDMETHOD.


  METHOD map_eq_filter.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_filters
      WITH KEY field_name = 'STATUS'
      INTO DATA(ls_filter).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'I'
      act = ls_filter-sign
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'EQ'
      act = ls_filter-option
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'A'
      act = ls_filter-low_value
    ).

  ENDMETHOD.


  METHOD map_between_filter.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_filters
      WITH KEY
        field_name = 'AMOUNT'
        option     = 'BT'
      INTO DATA(ls_filter).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện filter AMOUNT BT'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = '100'
      act = ls_filter-low_value
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = '500'
      act = ls_filter-high_value
    ).

  ENDMETHOD.


  METHOD link_to_output.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_sorts
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_filters
    ).

    LOOP AT ls_result-alv_sorts
      ASSIGNING FIELD-SYMBOL(<sort>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <sort>-output_id
      ).

    ENDLOOP.

    LOOP AT ls_result-alv_filters
      ASSIGNING FIELD-SYMBOL(<filter>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <filter>-output_id
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD create_evidence.

    DATA(ls_result) = get_result( ).

    DATA(lv_expected) =
      lines( ls_result-alv_sorts )
      + lines( ls_result-alv_filters ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_expected
      act = lines( ls_result-evidences )
      msg = 'Mỗi sort/filter phải có evidence'
    ).

  ENDMETHOD.

ENDCLASS.
