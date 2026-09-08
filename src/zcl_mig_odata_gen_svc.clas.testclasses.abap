CLASS lcl_mig_odata_pipeline_fake DEFINITION
  FINAL.

  PUBLIC SECTION.

    INTERFACES:
      zif_mig_analysis_reader,
      zif_mig_service_blueprint,
      zif_mig_provider_contract,
      zif_mig_sig_rslv,
      zif_mig_svc_map,
      zif_mig_row_rslv,
      zif_mig_art_mfst,
      zif_mig_art_pref,
      zif_mig_art_repo.

    METHODS constructor
      IMPORTING
        iv_block_blueprint      TYPE abap_bool DEFAULT abap_false
        iv_unsupported_boundary TYPE abap_bool DEFAULT abap_false
        iv_bapi_provider        TYPE abap_bool DEFAULT abap_false.

    DATA provider_called TYPE abap_bool READ-ONLY.
    DATA binding_exists TYPE abap_bool.
    DATA binding_package TYPE devclass.
    DATA preflight_manifest TYPE zif_mig_types=>ty_art_mfst.
    DATA provider_exists TYPE abap_bool.
    DATA provider_current_package TYPE devclass.

  PRIVATE SECTION.

    DATA mv_block_blueprint TYPE abap_bool.
    DATA mv_unsupported_boundary TYPE abap_bool.
    DATA mv_bapi_provider TYPE abap_bool.

ENDCLASS.


CLASS lcl_mig_xco_executor_fake DEFINITION
  FINAL.

  PUBLIC SECTION.

    INTERFACES zif_mig_xco_executor.

    DATA called TYPE abap_bool READ-ONLY.
    DATA transport TYPE trkorr READ-ONLY.
    DATA service_name TYPE zif_mig_types=>ty_art_name READ-ONLY.
    DATA manifest TYPE zif_mig_types=>ty_art_mfst READ-ONLY.
    DATA provider_generator TYPE REF TO zif_mig_prv_clas_gen READ-ONLY.

ENDCLASS.


CLASS lcl_mig_xco_executor_fake IMPLEMENTATION.

  METHOD zif_mig_xco_executor~execute_query.

    manifest = is_mfst.
    provider_generator = io_provider_gen.

    called =
      abap_true.

    transport =
      iv_transport.


    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_srvd
        art_role = zif_mig_types=>gc_art_srv_def
      INTO DATA(ls_srvd).

    IF sy-subrc = 0.

      service_name =
        ls_srvd-object_name.

    ENDIF.

  ENDMETHOD.

ENDCLASS.


