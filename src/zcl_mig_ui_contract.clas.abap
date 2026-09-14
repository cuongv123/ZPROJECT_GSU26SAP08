CLASS zcl_mig_ui_contract DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS normalize_name
      IMPORTING iv_name TYPE string
      RETURNING VALUE(rv_name) TYPE string.
    CLASS-METHODS resolve_filter
      IMPORTING iv_name TYPE string
                it_fields TYPE zif_mig_types=>tt_service_field
      RETURNING VALUE(rv_property) TYPE string
      RAISING zcx_mig_query_error.
    METHODS build
      IMPORTING is_bp TYPE zif_mig_types=>ty_service_blueprint_result
                is_smap TYPE zif_mig_types=>ty_svc_map_result
                it_sorts TYPE zif_mig_types=>tt_alv_sort OPTIONAL
                iv_service_root_url TYPE string OPTIONAL
      RETURNING VALUE(rs_config) TYPE zif_mig_ui_contract=>ty_config.
    CLASS-METHODS finish
      CHANGING cs_config TYPE zif_mig_ui_contract=>ty_config.
  PRIVATE SECTION.
    METHODS add_issue
      IMPORTING iv_code TYPE string iv_target TYPE string iv_message TYPE string
                iv_severity TYPE c DEFAULT 'E'
      CHANGING cs_config TYPE zif_mig_ui_contract=>ty_config.
ENDCLASS.

