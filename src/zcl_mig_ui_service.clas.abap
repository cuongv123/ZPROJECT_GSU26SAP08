CLASS zcl_mig_ui_service DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_reader TYPE REF TO zif_mig_analysis_reader OPTIONAL
                io_blueprint TYPE REF TO zif_mig_service_blueprint OPTIONAL
                io_provider TYPE REF TO zif_mig_provider_contract OPTIONAL
                io_signature TYPE REF TO zif_mig_sig_rslv OPTIONAL
                io_service_map TYPE REF TO zif_mig_svc_map OPTIONAL
                io_row_resolver TYPE REF TO zif_mig_row_rslv OPTIONAL
                io_manifest TYPE REF TO zif_mig_art_mfst OPTIONAL.
    METHODS prepare
      IMPORTING iv_analysis_id TYPE sysuuid_x16
                iv_package TYPE devclass
                iv_service_root_url TYPE string OPTIONAL
      RETURNING VALUE(rs_config) TYPE zif_mig_ui_contract=>ty_config
      RAISING zcx_mig_analysis.
    CLASS-METHODS to_json
      IMPORTING is_config TYPE zif_mig_ui_contract=>ty_config
      RETURNING VALUE(rv_json) TYPE string.
  PRIVATE SECTION.
    DATA mo_reader TYPE REF TO zif_mig_analysis_reader.
    DATA mo_blueprint TYPE REF TO zif_mig_service_blueprint.
    DATA mo_provider TYPE REF TO zif_mig_provider_contract.
    DATA mo_signature TYPE REF TO zif_mig_sig_rslv.
    DATA mo_service_map TYPE REF TO zif_mig_svc_map.
    DATA mo_row_resolver TYPE REF TO zif_mig_row_rslv.
    DATA mo_manifest TYPE REF TO zif_mig_art_mfst.
    METHODS block
      IMPORTING iv_code TYPE string iv_target TYPE string iv_message TYPE string
      CHANGING cs_config TYPE zif_mig_ui_contract=>ty_config.
ENDCLASS.

