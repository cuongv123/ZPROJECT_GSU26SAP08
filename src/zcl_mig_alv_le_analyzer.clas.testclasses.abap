CLASS ltc_alv_le_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_alv_le_result
        RAISING
          zcx_mig_analysis,

      map_layout
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_four_events
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_double_click
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_data_changed
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_user_command
        FOR TESTING
        RAISING zcx_mig_analysis,

      link_events_to_output
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_evidence
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_alv_le_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_alv_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(lo_le_analyzer) =
      NEW zcl_mig_alv_le_analyzer( ).

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

    DATA(ls_alv_result) =
      lo_alv_analyzer->zif_mig_alv_analyzer~analyze(
        it_source_units =
          lt_source_units
      ).

    rs_result =
      lo_le_analyzer->zif_mig_alv_le_analyzer~analyze(
        it_source_units =
          lt_source_units
        it_alv_outputs =
          ls_alv_result-alv_outputs
      ).

  ENDMETHOD.

    METHOD map_layout.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'CL_GUI_ALV_GRID'
      INTO DATA(ls_grid).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GO_GRID'
      act = ls_grid-control_object
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_grid-zebra
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_grid-auto_width
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_grid-editable
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'A'
      act = ls_grid-selection_mode
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_grid-layout_evidence_id
    ).

  ENDMETHOD.


  METHOD detect_four_events.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 4
      act = lines( ls_result-alv_events )
      msg = 'Phải phát hiện 4 ALV event registrations'
    ).

  ENDMETHOD.


  METHOD detect_double_click.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_events
      WITH KEY event_name = 'DOUBLE_CLICK'
      INTO DATA(ls_event).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện DOUBLE_CLICK'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GO_HANDLER->HANDLE_DOUBLE_CLICK'
      act = ls_event-handler_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'INSTANCE_METHOD'
      act = ls_event-handler_kind
    ).

  ENDMETHOD.


  METHOD detect_data_changed.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_events
      WITH KEY event_name = 'DATA_CHANGED'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện DATA_CHANGED'
    ).

  ENDMETHOD.


  METHOD detect_user_command.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_events
      WITH KEY event_name = 'USER_COMMAND'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện USER_COMMAND'
    ).

  ENDMETHOD.


  METHOD link_events_to_output.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_events
    ).

    LOOP AT ls_result-alv_events
      ASSIGNING FIELD-SYMBOL(<event>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <event>-output_id
      ).

      cl_abap_unit_assert=>assert_equals(
        exp = 'GO_GRID'
        act = <event>-control_object
      ).

      cl_abap_unit_assert=>assert_true(
        act = <event>-gui_dependency
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD create_evidence.

    DATA(ls_result) = get_result( ).

    DATA(lv_expected) =
      lines( ls_result-alv_events ) + 1.

    cl_abap_unit_assert=>assert_equals(
      exp = lv_expected
      act = lines( ls_result-evidences )
      msg = 'Cần một evidence cho layout và mỗi event'
    ).

  ENDMETHOD.

ENDCLASS.
