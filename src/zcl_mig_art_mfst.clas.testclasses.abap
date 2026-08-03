CLASS ltc_art_mfst DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS:
      gc_anl_id TYPE zif_mig_types=>ty_analysis_id
        VALUE '00000000000000000000000000000061',

      gc_item_id TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000062'.


    METHODS make_bp
      IMPORTING
        iv_strategy
          TYPE zif_mig_types=>ty_service_strategy
      RETURNING
        VALUE(rs_bp)
          TYPE zif_mig_types=>ty_service_blueprint_result.


    METHODS make_prv
      IMPORTING
        iv_strategy
          TYPE zif_mig_types=>ty_service_strategy
      RETURNING
        VALUE(rs_prv)
          TYPE zif_mig_types=>ty_provider_contract.


    METHODS make_sig
      IMPORTING
        iv_strategy
          TYPE zif_mig_types=>ty_service_strategy
      RETURNING
        VALUE(rs_sig)
          TYPE zif_mig_types=>ty_sig_result.


    METHODS make_smap
      RETURNING
        VALUE(rs_map)
          TYPE zif_mig_types=>ty_svc_map_result.


    METHODS make_row
      RETURNING
        VALUE(rs_row)
          TYPE zif_mig_types=>ty_row_result.


    METHODS:
      build_query_mfst
        FOR TESTING
        RAISING zcx_mig_analysis,

      build_action_mfst
        FOR TESTING
        RAISING zcx_mig_analysis,

      check_query_deps
        FOR TESTING
        RAISING zcx_mig_analysis,

      trim_long_names
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_bad_sig
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_bad_map
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_bad_row
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_manual_bp
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_no_package
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_art_mfst IMPLEMENTATION.

  METHOD make_bp.

    rs_bp-blueprint-analysis_id =
      gc_anl_id.

    rs_bp-blueprint-source_program =
      'ZRMIG_TEST_FULL'.

    rs_bp-blueprint-strategy =
      iv_strategy.


    APPEND VALUE #(
      source_item_id = gc_item_id
      field_name     = 'BUKRS'
      label          = 'Company Code'
      edm_type       = 'Edm.String'
      position       = 1
      visible        = abap_true
    ) TO rs_bp-fields.

  ENDMETHOD.


  METHOD make_prv.

    rs_prv-analysis_id =
      gc_anl_id.

    rs_prv-service_strategy =
      iv_strategy.

    rs_prv-provider_kind =
      zif_mig_types=>gc_provider_function.

    rs_prv-provider_status =
      zif_mig_types=>gc_provider_signature.


    IF iv_strategy =
         zif_mig_types=>gc_svc_query.

      rs_prv-proposed_class_name =
        'ZCL_MIG_Q_ZRMIG_TEST'.

      rs_prv-proposed_method_name =
        'GET_DATA'.

    ELSE.

      rs_prv-proposed_class_name =
        'ZCL_MIG_A_ZRMIG_TEST'.

      rs_prv-proposed_method_name =
        'EXECUTE'.

    ENDIF.

  ENDMETHOD.


  METHOD make_sig.

    rs_sig-analysis_id =
      gc_anl_id.

    rs_sig-service_strategy =
      iv_strategy.

    rs_sig-provider_kind =
      zif_mig_types=>gc_provider_function.

    rs_sig-status =
      zif_mig_types=>gc_sig_ready.

  ENDMETHOD.


  METHOD make_smap.

    rs_map-analysis_id =
      gc_anl_id.

    rs_map-status =
      zif_mig_types=>gc_smap_ready.

    rs_map-manual_review =
      abap_false.

    rs_map-selected_out-par_name =
      'ET_RESULT'.

    rs_map-selected_out-direction =
      zif_mig_types=>gc_sig_exp.

    rs_map-selected_out-type_name =
      'BAPIRET2_T'.

    rs_map-selected_out-edm_type =
      'Collection'.

    rs_map-selected_out-is_table =
      abap_true.

  ENDMETHOD.


  METHOD make_row.

    rs_row-analysis_id =
      gc_anl_id.

    rs_row-status =
      zif_mig_types=>gc_row_ready.

    rs_row-manual_review =
      abap_false.

    rs_row-output_name =
      'ET_RESULT'.

    rs_row-row_type =
      'BAPIRET2'.

  ENDMETHOD.


  METHOD build_query_mfst.

    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_smap =
            make_smap( )

          is_row =
            make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_ready
      act = ls_mfst-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 5
      act = ls_mfst-item_count
    ).


    READ TABLE ls_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_clas
        art_role = zif_mig_types=>gc_art_query_prv
      INTO DATA(ls_class).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZCL_MIG_Q_ZRMIG_TEST'
      act = ls_class-object_name
    ).

  ENDMETHOD.


  METHOD build_action_mfst.

    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_action
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_action
            )

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_action
            )

          is_smap =
            make_smap( )

          is_row =
            make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_ready
      act = ls_mfst-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 9
      act = ls_mfst-item_count
    ).


    DATA lv_bdef_count TYPE i.
    DATA lv_clas_count TYPE i.

    LOOP AT ls_mfst-items
      INTO DATA(ls_item).

      IF ls_item-art_type =
           zif_mig_types=>gc_art_bdef.

        lv_bdef_count += 1.

      ENDIF.

      IF ls_item-art_type =
           zif_mig_types=>gc_art_clas.

        lv_clas_count += 1.

      ENDIF.

    ENDLOOP.


    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lv_bdef_count
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lv_clas_count
    ).

  ENDMETHOD.


  METHOD check_query_deps.

    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_smap =
            make_smap( )

          is_row =
            make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = 4
      act = ls_mfst-dep_count
    ).


    READ TABLE ls_mfst-dependencies
      WITH KEY
        art_seq = 50
        req_seq = 40
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Service binding dependency is missing'
    ).

  ENDMETHOD.


  METHOD trim_long_names.

    DATA(ls_bp) =
      make_bp(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).

    ls_bp-blueprint-source_program =
      'ZVERY_LONG_REPORT_NAME_FOR_MIGRATION_01'.


    DATA(ls_prv) =
      make_prv(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).

    CLEAR ls_prv-proposed_class_name.


    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'
          is_bp       = ls_bp
          is_prv      = ls_prv

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_smap =
            make_smap( )

          is_row =
            make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_ready
      act = ls_mfst-status
    ).


    LOOP AT ls_mfst-items
      INTO DATA(ls_item).

      cl_abap_unit_assert=>assert_bound(
        act = REF #( ls_item )
      ).

      cl_abap_unit_assert=>assert_not_initial(
        act = ls_item-object_name
      ).

      cl_abap_unit_assert=>assert_true(
        act =
          xsdbool(
            strlen(
              CONV string(
                ls_item-object_name
              )
            ) <= 30
          )
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD block_bad_sig.

    DATA(ls_sig) =
      make_sig(
        iv_strategy =
          zif_mig_types=>gc_svc_query
      ).

    ls_sig-status =
      zif_mig_types=>gc_sig_review.


    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_sig  = ls_sig
          is_smap = make_smap( )
          is_row  = make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_mfst-status
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_mfst-items
    ).

  ENDMETHOD.


  METHOD block_bad_map.

    DATA(ls_map) =
      make_smap( ).

    ls_map-status =
      zif_mig_types=>gc_smap_review.


    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_smap = ls_map
          is_row  = make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_mfst-status
    ).

  ENDMETHOD.


  METHOD block_bad_row.

    DATA(ls_row) =
      make_row( ).

    ls_row-status =
      zif_mig_types=>gc_row_review.


    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_smap = make_smap( )
          is_row  = ls_row
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_mfst-status
    ).

  ENDMETHOD.


  METHOD block_manual_bp.

    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = '$TMP'

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_manual
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_manual
            )

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_manual
            )

          is_smap =
            make_smap( )

          is_row =
            make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_mfst-status
    ).

  ENDMETHOD.


  METHOD block_no_package.

    DATA(ls_mfst) =
      NEW zcl_mig_art_mfst(
        )->zif_mig_art_mfst~build(
          iv_package = ''

          is_bp =
            make_bp(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_prv =
            make_prv(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_sig =
            make_sig(
              iv_strategy =
                zif_mig_types=>gc_svc_query
            )

          is_smap =
            make_smap( )

          is_row =
            make_row( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_mfst-status
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_mfst-items
    ).

  ENDMETHOD.

ENDCLASS.
