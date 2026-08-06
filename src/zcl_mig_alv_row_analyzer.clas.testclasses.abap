CLASS ltc_mig_alv_row_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS get_result
      EXPORTING
        et_outputs TYPE zif_mig_types=>tt_alv_output
        es_result  TYPE zif_mig_types=>ty_alv_fcat_result
      RAISING
        zcx_mig_analysis.

    METHODS infer_salv_columns
      FOR TESTING
      RAISING
        zcx_mig_analysis.

    METHODS link_columns_to_salv
      FOR TESTING
      RAISING
        zcx_mig_analysis.

    METHODS preserve_ddic_metadata
      FOR TESTING
      RAISING
        zcx_mig_analysis.

ENDCLASS.


CLASS ltc_mig_alv_row_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_alv_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(lo_row_analyzer) =
      NEW zcl_mig_alv_row_analyzer( ).


    DATA(lt_source) =
      lo_source_repo->zif_mig_source_repo~read_program(
        iv_program_name =
          'ZRMIG_TEST_R1_ALV_COVERAGE'
      ).


    DATA(ls_scan_result) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object =
          'ZRMIG_TEST_R1_ALV_COVERAGE'

        it_source =
          lt_source
      ).


    DATA(ls_normalized) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result =
          ls_scan_result
      ).


    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.


    APPEND VALUE #(
      source_object = VALUE #(
        object_name =
          'ZRMIG_TEST_R1_ALV_COVERAGE'

        object_type =
          'PROGRAM'

        source_lines =
          lt_source
      )

      scan_result =
        ls_normalized
    ) TO lt_source_units.


    DATA(ls_alv_result) =
      lo_alv_analyzer->zif_mig_alv_analyzer~analyze(
        it_source_units =
          lt_source_units
      ).


    et_outputs =
      ls_alv_result-alv_outputs.


    es_result =
      lo_row_analyzer->zif_mig_alv_fcat_analyzer~analyze(
        it_source_units =
          lt_source_units

        it_alv_outputs =
          ls_alv_result-alv_outputs
      ).

  ENDMETHOD.


  METHOD infer_salv_columns.

    DATA:
      lt_outputs TYPE zif_mig_types=>tt_alv_output,
      ls_result  TYPE zif_mig_types=>ty_alv_fcat_result.


    get_result(
      IMPORTING
        et_outputs = lt_outputs
        es_result  = ls_result
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 6
      act = lines(
        ls_result-alv_columns
      )
      msg = 'SALV fallback must infer six TY_RESULT fields'
    ).


    DATA lt_expected_fields
      TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.


    lt_expected_fields =
      VALUE #(
        ( `BUKRS` )
        ( `BUKRS_EXT` )
        ( `BUTXT` )
        ( `ORT01` )
        ( `WAERS` )
        ( `STATUS` )
      ).


    LOOP AT lt_expected_fields
      INTO DATA(lv_field_name).


      READ TABLE ls_result-alv_columns
        WITH KEY
          field_name = lv_field_name
        TRANSPORTING NO FIELDS.


      cl_abap_unit_assert=>assert_subrc(
        exp = 0
        msg = |Missing inferred SALV column { lv_field_name }|
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD link_columns_to_salv.

    DATA:
      lt_outputs TYPE zif_mig_types=>tt_alv_output,
      ls_result  TYPE zif_mig_types=>ty_alv_fcat_result.


    get_result(
      IMPORTING
        et_outputs = lt_outputs
        es_result  = ls_result
    ).


    READ TABLE lt_outputs
      WITH KEY
        framework = 'CL_SALV_TABLE'
      INTO DATA(ls_salv_output).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'SALV output was not detected'
    ).


    LOOP AT ls_result-alv_columns
      ASSIGNING FIELD-SYMBOL(<column>).


      cl_abap_unit_assert=>assert_equals(
        exp = ls_salv_output-output_id
        act = <column>-output_id
        msg = |Column { <column>-field_name } linked to wrong output|
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD preserve_ddic_metadata.

    DATA:
      lt_outputs TYPE zif_mig_types=>tt_alv_output,
      ls_result  TYPE zif_mig_types=>ty_alv_fcat_result.


    get_result(
      IMPORTING
        et_outputs = lt_outputs
        es_result  = ls_result
    ).


    READ TABLE ls_result-alv_columns
      WITH KEY
        field_name = 'BUKRS'
      INTO DATA(ls_bukrs).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'T001'
      act = ls_bukrs-reference_table
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'BUKRS'
      act = ls_bukrs-reference_field
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'BUKRS'
      act = ls_bukrs-data_element
    ).

  ENDMETHOD.

ENDCLASS.
