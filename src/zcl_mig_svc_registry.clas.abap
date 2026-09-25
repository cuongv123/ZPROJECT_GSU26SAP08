CLASS zcl_mig_svc_registry DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS gc_shared_binding
      TYPE zif_mig_types=>ty_art_name
      VALUE 'ZUI_MIG_SHARED_O4'.

    METHODS read_all
      IMPORTING
        iv_binding_name TYPE zif_mig_types=>ty_art_name
          DEFAULT gc_shared_binding
      RETURNING
        VALUE(rt_services) TYPE zif_mig_types=>tt_shared_service
      RAISING
        zcx_mig_analysis.

    METHODS find_by_analysis
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
      RETURNING
        VALUE(rs_result) TYPE zif_mig_odata_gen_svc=>ty_result
      RAISING
        zcx_mig_analysis.

    METHODS upsert
      IMPORTING
        iv_binding_name TYPE zif_mig_types=>ty_art_name
          DEFAULT gc_shared_binding
        iv_service_name TYPE zif_mig_types=>ty_art_name
        iv_srvd_name TYPE zif_mig_types=>ty_art_name
        iv_version TYPE i DEFAULT 1
        iv_analysis_id TYPE sysuuid_x16 OPTIONAL
        iv_source_program TYPE progname OPTIONAL
        iv_target_package TYPE devclass OPTIONAL
        iv_entity_name TYPE zif_mig_types=>ty_art_name OPTIONAL
        iv_query_provider_class TYPE seoclsname OPTIONAL
      RAISING
        zcx_mig_analysis.

  PRIVATE SECTION.

    METHODS make_service_name
      IMPORTING
        iv_source_program TYPE progname
      RETURNING
        VALUE(rv_service_name) TYPE zif_mig_types=>ty_art_name.

    METHODS build_service_root
      IMPORTING
        iv_binding_name TYPE zif_mig_types=>ty_art_name
        iv_service_name TYPE zif_mig_types=>ty_art_name
        iv_version TYPE i
      RETURNING
        VALUE(rv_service_root) TYPE string.

ENDCLASS.