CLASS lcl_mig_odata_pipeline_fake IMPLEMENTATION.

  METHOD constructor.

    mv_block_blueprint = iv_block_blueprint.
    mv_unsupported_boundary = iv_unsupported_boundary.
    mv_bapi_provider = iv_bapi_provider.

  ENDMETHOD.


  METHOD zif_mig_analysis_reader~read.

    rs_result-analysis_id = iv_analysis_id.
    rs_result-overview-analysis_id = iv_analysis_id.
    rs_result-overview-program_name = 'ZLEGACY_REPORT'.

  ENDMETHOD.


  METHOD zif_mig_service_blueprint~build.

    rs_blueprint-blueprint-analysis_id = is_analysis-analysis_id.
    rs_blueprint-blueprint-source_program =
      is_analysis-overview-program_name.


    IF mv_block_blueprint = abap_true.

      rs_blueprint-blueprint-strategy =
        zif_mig_types=>gc_svc_manual.

      rs_blueprint-blueprint-manual_review = abap_true.
      rs_blueprint-blueprint-decision_reason =
        'Blueprint requires manual review.'.

      RETURN.

    ENDIF.


    rs_blueprint-blueprint-strategy =
      zif_mig_types=>gc_svc_query.

    rs_blueprint-blueprint-entity_name = 'MigrationResult'.
    rs_blueprint-blueprint-manual_review = abap_false.

    APPEND VALUE #(
      field_name = 'CompanyCode'
      edm_type   = COND #(
        WHEN mv_unsupported_boundary = abap_true
        THEN 'Edm.Binary'
        ELSE 'Edm.String'
      )
      length     = 4
      position   = 10
      key_field  = abap_true
      visible    = abap_true
      filterable = abap_true
      sortable   = abap_true
    ) TO rs_blueprint-fields.

  ENDMETHOD.


  METHOD zif_mig_provider_contract~build.

    provider_called = abap_true.

    rs_result-contract-analysis_id =
      is_blueprint-blueprint-analysis_id.

    rs_result-contract-service_strategy =
      zif_mig_types=>gc_svc_query.

    rs_result-contract-provider_kind =
      COND #(
        WHEN mv_bapi_provider = abap_true
        THEN zif_mig_types=>gc_provider_bapi
        ELSE zif_mig_types=>gc_provider_function
      ).

    "A function module can require signature resolution before it
    "becomes safe for generation.
    rs_result-contract-provider_status =
      zif_mig_types=>gc_provider_signature.

    rs_result-contract-source_object_name =
      COND #(
        WHEN mv_bapi_provider = abap_true
        THEN 'BAPI_EPM_PRODUCT_GET_LIST'
        ELSE 'Z_READ_LEGACY_DATA'
      ).
    rs_result-contract-manual_review = abap_false.

  ENDMETHOD.


  METHOD zif_mig_sig_rslv~resolve.

    rs_result-analysis_id = is_prv-analysis_id.
    rs_result-service_strategy = is_prv-service_strategy.
    rs_result-provider_kind = is_prv-provider_kind.
    rs_result-object_name = is_prv-source_object_name.
    rs_result-status = zif_mig_types=>gc_sig_ready.
    rs_result-manual_review = abap_false.

    APPEND VALUE #(
      par_name   = 'ET_RESULT'
      direction  = zif_mig_types=>gc_sig_exp
      type_name  = 'ZTT_MIG_TEST_RESULT'
      odata_role = zif_mig_types=>gc_sig_out
      is_table   = abap_true
    ) TO rs_result-output_params.

    rs_result-all_params = rs_result-output_params.

  ENDMETHOD.


  METHOD zif_mig_svc_map~build.

    rs_map-analysis_id = is_bp-blueprint-analysis_id.
    rs_map-status = zif_mig_types=>gc_smap_ready.
    rs_map-manual_review = abap_false.

    rs_map-selected_out = VALUE #(
      par_name   = 'ET_RESULT'
      direction  = zif_mig_types=>gc_sig_exp
      type_name  = 'ZTT_MIG_TEST_RESULT'
      odata_role = zif_mig_types=>gc_sig_out
      is_table   = abap_true
    ).

  ENDMETHOD.


  METHOD zif_mig_row_rslv~resolve.

    rs_result-analysis_id = is_bp-blueprint-analysis_id.
    rs_result-status = zif_mig_types=>gc_row_ready.
    rs_result-manual_review = abap_false.
    rs_result-output_name = is_smap-selected_out-par_name.
    rs_result-row_type = 'ZMIG_TEST_RESULT'.
    rs_result-mapped_fields = 1.

    APPEND VALUE #(
      svc_name  = 'CompanyCode'
      comp_name = 'BUKRS'
      svc_edm   = 'Edm.String'
      comp_edm  = 'Edm.String'
      position  = 10
      map_state = zif_mig_types=>gc_row_auto
      exact_name = abap_false
      type_match = abap_true
    ) TO rs_result-field_maps.

  ENDMETHOD.


  METHOD zif_mig_art_mfst~build.

    rs_mfst-analysis_id = is_bp-blueprint-analysis_id.
    rs_mfst-strategy = zif_mig_types=>gc_svc_query.
    rs_mfst-source_program = is_bp-blueprint-source_program.
    rs_mfst-package = iv_package.
    rs_mfst-status = zif_mig_types=>gc_art_ready.
    rs_mfst-manual_review = abap_false.

    rs_mfst-items = VALUE #(
      ( seq         = 10
        art_type    = zif_mig_types=>gc_art_clas
        art_role    = zif_mig_types=>gc_art_query_prv
        object_name = 'ZCL_MIG_Q_TEST'
        package     = iv_package
        required    = abap_true )
      ( seq         = 20
        art_type    = zif_mig_types=>gc_art_ddls
        art_role    = zif_mig_types=>gc_art_entity
        object_name = 'ZC_MIG_Q_TEST'
        package     = iv_package
        required    = abap_true )
      ( seq         = 30
        art_type    = zif_mig_types=>gc_art_srvd
        art_role    = zif_mig_types=>gc_art_srv_def
        object_name = 'ZUI_MIG_Q_TEST'
        package     = iv_package
        required    = abap_true )
    ).

    rs_mfst-item_count = lines( rs_mfst-items ).

  ENDMETHOD.


  METHOD zif_mig_art_pref~apply.

    preflight_manifest = is_mfst.

    rs_mfst = is_mfst.
    rs_mfst-status = zif_mig_types=>gc_art_ready.
    rs_mfst-manual_review = abap_false.
    rs_mfst-create_count = lines( rs_mfst-items ).
    rs_mfst-block_count = 0.

    LOOP AT rs_mfst-items
      ASSIGNING FIELD-SYMBOL(<item>).

      <item>-gen_state = zif_mig_types=>gc_art_planned.
      <item>-gen_mode = zif_mig_types=>gc_art_create.

    ENDLOOP.

  ENDMETHOD.


  METHOD zif_mig_art_repo~read_info.

    rs_info-art_type = iv_type.
    rs_info-object_name = iv_name.
    rs_info-read_ok = abap_true.
    rs_info-exists = binding_exists.
    rs_info-package = binding_package.

  ENDMETHOD.


  METHOD zif_mig_art_repo~read_many.

    LOOP AT it_items
      INTO DATA(ls_item).

      APPEND VALUE #(
        art_type    = ls_item-art_type
        object_name = ls_item-object_name
        read_ok     = abap_true
        exists      = COND #( WHEN ls_item-art_type = zif_mig_types=>gc_art_clas
                              THEN provider_exists ELSE abap_false )
        package     = COND #( WHEN ls_item-art_type = zif_mig_types=>gc_art_clas
                              THEN provider_current_package )
      ) TO rt_info.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS lcl_mig_odata_repo_fake DEFINITION
  FINAL.

  PUBLIC SECTION.

    INTERFACES:
      zif_mig_analysis_reader,
      zif_mig_sig_repo,
      zif_mig_row_repo,
      zif_mig_art_repo.

