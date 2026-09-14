CLASS ltc_mig_art_cap DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS supports_query_artifacts FOR TESTING.
    METHODS rejects_action_artifacts FOR TESTING.

ENDCLASS.


CLASS ltc_mig_art_cap IMPLEMENTATION.

  METHOD supports_query_artifacts.

    DATA(ls_mfst) =
      VALUE zif_mig_types=>ty_art_mfst(
        strategy = zif_mig_types=>gc_svc_query
        items = VALUE #(
          ( art_type = zif_mig_types=>gc_art_clas
            art_role = zif_mig_types=>gc_art_query_prv )
          ( art_type = zif_mig_types=>gc_art_ddls
            art_role = zif_mig_types=>gc_art_entity )
          ( art_type = zif_mig_types=>gc_art_srvd
            art_role = zif_mig_types=>gc_art_srv_def ) )
      ).


    DATA(ls_result) =
      NEW zcl_mig_art_cap( )->apply(
        is_mfst = ls_mfst
      ).


    LOOP AT ls_result-items
      INTO DATA(ls_item).

      cl_abap_unit_assert=>assert_equals(
        exp = zif_mig_types=>gc_art_cap_yes
        act = ls_item-cap_state
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD rejects_action_artifacts.

    DATA(ls_mfst) =
      VALUE zif_mig_types=>ty_art_mfst(
        strategy = zif_mig_types=>gc_svc_action
        items = VALUE #(
          ( art_type = zif_mig_types=>gc_art_bdef
            art_role = zif_mig_types=>gc_art_bdef_root ) )
      ).


    DATA(ls_result) =
      NEW zcl_mig_art_cap( )->apply(
        is_mfst = ls_mfst
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_cap_no
      act = ls_result-items[ 1 ]-cap_state
    ).

  ENDMETHOD.

ENDCLASS.
