CLASS ltc_provider_contract DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS:
      gc_analysis_id TYPE zif_mig_types=>ty_analysis_id
        VALUE '00000000000000000000000000000021',

      gc_item_id_1 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000022',

      gc_item_id_2 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000023'.


    METHODS make_analysis
      RETURNING
        VALUE(rs_analysis)
          TYPE zif_mig_types=>ty_analysis_result.


    METHODS make_blueprint
      IMPORTING
        iv_strategy TYPE zif_mig_types=>ty_service_strategy
      RETURNING
        VALUE(rs_blueprint)
          TYPE zif_mig_types=>ty_service_blueprint_result.


    METHODS:
      select_static_method
        FOR TESTING
        RAISING zcx_mig_analysis,

      select_function_module
        FOR TESTING
        RAISING zcx_mig_analysis,

      select_bapi_for_action
        FOR TESTING
        RAISING zcx_mig_analysis,

      local_form_requires_refactor
        FOR TESTING
        RAISING zcx_mig_analysis,

      multiple_targets_require
        FOR TESTING
        RAISING zcx_mig_analysis,

      manual_blueprint_blocks_target
        FOR TESTING
        RAISING zcx_mig_analysis,

      no_logic_requires_refactor
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_provider_contract IMPLEMENTATION.

  METHOD make_analysis.

    rs_analysis-analysis_id =
      gc_analysis_id.

    rs_analysis-overview-analysis_id =
      gc_analysis_id.

    rs_analysis-overview-program_name =
      'ZRMIG_TEST_FULL'.

  ENDMETHOD.


  METHOD make_blueprint.

    rs_blueprint-blueprint-analysis_id =
      gc_analysis_id.

    rs_blueprint-blueprint-source_program =
      'ZRMIG_TEST_FULL'.

    rs_blueprint-blueprint-strategy =
      iv_strategy.

  ENDMETHOD.


  METHOD select_static_method.

    DATA(ls_analysis) =
      make_analysis( ).

    APPEND VALUE #(
      item_id          = gc_item_id_1
      analysis_id      = gc_analysis_id
      object_name      = 'READ_DATA'
      object_type      = 'STATIC_METHOD'
      container_name   = 'ZCL_LEGACY_REPORT'
      interface_summary = 'IV_BUKRS;RT_RESULT'
      side_effect      = 'READ_OR_UNKNOWN'
      reuse_feasibility = 'REUSABLE'
    ) TO ls_analysis-business_logic.


    DATA(ls_blueprint) =
      make_blueprint(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).


    DATA(ls_result) =
      NEW zcl_mig_provider_contract(
        )->zif_mig_provider_contract~build(
          is_analysis  = ls_analysis
          is_blueprint = ls_blueprint
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_class_method
      act = ls_result-contract-provider_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_ready
      act = ls_result-contract-provider_status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZCL_LEGACY_REPORT'
      act = ls_result-contract-source_container_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'READ_DATA'
      act = ls_result-contract-source_object_name
    ).

  ENDMETHOD.


  METHOD select_function_module.

    DATA(ls_analysis) =
      make_analysis( ).

    APPEND VALUE #(
      item_id          = gc_item_id_1
      analysis_id      = gc_analysis_id
      object_name      = 'Z_READ_REPORT_DATA'
      object_type      = 'FUNCTION_MODULE'
      side_effect      = 'READ_OR_UNKNOWN'
      reuse_feasibility = 'ADAPTER_REVIEW'
    ) TO ls_analysis-business_logic.


    DATA(ls_blueprint) =
      make_blueprint(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).


    DATA(ls_result) =
      NEW zcl_mig_provider_contract(
        )->zif_mig_provider_contract~build(
          is_analysis  = ls_analysis
          is_blueprint = ls_blueprint
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_function
      act = ls_result-contract-provider_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_signature
      act = ls_result-contract-provider_status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_result-contract-manual_review
    ).

  ENDMETHOD.


  METHOD select_bapi_for_action.

    DATA(ls_analysis) =
      make_analysis( ).

    APPEND VALUE #(
      item_id                = gc_item_id_1
      analysis_id            = gc_analysis_id
      object_name            = 'BAPI_SALESORDER_CREATEFROMDAT2'
      object_type            = 'BAPI'
      side_effect            = 'WRITE'
      transaction_dependency = abap_true
      reuse_feasibility      = 'ADAPTER_REVIEW'
    ) TO ls_analysis-business_logic.


    DATA(ls_blueprint) =
      make_blueprint(
        iv_strategy =
          zif_mig_types=>gc_svc_action
      ).


    DATA(ls_result) =
      NEW zcl_mig_provider_contract(
        )->zif_mig_provider_contract~build(
          is_analysis  = ls_analysis
          is_blueprint = ls_blueprint
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_bapi
      act = ls_result-contract-provider_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_signature
      act = ls_result-contract-provider_status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_svc_action
      act = ls_result-contract-service_strategy
    ).

  ENDMETHOD.


  METHOD local_form_requires_refactor.

    DATA(ls_analysis) =
      make_analysis( ).

    APPEND VALUE #(
      item_id          = gc_item_id_1
      analysis_id      = gc_analysis_id
      object_name      = 'GET_DATA'
      object_type      = 'FORM_DEFINITION'
      side_effect      = 'READ_OR_UNKNOWN'
      reuse_feasibility = 'REFACTOR'
    ) TO ls_analysis-business_logic.


    DATA(ls_blueprint) =
      make_blueprint(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).


    DATA(ls_result) =
      NEW zcl_mig_provider_contract(
        )->zif_mig_provider_contract~build(
          is_analysis  = ls_analysis
          is_blueprint = ls_blueprint
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_report_logic
      act = ls_result-contract-provider_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_refactor
      act = ls_result-contract-provider_status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-contract-manual_review
    ).

  ENDMETHOD.


  METHOD multiple_targets_require.

    DATA(ls_analysis) =
      make_analysis( ).

    APPEND VALUE #(
      item_id     = gc_item_id_1
      analysis_id = gc_analysis_id
      object_name = 'Z_READ_HEADER'
      object_type = 'FUNCTION_MODULE'
    ) TO ls_analysis-business_logic.

    APPEND VALUE #(
      item_id     = gc_item_id_2
      analysis_id = gc_analysis_id
      object_name = 'Z_READ_ITEMS'
      object_type = 'FUNCTION_MODULE'
    ) TO ls_analysis-business_logic.


    DATA(ls_blueprint) =
      make_blueprint(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).


    DATA(ls_result) =
      NEW zcl_mig_provider_contract(
        )->zif_mig_provider_contract~build(
          is_analysis  = ls_analysis
          is_blueprint = ls_blueprint
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_review
      act = ls_result-contract-provider_status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-contract-manual_review
    ).

  ENDMETHOD.


  METHOD manual_blueprint_blocks_target.

    DATA(ls_analysis) =
      make_analysis( ).

    APPEND VALUE #(
      item_id     = gc_item_id_1
      analysis_id = gc_analysis_id
      object_name = 'Z_READ_DATA'
      object_type = 'FUNCTION_MODULE'
    ) TO ls_analysis-business_logic.


    DATA(ls_blueprint) =
      make_blueprint(
        iv_strategy =
          zif_mig_types=>gc_svc_manual
      ).


    DATA(ls_result) =
      NEW zcl_mig_provider_contract(
        )->zif_mig_provider_contract~build(
          is_analysis  = ls_analysis
          is_blueprint = ls_blueprint
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_none
      act = ls_result-contract-provider_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_review
      act = ls_result-contract-provider_status
    ).

  ENDMETHOD.


  METHOD no_logic_requires_refactor.

    DATA(ls_analysis) =
      make_analysis( ).

    DATA(ls_blueprint) =
      make_blueprint(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).


    DATA(ls_result) =
      NEW zcl_mig_provider_contract(
        )->zif_mig_provider_contract~build(
          is_analysis  = ls_analysis
          is_blueprint = ls_blueprint
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_report_logic
      act = ls_result-contract-provider_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_refactor
      act = ls_result-contract-provider_status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_TEST_FULL'
      act = ls_result-contract-source_object_name
    ).

  ENDMETHOD.

ENDCLASS.
