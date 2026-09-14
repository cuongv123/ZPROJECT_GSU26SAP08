CLASS ltc_call_bind_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS detect_bapi_bindings
      FOR TESTING
      RAISING zcx_mig_analysis.
    METHODS:
  detect_method_changing
    FOR TESTING
    RAISING zcx_mig_analysis,

  detect_commit_binding
    FOR TESTING
    RAISING zcx_mig_analysis,

  detect_perform_bindings
    FOR TESTING
    RAISING zcx_mig_analysis.

ENDCLASS.



CLASS ltc_call_bind_analyzer IMPLEMENTATION.


  METHOD detect_bapi_bindings.

    CONSTANTS gc_program TYPE progname
      VALUE 'ZRMIG_UT_CALL_BIND'.


    DATA lt_source
      TYPE zif_mig_types=>tt_source_line.


    lt_source = VALUE #(

      (
        source_object = gc_program
        line_number   = 1
        source_text   =
          `REPORT zrmig_ut_call_bind.`
      )

      (
        source_object = gc_program
        line_number   = 2
        source_text   =
          `DATA ls_address TYPE bapiaddr3.`
      )

      (
        source_object = gc_program
        line_number   = 3
        source_text   =
          `DATA lt_return TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.`
      )

      (
        source_object = gc_program
        line_number   = 4
        source_text   =
          `START-OF-SELECTION.`
      )

      (
        source_object = gc_program
        line_number   = 5
        source_text   =
          `CALL FUNCTION 'BAPI_USER_GET_DETAIL'`
      )

      (
        source_object = gc_program
        line_number   = 6
        source_text   =
          `  EXPORTING`
      )

      (
        source_object = gc_program
        line_number   = 7
        source_text   =
          `    username = sy-uname`
      )

      (
        source_object = gc_program
        line_number   = 8
        source_text   =
          `  IMPORTING`
      )

      (
        source_object = gc_program
        line_number   = 9
        source_text   =
          `    address = ls_address`
      )

      (
        source_object = gc_program
        line_number   = 10
        source_text   =
          `  TABLES`
      )

      (
        source_object = gc_program
        line_number   = 11
        source_text   =
          `    return = lt_return.`
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

      scan_result =
        ls_normalized

    ) TO lt_source_units.


    "==========================================================
    " Logic detection trước
    "==========================================================
    DATA(lo_logic_analyzer) =
      NEW zcl_mig_logic_analyzer( ).


    DATA(ls_logic_result) =
      lo_logic_analyzer->zif_mig_logic_analyzer~analyze(
        it_source_units =
          lt_source_units
      ).


    READ TABLE ls_logic_result-business_logic
      WITH KEY
        object_type = 'BAPI'
        object_name = 'BAPI_USER_GET_DETAIL'
      INTO DATA(ls_bapi).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect BAPI_USER_GET_DETAIL'
    ).


    "==========================================================
    " Binding analysis
    "==========================================================
    DATA(lo_bind_analyzer) =
      NEW zcl_mig_call_bind_analyzer( ).


    DATA(ls_bind_result) =
      lo_bind_analyzer->zif_mig_call_bind_analyzer~analyze(

        it_source_units =
          lt_source_units

        it_logic =
          ls_logic_result-business_logic

        it_evidences =
          ls_logic_result-evidences

      ).


    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = lines(
              ls_bind_result-call_bindings
            )
      msg = 'BAPI phải có 3 observed bindings'
    ).


    "==========================================================
    " USERNAME
    "==========================================================
    READ TABLE ls_bind_result-call_bindings
      WITH KEY
        call_item_id   = ls_bapi-item_id
        parameter_name = 'USERNAME'
      INTO DATA(ls_username).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu USERNAME binding'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'EXPORTING'
      act = ls_username-direction
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'SY-UNAME'
      act = to_upper(
              ls_username-actual_expression
            )
    ).


    "==========================================================
    " ADDRESS
    "==========================================================
    READ TABLE ls_bind_result-call_bindings
      WITH KEY
        call_item_id   = ls_bapi-item_id
        parameter_name = 'ADDRESS'
      INTO DATA(ls_address_binding).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu ADDRESS binding'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'IMPORTING'
      act = ls_address_binding-direction
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'LS_ADDRESS'
      act = to_upper(
              ls_address_binding-actual_expression
            )
    ).


    "==========================================================
    " RETURN
    "==========================================================
    READ TABLE ls_bind_result-call_bindings
      WITH KEY
        call_item_id   = ls_bapi-item_id
        parameter_name = 'RETURN'
      INTO DATA(ls_return).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu RETURN binding'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'TABLES'
      act = ls_return-direction
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'LT_RETURN'
      act = to_upper(
              ls_return-actual_expression
            )
    ).

  ENDMETHOD.

  METHOD detect_method_changing.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_METHOD_BIND'.


  DATA lt_source
    TYPE zif_mig_types=>tt_source_line.


  lt_source = VALUE #(

    (
      source_object = gc_program
      line_number   = 1
      source_text   =
        `REPORT zrmig_ut_method_bind.`
    )

    (
      source_object = gc_program
      line_number   = 2
      source_text   =
        `DATA gt_result TYPE STANDARD TABLE OF t001 WITH EMPTY KEY.`
    )

    (
      source_object = gc_program
      line_number   = 3
      source_text   =
        `START-OF-SELECTION.`
    )

    (
      source_object = gc_program
      line_number   = 4
      source_text   =
        `lcl_worker=>enrich_static(`
    )

    (
      source_object = gc_program
      line_number   = 5
      source_text   =
        `  CHANGING`
    )

    (
      source_object = gc_program
      line_number   = 6
      source_text   =
        `    ct_result = gt_result`
    )

    (
      source_object = gc_program
      line_number   = 7
      source_text   =
        `).`
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


  DATA(lo_logic_analyzer) =
    NEW zcl_mig_logic_analyzer( ).


  DATA(ls_logic_result) =
    lo_logic_analyzer->zif_mig_logic_analyzer~analyze(
      it_source_units = lt_source_units
    ).


  READ TABLE ls_logic_result-business_logic
    WITH KEY
      object_type    = 'STATIC_METHOD'
      object_name    = 'ENRICH_STATIC'
      container_name = 'LCL_WORKER'
    INTO DATA(ls_method).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không detect LCL_WORKER=>ENRICH_STATIC'
  ).


  DATA(lo_bind_analyzer) =
    NEW zcl_mig_call_bind_analyzer( ).


  DATA(ls_bind_result) =
    lo_bind_analyzer->zif_mig_call_bind_analyzer~analyze(

      it_source_units = lt_source_units

      it_logic =
        ls_logic_result-business_logic

      it_evidences =
        ls_logic_result-evidences

    ).


  READ TABLE ls_bind_result-call_bindings
    WITH KEY
      call_item_id   = ls_method-item_id
      parameter_name = 'CT_RESULT'
    INTO DATA(ls_binding).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Thiếu CT_RESULT binding'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'CHANGING'
    act = ls_binding-direction
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'GT_RESULT'
    act = to_upper(
            ls_binding-actual_expression
          )
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 1
    act = lines(
            ls_bind_result-call_bindings
          )
    msg = 'Method phải có đúng 1 binding'
  ).

