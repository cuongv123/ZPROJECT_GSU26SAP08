CLASS ltc_flow_summarizer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS get_summary
      RETURNING
        VALUE(rs_summary)
          TYPE zif_mig_flow_summarizer=>ty_flow_summary
      RAISING
        zcx_mig_analysis.


    METHODS event_routine_flow
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS database_flow
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS logic_flow
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS alv_flow
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.



CLASS ltc_flow_summarizer IMPLEMENTATION.


  METHOD get_summary.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).


    DATA(ls_result) =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'
      ).


    DATA(lo_summarizer) =
      NEW zcl_mig_flow_summarizer( ).


    rs_summary =
      lo_summarizer->zif_mig_flow_summarizer~summarize(
        is_result = ls_result
      ).


  ENDMETHOD.



  METHOD event_routine_flow.

    DATA(ls_summary) =
      get_summary( ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_FULL'
      act = ls_summary-program_name
    ).


    "----------------------------------------------------------
    " START-OF-SELECTION
    "----------------------------------------------------------
    READ TABLE ls_summary-steps
      WITH KEY
        step_kind   = 'EVENT'
        object_name = 'START-OF-SELECTION'
      INTO DATA(ls_start).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu START-OF-SELECTION'
    ).


    "----------------------------------------------------------
    " LOAD_DATA
    "----------------------------------------------------------
    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'ROUTINE'
        context_name = 'START-OF-SELECTION'
        object_name  = 'LOAD_DATA'
      INTO DATA(ls_load).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu LOAD_DATA dưới START-OF-SELECTION'
    ).


    "----------------------------------------------------------
    " PROCESS_DATA
    "----------------------------------------------------------
    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'ROUTINE'
        context_name = 'START-OF-SELECTION'
        object_name  = 'PROCESS_DATA'
      INTO DATA(ls_process).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu PROCESS_DATA'
    ).


    "----------------------------------------------------------
    " END-OF-SELECTION → DISPLAY_DATA
    "----------------------------------------------------------
    READ TABLE ls_summary-steps
      WITH KEY
        step_kind   = 'EVENT'
        object_name = 'END-OF-SELECTION'
      INTO DATA(ls_end).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).


    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'ROUTINE'
        context_name = 'END-OF-SELECTION'
        object_name  = 'DISPLAY_DATA'
      INTO DATA(ls_display).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu DISPLAY_DATA'
    ).


    "Logical event ordering
    cl_abap_unit_assert=>assert_true(
      act = xsdbool(
        ls_start-sequence
          < ls_end-sequence
      )
      msg = 'START phải đứng trước END'
    ).


  ENDMETHOD.



  METHOD database_flow.

    DATA(ls_summary) =
      get_summary( ).


    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'DATABASE'
        context_name = 'LOAD_DATA'
        object_name  = 'T001'
      INTO DATA(ls_db).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'LOAD_DATA không nối tới T001'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_db-detail
      exp = '*T001K*'
      msg = 'Flow thiếu JOIN T001K'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_db-detail
      exp = '*T001W*'
      msg = 'Flow thiếu JOIN T001W'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_db-detail
      exp = '*GT_RESULT*'
      msg = 'Flow thiếu RESULT GT_RESULT'
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_db-evidence_id
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_db-source_object
    ).


    cl_abap_unit_assert=>assert_true(
      act = xsdbool(
        ls_db-source_line > 0
      )
    ).


  ENDMETHOD.



  METHOD logic_flow.

    DATA(ls_summary) =
      get_summary( ).


    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'CALL'
        context_name = 'PROCESS_DATA'
        object_name  = 'DDIF_FIELDINFO_GET'
      TRANSPORTING NO FIELDS.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Flow thiếu DDIF_FIELDINFO_GET'
    ).


    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'CALL'
        context_name = 'PROCESS_DATA'
        object_name  = 'BAPI_USER_GET_DETAIL'
      TRANSPORTING NO FIELDS.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Flow thiếu BAPI_USER_GET_DETAIL'
    ).


    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'CALL'
        context_name = 'PROCESS_DATA'
        object_name  = 'ENRICH_STATIC'
      INTO DATA(ls_static).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Flow thiếu ENRICH_STATIC'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_static-detail
      exp = '*LCL_WORKER*'
    ).


    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'CALL'
        context_name = 'PROCESS_DATA'
        object_name  = 'CALCULATE'
      INTO DATA(ls_instance).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Flow thiếu CALCULATE'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_instance-detail
      exp = '*LO_WORKER*'
    ).


  ENDMETHOD.



  METHOD alv_flow.

    DATA(ls_summary) =
      get_summary( ).


    READ TABLE ls_summary-steps
      WITH KEY
        step_kind    = 'ALV'
        context_name = 'DISPLAY_DATA'
      INTO DATA(ls_alv).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'DISPLAY_DATA không nối tới ALV'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'CL_GUI_ALV_GRID'
      act = ls_alv-object_type
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_alv-detail
      exp = '*GT_RESULT*'
      msg = 'ALV flow thiếu GT_RESULT'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_alv-detail
      exp = '*GO_GRID*'
      msg = 'ALV flow thiếu GO_GRID'
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_alv-evidence_id
    ).


  ENDMETHOD.


ENDCLASS.
