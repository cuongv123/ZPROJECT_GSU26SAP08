CLASS zcl_mig_odata_gen_svc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_odata_gen_svc.

    METHODS constructor
      IMPORTING
        io_reader
          TYPE REF TO zif_mig_analysis_reader OPTIONAL

        io_blueprint
          TYPE REF TO zif_mig_service_blueprint OPTIONAL

        io_provider
          TYPE REF TO zif_mig_provider_contract OPTIONAL

        io_signature
          TYPE REF TO zif_mig_sig_rslv OPTIONAL

        io_service_map
          TYPE REF TO zif_mig_svc_map OPTIONAL

        io_row_resolver
          TYPE REF TO zif_mig_row_rslv OPTIONAL

        io_manifest
          TYPE REF TO zif_mig_art_mfst OPTIONAL

        io_preflight
          TYPE REF TO zif_mig_art_pref OPTIONAL

        io_art_repo
          TYPE REF TO zif_mig_art_repo OPTIONAL

        io_executor
          TYPE REF TO zif_mig_xco_executor OPTIONAL

        io_provider_gen
          TYPE REF TO zif_mig_prv_clas_gen OPTIONAL.

  PRIVATE SECTION.

    DATA:
      mo_reader       TYPE REF TO zif_mig_analysis_reader,
      mo_blueprint    TYPE REF TO zif_mig_service_blueprint,
      mo_provider     TYPE REF TO zif_mig_provider_contract,
      mo_signature    TYPE REF TO zif_mig_sig_rslv,
      mo_service_map  TYPE REF TO zif_mig_svc_map,
      mo_row_resolver TYPE REF TO zif_mig_row_rslv,
      mo_manifest     TYPE REF TO zif_mig_art_mfst,
      mo_preflight    TYPE REF TO zif_mig_art_pref,
      mo_art_repo     TYPE REF TO zif_mig_art_repo,
      mo_executor     TYPE REF TO zif_mig_xco_executor.

    DATA mo_provider_gen TYPE REF TO zif_mig_prv_clas_gen.


    METHODS block_result
      IMPORTING
        VALUE(iv_message) TYPE string
      CHANGING
        cs_result TYPE zif_mig_odata_gen_svc=>ty_result.


    METHODS fill_artifact_names
      IMPORTING
        is_mfst TYPE zif_mig_types=>ty_art_mfst
      CHANGING
        cs_result TYPE zif_mig_odata_gen_svc=>ty_result.


    METHODS first_block_reason
      IMPORTING
        is_mfst TYPE zif_mig_types=>ty_art_mfst
      RETURNING
        VALUE(rv_reason) TYPE string.

ENDCLASS.


