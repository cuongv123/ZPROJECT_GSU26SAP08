CLASS ltc_logic_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_logic_analysis_result
        RAISING
          zcx_mig_analysis,

      detect_form_definition
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_form_call
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_bapi
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_static_method
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_instance_method
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_gui_dependencies
        FOR TESTING
        RAISING zcx_mig_analysis,

      detect_submit
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_evidence
        FOR TESTING
        RAISING zcx_mig_analysis.

      METHODS:
  get_side_effect_result
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_logic_analysis_result
    RAISING
      zcx_mig_analysis,

  avoid_false_write_side_effect
    FOR TESTING
    RAISING
      zcx_mig_analysis,

  classify_write_hint_as_review
    FOR TESTING
    RAISING
      zcx_mig_analysis,

  classify_transaction
    FOR TESTING
    RAISING
      zcx_mig_analysis.

ENDCLASS.

CLASS ltc_logic_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_analyzer) =
      NEW zcl_mig_logic_analyzer( ).

    DATA(lt_source) =
      lo_source_repo->zif_mig_source_repo~read_program(
        iv_program_name =
          'ZRMIG_SAMPLE_LOGIC'
      ).

    DATA(ls_scan_result) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object =
          'ZRMIG_SAMPLE_LOGIC'
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
        object_name  = 'ZRMIG_SAMPLE_LOGIC'
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized
    ) TO lt_source_units.

    rs_result =
      lo_analyzer->zif_mig_logic_analyzer~analyze(
        it_source_units =
          lt_source_units
      ).

  ENDMETHOD.

    METHOD detect_form_definition.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_DEFINITION'
        object_name = 'VALIDATE_INPUT'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện FORM VALIDATE_INPUT'
    ).

  ENDMETHOD.


  METHOD detect_form_call.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_CALL'
        object_name = 'VALIDATE_INPUT'
      INTO DATA(ls_form_call).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện PERFORM VALIDATE_INPUT'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'START-OF-SELECTION'
      act = ls_form_call-calling_routine
    ).

  ENDMETHOD.


  METHOD detect_bapi.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'BAPI'
        object_name = 'BAPI_USER_GET_DETAIL'
      INTO DATA(ls_bapi).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện BAPI_USER_GET_DETAIL'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ADAPTER_REVIEW'
      act = ls_bapi-reuse_feasibility
    ).

  ENDMETHOD.


  METHOD detect_static_method.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type    = 'STATIC_METHOD'
        object_name    = 'READ_DATA'
        container_name = 'LCL_WORKER'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện static method call'
    ).

  ENDMETHOD.


  METHOD detect_instance_method.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type    = 'INSTANCE_METHOD'
        object_name    = 'CALCULATE'
        container_name = 'LO_WORKER'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện instance method call'
    ).

  ENDMETHOD.


  METHOD detect_gui_dependencies.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'DYPRO'
        object_name = '0100'
      INTO DATA(ls_screen).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện CALL SCREEN'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_screen-gui_dependency
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'REDESIGN'
      act = ls_screen-reuse_feasibility
    ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'TRANSACTION'
        object_name = 'SE38'
      INTO DATA(ls_transaction).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện CALL TRANSACTION'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_transaction-gui_dependency
    ).

  ENDMETHOD.


  METHOD detect_submit.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'REPORT_SUBMIT'
        object_name = 'ZRMIG_SAMPLE_BASIC'
      INTO DATA(ls_submit).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện SUBMIT'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ADAPTER_REVIEW'
      act = ls_submit-reuse_feasibility
    ).

  ENDMETHOD.


  METHOD create_evidence.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_result-business_logic )
      act = lines( ls_result-evidences )
      msg = 'Mỗi business logic fact phải có evidence'
    ).

    LOOP AT ls_result-evidences
      ASSIGNING FIELD-SYMBOL(<evidence>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <evidence>-evidence_id
      ).

      cl_abap_unit_assert=>assert_equals(
        exp = 'ZRMIG_SAMPLE_LOGIC'
        act = <evidence>-source_object
      ).

    ENDLOOP.

  ENDMETHOD.

  METHOD get_side_effect_result.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_SIDE_EFFECT'.

  DATA lt_source
    TYPE zif_mig_types=>tt_source_line.

  lt_source = VALUE #(
    (
      source_object = gc_program
      line_number   = 1
      source_text   = `REPORT zrmig_ut_side_effect.`
    )
    (
      source_object = gc_program
      line_number   = 2
      source_text   = `CLASS lcl_handler DEFINITION.`
    )
    (
      source_object = gc_program
      line_number   = 3
      source_text   = `  PUBLIC SECTION.`
    )
    (
      source_object = gc_program
      line_number   = 4
      source_text   = `    METHODS handle_data_changed.`
    )
    (
      source_object = gc_program
      line_number   = 5
      source_text   = `    METHODS save_document.`
    )
    (
      source_object = gc_program
      line_number   = 6
      source_text   = `ENDCLASS.`
    )
    (
      source_object = gc_program
      line_number   = 7
      source_text   = `CLASS lcl_handler IMPLEMENTATION.`
    )
    (
      source_object = gc_program
      line_number   = 8
      source_text   = `  METHOD handle_data_changed.`
    )
    (
      source_object = gc_program
      line_number   = 9
      source_text   = `  ENDMETHOD.`
    )
    (
      source_object = gc_program
      line_number   = 10
      source_text   = `  METHOD save_document.`
    )
    (
      source_object = gc_program
      line_number   = 11
      source_text   = `  ENDMETHOD.`
    )
    (
      source_object = gc_program
      line_number   = 12
      source_text   = `ENDCLASS.`
    )
    (
      source_object = gc_program
      line_number   = 13
      source_text   = `START-OF-SELECTION.`
    )
    (
      source_object = gc_program
      line_number   = 14
      source_text   = `  DATA(lo_handler) = NEW lcl_handler( ).`
    )
    (
      source_object = gc_program
      line_number   = 15
      source_text   = `  lo_handler->handle_data_changed( ).`
    )
    (
      source_object = gc_program
      line_number   = 16
      source_text   = `  lo_handler->save_document( ).`
    )
    (
      source_object = gc_program
      line_number   = 17
      source_text   = `  CALL FUNCTION 'BAPI_USER_GET_DETAIL'.`
    )
    (
      source_object = gc_program
      line_number   = 18
      source_text   = `  CALL TRANSACTION 'SE38'.`
    )
    (
      source_object = gc_program
      line_number   = 19
      source_text   = `  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.`
    )
  ).

  DATA(lo_scanner) =
    NEW zcl_mig_abap_scanner( ).

  DATA(ls_scan_result) =
    lo_scanner->zif_mig_abap_scanner~scan(
      iv_source_object = gc_program
      it_source        = lt_source
    ).

  DATA(lo_normalizer) =
    NEW zcl_mig_stmt_normalizer( ).

  DATA(ls_normalized) =
    lo_normalizer->zif_mig_stmt_normalizer~normalize(
      is_scan_result = ls_scan_result
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
    NEW zcl_mig_logic_analyzer( ).

  rs_result =
    lo_analyzer->zif_mig_logic_analyzer~analyze(
      it_source_units = lt_source_units
    ).

ENDMETHOD.

METHOD avoid_false_write_side_effect.

  DATA(ls_result) =
    get_side_effect_result( ).

  "Method definition
  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'METHOD_DEFINITION'
      object_name = 'HANDLE_DATA_CHANGED'
    INTO DATA(ls_definition).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện definition HANDLE_DATA_CHANGED'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'NONE'
    act = ls_definition-side_effect
    msg = 'Method definition không được suy luận là WRITE'
  ).

  cl_abap_unit_assert=>assert_false(
    act = ls_definition-transaction_dependency
    msg = 'Method definition không được transaction-dependent'
  ).

  "Method invocation
  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'INSTANCE_METHOD'
      object_name = 'HANDLE_DATA_CHANGED'
    INTO DATA(ls_call).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện call HANDLE_DATA_CHANGED'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'READ_OR_UNKNOWN'
    act = ls_call-side_effect
    msg = 'DATA_CHANGED không được nhận nhầm thành CHANGE'
  ).

  cl_abap_unit_assert=>assert_false(
    act = ls_call-transaction_dependency
    msg = 'HANDLE_DATA_CHANGED không được transaction-dependent'
  ).

