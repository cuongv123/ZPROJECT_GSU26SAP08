CLASS lcl_ui_boundary_log DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA called TYPE abap_bool.
    CLASS-DATA fail TYPE abap_bool.
ENDCLASS.
CLASS lcl_ui_boundary_log IMPLEMENTATION.
ENDCLASS.

CLASS lcl_ui_pipeline DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_mig_analysis_reader.
    INTERFACES zif_mig_service_blueprint.
    INTERFACES zif_mig_provider_contract.
    INTERFACES zif_mig_sig_rslv.
    INTERFACES zif_mig_svc_map.
    INTERFACES zif_mig_row_rslv.
    INTERFACES zif_mig_art_mfst.
    DATA fail_at TYPE string.
    DATA calls TYPE string_table.
ENDCLASS.
CLASS lcl_ui_pipeline IMPLEMENTATION.
  METHOD zif_mig_analysis_reader~read.
    APPEND `READ` TO calls.
    rs_result-analysis_id = iv_analysis_id.
    rs_result-overview-program_name = 'ZUI_TEST_REPORT'.
    IF fail_at = 'READ'.
      CLEAR rs_result-analysis_id.
    ENDIF.
  ENDMETHOD.
  METHOD zif_mig_service_blueprint~build.
    APPEND `BLUEPRINT` TO calls.
    rs_blueprint-blueprint = VALUE #( analysis_id = is_analysis-analysis_id
      source_program = is_analysis-overview-program_name entity_name = 'ResultAlias'
      strategy = zif_mig_types=>gc_svc_query ).
    rs_blueprint-fields = VALUE #( ( field_name = 'BUKRS' label = 'Company code'
      edm_type = 'Edm.String' length = 4 key_field = abap_true visible = abap_true
      filterable = abap_true sortable = abap_true position = 10 ) ).
    IF fail_at = 'BLUEPRINT'.
      rs_blueprint-blueprint-manual_review = abap_true.
      rs_blueprint-blueprint-decision_reason = 'Ambiguous ALV output'.
    ENDIF.
  ENDMETHOD.
  METHOD zif_mig_provider_contract~build.
    APPEND `PROVIDER` TO calls.
    rs_result-contract = VALUE #( analysis_id = is_analysis-analysis_id
      service_strategy = zif_mig_types=>gc_svc_query provider_kind = zif_mig_types=>gc_provider_bapi
      provider_status = zif_mig_types=>gc_provider_signature source_object_name = 'BAPI_TEST_GETLIST' ).
    IF fail_at = 'PROVIDER'.
      rs_result-contract-manual_review = abap_true.
      rs_result-contract-decision_reason = 'Provider requires review'.
    ENDIF.
  ENDMETHOD.
  METHOD zif_mig_sig_rslv~resolve.
    APPEND `SIGNATURE` TO calls.
    rs_result-analysis_id = is_prv-analysis_id.
    rs_result-status = zif_mig_types=>gc_sig_ready.
    IF fail_at = 'SIGNATURE'.
      rs_result-manual_review = abap_true.
      rs_result-decision_reason = 'Signature unavailable'.
    ENDIF.
  ENDMETHOD.
  METHOD zif_mig_svc_map~build.
    APPEND `MAPPING` TO calls.
    rs_map-analysis_id = is_bp-blueprint-analysis_id.
    rs_map-status = zif_mig_types=>gc_smap_ready.
    IF fail_at = 'MAPPING'.
      rs_map-manual_review = abap_true.
      rs_map-decision_reason = 'Input mapping missing'.
    ENDIF.
  ENDMETHOD.
  METHOD zif_mig_row_rslv~resolve.
    APPEND `ROW` TO calls.
    rs_result-analysis_id = is_bp-blueprint-analysis_id.
    rs_result-status = zif_mig_types=>gc_row_ready.
    IF fail_at = 'ROW'.
      rs_result-manual_review = abap_true.
      rs_result-decision_reason = 'Output mapping missing'.
    ENDIF.
  ENDMETHOD.
  METHOD zif_mig_art_mfst~build.
    APPEND `MANIFEST` TO calls.
    rs_mfst-analysis_id = is_bp-blueprint-analysis_id.
    rs_mfst-status = zif_mig_types=>gc_art_ready.
    rs_mfst-items = VALUE #(
      ( art_role = zif_mig_types=>gc_art_query_prv object_name = 'ZCL_MIG_Q_TEST' )
      ( art_role = zif_mig_types=>gc_art_entity object_name = 'ZC_MIG_TEST' )
      ( art_role = zif_mig_types=>gc_art_srv_def object_name = 'ZUI_MIG_TEST' ) ).
    IF fail_at = 'MANIFEST'.
      rs_mfst-manual_review = abap_true.
      CLEAR rs_mfst-status.
      rs_mfst-decision_reason = 'Artifact plan rejected'.
    ELSEIF fail_at = 'NAMES'.
      CLEAR rs_mfst-items.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_ui_service DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA mo_fake TYPE REF TO lcl_ui_pipeline.
    DATA mo_cut TYPE REF TO zcl_mig_ui_service.
    METHODS setup.
    METHODS run
      IMPORTING iv_package TYPE devclass DEFAULT 'ZTEST'
                iv_url TYPE string DEFAULT '/sap/opu/odata4/sap/test/'
      RETURNING VALUE(rs_config) TYPE zif_mig_ui_contract=>ty_config
      RAISING zcx_mig_analysis.
    METHODS prepare_keeps_alias FOR TESTING RAISING zcx_mig_analysis.
    METHODS repeat_is_read_only FOR TESTING RAISING zcx_mig_analysis.
    METHODS request_stops_before_reader FOR TESTING RAISING zcx_mig_analysis.
    METHODS wrong_snapshot_stops FOR TESTING RAISING zcx_mig_analysis.
    METHODS blueprint_stops_provider FOR TESTING RAISING zcx_mig_analysis.
    METHODS provider_stops_signature FOR TESTING RAISING zcx_mig_analysis.
    METHODS signature_stops_mapping FOR TESTING RAISING zcx_mig_analysis.
    METHODS mapping_stops_row FOR TESTING RAISING zcx_mig_analysis.
    METHODS row_stops_boundary FOR TESTING RAISING zcx_mig_analysis.
    METHODS boundary_stops_manifest FOR TESTING RAISING zcx_mig_analysis.
    METHODS missing_names_block FOR TESTING RAISING zcx_mig_analysis.
    METHODS manifest_error_is_reported FOR TESTING RAISING zcx_mig_analysis.
    METHODS no_url_still_resolves_names FOR TESTING RAISING zcx_mig_analysis.
    METHODS json_roundtrip FOR TESTING RAISING zcx_mig_analysis.