CLASS zcl_mig_ui_service IMPLEMENTATION.
  METHOD constructor.
    mo_reader = COND #( WHEN io_reader IS BOUND THEN io_reader ELSE NEW zcl_mig_analysis_reader( ) ).
    mo_blueprint = COND #( WHEN io_blueprint IS BOUND THEN io_blueprint ELSE NEW zcl_mig_service_blueprint( ) ).
    mo_provider = COND #( WHEN io_provider IS BOUND THEN io_provider ELSE NEW zcl_mig_provider_contract( ) ).
    mo_signature = COND #( WHEN io_signature IS BOUND THEN io_signature
      ELSE NEW zcl_mig_sig_rslv( io_repo = NEW zcl_mig_sig_repo( ) ) ).
    mo_service_map = COND #( WHEN io_service_map IS BOUND THEN io_service_map ELSE NEW zcl_mig_svc_map( ) ).
    mo_row_resolver = COND #( WHEN io_row_resolver IS BOUND THEN io_row_resolver
      ELSE NEW zcl_mig_row_rslv( io_repo = NEW zcl_mig_row_repo( ) ) ).
    mo_manifest = COND #( WHEN io_manifest IS BOUND THEN io_manifest ELSE NEW zcl_mig_art_mfst( ) ).
  ENDMETHOD.

  METHOD block.
    APPEND VALUE #( severity = 'E' code = iv_code target = iv_target
      message = COND #( WHEN iv_message IS NOT INITIAL THEN iv_message ELSE iv_code ) ) TO cs_config-issues.
    zcl_mig_ui_contract=>finish( CHANGING cs_config = cs_config ).
  ENDMETHOD.

  METHOD to_json.
    rv_json = /ui2/cl_json=>serialize( data = is_config
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
  ENDMETHOD.

  METHOD prepare.
    "No execute/generate call, repository collision preflight, publish or write.
    rs_config-contract_version = zif_mig_ui_contract=>gc_version.
    rs_config-analysis_id = iv_analysis_id.
    rs_config-template = 'sap.fe.templates.ListReport'.
    rs_config-odata_version = '4.0'.
    rs_config-read_only = abap_true.
    rs_config-service_binding = zcl_mig_svc_registry=>gc_shared_binding.
    IF iv_analysis_id IS INITIAL OR iv_package IS INITIAL.
      block( EXPORTING iv_code = 'REQUEST_INVALID' iv_target = 'AnalysisId/Package'
        iv_message = 'Analysis ID and OData artifact package are required.' CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    DATA(ls_analysis) = mo_reader->read( iv_analysis_id = iv_analysis_id ).
    IF ls_analysis-analysis_id <> iv_analysis_id.
      block( EXPORTING iv_code = 'SNAPSHOT_MISMATCH' iv_target = 'AnalysisId'
        iv_message = 'The reader did not return the requested analysis snapshot.' CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    DATA(ls_bp) = mo_blueprint->build( is_analysis = ls_analysis ).
    rs_config-source_program = ls_bp-blueprint-source_program.
    rs_config-app_title = ls_bp-blueprint-source_program.
    rs_config-entity_set = ls_bp-blueprint-entity_name.
    IF ls_bp-blueprint-analysis_id <> iv_analysis_id OR
       ls_bp-blueprint-strategy <> zif_mig_types=>gc_svc_query OR ls_bp-blueprint-manual_review = abap_true.
      block( EXPORTING iv_code = 'BLUEPRINT_NOT_READY' iv_target = 'Blueprint'
        iv_message = ls_bp-blueprint-decision_reason CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    DATA(ls_provider) = mo_provider->build( is_analysis = ls_analysis is_blueprint = ls_bp ).
    IF ls_provider-contract-analysis_id <> iv_analysis_id OR
       ls_provider-contract-service_strategy <> zif_mig_types=>gc_svc_query OR
       ls_provider-contract-manual_review = abap_true OR
       ( ls_provider-contract-provider_status <> zif_mig_types=>gc_provider_ready AND
         ls_provider-contract-provider_status <> zif_mig_types=>gc_provider_signature ) OR
       ( ls_provider-contract-provider_kind <> zif_mig_types=>gc_provider_function AND
         ls_provider-contract-provider_kind <> zif_mig_types=>gc_provider_bapi AND
         ls_provider-contract-provider_kind <> zif_mig_types=>gc_provider_class_method ).
      block( EXPORTING iv_code = 'PROVIDER_NOT_READY' iv_target = 'Provider'
        iv_message = ls_provider-contract-decision_reason CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    DATA(ls_sig) = mo_signature->resolve( is_prv = ls_provider-contract ).
    IF ls_sig-analysis_id <> iv_analysis_id OR ls_sig-status <> zif_mig_types=>gc_sig_ready OR ls_sig-manual_review = abap_true.
      block( EXPORTING iv_code = 'SIGNATURE_NOT_READY' iv_target = 'Signature'
        iv_message = ls_sig-decision_reason CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    DATA(ls_smap) = mo_service_map->build( is_bp = ls_bp is_sig = ls_sig ).
    rs_config = NEW zcl_mig_ui_contract( )->build( is_bp = ls_bp is_smap = ls_smap
      it_sorts = ls_analysis-alv_sorts iv_service_root_url = iv_service_root_url ).
    IF rs_config-status = 'BLOCKED'.
      RETURN.
    ENDIF.
    DATA(ls_row) = mo_row_resolver->resolve( is_bp = ls_bp is_smap = ls_smap ).
    IF ls_row-analysis_id <> iv_analysis_id OR ls_row-status <> zif_mig_types=>gc_row_ready OR ls_row-manual_review = abap_true.
      block( EXPORTING iv_code = 'ROW_NOT_READY' iv_target = 'Columns'
        iv_message = ls_row-decision_reason CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    TRY.
        TEST-SEAM ui_query_validation.
          NEW zcl_mig_xco_gen( )->validate_query_contract( is_bp = ls_bp
            is_prv = ls_provider-contract is_sig = ls_sig is_smap = ls_smap is_row = ls_row ).
        END-TEST-SEAM.
      CATCH zcx_mig_analysis INTO DATA(lx_boundary).
        block( EXPORTING iv_code = 'QUERY_CONTRACT_INVALID' iv_target = 'Provider'
          iv_message = |Query boundary validation failed: { lx_boundary->get_text( ) }| CHANGING cs_config = rs_config ).
        RETURN.
    ENDTRY.
    "Same naming implementation as generation, without create collision checks.
    DATA(ls_manifest) = mo_manifest->build( iv_package = iv_package is_bp = ls_bp
      is_prv = ls_provider-contract is_sig = ls_sig is_smap = ls_smap is_row = ls_row ).
    IF ls_manifest-analysis_id <> iv_analysis_id OR ls_manifest-status <> zif_mig_types=>gc_art_ready
       OR ls_manifest-manual_review = abap_true.
      block( EXPORTING iv_code = 'ARTIFACT_PLAN_INVALID' iv_target = 'Package'
        iv_message = ls_manifest-decision_reason CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    LOOP AT ls_manifest-items INTO DATA(ls_item).
      CASE ls_item-art_role.
        WHEN zif_mig_types=>gc_art_query_prv.
          rs_config-query_provider = ls_item-object_name.
        WHEN zif_mig_types=>gc_art_entity.
          rs_config-custom_entity = ls_item-object_name.
        WHEN zif_mig_types=>gc_art_srv_def.
          rs_config-service_definition = ls_item-object_name.
      ENDCASE.
    ENDLOOP.
    IF rs_config-query_provider IS INITIAL OR rs_config-custom_entity IS INITIAL OR rs_config-service_definition IS INITIAL.
      block( EXPORTING iv_code = 'ARTIFACT_NAMES_MISSING' iv_target = 'Artifacts'
        iv_message = 'Artifact plan must contain the provider, custom entity and service definition.' CHANGING cs_config = rs_config ).
      RETURN.
    ENDIF.
    zcl_mig_ui_contract=>finish( CHANGING cs_config = rs_config ).
  ENDMETHOD.
ENDCLASS.