CLASS zcl_mig_ui_contract IMPLEMENTATION.
  METHOD normalize_name.
    DATA lv_changed TYPE abap_bool.
    rv_name = to_upper( iv_name ).
    CONDENSE rv_name NO-GAPS.
    DO 3 TIMES.
      lv_changed = abap_false.
      IF strlen( rv_name ) >= 3.
        CASE substring( val = rv_name len = 3 ).
          WHEN 'IV_' OR 'IS_' OR 'IT_' OR 'EV_' OR 'ES_' OR 'ET_'
            OR 'CV_' OR 'CS_' OR 'CT_' OR 'RV_' OR 'RS_' OR 'RT_'
            OR 'GT_' OR 'GS_'.
            rv_name = substring( val = rv_name off = 3 ).
            lv_changed = abap_true.
        ENDCASE.
      ENDIF.
      IF lv_changed = abap_false AND strlen( rv_name ) >= 2.
        CASE substring( val = rv_name len = 2 ).
          WHEN 'I_' OR 'E_' OR 'C_' OR 'R_' OR 'P_' OR 'S_' OR 'T_'.
            rv_name = substring( val = rv_name off = 2 ).
            lv_changed = abap_true.
        ENDCASE.
      ENDIF.
      IF lv_changed = abap_false.
        EXIT.
      ENDIF.
    ENDDO.
    REPLACE ALL OCCURRENCES OF '_' IN rv_name WITH ''.
  ENDMETHOD.

  METHOD resolve_filter.
    DATA(lv_name) = normalize_name( iv_name ).
    DATA lv_hits TYPE i.
    LOOP AT it_fields INTO DATA(ls_field)
      WHERE visible = abap_true AND filterable = abap_true.
      IF lv_name IS NOT INITIAL AND
         normalize_name( CONV #( ls_field-field_name ) ) = lv_name.
        lv_hits += 1.
        rv_property = ls_field-field_name.
      ENDIF.
    ENDLOOP.
    IF lv_hits <> 1.
      RAISE EXCEPTION NEW zcx_mig_query_error(
        iv_message = |Filter { iv_name }: expected one exposed filterable property, found { lv_hits }.| ).
    ENDIF.
  ENDMETHOD.

  METHOD add_issue.
    APPEND VALUE #( severity = iv_severity code = iv_code
      target = iv_target message = iv_message ) TO cs_config-issues.
  ENDMETHOD.

  METHOD finish.
    cs_config-status = 'CONFIG_READY'.
    cs_config-table_supported = abap_true.
    cs_config-filter_supported = xsdbool( cs_config-filters IS NOT INITIAL ).
    cs_config-chart_supported = abap_false.
    "Static contract readiness must never imply a published, tested endpoint.
    cs_config-runtime_check = 'METADATA_REQUIRED'.
    IF line_exists( cs_config-issues[ severity = 'E' ] ).
      cs_config-status = 'BLOCKED'.
      cs_config-table_supported = abap_false.
      cs_config-filter_supported = abap_false.
    ELSEIF cs_config-service_root_url IS INITIAL.
      cs_config-status = 'NEEDS_ENDPOINT'.
    ENDIF.
  ENDMETHOD.

  METHOD build.
    rs_config-contract_version = zif_mig_ui_contract=>gc_version.
    rs_config-analysis_id = is_bp-blueprint-analysis_id.
    rs_config-source_program = is_bp-blueprint-source_program.
    rs_config-app_title = is_bp-blueprint-source_program.
    rs_config-template = 'sap.fe.templates.ListReport'.
    rs_config-odata_version = '4.0'.
    rs_config-read_only = abap_true.
    "add_srvd uses this exact alias, independently of the DDLS object name.
    rs_config-entity_set = is_bp-blueprint-entity_name.
    rs_config-service_binding = zcl_mig_svc_registry=>gc_shared_binding.

    IF is_bp-blueprint-analysis_id IS INITIAL OR
       is_smap-analysis_id <> is_bp-blueprint-analysis_id OR
       is_bp-blueprint-source_program IS INITIAL OR rs_config-entity_set IS INITIAL.
      add_issue( EXPORTING iv_code = 'IDENTITY_INVALID' iv_target = 'AnalysisId'
        iv_message = 'Analysis, service map and entity alias must identify the same report.'
        CHANGING cs_config = rs_config ).
    ENDIF.
    IF is_bp-blueprint-strategy <> zif_mig_types=>gc_svc_query OR
       is_bp-blueprint-manual_review = abap_true OR
       is_smap-status <> zif_mig_types=>gc_smap_ready OR is_smap-manual_review = abap_true.
      add_issue( EXPORTING iv_code = 'CONTRACT_NOT_READY' iv_target = 'Blueprint'
        iv_message = |Read-only blueprint/service mapping is not ready: { is_smap-decision_reason }|
        CHANGING cs_config = rs_config ).
    ENDIF.

    DATA(lt_fields) = is_bp-fields.
    DELETE lt_fields WHERE visible = abap_false.
    SORT lt_fields BY position field_name.
    DATA lv_keys TYPE i.
    LOOP AT lt_fields INTO DATA(ls_field).
      IF ls_field-field_name IS INITIAL OR
         line_exists( rs_config-columns[ property = CONV string( ls_field-field_name ) ] ).
        add_issue( EXPORTING iv_code = 'PROPERTY_INVALID' iv_target = CONV #( ls_field-field_name )
          iv_message = 'Exposed property names must be nonempty and unique.' CHANGING cs_config = rs_config ).
      ENDIF.
      IF ls_field-key_field = abap_true.
        lv_keys += 1.
      ENDIF.
      APPEND VALUE #( property = ls_field-field_name
        label = COND #( WHEN ls_field-label IS NOT INITIAL THEN ls_field-label ELSE ls_field-field_name )
        edm_type = ls_field-edm_type
        position = COND #( WHEN ls_field-position > 0 THEN ls_field-position ELSE lines( rs_config-columns ) * 10 + 10 )
        is_key = ls_field-key_field currency_property = ls_field-currency_field
        unit_property = ls_field-unit_field ) TO rs_config-columns.
      DO 2 TIMES.
        DATA(lv_reference) = COND string( WHEN sy-index = 1 THEN ls_field-currency_field ELSE ls_field-unit_field ).
        IF lv_reference IS INITIAL.
          CONTINUE.
        ENDIF.
        READ TABLE lt_fields WITH KEY field_name = lv_reference INTO DATA(ls_reference).
        IF sy-subrc <> 0 OR ls_reference-edm_type <> 'Edm.String'.
          add_issue( EXPORTING iv_code = 'SEMANTIC_REFERENCE_INVALID'
            iv_target = CONV #( ls_field-field_name )
            iv_message = |Currency/unit reference { lv_reference } must be an exposed string property.|
            CHANGING cs_config = rs_config ).
        ENDIF.
        IF ls_field-edm_type <> 'Edm.Decimal'.
          add_issue( EXPORTING iv_code = 'SEMANTIC_TYPE_INVALID'
            iv_target = CONV #( ls_field-field_name )
            iv_message = 'Amount/quantity annotations currently require an Edm.Decimal property.'
            CHANGING cs_config = rs_config ).
        ENDIF.
      ENDDO.
      IF ls_field-currency_field IS NOT INITIAL AND ls_field-unit_field IS NOT INITIAL.
        add_issue( EXPORTING iv_code = 'SEMANTIC_CONFLICT' iv_target = CONV #( ls_field-field_name )
          iv_message = 'A property cannot be both an amount and a quantity.' CHANGING cs_config = rs_config ).
      ENDIF.
    ENDLOOP.
    IF lv_keys = 0 OR rs_config-columns IS INITIAL.
      add_issue( EXPORTING iv_code = 'KEY_OR_COLUMNS_MISSING' iv_target = 'Columns'
        iv_message = 'The generated entity needs visible columns and at least one exposed key.'
        CHANGING cs_config = rs_config ).
    ENDIF.

    LOOP AT is_smap-input_maps INTO DATA(ls_map).
      IF ls_map-map_state <> zif_mig_types=>gc_smap_auto.
        add_issue( EXPORTING iv_code = 'FILTER_MAPPING_INVALID' iv_target = CONV #( ls_map-svc_name )
          iv_message = ls_map-reason CHANGING cs_config = rs_config ).
        CONTINUE.
      ENDIF.
      TRY.
          DATA(lv_property) = resolve_filter( iv_name = CONV #( ls_map-svc_name ) it_fields = lt_fields ).
          IF line_exists( rs_config-filters[ property = lv_property ] ).
            add_issue( EXPORTING iv_code = 'FILTER_MAPPING_DUPLICATE' iv_target = lv_property
              iv_message = 'Multiple provider inputs map to one OData filter property.' CHANGING cs_config = rs_config ).
            CONTINUE.
          ENDIF.
          DATA(ls_parameter) = VALUE zif_mig_types=>ty_service_parameter(
            is_bp-parameters[ source_item_id = ls_map-svc_item_id ] OPTIONAL ).
          APPEND VALUE #( source_parameter = ls_parameter-parameter_name property = lv_property
            provider_parameter = ls_map-prv_name kind = ls_map-svc_kind
            required = xsdbool( ls_map-mandatory = abap_true OR ls_map-prv_optional = abap_false )
            value_help_supported = abap_false ) TO rs_config-filters.
        CATCH zcx_mig_query_error INTO DATA(lx_filter).
          add_issue( EXPORTING iv_code = 'FILTER_PROPERTY_INVALID' iv_target = CONV #( ls_map-svc_name )
            iv_message = lx_filter->get_text( ) CHANGING cs_config = rs_config ).
      ENDTRY.
    ENDLOOP.

    DATA(lt_sorts) = it_sorts.
    SORT lt_sorts BY position field_name.
    LOOP AT lt_sorts INTO DATA(ls_sort) WHERE output_id = is_bp-blueprint-source_output_id.
      READ TABLE lt_fields WITH KEY field_name = ls_sort-field_name INTO DATA(ls_sort_field).
      IF sy-subrc <> 0 OR ls_sort_field-sortable = abap_false OR
         ( ls_sort-ascending = abap_true AND ls_sort-descending = abap_true ).
        add_issue( EXPORTING iv_code = 'SORT_NOT_MAPPED' iv_target = CONV #( ls_sort-field_name )
          iv_message = 'Default ALV sort is not a valid exposed sortable property/direction.'
          iv_severity = 'W' CHANGING cs_config = rs_config ).
        CONTINUE.
      ENDIF.
      IF NOT line_exists( rs_config-default_sort[ property = CONV string( ls_sort-field_name ) ] ).
        APPEND VALUE #( property = ls_sort-field_name descending = ls_sort-descending ) TO rs_config-default_sort.
      ENDIF.
      IF ls_sort-subtotal = abap_true.
        add_issue( EXPORTING iv_code = 'SUBTOTAL_NOT_SUPPORTED' iv_target = CONV #( ls_sort-field_name )
          iv_message = 'Sort is retained; subtotal requires a separate aggregation implementation.'
          iv_severity = 'W' CHANGING cs_config = rs_config ).
      ENDIF.
    ENDLOOP.
    "Stable tie-breakers also support deterministic paging in the future UI.
    LOOP AT rs_config-columns INTO DATA(ls_column) WHERE is_key = abap_true.
      IF NOT line_exists( rs_config-default_sort[ property = ls_column-property ] ).
        APPEND VALUE #( property = ls_column-property ) TO rs_config-default_sort.
      ENDIF.
    ENDLOOP.

    rs_config-service_root_url = iv_service_root_url.
    IF iv_service_root_url IS INITIAL.
      add_issue( EXPORTING iv_code = 'ENDPOINT_REQUIRED' iv_target = 'ServiceRootUrl'
        iv_message = 'Supply the service root copied from the published binding. No URL is guessed.'
        iv_severity = 'W' CHANGING cs_config = rs_config ).
    ELSEIF ( iv_service_root_url NP '/sap/opu/odata4/*' AND iv_service_root_url NP 'https://*/sap/opu/odata4/*' )
      OR iv_service_root_url CS '?' OR iv_service_root_url CS '#' OR iv_service_root_url CS '@'
      OR iv_service_root_url CS ` ` OR iv_service_root_url CS '..' OR iv_service_root_url CS '%'
      OR iv_service_root_url CS cl_abap_char_utilities=>newline
      OR iv_service_root_url CS cl_abap_char_utilities=>horizontal_tab
      OR iv_service_root_url CS '$metadata'.
      add_issue( EXPORTING iv_code = 'ENDPOINT_INVALID' iv_target = 'ServiceRootUrl'
        iv_message = 'Use an OData V4 service root (relative SAP path or HTTPS), without query, credentials or $metadata.'
        CHANGING cs_config = rs_config ).
    ELSE.
      IF substring( val = rs_config-service_root_url off = strlen( rs_config-service_root_url ) - 1 ) <> '/'.
        rs_config-service_root_url = rs_config-service_root_url && '/'.
      ENDIF.
      rs_config-metadata_url = rs_config-service_root_url && '$metadata'.
    ENDIF.
    finish( CHANGING cs_config = rs_config ).
  ENDMETHOD.
ENDCLASS.

