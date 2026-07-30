CLASS ltc_ui_filter_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_ui_analysis_result
        RAISING
          zcx_mig_analysis,

      detect_all_fields
        FOR TESTING
        RAISING zcx_mig_analysis,

      parse_parameter
        FOR TESTING
        RAISING zcx_mig_analysis,

      parse_select_options
        FOR TESTING
        RAISING zcx_mig_analysis,

      parse_checkbox_and_radio
        FOR TESTING
        RAISING zcx_mig_analysis,

      parse_hidden_field
        FOR TESTING
        RAISING zcx_mig_analysis,

      preserve_block_and_validation
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_evidence
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_ui_filter_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_analyzer) =
      NEW zcl_mig_ui_filter_analyzer( ).

    DATA(lt_source) =
      lo_source_repo->zif_mig_source_repo~read_program(
        iv_program_name =
          'ZRMIG_SAMPLE_FILTER'
      ).

    DATA(ls_scan_result) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object =
          'ZRMIG_SAMPLE_FILTER'
        it_source =
          lt_source
      ).

    DATA(ls_normalized_result) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result =
          ls_scan_result
      ).

    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.

    APPEND VALUE #(
      source_object = VALUE #(
        object_name  = 'ZRMIG_SAMPLE_FILTER'
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized_result
    ) TO lt_source_units.

    rs_result =
      lo_analyzer->zif_mig_ui_filter_analyzer~analyze(
        it_source_units =
          lt_source_units
      ).

  ENDMETHOD.

    METHOD detect_all_fields.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 7
      act = lines( ls_result-ui_filters )
      msg = 'Phải phát hiện 7 selection fields'
    ).

  ENDMETHOD.


  METHOD parse_parameter.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_VKORG'
      INTO DATA(ls_filter).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện P_VKORG'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PARAMETER'
      act = ls_filter-field_kind
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_filter-mandatory
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'VKORG'
      act = ls_filter-data_type
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = |'1000'|
      act = ls_filter-default_value
    ).

  ENDMETHOD.


  METHOD parse_select_options.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'S_VBELN'
      INTO DATA(ls_vbeln).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện S_VBELN'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'SELECT_OPTIONS'
      act = ls_vbeln-field_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'VBAK'
      act = ls_vbeln-reference_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'VBELN'
      act = ls_vbeln-reference_field
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_vbeln-multiple_selection
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_vbeln-range_supported
    ).

    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'S_AUDAT'
      INTO DATA(ls_audat).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện S_AUDAT'
    ).

    cl_abap_unit_assert=>assert_false(
      act = ls_audat-multiple_selection
    ).

    cl_abap_unit_assert=>assert_false(
      act = ls_audat-range_supported
    ).

  ENDMETHOD.


  METHOD parse_checkbox_and_radio.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_TEST'
      INTO DATA(ls_checkbox).

    cl_abap_unit_assert=>assert_true(
      act = ls_checkbox-checkbox
    ).

    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_A'
      INTO DATA(ls_radio).

    cl_abap_unit_assert=>assert_equals(
      exp = 'G1'
      act = ls_radio-radio_group
    ).

  ENDMETHOD.


  METHOD parse_hidden_field.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_HIDDEN'
      INTO DATA(ls_hidden).

    cl_abap_unit_assert=>assert_true(
      act = ls_hidden-hidden
    ).

  ENDMETHOD.


  METHOD preserve_block_and_validation.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_VKORG'
      INTO DATA(ls_filter).

    cl_abap_unit_assert=>assert_equals(
      exp = 'B1'
      act = ls_filter-selection_block
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'AT SELECTION-SCREEN ON P_VKORG'
      act = ls_filter-validation_routine
    ).

  ENDMETHOD.


  METHOD create_evidence.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_result-ui_filters )
      act = lines( ls_result-evidences )
      msg = 'Mỗi filter phải có declaration evidence'
    ).

    LOOP AT ls_result-evidences
      ASSIGNING FIELD-SYMBOL(<evidence>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <evidence>-evidence_id
      ).

      cl_abap_unit_assert=>assert_equals(
        exp = 'ZRMIG_SAMPLE_FILTER'
        act = <evidence>-source_object
      ).

      cl_abap_unit_assert=>assert_true(
        act = xsdbool(
          <evidence>-start_line > 0
        )
      ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