ENDCLASS.


CLASS lcl_mig_odata_repo_fake IMPLEMENTATION.

  METHOD zif_mig_analysis_reader~read.

    rs_result-analysis_id = iv_analysis_id.
    rs_result-overview-analysis_id = iv_analysis_id.
    rs_result-overview-program_name = 'ZRMIG_PIPELINE_TEST'.

    APPEND VALUE #(
      output_id    = '000000000000000000000000000000B1'
      analysis_id  = iv_analysis_id
      output_name  = 'GT_RESULT'
      output_kind  = 'TABLE'
      framework    = 'SALV'
      output_table = 'GT_RESULT'
      row_type     = 'ZTT_RESULT'
      editable     = abap_false
      hierarchical = abap_false
    ) TO rs_result-alv_outputs.

    APPEND VALUE #(
      item_id        = '000000000000000000000000000000B2'
      analysis_id    = iv_analysis_id
      output_id      = '000000000000000000000000000000B1'
      field_name     = 'BUKRS'
      label          = 'Company Code'
      position       = 10
      data_type      = 'C'
      data_element   = 'BUKRS'
      length         = 4
      visible        = abap_true
      key_field      = abap_true
      technical      = abap_false
      icon           = abap_false
      source_mapping = 'GT_RESULT-BUKRS'
    ) TO rs_result-alv_columns.

    APPEND VALUE #(
      item_id           = '000000000000000000000000000000B3'
      analysis_id       = iv_analysis_id
      object_name       = 'Z_READ_DATA'
      object_type       = 'FUNCTION_MODULE'
      side_effect       = 'READ_OR_UNKNOWN'
      reuse_feasibility = 'ADAPTER_REVIEW'
    ) TO rs_result-business_logic.

  ENDMETHOD.


  METHOD zif_mig_sig_repo~read_fm.

    rs_sig-provider_kind =
      zif_mig_types=>gc_provider_function.

    rs_sig-obj_name = iv_fm.

    IF iv_fm <> 'Z_READ_DATA'.
      RETURN.
    ENDIF.

    rs_sig-exists = abap_true.

    APPEND VALUE #(
      par_name  = 'ET_RESULT'
      direction = zif_mig_types=>gc_sig_exp
      type_name = 'ZTT_RESULT'
      is_table  = abap_true
    ) TO rs_sig-params.

  ENDMETHOD.


  METHOD zif_mig_sig_repo~read_mth.

    rs_sig-provider_kind =
      zif_mig_types=>gc_provider_class_method.

    rs_sig-class_name = iv_class.
    rs_sig-method_name = iv_mth.
    rs_sig-exists = abap_false.

  ENDMETHOD.


  METHOD zif_mig_row_repo~read_type.

    rs_row-type_name = iv_type.

    IF iv_type <> 'ZTT_RESULT'.
      RETURN.
    ENDIF.

    rs_row-exists = abap_true.
    rs_row-structured = abap_true.
    rs_row-line_name = 'ZS_RESULT'.

    APPEND VALUE #(
      comp_name = 'BUKRS'
      position  = 1
      abap_type = 'C'
      type_name = 'BUKRS'
      edm_type  = 'Edm.String'
    ) TO rs_row-components.

  ENDMETHOD.


  METHOD zif_mig_art_repo~read_info.

    rs_info-art_type = iv_type.
    rs_info-object_name = iv_name.
    rs_info-read_ok = abap_true.
    rs_info-exists = abap_false.
    rs_info-reason = 'Repository object does not exist.'.

  ENDMETHOD.


  METHOD zif_mig_art_repo~read_many.

    LOOP AT it_items
      INTO DATA(ls_item).

      APPEND VALUE #(
        art_type    = ls_item-art_type
        object_name = ls_item-object_name
        read_ok     = abap_true
        exists      = abap_false
        reason      = 'Repository object does not exist.'
      ) TO rt_info.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS lcl_mig_std_generator_fake DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_mig_prv_clas_gen.
    DATA checked_package TYPE devclass.
    DATA generate_called TYPE abap_bool.
    DATA throw_error TYPE abap_bool.
    DATA check_result TYPE zif_mig_prv_clas_gen=>ty_check.
    METHODS constructor.