ENDMETHOD.

METHOD detect_commit_binding.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_COMMIT_BIND'.


  DATA lt_source
    TYPE zif_mig_types=>tt_source_line.


  lt_source = VALUE #(

    (
      source_object = gc_program
      line_number   = 1
      source_text   =
        `REPORT zrmig_ut_commit_bind.`
    )

    (
      source_object = gc_program
      line_number   = 2
      source_text   =
        `PARAMETERS p_commit AS CHECKBOX.`
    )

    (
      source_object = gc_program
      line_number   = 3
      source_text   =
        `START-OF-SELECTION.`
    )

    (
      source_object = gc_program
      line_number   = 4
      source_text   =
        `IF p_commit = abap_true.`
    )

    (
      source_object = gc_program
      line_number   = 5
      source_text   =
        `CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'`
    )

    (
      source_object = gc_program
      line_number   = 6
      source_text   =
        `  EXPORTING`
    )

    (
      source_object = gc_program
      line_number   = 7
      source_text   =
        `    wait = abap_true.`
    )

    (
      source_object = gc_program
      line_number   = 8
      source_text   =
        `ENDIF.`
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


  DATA(lo_logic_analyzer) =
    NEW zcl_mig_logic_analyzer( ).


  DATA(ls_logic_result) =
    lo_logic_analyzer->zif_mig_logic_analyzer~analyze(
      it_source_units = lt_source_units
    ).


  READ TABLE ls_logic_result-business_logic
    WITH KEY
      object_type = 'BAPI'
      object_name = 'BAPI_TRANSACTION_COMMIT'
    INTO DATA(ls_commit).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không detect BAPI_TRANSACTION_COMMIT'
  ).


  "============================================================
  " Fix 1 phải vẫn còn đúng
  "============================================================
  cl_abap_unit_assert=>assert_equals(
    exp = 'CONDITIONAL'
    act = ls_commit-execution_kind
    msg = 'Commit phải giữ execution context'
  ).


  DATA(lv_execution_context) =
    to_upper(
      ls_commit-execution_context
    ).


  cl_abap_unit_assert=>assert_char_cp(
    act = lv_execution_context
    exp = '*IF*P_COMMIT*=*ABAP_TRUE*'
    msg = 'Commit phải giữ IF P_COMMIT condition'
  ).


  "============================================================
  " Fix 2
  "============================================================
  DATA(lo_bind_analyzer) =
    NEW zcl_mig_call_bind_analyzer( ).


  DATA(ls_bind_result) =
    lo_bind_analyzer->zif_mig_call_bind_analyzer~analyze(

      it_source_units = lt_source_units

      it_logic =
        ls_logic_result-business_logic

      it_evidences =
        ls_logic_result-evidences

    ).


  READ TABLE ls_bind_result-call_bindings
    WITH KEY
      call_item_id   = ls_commit-item_id
      parameter_name = 'WAIT'
    INTO DATA(ls_wait).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Thiếu WAIT binding'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'EXPORTING'
    act = ls_wait-direction
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'ABAP_TRUE'
    act = to_upper(
            ls_wait-actual_expression
          )
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 1
    act = lines(
            ls_bind_result-call_bindings
          )
    msg = 'Commit call phải có đúng 1 binding'
  ).

