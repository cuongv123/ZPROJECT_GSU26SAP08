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

    METHODS preserve_call_bindings
      FOR TESTING
      RAISING zcx_mig_analysis.

      METHODS preserve_commit_context
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

  METHOD preserve_call_bindings.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).


  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name =
        'ZRMIG_SAMPLE_FULL'
    ).


  DATA(lo_flow) =
    NEW zcl_mig_flow_summarizer( ).


  DATA(ls_flow) =
    lo_flow->zif_mig_flow_summarizer~summarize(
      is_result =
        ls_result
    ).


  READ TABLE ls_flow-steps
    WITH KEY
      step_kind   = 'CALL'
      object_name = 'BAPI_USER_GET_DETAIL'
    INTO DATA(ls_bapi).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Flow thiếu BAPI_USER_GET_DETAIL'
  ).


  DATA(lv_detail) =
    to_upper(
      ls_bapi-detail
    ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*OBSERVEDBINDINGS*'
    msg = 'Flow chưa expose observed bindings'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*EXPORTING*USERNAME*=*SY-UNAME*'
    msg = 'Flow thiếu USERNAME binding'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*IMPORTING*ADDRESS*=*LS_ADDRESS*'
    msg = 'Flow thiếu ADDRESS binding'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*TABLES*RETURN*=*LT_RETURN*'
    msg = 'Flow thiếu RETURN binding'
  ).

ENDMETHOD.

METHOD preserve_commit_context.

  "============================================================
  " Analyze sample thực
  "============================================================
  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).


  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name =
        'ZRMIG_SAMPLE_FULL'
    ).


  "============================================================
  " Trước tiên kiểm tra Analysis IR
  "
  " Nếu test fail ở đây thì lỗi thuộc analyzer/aggregator,
  " không phải Flow Summarizer.
  "============================================================
  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'BAPI'
      object_name = 'BAPI_TRANSACTION_COMMIT'
    INTO DATA(ls_commit_logic).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Analysis IR thiếu BAPI_TRANSACTION_COMMIT'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'CONDITIONAL'
    act = ls_commit_logic-execution_kind
    msg = 'Commit phải được đánh dấu CONDITIONAL'
  ).


  DATA(lv_context) =
    to_upper(
      ls_commit_logic-execution_context
    ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_context
    exp = '*P_COMMIT*ABAP_TRUE*'
    msg = 'Commit mất IF P_COMMIT execution context'
  ).


  "============================================================
  " Binding phải link đúng Business Logic ItemId
  "============================================================
  READ TABLE ls_result-call_bindings
    WITH KEY
      call_item_id   = ls_commit_logic-item_id
      parameter_name = 'WAIT'
    INTO DATA(ls_wait_binding).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Analysis IR thiếu WAIT binding của commit'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'EXPORTING'
    act = ls_wait_binding-direction
    msg = 'WAIT binding phải thuộc EXPORTING'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'ABAP_TRUE'
    act = to_upper(
            ls_wait_binding-actual_expression
          )
    msg = 'WAIT phải bind với ABAP_TRUE'
  ).


  "============================================================
  " Build Legacy Flow
  "============================================================
  DATA(lo_flow) =
    NEW zcl_mig_flow_summarizer( ).


  DATA(ls_flow) =
    lo_flow->zif_mig_flow_summarizer~summarize(
      is_result =
        ls_result
    ).


  READ TABLE ls_flow-steps
    WITH KEY
      step_kind   = 'CALL'
      object_name = 'BAPI_TRANSACTION_COMMIT'
    INTO DATA(ls_commit_step).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Legacy Flow thiếu BAPI_TRANSACTION_COMMIT'
  ).


  "============================================================
  " Evidence relation không được mất khi projection sang Flow
  "============================================================
  cl_abap_unit_assert=>assert_equals(
    exp = ls_commit_logic-evidence_id
    act = ls_commit_step-evidence_id
    msg = 'Flow commit node mất EvidenceId'
  ).


  "============================================================
  " Flow detail phải chứa BOTH:
  "
  " 1. Execution Context
  " 2. Observed Parameter Binding
  "============================================================
  DATA(lv_detail) =
    to_upper(
      ls_commit_step-detail
    ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*CONDITIONAL*'
    msg = 'Flow chưa biểu diễn commit là CONDITIONAL'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*P_COMMIT*ABAP_TRUE*'
    msg = 'Flow chưa giữ IF P_COMMIT context'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*OBSERVEDBINDINGS*'
    msg = 'Flow chưa expose observed bindings'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_detail
    exp = '*EXPORTING*WAIT*=*ABAP_TRUE*'
    msg = 'Flow thiếu EXPORTING WAIT = ABAP_TRUE'
  ).

ENDMETHOD.

ENDCLASS.
