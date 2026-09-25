CLASS zcl_mig_xco_executor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_xco_executor.

ENDCLASS.


CLASS zcl_mig_xco_executor IMPLEMENTATION.

  METHOD zif_mig_xco_executor~execute_query.

    DATA(lo_registry) = NEW zcl_mig_svc_registry( ).
    DATA(lt_shared_services) = lo_registry->read_all( ).

    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_srvd
        art_role = zif_mig_types=>gc_art_srv_def
      INTO DATA(ls_srvd).

    IF sy-subrc <> 0 OR ls_srvd-object_name IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
        program_name = is_mfst-source_program ).
    ENDIF.

    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_clas
        art_role = zif_mig_types=>gc_art_query_prv
      INTO DATA(ls_query_provider).

    IF sy-subrc <> 0 OR ls_query_provider-object_name IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
        program_name = is_mfst-source_program ).
    ENDIF.

    NEW zcl_mig_xco_gen( )->generate_query(
      is_mfst            = is_mfst
      is_bp              = is_bp
      is_prv             = is_prv
      is_sig             = is_sig
      is_smap            = is_smap
      is_row             = is_row
      it_shared_services = lt_shared_services
      iv_request         = iv_transport
      iv_execute         = abap_true
      io_provider_gen    = io_provider_gen
    ).

    TRY.
        lo_registry->upsert(
          iv_service_name = ls_srvd-object_name
          iv_srvd_name = ls_srvd-object_name
          iv_version = 1
          iv_analysis_id = is_mfst-analysis_id
          iv_source_program = is_mfst-source_program
          iv_target_package = is_mfst-package
          iv_entity_name = is_bp-blueprint-entity_name
          iv_query_provider_class = ls_query_provider-object_name
        ).
      CATCH zcx_mig_analysis INTO DATA(lx_registry).
        RAISE EXCEPTION NEW zcx_mig_generation(
          iv_detail = |Artifacts and binding for { ls_srvd-object_name } were generated, but registry update failed: { lx_registry->get_text( ) }. Review the objects before retrying.|
          previous = lx_registry ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
