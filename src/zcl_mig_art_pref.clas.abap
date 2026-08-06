CLASS zcl_mig_art_pref DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_art_pref.

    METHODS constructor
      IMPORTING
        io_repo TYPE REF TO zif_mig_art_repo.

  PRIVATE SECTION.

    DATA mo_repo
      TYPE REF TO zif_mig_art_repo.

    TYPES:
      tt_info_hash TYPE HASHED TABLE OF zif_mig_types=>ty_art_repo_info
        WITH UNIQUE KEY
          art_type
          object_name.


    METHODS check_items
      IMPORTING
        it_info
          TYPE zif_mig_types=>tt_art_repo_info

      CHANGING
        cs_mfst
          TYPE zif_mig_types=>ty_art_mfst.


    METHODS check_deps
      CHANGING
        cs_mfst TYPE zif_mig_types=>ty_art_mfst.


    METHODS set_status
      CHANGING
        cs_mfst TYPE zif_mig_types=>ty_art_mfst.


    METHODS block_all
      IMPORTING
        VALUE(iv_reason) TYPE string
      CHANGING
        cs_mfst TYPE zif_mig_types=>ty_art_mfst.

ENDCLASS.

CLASS zcl_mig_art_pref IMPLEMENTATION.

  METHOD constructor.

    mo_repo = io_repo.

  ENDMETHOD.

  METHOD zif_mig_art_pref~apply.

  rs_mfst = is_mfst.


  IF rs_mfst-status <>
       zif_mig_types=>gc_art_ready.

    DATA(lv_reason) =
      rs_mfst-decision_reason.

    IF lv_reason IS INITIAL.

      lv_reason =
        'Artifact manifest is not ready for preflight.'.

    ENDIF.


    block_all(
      EXPORTING
        iv_reason = lv_reason
      CHANGING
        cs_mfst   = rs_mfst
    ).

    RETURN.

  ENDIF.


  IF mo_repo IS NOT BOUND.

    block_all(
      EXPORTING
        iv_reason =
          'Artifact repository adapter is not available.'
      CHANGING
        cs_mfst =
          rs_mfst
    ).

    RETURN.

  ENDIF.


  DATA lt_info
    TYPE zif_mig_types=>tt_art_repo_info.


  TRY.

      lt_info =
        mo_repo->read_many(
          it_items = rs_mfst-items
        ).

    CATCH zcx_mig_analysis INTO DATA(lx_repo).

      block_all(
        EXPORTING
          iv_reason =
            lx_repo->get_text( )
        CHANGING
          cs_mfst =
            rs_mfst
      ).

      RETURN.

  ENDTRY.


  check_items(
      EXPORTING
        it_info = lt_info
      CHANGING
        cs_mfst = rs_mfst
    ).


  check_deps(
    CHANGING
      cs_mfst = rs_mfst
  ).


  set_status(
    CHANGING
      cs_mfst = rs_mfst
  ).

ENDMETHOD.


  METHOD check_items.

  DATA lt_info_hash
    TYPE tt_info_hash.


  INSERT LINES OF it_info
    INTO TABLE lt_info_hash.


  LOOP AT cs_mfst-items
    ASSIGNING FIELD-SYMBOL(<item>).

    CLEAR:
      <item>-object_exists,
      <item>-current_package.

    <item>-pref_state =
      zif_mig_types=>gc_pref_unknown.

    <item>-gen_mode =
      zif_mig_types=>gc_art_no_mode.


    "==========================================================
    " XCO capability
    "==========================================================
    IF <item>-cap_state <>
         zif_mig_types=>gc_art_cap_yes.

      <item>-pref_state =
        zif_mig_types=>gc_pref_unsup.

      <item>-gen_state =
        zif_mig_types=>gc_art_blocked.

      <item>-reason =
        'XCO generation API is unsupported.'.

      CONTINUE.

    ENDIF.


    "==========================================================
    " Lấy thông tin đã được đọc hàng loạt
    "==========================================================
    READ TABLE lt_info_hash
      WITH TABLE KEY
        art_type =
          <item>-art_type

        object_name =
          <item>-object_name

      INTO DATA(ls_info).


    IF sy-subrc <> 0.

      <item>-pref_state =
        zif_mig_types=>gc_pref_repo_err.

      <item>-gen_state =
        zif_mig_types=>gc_art_blocked.

      <item>-reason =
        'Repository adapter returned no object state.'.

      CONTINUE.

    ENDIF.


    IF ls_info-read_ok = abap_false.

      <item>-pref_state =
        zif_mig_types=>gc_pref_repo_err.

      <item>-gen_state =
        zif_mig_types=>gc_art_blocked.

      IF ls_info-reason IS INITIAL.

        <item>-reason =
          'Repository object state could not be read.'.

      ELSE.

        <item>-reason =
          ls_info-reason.

      ENDIF.

      CONTINUE.

    ENDIF.


    <item>-object_exists =
      ls_info-exists.

    <item>-current_package =
      ls_info-package.


    "==========================================================
    " Object chưa tồn tại
    "==========================================================
    IF ls_info-exists = abap_false.

      <item>-pref_state =
        zif_mig_types=>gc_pref_new.

      <item>-gen_mode =
        zif_mig_types=>gc_art_create.

      <item>-gen_state =
        zif_mig_types=>gc_art_planned.

      <item>-reason =
        'Repository object will be created.'.

      CONTINUE.

    ENDIF.


    "==========================================================
    " Object tồn tại nhưng package không xác định
    "==========================================================
    IF ls_info-package IS INITIAL.

      <item>-pref_state =
        zif_mig_types=>gc_pref_repo_err.

      <item>-gen_state =
        zif_mig_types=>gc_art_blocked.

      <item>-reason =
        'Existing object package could not be resolved.'.

      CONTINUE.

    ENDIF.


    "==========================================================
    " Object tồn tại ở package khác
    "==========================================================
    IF ls_info-package <> <item>-package.

      <item>-pref_state =
        zif_mig_types=>gc_pref_pkg_conf.

      <item>-gen_state =
        zif_mig_types=>gc_art_blocked.

      <item>-reason =
        'Repository object exists in another package.'.

      CONTINUE.

    ENDIF.

   <item>-pref_state =
      zif_mig_types=>gc_pref_exists.

    <item>-gen_mode =
      zif_mig_types=>gc_art_no_mode.

    <item>-gen_state =
      zif_mig_types=>gc_art_blocked.

    <item>-reason =
      'Repository object already exists.'.

  ENDLOOP.

