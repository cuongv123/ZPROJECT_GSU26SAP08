CLASS ltc_ui_contract DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_mig_ui_contract.
    DATA ms_bp TYPE zif_mig_types=>ty_service_blueprint_result.
    DATA ms_map TYPE zif_mig_types=>ty_svc_map_result.
    METHODS setup.
    METHODS valid_list_report FOR TESTING.
    METHODS endpoint_is_not_guessed FOR TESTING.
    METHODS reject_endpoint_query FOR TESTING.
    METHODS normalize_scalar_filter FOR TESTING.
    METHODS range_uses_reference_field FOR TESTING.
    METHODS reject_ambiguous_filter FOR TESTING.
    METHODS reject_hidden_filter FOR TESTING.
    METHODS reject_duplicate_filter FOR TESTING.
    METHODS reject_missing_key FOR TESTING.
    METHODS reject_mismatched_analysis FOR TESTING.
    METHODS reject_write_strategy FOR TESTING.
    METHODS reject_hidden_currency FOR TESTING.
    METHODS valid_currency_reference FOR TESTING.
    METHODS sort_order_and_key FOR TESTING.
    METHODS subtotal_is_not_aggregation FOR TESTING.
    METHODS ready_does_not_enable_chart FOR TESTING.
ENDCLASS.

