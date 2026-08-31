CLASS zcl_mig_xco_executor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_xco_executor.

ENDCLASS.


CLASS zcl_mig_xco_executor IMPLEMENTATION.

  METHOD zif_mig_xco_executor~execute_query.

    DATA(lo_registry) =
      NEW zcl_mig_svc_registry( ).


    DATA(lt_shared_services) =
      lo_registry->read_all( ).


    NEW zcl_mig_xco_gen( )->generate_query(
      is_mfst           = is_mfst
      is_bp             = is_bp
      is_prv            = is_prv
      is_sig            = is_sig
      is_smap           = is_smap
      is_row            = is_row
      it_shared_services = lt_shared_services
      iv_request        = iv_transport
      iv_execute        = abap_true
    ).


    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_srvd
        art_role = zif_mig_types=>gc_art_srv_def
      INTO DATA(ls_srvd).

    IF sy-subrc <> 0
       OR ls_srvd-object_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        program_name = is_mfst-source_program
      ).

    ENDIF.


    lo_registry->upsert(
      iv_service_name = ls_srvd-object_name
      iv_srvd_name    = ls_srvd-object_name
      iv_version      = 1
    ).

  ENDMETHOD.

ENDCLASS.