ENDMETHOD.


  METHOD check_deps.

    LOOP AT cs_mfst-dependencies
      INTO DATA(ls_dep).

      DATA lv_dep_blocked
        TYPE abap_bool.

      lv_dep_blocked =
        abap_false.


      READ TABLE cs_mfst-items
        WITH KEY seq = ls_dep-req_seq
        INTO DATA(ls_required).


      IF sy-subrc <> 0
         OR ls_required-gen_state =
              zif_mig_types=>gc_art_blocked.

        lv_dep_blocked =
          abap_true.

      ENDIF.


      IF lv_dep_blocked = abap_false.
        CONTINUE.
      ENDIF.


      READ TABLE cs_mfst-items
        WITH KEY seq = ls_dep-art_seq
        ASSIGNING FIELD-SYMBOL(<dependent>).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.


      IF <dependent>-gen_state =
           zif_mig_types=>gc_art_blocked.

        CONTINUE.

      ENDIF.


      <dependent>-pref_state =
        zif_mig_types=>gc_pref_dep_block.

      <dependent>-gen_mode =
        zif_mig_types=>gc_art_no_mode.

      <dependent>-gen_state =
        zif_mig_types=>gc_art_blocked.

      <dependent>-reason =
        'Required artifact dependency is blocked.'.

    ENDLOOP.

  ENDMETHOD.


  METHOD set_status.

    CLEAR:
      cs_mfst-create_count,
      cs_mfst-block_count.


    DATA lv_req_fail TYPE i.

    CLEAR lv_req_fail.


    LOOP AT cs_mfst-items
      INTO DATA(ls_item).

      CASE ls_item-gen_mode.

        WHEN zif_mig_types=>gc_art_create.

          cs_mfst-create_count += 1.


      ENDCASE.


      IF ls_item-gen_state =
           zif_mig_types=>gc_art_blocked.

        cs_mfst-block_count += 1.

        IF ls_item-required = abap_true.

          lv_req_fail += 1.

        ENDIF.

      ENDIF.

    ENDLOOP.


    cs_mfst-item_count =
      lines( cs_mfst-items ).

    cs_mfst-dep_count =
      lines( cs_mfst-dependencies ).


    IF lv_req_fail = 0.

      cs_mfst-status =
        zif_mig_types=>gc_art_ready.

      cs_mfst-manual_review =
        abap_false.

      cs_mfst-decision_reason =
        'Artifact repository preflight passed.'.

    ELSE.

      cs_mfst-status =
        zif_mig_types=>gc_art_review.

      cs_mfst-manual_review =
        abap_true.

      cs_mfst-decision_reason =
        'One or more required artifacts are blocked.'.

    ENDIF.

  ENDMETHOD.


  METHOD block_all.

    LOOP AT cs_mfst-items
      ASSIGNING FIELD-SYMBOL(<item>).

      IF <item>-pref_state IS INITIAL
         OR <item>-pref_state =
              zif_mig_types=>gc_pref_unknown.

        <item>-pref_state =
          zif_mig_types=>gc_pref_blocked.

      ENDIF.


      <item>-gen_mode =
        zif_mig_types=>gc_art_no_mode.

      <item>-gen_state =
        zif_mig_types=>gc_art_blocked.

      <item>-reason =
        iv_reason.

    ENDLOOP.


    cs_mfst-status =
      zif_mig_types=>gc_art_review.

    cs_mfst-manual_review =
      abap_true.

    cs_mfst-decision_reason =
      iv_reason.

    cs_mfst-create_count =
      0.


    cs_mfst-block_count =
      lines( cs_mfst-items ).

    cs_mfst-item_count =
      lines( cs_mfst-items ).

    cs_mfst-dep_count =
      lines( cs_mfst-dependencies ).

  ENDMETHOD.

ENDCLASS.