CLASS ltc_ui_contract IMPLEMENTATION.
  METHOD setup.
    mo_cut = NEW #( ).
    ms_bp-blueprint = VALUE #( analysis_id = '11111111111111111111111111111111'
      source_program = 'ZRMIG_SAMPLE_FM_ALV' entity_name = 'ZC_SAMPLE'
      source_output_id = '22222222222222222222222222222222'
      strategy = zif_mig_types=>gc_svc_query ).
    ms_bp-fields = VALUE #(
      ( field_name = 'BUKRS' edm_type = 'Edm.String' label = 'Company code'
        visible = abap_true key_field = abap_true filterable = abap_true sortable = abap_true position = 10 )
      ( field_name = 'BUTXT' edm_type = 'Edm.String' label = 'Company name'
        visible = abap_true filterable = abap_true sortable = abap_true position = 20 ) ).
    ms_bp-parameters = VALUE #( ( source_item_id = '33333333333333333333333333333333'
      parameter_name = 'P_BUKRS' source_field_name = 'BUKRS' odata_kind = 'SCALAR' ) ).
    ms_map = VALUE #( analysis_id = ms_bp-blueprint-analysis_id status = zif_mig_types=>gc_smap_ready
      input_maps = VALUE #( ( svc_item_id = '33333333333333333333333333333333'
        svc_name = 'P_BUKRS' prv_name = 'IV_BUKRS' svc_kind = 'SCALAR'
        map_state = zif_mig_types=>gc_smap_auto prv_optional = abap_true ) ) ).
  ENDMETHOD.

  METHOD valid_list_report.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map
      iv_service_root_url = '/sap/opu/odata4/sap/example/srvd/sap/report/0001' ).
    cl_abap_unit_assert=>assert_equals( exp = 'CONFIG_READY' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZC_SAMPLE' act = ls_result-entity_set ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( ls_result-columns ) ).
    cl_abap_unit_assert=>assert_equals( exp = '/sap/opu/odata4/sap/example/srvd/sap/report/0001/$metadata'
      act = ls_result-metadata_url ).
  ENDMETHOD.

  METHOD endpoint_is_not_guessed.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'NEEDS_ENDPOINT' act = ls_result-status ).
    cl_abap_unit_assert=>assert_initial( act = ls_result-service_root_url ).
    cl_abap_unit_assert=>assert_initial( act = ls_result-metadata_url ).
  ENDMETHOD.

  METHOD reject_endpoint_query.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map
      iv_service_root_url = '/sap/opu/odata4/sap/example/?sap-client=100' ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_result-issues[ code = 'ENDPOINT_INVALID' ] ) ) ).
  ENDMETHOD.

  METHOD normalize_scalar_filter.
    ms_map-input_maps[ 1 ]-prv_optional = abap_false.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'BUKRS' act = ls_result-filters[ 1 ]-property ).
    cl_abap_unit_assert=>assert_equals( exp = 'P_BUKRS' act = ls_result-filters[ 1 ]-source_parameter ).
    cl_abap_unit_assert=>assert_true( ls_result-filters[ 1 ]-required ).
  ENDMETHOD.

  METHOD range_uses_reference_field.
    ms_bp-fields[ 1 ]-field_name = 'PRODUCT_ID'.
    ms_bp-parameters[ 1 ]-parameter_name = 'S_PRODID'.
    ms_bp-parameters[ 1 ]-source_field_name = 'PRODUCT_ID'.
    ms_map-input_maps[ 1 ]-svc_name = 'PRODUCT_ID'.
    ms_map-input_maps[ 1 ]-prv_name = 'SELPARAMPRODUCTID'.
    ms_map-input_maps[ 1 ]-svc_kind = 'RANGE'.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'PRODUCT_ID' act = ls_result-filters[ 1 ]-property ).
    cl_abap_unit_assert=>assert_equals( exp = 'S_PRODID' act = ls_result-filters[ 1 ]-source_parameter ).
    cl_abap_unit_assert=>assert_equals( exp = 'RANGE' act = ls_result-filters[ 1 ]-kind ).
  ENDMETHOD.

  METHOD reject_ambiguous_filter.
    APPEND VALUE #( field_name = 'BU_KRS' edm_type = 'Edm.String'
      visible = abap_true filterable = abap_true ) TO ms_bp-fields.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_result-issues[ code = 'FILTER_PROPERTY_INVALID' ] ) ) ).
  ENDMETHOD.

  METHOD reject_hidden_filter.
    ms_bp-fields[ 1 ]-visible = abap_false.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_result-issues[ code = 'FILTER_PROPERTY_INVALID' ] ) ) ).
  ENDMETHOD.

  METHOD reject_duplicate_filter.
    APPEND ms_map-input_maps[ 1 ] TO ms_map-input_maps.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_result-issues[ code = 'FILTER_MAPPING_DUPLICATE' ] ) ) ).
  ENDMETHOD.

  METHOD reject_missing_key.
    ms_bp-fields[ 1 ]-key_field = abap_false.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_result-issues[ code = 'KEY_OR_COLUMNS_MISSING' ] ) ) ).
  ENDMETHOD.

  METHOD reject_mismatched_analysis.
    CLEAR ms_map-analysis_id.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
  ENDMETHOD.

  METHOD reject_write_strategy.
    ms_bp-blueprint-strategy = zif_mig_types=>gc_svc_action.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'BLOCKED' act = ls_result-status ).
    cl_abap_unit_assert=>assert_false( ls_result-table_supported ).
  ENDMETHOD.

  METHOD reject_hidden_currency.
    APPEND VALUE #( field_name = 'PRICE' edm_type = 'Edm.Decimal' visible = abap_true currency_field = 'WAERS' ) TO ms_bp-fields.
    APPEND VALUE #( field_name = 'WAERS' edm_type = 'Edm.String' visible = abap_false ) TO ms_bp-fields.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_result-issues[ code = 'SEMANTIC_REFERENCE_INVALID' ] ) ) ).
  ENDMETHOD.

  METHOD valid_currency_reference.
    APPEND VALUE #( field_name = 'PRICE' edm_type = 'Edm.Decimal' visible = abap_true currency_field = 'WAERS' ) TO ms_bp-fields.
    APPEND VALUE #( field_name = 'WAERS' edm_type = 'Edm.String' visible = abap_true ) TO ms_bp-fields.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map ).
    cl_abap_unit_assert=>assert_equals( exp = 'NEEDS_ENDPOINT' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = 'WAERS' act = ls_result-columns[ property = 'PRICE' ]-currency_property ).
  ENDMETHOD.

  METHOD sort_order_and_key.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map
      it_sorts = VALUE #( ( output_id = ms_bp-blueprint-source_output_id
        field_name = 'BUTXT' position = 1 descending = abap_true )
        ( output_id = '44444444444444444444444444444444' field_name = 'BUKRS' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( ls_result-default_sort ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BUTXT' act = ls_result-default_sort[ 1 ]-property ).
    cl_abap_unit_assert=>assert_true( ls_result-default_sort[ 1 ]-descending ).
    cl_abap_unit_assert=>assert_equals( exp = 'BUKRS' act = ls_result-default_sort[ 2 ]-property ).
  ENDMETHOD.

  METHOD subtotal_is_not_aggregation.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map
      it_sorts = VALUE #( ( output_id = ms_bp-blueprint-source_output_id
        field_name = 'BUTXT' subtotal = abap_true ) ) ).
    cl_abap_unit_assert=>assert_false( ls_result-chart_supported ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_result-issues[ code = 'SUBTOTAL_NOT_SUPPORTED' ] ) ) ).
  ENDMETHOD.

  METHOD ready_does_not_enable_chart.
    DATA(ls_result) = mo_cut->build( is_bp = ms_bp is_smap = ms_map
      iv_service_root_url = 'https://sap.example/sap/opu/odata4/sap/example/' ).
    cl_abap_unit_assert=>assert_equals( exp = 'CONFIG_READY' act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = 'METADATA_REQUIRED' act = ls_result-runtime_check ).
    cl_abap_unit_assert=>assert_false( ls_result-chart_supported ).
    cl_abap_unit_assert=>assert_false( ls_result-filters[ 1 ]-value_help_supported ).
  ENDMETHOD.
ENDCLASS.
