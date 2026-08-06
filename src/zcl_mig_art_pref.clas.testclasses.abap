CLASS lcl_art_repo DEFINITION
  FINAL.

  PUBLIC SECTION.

    INTERFACES zif_mig_art_repo.


    TYPES:
      tt_info_hash
        TYPE HASHED TABLE OF
          zif_mig_types=>ty_art_repo_info
        WITH UNIQUE KEY
          art_type
          object_name.


    DATA mt_info
      TYPE tt_info_hash.


    METHODS add_info
      IMPORTING
        is_info
          TYPE zif_mig_types=>ty_art_repo_info.

ENDCLASS.

CLASS lcl_art_repo IMPLEMENTATION.

  METHOD add_info.

    INSERT is_info
      INTO TABLE mt_info.

  ENDMETHOD.


  METHOD zif_mig_art_repo~read_info.

    CLEAR rs_info.

    rs_info-art_type =
      iv_type.

    rs_info-object_name =
      iv_name.

    rs_info-read_ok =
      abap_true.


    READ TABLE mt_info
      WITH TABLE KEY
        art_type =
          iv_type

        object_name =
          iv_name

      INTO DATA(ls_info).


    IF sy-subrc = 0.

      rs_info =
        ls_info.

      RETURN.

    ENDIF.


    rs_info-exists =
      abap_false.

  ENDMETHOD.


  METHOD zif_mig_art_repo~read_many.

    LOOP AT it_items
      INTO DATA(ls_item).

      DATA(ls_info) =
        zif_mig_art_repo~read_info(
          iv_type = ls_item-art_type
          iv_name = ls_item-object_name
        ).

      APPEND ls_info
        TO rt_info.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS ltc_art_pref DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS make_mfst
      RETURNING
        VALUE(rs_mfst)
          TYPE zif_mig_types=>ty_art_mfst.


    METHODS:
      new_objects_ready
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_existing
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_pkg_mismatch
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_unsupported
        FOR TESTING
        RAISING zcx_mig_analysis,

      keep_unready_mfst
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_dependency
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_art_pref IMPLEMENTATION.

  METHOD make_mfst.

    rs_mfst-analysis_id =
      '00000000000000000000000000000081'.

    rs_mfst-strategy =
      zif_mig_types=>gc_svc_query.

    rs_mfst-source_program =
      'ZRMIG_TEST_FULL'.

    rs_mfst-package =
      '$TMP'.

    rs_mfst-status =
      zif_mig_types=>gc_art_ready.


    APPEND VALUE #(
      seq         = 10
      art_type    = zif_mig_types=>gc_art_clas
      art_role    = zif_mig_types=>gc_art_query_prv
      object_name = 'ZCL_MIG_Q_TEST'
      package     = '$TMP'
      gen_order   = 10
      required    = abap_true
      cap_state   = zif_mig_types=>gc_art_cap_yes
      gen_state   = zif_mig_types=>gc_art_planned
      pref_state  = zif_mig_types=>gc_pref_unknown
      gen_mode    = zif_mig_types=>gc_art_no_mode
    ) TO rs_mfst-items.


    APPEND VALUE #(
      seq         = 20
      art_type    = zif_mig_types=>gc_art_ddls
      art_role    = zif_mig_types=>gc_art_entity
      object_name = 'ZC_MIG_TEST'
      package     = '$TMP'
      gen_order   = 20
      required    = abap_true
      cap_state   = zif_mig_types=>gc_art_cap_yes
      gen_state   = zif_mig_types=>gc_art_planned
      pref_state  = zif_mig_types=>gc_pref_unknown
      gen_mode    = zif_mig_types=>gc_art_no_mode
    ) TO rs_mfst-items.


    APPEND VALUE #(
      seq         = 30
      art_type    = zif_mig_types=>gc_art_srvd
      art_role    = zif_mig_types=>gc_art_srv_def
      object_name = 'ZUI_MIG_TEST'
      package     = '$TMP'
      gen_order   = 30
      required    = abap_true
      cap_state   = zif_mig_types=>gc_art_cap_yes
      gen_state   = zif_mig_types=>gc_art_planned
      pref_state  = zif_mig_types=>gc_pref_unknown
      gen_mode    = zif_mig_types=>gc_art_no_mode
    ) TO rs_mfst-items.


    APPEND VALUE #(
      art_seq = 20
      req_seq = 10
    ) TO rs_mfst-dependencies.


    APPEND VALUE #(
      art_seq = 30
      req_seq = 20
    ) TO rs_mfst-dependencies.


    rs_mfst-item_count =
      lines( rs_mfst-items ).

    rs_mfst-dep_count =
      lines( rs_mfst-dependencies ).

  ENDMETHOD.


  METHOD new_objects_ready.

    DATA(ls_result) =
      NEW zcl_mig_art_pref(
        io_repo = NEW lcl_art_repo( )
      )->zif_mig_art_pref~apply(
        is_mfst = make_mfst( )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_ready
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = ls_result-create_count
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = ls_result-block_count
    ).


    LOOP AT ls_result-items
      INTO DATA(ls_item).

      cl_abap_unit_assert=>assert_equals(
        exp = zif_mig_types=>gc_pref_new
        act = ls_item-pref_state
      ).

      cl_abap_unit_assert=>assert_equals(
        exp = zif_mig_types=>gc_art_create
        act = ls_item-gen_mode
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD block_existing.

    DATA(lo_repo) =
      NEW lcl_art_repo( ).

    lo_repo->add_info(
      VALUE #(
        art_type    = zif_mig_types=>gc_art_clas
        object_name = 'ZCL_MIG_Q_TEST'
        read_ok     = abap_true
        exists      = abap_true
        package     = '$TMP'
      )
    ).


    DATA(ls_result) =
      NEW zcl_mig_art_pref(
        io_repo = lo_repo
      )->zif_mig_art_pref~apply(
        is_mfst = make_mfst( )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_result-status
    ).


    READ TABLE ls_result-items
      WITH KEY seq = 10
      INTO DATA(ls_item).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_pref_exists
      act = ls_item-pref_state
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_blocked
      act = ls_item-gen_state
    ).

  ENDMETHOD.


  METHOD block_pkg_mismatch.

    DATA(lo_repo) =
      NEW lcl_art_repo( ).

    lo_repo->add_info(
      VALUE #(
        art_type    = zif_mig_types=>gc_art_clas
        object_name = 'ZCL_MIG_Q_TEST'
        read_ok     = abap_true
        exists      = abap_true
        package     = 'ZOTHER'
      )
    ).


    DATA(ls_result) =
      NEW zcl_mig_art_pref(
        io_repo = lo_repo
      )->zif_mig_art_pref~apply(
        is_mfst         = make_mfst( )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_result-status
    ).


    READ TABLE ls_result-items
      WITH KEY seq = 10
      INTO DATA(ls_item).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_pref_pkg_conf
      act = ls_item-pref_state
    ).

  ENDMETHOD.


  METHOD block_unsupported.

    DATA(ls_mfst) =
      make_mfst( ).

    ls_mfst-items[ seq = 20 ]-cap_state =
      zif_mig_types=>gc_art_cap_no.


    DATA(ls_result) =
      NEW zcl_mig_art_pref(
        io_repo = NEW lcl_art_repo( )
      )->zif_mig_art_pref~apply(
        is_mfst = ls_mfst
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_result-status
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_pref_unsup
      act = ls_result-items[ seq = 20 ]-pref_state
    ).

  ENDMETHOD.


  METHOD keep_unready_mfst.

    DATA(ls_mfst) =
      make_mfst( ).

    ls_mfst-status =
      zif_mig_types=>gc_art_review.

    ls_mfst-manual_review =
      abap_true.

    ls_mfst-decision_reason =
      'Manifest is not ready.'.


    DATA(ls_result) =
      NEW zcl_mig_art_pref(
        io_repo = NEW lcl_art_repo( )
      )->zif_mig_art_pref~apply(
        is_mfst = ls_mfst
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = ls_result-block_count
    ).

  ENDMETHOD.


  METHOD block_dependency.

    DATA(ls_mfst) =
      make_mfst( ).

    ls_mfst-items[ seq = 10 ]-required =
      abap_false.

    ls_mfst-items[ seq = 10 ]-cap_state =
      zif_mig_types=>gc_art_cap_no.


    DATA(ls_result) =
      NEW zcl_mig_art_pref(
        io_repo = NEW lcl_art_repo( )
      )->zif_mig_art_pref~apply(
        is_mfst = ls_mfst
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_pref_dep_block
      act = ls_result-items[ seq = 20 ]-pref_state
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_art_blocked
      act = ls_result-items[ seq = 30 ]-gen_state
    ).

  ENDMETHOD.

ENDCLASS.
