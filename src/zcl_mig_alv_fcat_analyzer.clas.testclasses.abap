CLASS ltc_alv_fcat_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_alv_fcat_result
        RAISING
          zcx_mig_analysis,

      detect_five_columns
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_basic_column
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_editable_column
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_amount_semantics
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_technical_column
        FOR TESTING
        RAISING zcx_mig_analysis,

      link_to_alv_output
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_evidence
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_alv_fcat_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_alv_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(lo_fcat_analyzer) =
      NEW zcl_mig_alv_fcat_analyzer( ).

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
      lo_fcat_analyzer->zif_mig_alv_fcat_analyzer~analyze(
        it_source_units = lt_source_units
        it_alv_outputs  = ls_alv_result-alv_outputs
      ).

  ENDMETHOD.

    METHOD detect_five_columns.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 5
      act = lines( ls_result-alv_columns )
      msg = 'Phải phát hiện 5 field catalog columns'
    ).

  ENDMETHOD.


  METHOD map_basic_column.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_columns
      WITH KEY field_name = 'ITEM_ID'
      INTO DATA(ls_column).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện ITEM_ID'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Item ID'
      act = ls_column-label
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = ls_column-position
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_column-key_field
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_column-hotspot
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZTMIG_SAMPLE_DB'
      act = ls_column-reference_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ITEM_ID'
      act = ls_column-reference_field
    ).

  ENDMETHOD.


  METHOD map_editable_column.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_columns
      WITH KEY field_name = 'DESCRIPTION'
      INTO DATA(ls_column).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_column-editable
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_column-visible
    ).

  ENDMETHOD.


  METHOD map_amount_semantics.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_columns
      WITH KEY field_name = 'AMOUNT'
      INTO DATA(ls_column).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện AMOUNT'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'CURR'
      act = ls_column-data_type
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 15
      act = ls_column-length
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = ls_column-decimals
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'CURRENCY'
      act = ls_column-currency_field
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'SUM'
      act = ls_column-aggregation
    ).

  ENDMETHOD.


  METHOD map_technical_column.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_columns
      WITH KEY field_name = 'STATUS'
      INTO DATA(ls_column).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_column-technical
    ).

    cl_abap_unit_assert=>assert_false(
      act = ls_column-visible
    ).

  ENDMETHOD.


METHOD link_to_alv_output.

  DATA(ls_result) = get_result( ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-alv_columns
    msg = 'Không có ALV column để kiểm tra output link'
  ).

  LOOP AT ls_result-alv_columns
    ASSIGNING FIELD-SYMBOL(<column>).

    cl_abap_unit_assert=>assert_not_initial(
      act = <column>-output_id
      msg = |Column chưa được link với ALV output: {
        <column>-field_name }|
    ).

  ENDLOOP.

ENDMETHOD.

METHOD create_evidence.

  DATA(ls_result) = get_result( ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-alv_columns
    msg = 'Không có ALV column để kiểm tra evidence'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lines( ls_result-alv_columns )
    act = lines( ls_result-evidences )
    msg = 'Mỗi ALV column phải có evidence'
  ).

  LOOP AT ls_result-evidences
    ASSIGNING FIELD-SYMBOL(<evidence>).

    cl_abap_unit_assert=>assert_not_initial(
      act = <evidence>-evidence_id
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_ALV'
      act = <evidence>-source_object
    ).

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