ENDMETHOD.

METHOD detect_perform_bindings.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_PERFORM_BIND'.


  DATA lt_source
    TYPE zif_mig_types=>tt_source_line.


  lt_source = VALUE #(

    (
      source_object = gc_program
      line_number   = 1
      source_text   =
        `REPORT zrmig_ut_perform_bind.`
    )

    (
      source_object = gc_program
      line_number   = 2
      source_text   =
        `PARAMETERS p_bukrs TYPE bukrs.`
    )

    (
      source_object = gc_program
      line_number   = 3
      source_text   =
        `DATA gt_items TYPE STANDARD TABLE OF t001 WITH EMPTY KEY.`
    )

    (
      source_object = gc_program
      line_number   = 4
      source_text   =
        `DATA gv_total TYPE i.`
    )

    (
      source_object = gc_program
      line_number   = 5
      source_text   =
        `START-OF-SELECTION.`
    )

    (
      source_object = gc_program
      line_number   = 6
      source_text   =
        `PERFORM calculate_total`
    )

    (
      source_object = gc_program
      line_number   = 7
      source_text   =
        `  USING`
    )

    (
      source_object = gc_program
      line_number   = 8
      source_text   =
        `    p_bukrs`
    )

    (
      source_object = gc_program
      line_number   = 9
      source_text   =
        `    gt_items`
    )

    (
      source_object = gc_program
      line_number   = 10
      source_text   =
        `  CHANGING`
    )

    (
      source_object = gc_program
      line_number   = 11
      source_text   =
        `    gv_total.`
    )

    (
      source_object = gc_program
      line_number   = 12
      source_text   =
        `FORM calculate_total USING iv_bukrs iv_items CHANGING cv_total.`
    )

    (
      source_object = gc_program
      line_number   = 13
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


  DATA(lo_logic_analyzer) =
    NEW zcl_mig_logic_analyzer( ).


  DATA(ls_logic_result) =
    lo_logic_analyzer->zif_mig_logic_analyzer~analyze(
      it_source_units = lt_source_units
    ).


  READ TABLE ls_logic_result-business_logic
    WITH KEY
      object_type = 'FORM_CALL'
      object_name = 'CALCULATE_TOTAL'
    INTO DATA(ls_perform).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không detect PERFORM CALCULATE_TOTAL'
  ).


  DATA(lo_bind_analyzer) =
    NEW zcl_mig_call_bind_analyzer( ).


  DATA(ls_bind_result) =
    lo_bind_analyzer->zif_mig_call_bind_analyzer~analyze(

      it_source_units = lt_source_units

      it_logic =
        ls_logic_result-business_logic

      it_evidences =
        ls_logic_result-evidences

    ).


  cl_abap_unit_assert=>assert_equals(
    exp = 3
    act = lines(
            ls_bind_result-call_bindings
          )
    msg = 'PERFORM phải tạo 3 positional bindings'
  ).


  "============================================================
  " USING #1 = P_BUKRS
  "============================================================
  READ TABLE ls_bind_result-call_bindings
    WITH KEY
      call_item_id   = ls_perform-item_id
      direction      = 'USING'
      parameter_name = '#1'
    INTO DATA(ls_using_1).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Thiếu USING #1'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'P_BUKRS'
    act = to_upper(
            ls_using_1-actual_expression
          )
  ).


  "============================================================
  " USING #2 = GT_ITEMS
  "============================================================
  READ TABLE ls_bind_result-call_bindings
    WITH KEY
      call_item_id   = ls_perform-item_id
      direction      = 'USING'
      parameter_name = '#2'
    INTO DATA(ls_using_2).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Thiếu USING #2'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'GT_ITEMS'
    act = to_upper(
            ls_using_2-actual_expression
          )
  ).


  "============================================================
  " CHANGING #1 = GV_TOTAL
  "============================================================
  READ TABLE ls_bind_result-call_bindings
    WITH KEY
      call_item_id   = ls_perform-item_id
      direction      = 'CHANGING'
      parameter_name = '#1'
    INTO DATA(ls_changing_1).


  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Thiếu CHANGING #1'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = 'GV_TOTAL'
    act = to_upper(
            ls_changing_1-actual_expression
          )
  ).

ENDMETHOD.

ENDCLASS.