ENDCLASS.
CLASS ltc_ui_service IMPLEMENTATION.
  METHOD setup.
    CLEAR: lcl_ui_boundary_log=>called, lcl_ui_boundary_log=>fail.
    mo_fake = NEW #( ).
    mo_cut = NEW #( io_reader = mo_fake io_blueprint = mo_fake io_provider = mo_fake
      io_signature = mo_fake io_service_map = mo_fake io_row_resolver = mo_fake io_manifest = mo_fake ).
  ENDMETHOD.
  METHOD run.
    TEST-INJECTION ui_query_validation.
      lcl_ui_boundary_log=>called = abap_true.
      IF lcl_ui_boundary_log=>fail = abap_true.
        RAISE EXCEPTION NEW zcx_mig_analysis( textid = zcx_mig_analysis=>analysis_failed ).
      ENDIF.
    END-TEST-INJECTION.
    rs_config = mo_cut->prepare( iv_analysis_id = '11111111111111111111111111111111'
      iv_package = iv_package iv_service_root_url = iv_url ).
  ENDMETHOD.
  METHOD prepare_keeps_alias.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'CONFIG_READY' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = 'ResultAlias' act = ls_result-entity_set ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZC_MIG_TEST' act = ls_result-custom_entity ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZUI_MIG_TEST' act = ls_result-service_definition ).
    cl_abap_unit_assert=>assert_equals( exp = 'METADATA_REQUIRED' act = ls_result-runtime_check ).
    cl_abap_unit_assert=>assert_true( lcl_ui_boundary_log=>called ).
  ENDMETHOD.
  METHOD repeat_is_read_only.
    DATA(ls_first) = run( ).
    CLEAR mo_fake->calls.
    DATA(ls_second) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = ls_first act = ls_second ).
    cl_abap_unit_assert=>assert_equals( exp = VALUE string_table(
      ( `READ` ) ( `BLUEPRINT` ) ( `PROVIDER` ) ( `SIGNATURE` ) ( `MAPPING` ) ( `ROW` ) ( `MANIFEST` ) ) act = mo_fake->calls ).
  ENDMETHOD.
  METHOD request_stops_before_reader.
    DATA(ls_result) = run( iv_package = VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_initial( mo_fake->calls ).
  ENDMETHOD.
  METHOD wrong_snapshot_stops.
    mo_fake->fail_at = 'READ'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'SNAPSHOT_MISMATCH' act = ls_result-issues[ 1 ]-code ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mo_fake->calls ) ).
  ENDMETHOD.
  METHOD blueprint_stops_provider.
    mo_fake->fail_at = 'BLUEPRINT'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLUEPRINT_NOT_READY' act = ls_result-issues[ 1 ]-code ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( mo_fake->calls ) ).
  ENDMETHOD.
  METHOD provider_stops_signature.
    mo_fake->fail_at = 'PROVIDER'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'PROVIDER_NOT_READY' act = ls_result-issues[ 1 ]-code ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( mo_fake->calls ) ).
  ENDMETHOD.
  METHOD signature_stops_mapping.
    mo_fake->fail_at = 'SIGNATURE'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'SIGNATURE_NOT_READY' act = ls_result-issues[ 1 ]-code ).
    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( mo_fake->calls ) ).
  ENDMETHOD.
  METHOD mapping_stops_row.
    mo_fake->fail_at = 'MAPPING'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = 5 act = lines( mo_fake->calls ) ).
  ENDMETHOD.
  METHOD row_stops_boundary.
    mo_fake->fail_at = 'ROW'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'ROW_NOT_READY' act = ls_result-issues[ 1 ]-code ).
    cl_abap_unit_assert=>assert_false( lcl_ui_boundary_log=>called ).
  ENDMETHOD.
  METHOD boundary_stops_manifest.
    lcl_ui_boundary_log=>fail = abap_true.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'QUERY_CONTRACT_INVALID' act = ls_result-issues[ 1 ]-code ).
    cl_abap_unit_assert=>assert_equals( exp = 6 act = lines( mo_fake->calls ) ).
  ENDMETHOD.
  METHOD missing_names_block.
    mo_fake->fail_at = 'NAMES'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'ARTIFACT_NAMES_MISSING' act = ls_result-issues[ 1 ]-code ).
  ENDMETHOD.
  METHOD manifest_error_is_reported.
    mo_fake->fail_at = 'MANIFEST'.
    DATA(ls_result) = run( ).
    cl_abap_unit_assert=>assert_equals( exp = 'ARTIFACT_PLAN_INVALID' act = ls_result-issues[ 1 ]-code ).
  ENDMETHOD.
  METHOD no_url_still_resolves_names.
    DATA(ls_result) = run( iv_url = `` ).
    cl_abap_unit_assert=>assert_equals( exp = 'NEEDS_ENDPOINT' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZC_MIG_TEST' act = ls_result-custom_entity ).
    cl_abap_unit_assert=>assert_initial( ls_result-metadata_url ).
  ENDMETHOD.
  METHOD json_roundtrip.
    DATA(ls_result) = run( ).
    DATA(lv_json) = zcl_mig_ui_service=>to_json( ls_result ).
    DATA ls_parsed TYPE zif_mig_ui_contract=>ty_config.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json pretty_name = /ui2/cl_json=>pretty_mode-camel_case
      CHANGING data = ls_parsed ).
    cl_abap_unit_assert=>assert_equals( exp = ls_result act = ls_parsed ).
  ENDMETHOD.
ENDCLASS.