CLASS zcl_mig_svc_registry IMPLEMENTATION.

  METHOD read_all.

    DATA(lv_binding_name) =
      to_upper( CONV string( iv_binding_name ) ).
    CONDENSE lv_binding_name NO-GAPS.

    IF lv_binding_name IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed ).
    ENDIF.

    TRY.
        SELECT
          FROM zmig_svc_reg
          FIELDS
            service_name,
            srvd_name,
            service_version AS version
          WHERE binding_name = @lv_binding_name
          ORDER BY service_name, service_version
          INTO CORRESPONDING FIELDS OF TABLE @rt_services.
      CATCH cx_sy_open_sql_db.
        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid = zcx_mig_analysis=>analysis_failed ).
    ENDTRY.

  ENDMETHOD.


  METHOD find_by_analysis.

    CLEAR rs_result.

    IF iv_analysis_id IS INITIAL.
      RETURN.
    ENDIF.

    DATA ls_registry TYPE zmig_svc_reg.
    DATA lv_source_program TYPE progname.
    DATA lv_source_hash TYPE c LENGTH 64.
    DATA(lv_shared_binding) = gc_shared_binding.

    TRY.
        SELECT SINGLE program_name, source_hash
          FROM zmig_anl_h
          WHERE analysis_id = @iv_analysis_id
          INTO (@lv_source_program, @lv_source_hash).

        SELECT SINGLE *
          FROM zmig_svc_reg
          WHERE analysis_id = @iv_analysis_id
          INTO @ls_registry.

        IF ls_registry IS INITIAL
           AND lv_source_program IS NOT INITIAL.

          DATA(lv_legacy_service_name) =
            make_service_name( lv_source_program ).

          SELECT SINGLE *
            FROM zmig_svc_reg
            WHERE binding_name = @lv_shared_binding
              AND service_name = @lv_legacy_service_name
            INTO @ls_registry.
        ENDIF.

      CATCH cx_sy_open_sql_db.
        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid = zcx_mig_analysis=>analysis_failed ).
    ENDTRY.

    IF ls_registry IS INITIAL.
      RETURN.
    ENDIF.

    rs_result-analysis_id = iv_analysis_id.
    rs_result-status = zif_mig_odata_gen_svc=>gc_status_generated.
    rs_result-manual_review = abap_false.
    rs_result-query_provider_class = ls_registry-query_provider_class.
    rs_result-entity_name = ls_registry-entity_name.
    rs_result-service_name = ls_registry-service_name.
    rs_result-service_binding = ls_registry-binding_name.
    rs_result-service_url = build_service_root(
      iv_binding_name = ls_registry-binding_name
      iv_service_name = ls_registry-service_name
      iv_version = ls_registry-service_version ).
    rs_result-message =
      'Existing OData V4 deployment found. Reuse this Service Root URL.'.

    IF ls_registry-status = zif_mig_odata_gen_svc=>gc_status_stale
       OR ( ls_registry-source_hash IS NOT INITIAL
            AND lv_source_hash IS NOT INITIAL
            AND ls_registry-source_hash <> lv_source_hash ).

      rs_result-status = zif_mig_odata_gen_svc=>gc_status_stale.
      rs_result-manual_review = abap_true.
      rs_result-message =
        'An OData deployment exists, but its source hash differs. Review it; automatic regeneration is blocked.'.
    ENDIF.

  ENDMETHOD.


  METHOD upsert.

    DATA(lv_binding_name) =
      to_upper( CONV string( iv_binding_name ) ).
    CONDENSE lv_binding_name NO-GAPS.

    DATA(lv_service_name) =
      to_upper( CONV string( iv_service_name ) ).
    CONDENSE lv_service_name NO-GAPS.

    DATA(lv_srvd_name) =
      to_upper( CONV string( iv_srvd_name ) ).
    CONDENSE lv_srvd_name NO-GAPS.

    DATA(lv_version) = iv_version.
    IF lv_version <= 0.
      lv_version = 1.
    ENDIF.

    IF lv_binding_name IS INITIAL
       OR lv_service_name IS INITIAL
       OR lv_srvd_name IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed ).
    ENDIF.

    DATA ls_registry TYPE zmig_svc_reg.
    DATA lv_source_hash TYPE c LENGTH 64.

    TRY.
        SELECT SINGLE *
          FROM zmig_svc_reg
          WHERE binding_name = @lv_binding_name
            AND service_name = @lv_service_name
          INTO @ls_registry.

        IF iv_analysis_id IS NOT INITIAL.
          SELECT SINGLE source_hash
            FROM zmig_anl_h
            WHERE analysis_id = @iv_analysis_id
            INTO @lv_source_hash.
        ENDIF.

        ls_registry-client = sy-mandt.
        ls_registry-binding_name = lv_binding_name.
        ls_registry-service_name = lv_service_name.
        ls_registry-srvd_name = lv_srvd_name.
        ls_registry-service_version = lv_version.

        IF iv_analysis_id IS NOT INITIAL.
          ls_registry-analysis_id = iv_analysis_id.
          ls_registry-source_hash = lv_source_hash.
        ENDIF.

        IF iv_source_program IS NOT INITIAL.
          ls_registry-source_program = iv_source_program.
        ENDIF.

        IF iv_target_package IS NOT INITIAL.
          ls_registry-target_package = iv_target_package.
        ENDIF.

        IF iv_entity_name IS NOT INITIAL.
          ls_registry-entity_name = iv_entity_name.
        ENDIF.

        IF iv_query_provider_class IS NOT INITIAL.
          ls_registry-query_provider_class = iv_query_provider_class.
        ENDIF.

        ls_registry-status =
          zif_mig_odata_gen_svc=>gc_status_generated.
        ls_registry-generated_by = sy-uname.
        GET TIME STAMP FIELD ls_registry-generated_at.

        MODIFY zmig_svc_reg FROM @ls_registry.

        IF sy-subrc <> 0.
          RAISE EXCEPTION NEW zcx_mig_analysis(
            textid = zcx_mig_analysis=>analysis_failed ).
        ENDIF.

      CATCH cx_sy_open_sql_db.
        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid = zcx_mig_analysis=>analysis_failed ).
    ENDTRY.

  ENDMETHOD.


  METHOD make_service_name.

    DATA(lv_base) = to_upper( CONV string( iv_source_program ) ).
    CONDENSE lv_base NO-GAPS.

    REPLACE ALL OCCURRENCES OF '/' IN lv_base WITH '_'.
    REPLACE ALL OCCURRENCES OF '\' IN lv_base WITH '_'.
    REPLACE ALL OCCURRENCES OF '-' IN lv_base WITH '_'.
    REPLACE ALL OCCURRENCES OF '.' IN lv_base WITH '_'.

    IF lv_base IS INITIAL.
      lv_base = 'REPORT'.
    ENDIF.

    IF strlen( lv_base ) > 22.
      lv_base = substring( val = lv_base len = 22 ).
    ENDIF.

    rv_service_name = |ZUI_MIG_{ lv_base }|.

  ENDMETHOD.


  METHOD build_service_root.

    DATA(lv_binding_name) =
      to_lower( CONV string( iv_binding_name ) ).
    DATA(lv_service_name) =
      to_lower( CONV string( iv_service_name ) ).
    DATA(lv_version) = iv_version.

    CONDENSE lv_binding_name NO-GAPS.
    CONDENSE lv_service_name NO-GAPS.

    IF lv_version <= 0.
      lv_version = 1.
    ENDIF.

    DATA(lv_version_text) =
      |{ lv_version ALIGN = RIGHT WIDTH = 4 PAD = '0' }|.

    rv_service_root =
      |/sap/opu/odata4/sap/{ lv_binding_name }/srvd/sap/{ lv_service_name }/{ lv_version_text }/|.

  ENDMETHOD.

ENDCLASS.
