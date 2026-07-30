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

ENDCLASS.