ENDCLASS.

CLASS lcl_mig_std_generator_fake IMPLEMENTATION.
  METHOD constructor.
    check_result = VALUE #( allowed = abap_true language_code = space ).
  ENDMETHOD.
  METHOD zif_mig_prv_clas_gen~check_target.
    checked_package = iv_package.
    IF throw_error = abap_true.
      RAISE EXCEPTION TYPE cx_sy_conversion_no_number.
    ENDIF.
    rs_check = check_result.
  ENDMETHOD.
  METHOD zif_mig_prv_clas_gen~generate.
    generate_called = abap_true.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_mig_odata_gen_svc DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS gc_analysis_id TYPE zif_mig_types=>ty_analysis_id
      VALUE '000000000000000000000000000000A1'.

    METHODS dry_run_is_ready
      FOR TESTING
      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.

    METHODS bapi_dry_run_is_ready
      FOR TESTING
      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.

    METHODS blocked_blueprint_stops
      FOR TESTING
      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.

    METHODS unsupported_boundary_stops
      FOR TESTING
      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.

    METHODS binding_package_conflict
      FOR TESTING
      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.

    METHODS real_pipeline_dry_run
      FOR TESTING
      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.

    METHODS execute_requires_transport
      FOR TESTING.

    METHODS execute_calls_executor
      FOR TESTING
      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.

    METHODS standard_dry_run FOR TESTING RAISING cx_static_check.
    METHODS standard_execute FOR TESTING RAISING cx_static_check.
    METHODS standard_missing_package FOR TESTING RAISING cx_static_check.
    METHODS standard_missing_executor FOR TESTING RAISING cx_static_check.
    METHODS standard_wrong_language FOR TESTING RAISING cx_static_check.
    METHODS standard_check_error FOR TESTING RAISING cx_static_check.
    METHODS standard_existing_class FOR TESTING RAISING cx_static_check.
    METHODS standard_package_conflict FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_language FOR TESTING RAISING cx_static_check.

    METHODS standard_service
      IMPORTING
        io_pipeline TYPE REF TO lcl_mig_odata_pipeline_fake
        io_executor TYPE REF TO lcl_mig_xco_executor_fake
        io_standard TYPE REF TO zif_mig_prv_clas_gen OPTIONAL
        io_preflight TYPE REF TO zif_mig_art_pref OPTIONAL
      RETURNING VALUE(ro_service) TYPE REF TO zif_mig_odata_gen_svc.

