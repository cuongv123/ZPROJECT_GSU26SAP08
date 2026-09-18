CLASS ltc_alv_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_alv_analysis_result
        RAISING
          zcx_mig_analysis,

      detect_two_outputs
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_grid_framework
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_grid_dependencies
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_salv_framework
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_salv_output
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_evidence
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_alv_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(lt_source) =
      lo_source_repo->zif_mig_source_repo~read_program(
        iv_program_name =
          'ZRMIG_SAMPLE_ALV'
      ).

    DATA(ls_scan_result) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object =
          'ZRMIG_SAMPLE_ALV'
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
        object_name  = 'ZRMIG_SAMPLE_ALV'
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized
    ) TO lt_source_units.

    rs_result =
      lo_analyzer->zif_mig_alv_analyzer~analyze(
        it_source_units =
          lt_source_units
      ).

  ENDMETHOD.

    METHOD detect_two_outputs.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( ls_result-alv_outputs )
      msg = 'Phải phát hiện Grid ALV và SALV'
    ).

  ENDMETHOD.


  METHOD detect_grid_framework.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'CL_GUI_ALV_GRID'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện CL_GUI_ALV_GRID'
    ).

  ENDMETHOD.


  METHOD map_grid_dependencies.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'CL_GUI_ALV_GRID'
      INTO DATA(ls_grid).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_grid-output_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_FIELDCAT'
      act = ls_grid-field_catalog
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_SORT'
      act = ls_grid-sort_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_FILTER'
      act = ls_grid-filter_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GS_LAYOUT'
      act = ls_grid-layout_object
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GS_VARIANT'
      act = ls_grid-variant_object
    ).

  ENDMETHOD.


  METHOD detect_salv_framework.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'CL_SALV_TABLE'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện CL_SALV_TABLE'
    ).

  ENDMETHOD.


  METHOD map_salv_output.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'CL_SALV_TABLE'
      INTO DATA(ls_salv).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_salv-output_table
      msg = 'Không lấy được T_TABLE của SALV'
    ).

  ENDMETHOD.


  METHOD create_evidence.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_result-alv_outputs )
      act = lines( ls_result-evidences )
      msg = 'Mỗi ALV output phải có evidence'
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

CLASS ltc_cp4_alv_routine DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS preserve_alv_routine
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_cp4_alv_routine IMPLEMENTATION.

  METHOD preserve_alv_routine.

    CONSTANTS gc_program TYPE progname
      VALUE 'ZRMIG_UT_ALV_REL'.


    DATA lt_source
      TYPE zif_mig_types=>tt_source_line.


    lt_source = VALUE #(

      (
        source_object = gc_program
        line_number   = 1
        source_text   = `REPORT zrmig_ut_alv_rel.`
      )

      (
        source_object = gc_program
        line_number   = 2
        source_text   =
          `DATA gt_result TYPE STANDARD TABLE OF t001.`
      )

      (
        source_object = gc_program
        line_number   = 3
        source_text   =
          `DATA gt_fcat TYPE lvc_t_fcat.`
      )

      (
        source_object = gc_program
        line_number   = 4
        source_text   =
          `DATA go_grid TYPE REF TO cl_gui_alv_grid.`
      )

      (
        source_object = gc_program
        line_number   = 5
        source_text   =
          `FORM display_data.`
      )

      (
        source_object = gc_program
        line_number   = 6
        source_text   =
          `go_grid->set_table_for_first_display(`
      )

      (
        source_object = gc_program
        line_number   = 7
        source_text   =
          `  CHANGING`
      )

      (
        source_object = gc_program
        line_number   = 8
        source_text   =
          `    it_outtab       = gt_result`
      )

      (
        source_object = gc_program
        line_number   = 9
        source_text   =
          `    it_fieldcatalog = gt_fcat ).`
      )

      (
        source_object = gc_program
        line_number   = 10
        source_text   =
          `ENDFORM.`
      )

    ).


    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(ls_scan) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object = gc_program
        it_source        = lt_source
      ).


    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(ls_normalized) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result = ls_scan
      ).


    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.

    APPEND VALUE #(
      source_object = VALUE #(
        object_name  = gc_program
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized
    ) TO lt_source_units.


    DATA(lo_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(ls_result) =
      lo_analyzer->zif_mig_alv_analyzer~analyze(
        it_source_units = lt_source_units
      ).


    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'CL_GUI_ALV_GRID'
      INTO DATA(ls_alv).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện CL_GUI_ALV_GRID'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_alv-output_table
      msg = 'ALV output table không đúng'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'DISPLAY_DATA'
      act = ls_alv-containing_routine
      msg = 'ALV không được gắn với FORM DISPLAY_DATA'
    ).

  ENDMETHOD.

ENDCLASS.

CLASS ltc_cp5_alv_unresolved DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS unresolved_table_is_medium
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_cp5_alv_unresolved IMPLEMENTATION.

  METHOD unresolved_table_is_medium.

    CONSTANTS gc_program TYPE progname
      VALUE 'ZRMIG_UT_ALV_UNRES'.

    DATA(lt_source) =
      VALUE zif_mig_types=>tt_source_line(

        (
          source_object = gc_program
          line_number   = 1
          source_text   = `REPORT zrmig_ut_alv_unres.`
        )

        (
          source_object = gc_program
          line_number   = 2
          source_text   = `FORM display_data.`
        )

        (
          source_object = gc_program
          line_number   = 3
          source_text   =
            `CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'.`
        )

        (
          source_object = gc_program
          line_number   = 4
          source_text   = `ENDFORM.`
        )

      ).


    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(ls_scan) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object = gc_program
        it_source        = lt_source
      ).


    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(ls_normalized) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result = ls_scan
      ).


    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.

    APPEND VALUE #(
      source_object = VALUE #(
        object_name  = gc_program
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized
    ) TO lt_source_units.


    DATA(lo_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(ls_result) =
      lo_analyzer->zif_mig_alv_analyzer~analyze(
        it_source_units = lt_source_units
      ).


    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'REUSE_ALV_GRID_DISPLAY'
      INTO DATA(ls_alv).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'ALV invocation phải được phát hiện'
    ).


    cl_abap_unit_assert=>assert_initial(
      act = ls_alv-output_table
      msg = 'Test case này phải giữ OUTPUT_TABLE unresolved'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_conf_medium
      act = ls_alv-confidence
      msg = 'Unresolved ALV phải có confidence MEDIUM'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'DISPLAY_DATA'
      act = ls_alv-containing_routine
      msg = 'Phải giữ relationship với DISPLAY_DATA'
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_alv-evidence_id
    ).

  ENDMETHOD.

ENDCLASS.