CLASS zcl_mig_odata_gen_svc IMPLEMENTATION.

  METHOD constructor.

    mo_provider_gen = io_provider_gen.

    IF io_reader IS BOUND.
      mo_reader = io_reader.
    ELSE.
      mo_reader = NEW zcl_mig_analysis_reader( ).
    ENDIF.


    IF io_blueprint IS BOUND.
      mo_blueprint = io_blueprint.
    ELSE.
      mo_blueprint = NEW zcl_mig_service_blueprint( ).
    ENDIF.


    IF io_provider IS BOUND.
      mo_provider = io_provider.
    ELSE.
      mo_provider = NEW zcl_mig_provider_contract( ).
    ENDIF.


    IF io_signature IS BOUND.
      mo_signature = io_signature.
    ELSE.
      mo_signature =
        NEW zcl_mig_sig_rslv(
          io_repo = NEW zcl_mig_sig_repo( )
        ).
    ENDIF.


    IF io_service_map IS BOUND.
      mo_service_map = io_service_map.
    ELSE.
      mo_service_map = NEW zcl_mig_svc_map( ).
    ENDIF.


    IF io_row_resolver IS BOUND.
      mo_row_resolver = io_row_resolver.
    ELSE.
      mo_row_resolver =
        NEW zcl_mig_row_rslv(
          io_repo = NEW zcl_mig_row_repo( )
        ).
    ENDIF.


    IF io_manifest IS BOUND.
      mo_manifest = io_manifest.
    ELSE.
      mo_manifest = NEW zcl_mig_art_mfst( ).
    ENDIF.


    IF io_preflight IS BOUND.
      mo_preflight = io_preflight.
    ELSE.
      mo_preflight =
        NEW zcl_mig_art_pref(
          io_repo = NEW zcl_mig_art_repo( )
        ).
    ENDIF.


    IF io_art_repo IS BOUND.
      mo_art_repo = io_art_repo.
    ELSE.
      mo_art_repo = NEW zcl_mig_art_repo( ).
    ENDIF.


    IF io_executor IS BOUND.
      mo_executor = io_executor.
    ELSE.
      mo_executor = NEW zcl_mig_xco_executor( ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_mig_odata_gen_svc~generate.

    CLEAR rs_result.

    rs_result-analysis_id =
      is_request-analysis_id.

    rs_result-service_binding =
      zcl_mig_svc_registry=>gc_shared_binding.


    IF is_request-analysis_id IS INITIAL
       OR is_request-package IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    IF is_request-execute = abap_true
       AND is_request-transport IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    "==========================================================
    " 1. Read immutable analysis snapshot from part 1
    "==========================================================
    DATA(ls_analysis) =
      mo_reader->read(
        iv_analysis_id = is_request-analysis_id
      ).


    "==========================================================
    " 2. Build read-only target service blueprint
    "==========================================================
    DATA(ls_bp) =
      mo_blueprint->build(
        is_analysis = ls_analysis
      ).

    rs_result-strategy =
      ls_bp-blueprint-strategy.


    IF ls_bp-blueprint-strategy <>
         zif_mig_types=>gc_svc_query
       OR ls_bp-blueprint-manual_review = abap_true.

      block_result(
        EXPORTING
          iv_message = ls_bp-blueprint-decision_reason
        CHANGING
          cs_result  = rs_result
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " 3. Select reusable static class method or function module
    "==========================================================
    DATA(ls_prv_result) =
      mo_provider->build(
        is_analysis  = ls_analysis
        is_blueprint = ls_bp
      ).

    DATA(ls_prv) =
      ls_prv_result-contract.

    rs_result-provider_kind =
      ls_prv-provider_kind.


    IF ls_prv-provider_kind =
         zif_mig_types=>gc_provider_class_method.

      rs_result-provider_object =
        |{ ls_prv-source_container_name }=>{ ls_prv-source_object_name }|.

    ELSE.

      rs_result-provider_object =
        ls_prv-source_object_name.

    ENDIF.


    IF ( ls_prv-provider_kind <>
           zif_mig_types=>gc_provider_class_method
         AND ls_prv-provider_kind <>
           zif_mig_types=>gc_provider_function
         AND ls_prv-provider_kind <>
           zif_mig_types=>gc_provider_bapi )
       OR
       ( ls_prv-provider_status <>
           zif_mig_types=>gc_provider_ready
         AND ls_prv-provider_status <>
           zif_mig_types=>gc_provider_signature )
       OR ls_prv-manual_review = abap_true.

      block_result(
        EXPORTING
          iv_message = ls_prv-decision_reason
        CHANGING
          cs_result  = rs_result
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " 4. Resolve the actual provider signature
    "==========================================================
    DATA(ls_sig) =
      mo_signature->resolve(
        is_prv = ls_prv
      ).


    IF ls_sig-status <> zif_mig_types=>gc_sig_ready
       OR ls_sig-manual_review = abap_true.

      block_result(
        EXPORTING
          iv_message = ls_sig-decision_reason
        CHANGING
          cs_result  = rs_result
      ).

      RETURN.

    ENDIF.


    IF ls_prv-provider_kind =
         zif_mig_types=>gc_provider_class_method.

      READ TABLE ls_analysis-business_logic
        WITH KEY item_id = ls_prv-source_item_id
        INTO DATA(ls_provider_logic).

      IF sy-subrc <> 0
         OR ls_provider_logic-object_type <> 'STATIC_METHOD'.

        block_result(
          EXPORTING
            iv_message =
              'Instance or unresolved class methods are not supported by read-only generation.'
          CHANGING
            cs_result = rs_result
        ).

        RETURN.

      ENDIF.

    ENDIF.


    "==========================================================
    " 5. Map service filters and provider parameters
    "==========================================================
    DATA(ls_smap) =
      mo_service_map->build(
        is_bp  = ls_bp
        is_sig = ls_sig
      ).


    IF ls_smap-status <> zif_mig_types=>gc_smap_ready
       OR ls_smap-manual_review = abap_true.

      block_result(
        EXPORTING
          iv_message = ls_smap-decision_reason
        CHANGING
          cs_result  = rs_result
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " 6. Resolve explicit output row mapping
    "==========================================================
    DATA(ls_row) =
      mo_row_resolver->resolve(
        is_bp   = ls_bp
        is_smap = ls_smap
      ).


    IF ls_row-status <> zif_mig_types=>gc_row_ready
       OR ls_row-manual_review = abap_true.

      block_result(
        EXPORTING
          iv_message = ls_row-decision_reason
        CHANGING
          cs_result  = rs_result
      ).

      RETURN.

    ENDIF.


    "Return the concrete UI issue before the generic boundary check.
    DATA(ls_ui_check) = NEW zcl_mig_ui_contract( )->build(
      is_bp = ls_bp is_smap = ls_smap ).
    READ TABLE ls_ui_check-issues WITH KEY severity = 'E' INTO DATA(ls_ui_issue).
    IF sy-subrc = 0.
      rs_result-block_count += 1.
      block_result( EXPORTING iv_message =
        |{ ls_ui_issue-code } ({ ls_ui_issue-target }): { ls_ui_issue-message }|
        CHANGING cs_result = rs_result ).
      RETURN.
    ENDIF.

    "Validate the source that will be generated before repository
    "preflight reports READY. This includes the released OData boundary
    "type policy, key, provider signature, filter and row mapping.
    TRY.

        NEW zcl_mig_xco_gen( )->validate_query_contract(
          is_bp   = ls_bp
          is_prv  = ls_prv
          is_sig  = ls_sig
          is_smap = ls_smap
          is_row  = ls_row
        ).

      CATCH zcx_mig_analysis.

        rs_result-block_count += 1.

        block_result(
          EXPORTING
            iv_message =
              'Generated query contract is not safe for the OData boundary. Check field type/length, key, filter and row mapping.'
          CHANGING
            cs_result = rs_result
        ).

        RETURN.

    ENDTRY.


    "==========================================================
    " 7. Build artifact plan and resolve supported XCO types
    "==========================================================
    DATA(ls_mfst) =
      mo_manifest->build(
        iv_package = is_request-package
        is_bp       = ls_bp
        is_prv      = ls_prv
        is_sig      = ls_sig
        is_smap     = ls_smap
        is_row      = ls_row
      ).

    "Choose the class target explicitly, independently of provider kind.
    ls_mfst-provider_language = is_request-provider_language.
    IF ls_mfst-provider_language IS INITIAL.
      ls_mfst-provider_language = zif_mig_prv_clas_gen=>gc_cloud.
    ENDIF.
    ls_mfst-provider_package = is_request-provider_package.
    IF ls_mfst-provider_package IS INITIAL
       AND ls_mfst-provider_language = zif_mig_prv_clas_gen=>gc_cloud.
      ls_mfst-provider_package = is_request-package.
    ENDIF.

    rs_result-provider_package = ls_mfst-provider_package.
    rs_result-provider_language = ls_mfst-provider_language.

    DATA(lv_target_error) = VALUE string( ).
    CASE ls_mfst-provider_language.
      WHEN zif_mig_prv_clas_gen=>gc_cloud.
        "Existing CP path. Cloud API release checks still occur at activation.
      WHEN zif_mig_prv_clas_gen=>gc_standard.
        IF ls_mfst-provider_package IS INITIAL.
          lv_target_error = 'STANDARD requires an explicit provider package.'.
        ELSEIF mo_provider_gen IS NOT BOUND.
          lv_target_error = 'Standard provider executor is not configured. Inject ZIF_MIG_PRV_CLAS_GEN from the composition root.'.
        ELSE.
          TRY.
              DATA(ls_target) = mo_provider_gen->check_target( ls_mfst-provider_package ).
              IF ls_target-allowed <> abap_true OR ls_target-language_code <> space.
                lv_target_error = ls_target-message.
                IF lv_target_error IS INITIAL.
                  lv_target_error = 'Provider package did not pass the Standard ABAP check.'.
                ENDIF.
              ENDIF.
            CATCH cx_root INTO DATA(lx_target).
              lv_target_error = |Standard provider executor check failed: { lx_target->get_text( ) }|.
          ENDTRY.
        ENDIF.
      WHEN OTHERS.
        lv_target_error = |Unsupported provider language: { ls_mfst-provider_language }. Use CLOUD or STANDARD.|.
    ENDCASE.

    IF lv_target_error IS NOT INITIAL.
      rs_result-block_count += 1.
      block_result( EXPORTING iv_message = lv_target_error CHANGING cs_result = rs_result ).
      RETURN.
    ENDIF.

    LOOP AT ls_mfst-items ASSIGNING FIELD-SYMBOL(<provider_item>)
      WHERE art_type = zif_mig_types=>gc_art_clas
        AND art_role = zif_mig_types=>gc_art_query_prv.
      <provider_item>-package = ls_mfst-provider_package.
    ENDLOOP.


    IF ls_mfst-status <> zif_mig_types=>gc_art_ready.

      block_result(
        EXPORTING
          iv_message = ls_mfst-decision_reason
        CHANGING
          cs_result  = rs_result
      ).

      RETURN.

    ENDIF.


    ls_mfst =
      NEW zcl_mig_art_cap( )->apply(
        is_mfst = ls_mfst
      ).


    "==========================================================
    " 8. Check package and repository object collisions
    "==========================================================
    DATA(ls_pref) =
      mo_preflight->apply(
        is_mfst = ls_mfst
      ).

    fill_artifact_names(
      EXPORTING
        is_mfst   = ls_pref
      CHANGING
        cs_result = rs_result
    ).

    rs_result-create_count =
      ls_pref-create_count.

    rs_result-block_count =
      ls_pref-block_count.


    IF ls_pref-status <> zif_mig_types=>gc_art_ready
       OR ls_pref-block_count > 0.

      block_result(
        EXPORTING
          iv_message = first_block_reason(
            is_mfst = ls_pref
          )
        CHANGING
          cs_result = rs_result
      ).

      RETURN.

    ENDIF.


    "The shared binding is updated by every successful generation.
    "Check its package up front so XCO cannot fail after the three
    "report-specific artifacts have already been activated.
    DATA(ls_binding_info) =
      mo_art_repo->read_info(
        iv_type = zif_mig_types=>gc_art_srvb
        iv_name = zcl_mig_svc_registry=>gc_shared_binding
      ).


    IF ls_binding_info-read_ok = abap_false.

      rs_result-block_count += 1.

      block_result(
        EXPORTING
          iv_message = ls_binding_info-reason
        CHANGING
          cs_result  = rs_result
      ).

      RETURN.

    ENDIF.


    IF ls_binding_info-exists = abap_true
       AND ls_binding_info-package <> is_request-package.

      rs_result-block_count += 1.

      block_result(
        EXPORTING
          iv_message =
            |Shared binding { rs_result-service_binding } exists in package { ls_binding_info-package }. Use that package for generation.|
        CHANGING
          cs_result = rs_result
      ).

      RETURN.

    ENDIF.


    IF ls_binding_info-exists = abap_false.
      rs_result-create_count += 1.
    ENDIF.


    "==========================================================
    " 9. Dry-run stops before any repository mutation
    "==========================================================
    IF is_request-execute = abap_false.

      rs_result-status =
        zif_mig_odata_gen_svc=>gc_status_ready.

      rs_result-manual_review =
        abap_false.

      rs_result-message =
        'Generation preflight passed. Execute can now create the OData V4 artifacts.'.

      RETURN.

    ENDIF.


    "==========================================================
    " 10. Execute repository generation after successful preflight
    "==========================================================
    mo_executor->execute_query(
      is_mfst      = ls_pref
      is_bp        = ls_bp
      is_prv       = ls_prv
      is_sig       = ls_sig
      is_smap      = ls_smap
      is_row       = ls_row
      iv_transport = is_request-transport
      io_provider_gen = mo_provider_gen
    ).


    rs_result-status =
      zif_mig_odata_gen_svc=>gc_status_generated.

    "The shared binding writer registers newly generated services as version 0001.
    "Return a same-origin path; publication and accessibility require a metadata check.
    DATA(lv_binding_name) = to_lower( CONV string( rs_result-service_binding ) ).
    DATA(lv_service_name) = to_lower( CONV string( rs_result-service_name ) ).
    CONDENSE lv_binding_name NO-GAPS.
    CONDENSE lv_service_name NO-GAPS.
    rs_result-service_url =
      |/sap/opu/odata4/sap/{ lv_binding_name }/srvd/sap/{ lv_service_name }/0001/|.

    rs_result-manual_review =
      abap_false.

    rs_result-message =
      'OData V4 repository artifacts were generated successfully.'.

  ENDMETHOD.


  METHOD block_result.

    cs_result-status =
      zif_mig_odata_gen_svc=>gc_status_blocked.

    cs_result-manual_review =
      abap_true.


    IF iv_message IS INITIAL.

      cs_result-message =
        'Generation requires manual review.'.

    ELSE.

      cs_result-message =
        iv_message.

    ENDIF.

  ENDMETHOD.


  METHOD fill_artifact_names.

    LOOP AT is_mfst-items
      INTO DATA(ls_item).

      CASE ls_item-art_role.

        WHEN zif_mig_types=>gc_art_query_prv.

          cs_result-query_provider_class =
            ls_item-object_name.


        WHEN zif_mig_types=>gc_art_entity.

          cs_result-entity_name =
            ls_item-object_name.


        WHEN zif_mig_types=>gc_art_srv_def.

          cs_result-service_name =
            ls_item-object_name.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.


  METHOD first_block_reason.

    rv_reason =
      is_mfst-decision_reason.


    LOOP AT is_mfst-items
      INTO DATA(ls_item)
      WHERE gen_state = zif_mig_types=>gc_art_blocked.

      IF ls_item-reason IS NOT INITIAL.

        rv_reason =
          |{ ls_item-object_name }: { ls_item-reason }|.

        RETURN.

      ENDIF.

    ENDLOOP.


    IF rv_reason IS INITIAL.

      rv_reason =
        'Artifact preflight blocked generation.'.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