ENDCLASS.


CLASS ltc_mig_odata_gen_svc IMPLEMENTATION.

  METHOD standard_service.
    DATA lo_preflight TYPE REF TO zif_mig_art_pref.
    lo_preflight = io_preflight.
    IF lo_preflight IS NOT BOUND.
      lo_preflight = io_pipeline.
    ENDIF.
    ro_service = NEW zcl_mig_odata_gen_svc(
      io_reader = io_pipeline io_blueprint = io_pipeline
      io_provider = io_pipeline io_signature = io_pipeline
      io_service_map = io_pipeline io_row_resolver = io_pipeline
      io_manifest = io_pipeline io_preflight = lo_preflight
      io_art_repo = io_pipeline io_executor = io_executor
      io_provider_gen = io_standard ).
  ENDMETHOD.

  METHOD standard_dry_run.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( iv_bapi_provider = abap_true ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_standard) = NEW lcl_mig_std_generator_fake( ).
    DATA(lo_service) = standard_service(
      io_pipeline = lo_pipeline io_executor = lo_executor io_standard = lo_standard ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST'
      provider_package = 'ZLEGACY_GEN' provider_language = 'STANDARD' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'READY' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = 'STANDARD' act = ls_result-provider_language ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZLEGACY_GEN' act = lo_standard->checked_package ).
    LOOP AT lo_pipeline->preflight_manifest-items INTO DATA(ls_item).
      DATA(lv_expected) = COND devclass(
        WHEN ls_item-art_role = zif_mig_types=>gc_art_query_prv
        THEN 'ZLEGACY_GEN' ELSE 'ZMIG_TEST' ).
      cl_abap_unit_assert=>assert_equals( exp = lv_expected act = ls_item-package ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_standard->generate_called ).
  ENDMETHOD.

  METHOD standard_execute.
    "Use the ordinary FM fixture: STANDARD must not depend on a BAPI name.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_standard) = NEW lcl_mig_std_generator_fake( ).
    DATA(lo_service) = standard_service(
      io_pipeline = lo_pipeline io_executor = lo_executor io_standard = lo_standard ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST'
      provider_package = 'ZLEGACY_GEN' provider_language = 'STANDARD'
      transport = 'DEVK900001' execute = abap_true ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'GENERATED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = lo_executor->called ).
    cl_abap_unit_assert=>assert_equals( exp = 'STANDARD' act = lo_executor->manifest-provider_language ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZLEGACY_GEN' act = lo_executor->manifest-provider_package ).
    cl_abap_unit_assert=>assert_equals( exp = lo_standard act = lo_executor->provider_generator ).
  ENDMETHOD.

  METHOD standard_missing_package.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_standard) = NEW lcl_mig_std_generator_fake( ).
    DATA(lo_service) = standard_service(
      io_pipeline = lo_pipeline io_executor = lo_executor io_standard = lo_standard ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST' provider_language = 'STANDARD' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*explicit provider package*' act = ls_result-message ).
    cl_abap_unit_assert=>assert_initial( act = lo_standard->checked_package ).
    cl_abap_unit_assert=>assert_initial( act = lo_pipeline->preflight_manifest-items ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
  ENDMETHOD.

  METHOD standard_missing_executor.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_service) = standard_service( io_pipeline = lo_pipeline io_executor = lo_executor ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST'
      provider_package = 'ZLEGACY_GEN' provider_language = 'STANDARD' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*executor is not configured*' act = ls_result-message ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
  ENDMETHOD.

  METHOD standard_wrong_language.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_standard) = NEW lcl_mig_std_generator_fake( ).
    lo_standard->check_result = VALUE #( allowed = abap_true language_code = '5' ).
    DATA(lo_service) = standard_service(
      io_pipeline = lo_pipeline io_executor = lo_executor io_standard = lo_standard ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST'
      provider_package = 'ZCLOUD_GEN' provider_language = 'STANDARD' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_result-message ).
    cl_abap_unit_assert=>assert_initial( act = lo_pipeline->preflight_manifest-items ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
  ENDMETHOD.

  METHOD standard_check_error.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_standard) = NEW lcl_mig_std_generator_fake( ).
    lo_standard->throw_error = abap_true.
    DATA(lo_service) = standard_service(
      io_pipeline = lo_pipeline io_executor = lo_executor io_standard = lo_standard ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST'
      provider_package = 'ZLEGACY_GEN' provider_language = 'STANDARD' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*executor check failed*' act = ls_result-message ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
  ENDMETHOD.

  METHOD standard_existing_class.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    lo_pipeline->provider_exists = abap_true.
    lo_pipeline->provider_current_package = 'ZLEGACY_GEN'.
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_standard) = NEW lcl_mig_std_generator_fake( ).
    DATA(lo_service) = standard_service(
      io_pipeline = lo_pipeline io_executor = lo_executor io_standard = lo_standard
      io_preflight = NEW zcl_mig_art_pref( io_repo = lo_pipeline ) ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST'
      provider_package = 'ZLEGACY_GEN' provider_language = 'STANDARD'
      transport = 'DEVK900001' execute = abap_true ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*already exists*' act = ls_result-message ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
  ENDMETHOD.

  METHOD standard_package_conflict.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    lo_pipeline->provider_exists = abap_true.
    lo_pipeline->provider_current_package = 'ZOTHER'.
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_standard) = NEW lcl_mig_std_generator_fake( ).
    DATA(lo_service) = standard_service(
      io_pipeline = lo_pipeline io_executor = lo_executor io_standard = lo_standard
      io_preflight = NEW zcl_mig_art_pref( io_repo = lo_pipeline ) ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST'
      provider_package = 'ZLEGACY_GEN' provider_language = 'STANDARD' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*another package*' act = ls_result-message ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
  ENDMETHOD.

  METHOD reject_unknown_language.
    DATA(lo_pipeline) = NEW lcl_mig_odata_pipeline_fake( ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).
    DATA(lo_service) = standard_service( io_pipeline = lo_pipeline io_executor = lo_executor ).
    DATA(ls_result) = lo_service->generate( VALUE #(
      analysis_id = gc_analysis_id package = 'ZMIG_TEST' provider_language = 'AUTO' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*Unsupported provider language*' act = ls_result-message ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lo_executor->called ).
  ENDMETHOD.

  METHOD dry_run_is_ready.

    DATA(lo_fake) = NEW lcl_mig_odata_pipeline_fake( ).
    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).

    DATA(lo_service) =
      NEW zcl_mig_odata_gen_svc(
        io_reader       = lo_fake
        io_blueprint    = lo_fake
        io_provider     = lo_fake
        io_signature    = lo_fake
        io_service_map  = lo_fake
        io_row_resolver = lo_fake
        io_manifest     = lo_fake
        io_preflight    = lo_fake
        io_art_repo     = lo_fake
        io_executor     = lo_executor
      ).

    DATA(ls_result) =
      lo_service->zif_mig_odata_gen_svc~generate(
        is_request = VALUE #(
          analysis_id = gc_analysis_id
          package     = 'ZMIG_TEST'
          execute     = abap_false
        )
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_odata_gen_svc=>gc_status_ready
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_svc_query
      act = ls_result-strategy
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 4
      act = ls_result-create_count
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZCL_MIG_Q_TEST'
      act = ls_result-query_provider_class
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZC_MIG_Q_TEST'
      act = ls_result-entity_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZUI_MIG_Q_TEST'
      act = ls_result-service_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zcl_mig_svc_registry=>gc_shared_binding
      act = ls_result-service_binding
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_executor->called
      msg = 'Dry-run must not call the repository executor'
    ).

  ENDMETHOD.


  METHOD bapi_dry_run_is_ready.

    DATA(lo_fake) =
      NEW lcl_mig_odata_pipeline_fake(
        iv_bapi_provider = abap_true
      ).

    DATA(ls_result) =
      NEW zcl_mig_odata_gen_svc(
        io_reader       = lo_fake
        io_blueprint    = lo_fake
        io_provider     = lo_fake
        io_signature    = lo_fake
        io_service_map  = lo_fake
        io_row_resolver = lo_fake
        io_manifest     = lo_fake
        io_preflight    = lo_fake
        io_art_repo     = lo_fake
      )->zif_mig_odata_gen_svc~generate(
        is_request = VALUE #(
          analysis_id = gc_analysis_id
          package     = 'ZMIG_TEST'
          execute     = abap_false
        )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_odata_gen_svc=>gc_status_ready
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_bapi
      act = ls_result-provider_kind
    ).

  ENDMETHOD.


  METHOD blocked_blueprint_stops.

    DATA(lo_fake) =
      NEW lcl_mig_odata_pipeline_fake(
        iv_block_blueprint = abap_true
      ).

    DATA(ls_result) =
      NEW zcl_mig_odata_gen_svc(
        io_reader       = lo_fake
        io_blueprint    = lo_fake
        io_provider     = lo_fake
        io_signature    = lo_fake
        io_service_map  = lo_fake
        io_row_resolver = lo_fake
        io_manifest     = lo_fake
        io_preflight    = lo_fake
        io_art_repo     = lo_fake
      )->zif_mig_odata_gen_svc~generate(
        is_request = VALUE #(
          analysis_id = gc_analysis_id
          package     = 'ZMIG_TEST'
          execute     = abap_false
        )
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_odata_gen_svc=>gc_status_blocked
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-manual_review
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_fake->provider_called
      msg = 'A blocked blueprint must stop before provider selection'
    ).

  ENDMETHOD.


  METHOD unsupported_boundary_stops.

    DATA(lo_fake) =
      NEW lcl_mig_odata_pipeline_fake(
        iv_unsupported_boundary = abap_true
      ).

    DATA(lo_executor) = NEW lcl_mig_xco_executor_fake( ).

    DATA(ls_result) =
      NEW zcl_mig_odata_gen_svc(
        io_reader       = lo_fake
        io_blueprint    = lo_fake
        io_provider     = lo_fake
        io_signature    = lo_fake
        io_service_map  = lo_fake
        io_row_resolver = lo_fake
        io_manifest     = lo_fake
        io_preflight    = lo_fake
        io_art_repo     = lo_fake
        io_executor     = lo_executor
      )->zif_mig_odata_gen_svc~generate(
        is_request = VALUE #(
          analysis_id = gc_analysis_id
          package     = 'ZMIG_TEST'
          execute     = abap_false
        )
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_odata_gen_svc=>gc_status_blocked
      act = ls_result-status
      msg = 'An unsupported boundary type must be blocked in dry-run'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = ls_result-block_count
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_executor->called
      msg = 'A blocked boundary contract must not execute XCO generation'
    ).

  ENDMETHOD.


  METHOD binding_package_conflict.

    DATA(lo_fake) = NEW lcl_mig_odata_pipeline_fake( ).

    lo_fake->binding_exists = abap_true.
    lo_fake->binding_package = 'ZMIG_OTHER'.

    DATA(ls_result) =
      NEW zcl_mig_odata_gen_svc(
        io_reader       = lo_fake
        io_blueprint    = lo_fake
        io_provider     = lo_fake
        io_signature    = lo_fake
        io_service_map  = lo_fake
        io_row_resolver = lo_fake
        io_manifest     = lo_fake
        io_preflight    = lo_fake
        io_art_repo     = lo_fake
      )->zif_mig_odata_gen_svc~generate(
        is_request = VALUE #(
          analysis_id = gc_analysis_id
          package     = 'ZMIG_TEST'
          execute     = abap_false
        )
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_odata_gen_svc=>gc_status_blocked
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = ls_result-block_count
    ).

  ENDMETHOD.


  METHOD real_pipeline_dry_run.

    DATA(lo_repo) =
      NEW lcl_mig_odata_repo_fake( ).

    DATA(lo_service) =
      NEW zcl_mig_odata_gen_svc(
        io_reader = lo_repo

        io_signature =
          NEW zcl_mig_sig_rslv(
            io_repo = lo_repo
          )

        io_row_resolver =
          NEW zcl_mig_row_rslv(
            io_repo = lo_repo
          )

        io_preflight =
          NEW zcl_mig_art_pref(
            io_repo = lo_repo
          )

        io_art_repo = lo_repo
      ).

    DATA(ls_result) =
      lo_service->zif_mig_odata_gen_svc~generate(
        is_request = VALUE #(
          analysis_id = gc_analysis_id
          package     = 'ZMIG_TEST'
          execute     = abap_false
        )
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_odata_gen_svc=>gc_status_ready
      act = ls_result-status
      msg = 'The real dry-run pipeline must reach READY'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_svc_query
      act = ls_result-strategy
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_provider_function
      act = ls_result-provider_kind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Z_READ_DATA'
      act = ls_result-provider_object
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 4
      act = ls_result-create_count
      msg = 'Three report artifacts and one shared binding are planned'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = ls_result-block_count
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-query_provider_class
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-entity_name
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-service_name
    ).

  ENDMETHOD.


  METHOD execute_requires_transport.

    DATA(lo_fake) =
      NEW lcl_mig_odata_pipeline_fake( ).

    DATA(lo_executor) =
      NEW lcl_mig_xco_executor_fake( ).

    TRY.

        DATA(ls_result) =
          NEW zcl_mig_odata_gen_svc(
            io_reader       = lo_fake
            io_blueprint    = lo_fake
            io_provider     = lo_fake
            io_signature    = lo_fake
            io_service_map  = lo_fake
            io_row_resolver = lo_fake
            io_manifest     = lo_fake
            io_preflight    = lo_fake
            io_art_repo     = lo_fake
            io_executor     = lo_executor
          )->zif_mig_odata_gen_svc~generate(
            is_request = VALUE #(
              analysis_id = gc_analysis_id
              package     = 'ZMIG_TEST'
              execute     = abap_true
            )
          ).

        cl_abap_unit_assert=>fail(
          msg = 'Execute without a transport request must be rejected'
        ).

      CATCH zcx_mig_analysis.
        "Expected before the analysis pipeline or XCO is called

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_executor->called
      msg = 'Invalid execute request must stop before repository execution'
    ).

  ENDMETHOD.


  METHOD execute_calls_executor.

    DATA(lo_fake) =
      NEW lcl_mig_odata_pipeline_fake( ).

    DATA(lo_executor) =
      NEW lcl_mig_xco_executor_fake( ).

    DATA(ls_result) =
      NEW zcl_mig_odata_gen_svc(
        io_reader       = lo_fake
        io_blueprint    = lo_fake
        io_provider     = lo_fake
        io_signature    = lo_fake
        io_service_map  = lo_fake
        io_row_resolver = lo_fake
        io_manifest     = lo_fake
        io_preflight    = lo_fake
        io_art_repo     = lo_fake
        io_executor     = lo_executor
      )->zif_mig_odata_gen_svc~generate(
        is_request = VALUE #(
          analysis_id = gc_analysis_id
          package     = 'ZMIG_TEST'
          transport   = 'S40K900001'
          execute     = abap_true
        )
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_odata_gen_svc=>gc_status_generated
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lo_executor->called
      msg = 'Execute must call the injected repository executor'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'S40K900001'
      act = lo_executor->transport
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZUI_MIG_Q_TEST'
      act = lo_executor->service_name
    ).

  ENDMETHOD.

ENDCLASS.