ENDMETHOD.

METHOD classify_write_hint_as_review.

  DATA(ls_result) =
    get_side_effect_result( ).

  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'METHOD_DEFINITION'
      object_name = 'SAVE_DOCUMENT'
    INTO DATA(ls_definition).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'NONE'
    act = ls_definition-side_effect
    msg = 'Definition SAVE_DOCUMENT không được là WRITE'
  ).

  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'INSTANCE_METHOD'
      object_name = 'SAVE_DOCUMENT'
    INTO DATA(ls_call).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện call SAVE_DOCUMENT'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'REVIEW'
    act = ls_call-side_effect
    msg = 'Tên SAVE chỉ được tạo manual-review hint'
  ).

  cl_abap_unit_assert=>assert_false(
    act = ls_call-transaction_dependency
    msg = 'Tên SAVE không đủ để kết luận transaction dependency'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = zif_mig_types=>gc_conf_medium
    act = ls_call-confidence
    msg = 'Name-based side-effect hint phải có confidence MEDIUM'
  ).

ENDMETHOD.

METHOD classify_transaction.

  DATA(ls_result) =
    get_side_effect_result( ).

  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'TRANSACTION'
      object_name = 'SE38'
    INTO DATA(ls_transaction).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện CALL TRANSACTION SE38'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'GUI_DEPENDENT'
    act = ls_transaction-side_effect
  ).

  cl_abap_unit_assert=>assert_true(
    act = ls_transaction-transaction_dependency
    msg = 'CALL TRANSACTION phải transaction-dependent'
  ).

  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'BAPI'
      object_name = 'BAPI_TRANSACTION_COMMIT'
    INTO DATA(ls_commit).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện BAPI_TRANSACTION_COMMIT'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'TRANSACTION'
    act = ls_commit-side_effect
  ).

  cl_abap_unit_assert=>assert_true(
    act = ls_commit-transaction_dependency
    msg = 'BAPI_TRANSACTION_COMMIT phải transaction-dependent'
  ).

  READ TABLE ls_result-business_logic
    WITH KEY
      object_type = 'BAPI'
      object_name = 'BAPI_USER_GET_DETAIL'
    INTO DATA(ls_read_bapi).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'REVIEW'
    act = ls_read_bapi-side_effect
  ).

  cl_abap_unit_assert=>assert_false(
    act = ls_read_bapi-transaction_dependency
    msg = 'BAPI đọc không được tự động transaction-dependent'
  ).

ENDMETHOD.

ENDCLASS.
