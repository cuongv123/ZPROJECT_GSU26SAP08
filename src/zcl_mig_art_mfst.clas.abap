CLASS zcl_mig_art_mfst DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_art_mfst.

  PRIVATE SECTION.

    TYPES:
      ty_base_name TYPE c LENGTH 40,
      ty_art_desc  TYPE c LENGTH 120.
    METHODS build_query
      IMPORTING
        is_prv TYPE zif_mig_types=>ty_provider_contract
      CHANGING
        cs_mfst TYPE zif_mig_types=>ty_art_mfst.


    METHODS build_action
      IMPORTING
        is_prv TYPE zif_mig_types=>ty_provider_contract
      CHANGING
        cs_mfst TYPE zif_mig_types=>ty_art_mfst.


    METHODS add_art
      IMPORTING
        iv_seq     TYPE i
        iv_type    TYPE zif_mig_types=>ty_art_type
        iv_role    TYPE zif_mig_types=>ty_art_role
        iv_name    TYPE zif_mig_types=>ty_art_name
        iv_package TYPE devclass
        iv_desc    TYPE ty_art_desc
        iv_order   TYPE i
        iv_req     TYPE abap_bool DEFAULT abap_true
      CHANGING
        ct_items TYPE zif_mig_types=>tt_art_item.


    METHODS add_dep
      IMPORTING
        iv_art_seq TYPE i
        iv_req_seq TYPE i
      CHANGING
        ct_deps TYPE zif_mig_types=>tt_art_dep.


    METHODS make_base
      IMPORTING
        iv_program TYPE progname
      RETURNING
        VALUE(rv_base) TYPE ty_base_name.


    METHODS make_name
      IMPORTING
        VALUE(iv_prefix) TYPE string
        VALUE(iv_base)   TYPE ty_base_name
        VALUE(iv_suffix) TYPE string OPTIONAL
      RETURNING
        VALUE(rv_name)
          TYPE zif_mig_types=>ty_art_name.


    METHODS set_status
      CHANGING
        cs_mfst TYPE zif_mig_types=>ty_art_mfst.


    METHODS block_mfst
      IMPORTING
        VALUE(iv_reason) TYPE string
      CHANGING
        cs_mfst TYPE zif_mig_types=>ty_art_mfst.

ENDCLASS.

CLASS zcl_mig_art_mfst IMPLEMENTATION.

  METHOD zif_mig_art_mfst~build.

    CLEAR rs_mfst.


    rs_mfst-analysis_id =
      is_bp-blueprint-analysis_id.

    rs_mfst-strategy =
      is_bp-blueprint-strategy.

    rs_mfst-source_program =
      is_bp-blueprint-source_program.

    rs_mfst-package =
      iv_package.

    rs_mfst-base_name =
      make_base(
        iv_program =
          is_bp-blueprint-source_program
      ).


    "==========================================================
    " Validate analysis identity
    "==========================================================
    IF is_bp-blueprint-analysis_id IS INITIAL
       OR is_prv-analysis_id IS INITIAL
       OR is_sig-analysis_id IS INITIAL
       OR is_smap-analysis_id IS INITIAL
       OR is_row-analysis_id IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_bp-blueprint-source_program
      ).

    ENDIF.


    IF is_bp-blueprint-analysis_id <> is_prv-analysis_id
       OR is_bp-blueprint-analysis_id <> is_sig-analysis_id
       OR is_bp-blueprint-analysis_id <> is_smap-analysis_id
       OR is_bp-blueprint-analysis_id <> is_row-analysis_id.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_bp-blueprint-source_program
      ).

    ENDIF.


    "==========================================================
    " Package is mandatory
    "==========================================================
    IF iv_package IS INITIAL.

      block_mfst(
        EXPORTING
          iv_reason =
            'Target package is required.'

        CHANGING
          cs_mfst =
            rs_mfst
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " Blueprint readiness
    "==========================================================
    IF is_bp-blueprint-strategy =
         zif_mig_types=>gc_svc_manual.

      block_mfst(
        EXPORTING
          iv_reason =
            'Service blueprint requires manual review.'

        CHANGING
          cs_mfst =
            rs_mfst
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " Provider readiness
    " SIGNATURE_REQUIRED is accepted because signature has
    " already been resolved by this stage.
    "==========================================================
    IF is_prv-provider_kind =
         zif_mig_types=>gc_provider_none
       OR is_prv-provider_status =
         zif_mig_types=>gc_provider_refactor
       OR is_prv-provider_status =
         zif_mig_types=>gc_provider_review
       OR is_prv-provider_status =
         zif_mig_types=>gc_provider_unsupported.

      block_mfst(
        EXPORTING
          iv_reason =
            'Provider contract is not ready for generation.'

        CHANGING
          cs_mfst =
            rs_mfst
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " Signature readiness
    "==========================================================
    IF is_sig-status <>
         zif_mig_types=>gc_sig_ready.

      block_mfst(
        EXPORTING
          iv_reason =
            'Provider signature is not ready.'

        CHANGING
          cs_mfst =
            rs_mfst
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " Service mapping readiness
    "==========================================================
    IF is_smap-status <>
         zif_mig_types=>gc_smap_ready.

      block_mfst(
        EXPORTING
          iv_reason =
            'Service parameter mapping is not ready.'

        CHANGING
          cs_mfst =
            rs_mfst
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " Row mapping readiness
    "==========================================================
    IF is_row-status <>
         zif_mig_types=>gc_row_ready.

      block_mfst(
        EXPORTING
          iv_reason =
            'Provider row mapping is not ready.'

        CHANGING
          cs_mfst =
            rs_mfst
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " Build manifest by strategy
    "==========================================================
    CASE is_bp-blueprint-strategy.

      WHEN zif_mig_types=>gc_svc_query.

        build_query(
          EXPORTING
            is_prv =
              is_prv

          CHANGING
            cs_mfst =
              rs_mfst
        ).


      WHEN zif_mig_types=>gc_svc_action.

        build_action(
          EXPORTING
            is_prv =
              is_prv

          CHANGING
            cs_mfst =
              rs_mfst
        ).


      WHEN OTHERS.

        block_mfst(
          EXPORTING
            iv_reason =
              'Unsupported service strategy.'

          CHANGING
            cs_mfst =
              rs_mfst
        ).

        RETURN.

    ENDCASE.


    set_status(
      CHANGING
        cs_mfst =
          rs_mfst
    ).

  ENDMETHOD.

 METHOD build_query.

  DATA:
    lv_ddls TYPE zif_mig_types=>ty_art_name,
    lv_clas TYPE zif_mig_types=>ty_art_name,
    lv_srvd TYPE zif_mig_types=>ty_art_name.


  "============================================================
  " Build object names
  "============================================================
  lv_ddls =
    make_name(
      iv_prefix = 'ZC_MIG_'
      iv_base   = cs_mfst-base_name
    ).


  lv_clas =
    is_prv-proposed_class_name.


  IF lv_clas IS INITIAL.

    lv_clas =
      make_name(
        iv_prefix = 'ZCL_MIG_Q_'
        iv_base   = cs_mfst-base_name
      ).

  ENDIF.


  lv_srvd =
    make_name(
      iv_prefix = 'ZUI_MIG_'
      iv_base   = cs_mfst-base_name
    ).


  "============================================================
  " 10 - Query Provider
  "
  "Query Provider phải active trước Custom Entity vì DDLS dùng:
  "@ObjectModel.query.implementedBy
  "============================================================
  add_art(
    EXPORTING
      iv_seq     = 10
      iv_type    = zif_mig_types=>gc_art_clas
      iv_role    = zif_mig_types=>gc_art_query_prv
      iv_name    = lv_clas
      iv_package = cs_mfst-package
      iv_desc    = 'Generated RAP query provider'
      iv_order   = 10

    CHANGING
      ct_items   = cs_mfst-items
  ).


  "============================================================
  " 20 - Custom Entity
  "
  "UI annotations được sinh trực tiếp vào DDLS.
  "Không tạo Metadata Extension riêng.
  "============================================================
  add_art(
    EXPORTING
      iv_seq     = 20
      iv_type    = zif_mig_types=>gc_art_ddls
      iv_role    = zif_mig_types=>gc_art_entity
      iv_name    = lv_ddls
      iv_package = cs_mfst-package
      iv_desc    = 'Generated RAP custom entity'
      iv_order   = 20

    CHANGING
      ct_items   = cs_mfst-items
  ).


  "============================================================
  " 30 - Service Definition
  "
  "Service Binding không được tạo riêng cho từng report.
  "SRVD sẽ được thêm vào shared binding ZUI_MIG_SHARED_O4.
  "============================================================
  add_art(
    EXPORTING
      iv_seq     = 30
      iv_type    = zif_mig_types=>gc_art_srvd
      iv_role    = zif_mig_types=>gc_art_srv_def
      iv_name    = lv_srvd
      iv_package = cs_mfst-package
      iv_desc    = 'Generated RAP service definition'
      iv_order   = 30

    CHANGING
      ct_items   = cs_mfst-items
  ).


  "============================================================
  " Dependencies
  "============================================================

  "Custom Entity requires Query Provider
  add_dep(
    EXPORTING
      iv_art_seq = 20
      iv_req_seq = 10

    CHANGING
      ct_deps    = cs_mfst-dependencies
  ).


  "Service Definition requires Custom Entity
  add_dep(
    EXPORTING
      iv_art_seq = 30
      iv_req_seq = 20

    CHANGING
      ct_deps    = cs_mfst-dependencies
  ).

ENDMETHOD.

    METHOD build_action.

    DATA:
      lv_root    TYPE zif_mig_types=>ty_art_name,
      lv_proj    TYPE zif_mig_types=>ty_art_name,
      lv_adapter TYPE zif_mig_types=>ty_art_name,
      lv_bpool   TYPE zif_mig_types=>ty_art_name,
      lv_srvd    TYPE zif_mig_types=>ty_art_name,
      lv_srvb    TYPE zif_mig_types=>ty_art_name.


    lv_root =
      make_name(
        iv_prefix = 'ZI_MIG_'
        iv_base   = cs_mfst-base_name
      ).


    lv_proj =
      make_name(
        iv_prefix = 'ZC_MIG_'
        iv_base   = cs_mfst-base_name
      ).


    lv_adapter =
      is_prv-proposed_class_name.

    IF lv_adapter IS INITIAL.

      lv_adapter =
        make_name(
          iv_prefix = 'ZCL_MIG_A_'
          iv_base   = cs_mfst-base_name
        ).

    ENDIF.


    lv_bpool =
      make_name(
        iv_prefix = 'ZBP_I_MIG_'
        iv_base   = cs_mfst-base_name
      ).


    lv_srvd =
      make_name(
        iv_prefix = 'ZUI_MIG_'
        iv_base   = cs_mfst-base_name
      ).


    lv_srvb =
      make_name(
        iv_prefix = 'ZUI_MIG_'
        iv_base   = cs_mfst-base_name
        iv_suffix = '_O4'
      ).


    "==========================================================
    " 10 - Interface Entity
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 10
        iv_type    = zif_mig_types=>gc_art_ddls
        iv_role    = zif_mig_types=>gc_art_entity
        iv_name    = lv_root
        iv_package = cs_mfst-package
        iv_desc    = 'Generated RAP interface entity'
        iv_order   = 10
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 20 - Projection Entity
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 20
        iv_type    = zif_mig_types=>gc_art_ddls
        iv_role    = zif_mig_types=>gc_art_projection
        iv_name    = lv_proj
        iv_package = cs_mfst-package
        iv_desc    = 'Generated RAP projection entity'
        iv_order   = 20
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 30 - Provider Adapter
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 30
        iv_type    = zif_mig_types=>gc_art_clas
        iv_role    = zif_mig_types=>gc_art_adapter
        iv_name    = lv_adapter
        iv_package = cs_mfst-package
        iv_desc    = 'Generated provider adapter'
        iv_order   = 30
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 40 - Interface Behavior
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 40
        iv_type    = zif_mig_types=>gc_art_bdef
        iv_role    = zif_mig_types=>gc_art_bdef_root
        iv_name    = lv_root
        iv_package = cs_mfst-package
        iv_desc    = 'Generated RAP interface behavior'
        iv_order   = 40
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 50 - Behavior Pool
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 50
        iv_type    = zif_mig_types=>gc_art_clas
        iv_role    = zif_mig_types=>gc_art_bpool
        iv_name    = lv_bpool
        iv_package = cs_mfst-package
        iv_desc    = 'Generated RAP behavior pool'
        iv_order   = 50
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 60 - Projection Behavior
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 60
        iv_type    = zif_mig_types=>gc_art_bdef
        iv_role    = zif_mig_types=>gc_art_bdef_proj
        iv_name    = lv_proj
        iv_package = cs_mfst-package
        iv_desc    = 'Generated projection behavior'
        iv_order   = 60
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 70 - Metadata Extension
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 70
        iv_type    = zif_mig_types=>gc_art_ddlx
        iv_role    = zif_mig_types=>gc_art_annot
        iv_name    = lv_proj
        iv_package = cs_mfst-package
        iv_desc    = 'Generated Fiori metadata extension'
        iv_order   = 70
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 80 - Service Definition
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 80
        iv_type    = zif_mig_types=>gc_art_srvd
        iv_role    = zif_mig_types=>gc_art_srv_def
        iv_name    = lv_srvd
        iv_package = cs_mfst-package
        iv_desc    = 'Generated RAP service definition'
        iv_order   = 80
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " 90 - Service Binding
    "==========================================================
    add_art(
      EXPORTING
        iv_seq     = 90
        iv_type    = zif_mig_types=>gc_art_srvb
        iv_role    = zif_mig_types=>gc_art_srv_bind
        iv_name    = lv_srvb
        iv_package = cs_mfst-package
        iv_desc    = 'Generated OData V4 service binding'
        iv_order   = 90
      CHANGING
        ct_items   = cs_mfst-items
    ).


    "==========================================================
    " Dependencies
    "==========================================================
    add_dep(
      EXPORTING
        iv_art_seq = 20
        iv_req_seq = 10
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 30
        iv_req_seq = 10
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 40
        iv_req_seq = 10
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 50
        iv_req_seq = 40
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 50
        iv_req_seq = 30
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 60
        iv_req_seq = 40
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 60
        iv_req_seq = 20
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 70
        iv_req_seq = 20
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 80
        iv_req_seq = 20
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

    add_dep(
      EXPORTING
        iv_art_seq = 90
        iv_req_seq = 80
      CHANGING
        ct_deps    = cs_mfst-dependencies
    ).

  ENDMETHOD.

    METHOD add_art.

      APPEND VALUE #(
        seq             = iv_seq
        art_type        = iv_type
        art_role        = iv_role
        object_name     = iv_name
        package         = iv_package
        description     = iv_desc
        gen_order       = iv_order
        required        = iv_req
        cap_state       = zif_mig_types=>gc_art_cap_unknown
        gen_state       = zif_mig_types=>gc_art_planned

        object_exists   = abap_false
        current_package = ''
        pref_state      = zif_mig_types=>gc_pref_unknown
        gen_mode        = zif_mig_types=>gc_art_no_mode

        reason =
          'Waiting for XCO capability check.'
      ) TO ct_items.

    ENDMETHOD.

    METHOD add_dep.

    APPEND VALUE #(
      art_seq = iv_art_seq
      req_seq = iv_req_seq
    ) TO ct_deps.

  ENDMETHOD.

    METHOD make_base.

    DATA lv_base TYPE string.

    lv_base =
      to_upper(
        CONV string( iv_program )
      ).

    CONDENSE lv_base NO-GAPS.


    REPLACE ALL OCCURRENCES OF '/'
      IN lv_base
      WITH '_'.

    REPLACE ALL OCCURRENCES OF '\'
      IN lv_base
      WITH '_'.

    REPLACE ALL OCCURRENCES OF '-'
      IN lv_base
      WITH '_'.

    REPLACE ALL OCCURRENCES OF '.'
      IN lv_base
      WITH '_'.


    IF lv_base IS INITIAL.

      lv_base =
        'REPORT'.

    ENDIF.


    IF strlen( lv_base ) > 40.

      lv_base =
        substring(
          val = lv_base
          len = 40
        ).

    ENDIF.


    rv_base =
      lv_base.

  ENDMETHOD.

    METHOD make_name.

  DATA:
    lv_base TYPE string,
    lv_max  TYPE i.

  lv_base =
    to_upper(
      CONV string( iv_base )
    ).

  CONDENSE lv_base NO-GAPS.


  lv_max =
      30
    - strlen( iv_prefix )
    - strlen( iv_suffix ).


  IF lv_max < 1.

    rv_name =
      substring(
        val = iv_prefix
        len = 30
      ).

    RETURN.

  ENDIF.


  IF strlen( lv_base ) > lv_max.

    lv_base =
      substring(
        val = lv_base
        len = lv_max
      ).

  ENDIF.


  rv_name =
    |{ iv_prefix }{ lv_base }{ iv_suffix }|.

ENDMETHOD.

    METHOD set_status.

    cs_mfst-item_count =
      lines( cs_mfst-items ).

    cs_mfst-dep_count =
      lines( cs_mfst-dependencies ).


    IF cs_mfst-items IS INITIAL.

      block_mfst(
        EXPORTING
          iv_reason =
            'Artifact manifest contains no objects.'

        CHANGING
          cs_mfst =
            cs_mfst
      ).

      RETURN.

    ENDIF.


    LOOP AT cs_mfst-items
      INTO DATA(ls_item).

      IF ls_item-object_name IS INITIAL
         OR ls_item-package IS INITIAL.

        block_mfst(
          EXPORTING
            iv_reason =
              'Artifact name or package is missing.'

          CHANGING
            cs_mfst =
              cs_mfst
        ).

        RETURN.

      ENDIF.

    ENDLOOP.


    "==========================================================
    " Duplicate check inside the same repository object type
    "==========================================================
    DATA lt_items
      TYPE zif_mig_types=>tt_art_item.

    lt_items =
      cs_mfst-items.

    SORT lt_items
      BY art_type
         object_name.


    DATA:
      lv_prev_type TYPE zif_mig_types=>ty_art_type,
      lv_prev_name TYPE zif_mig_types=>ty_art_name.


    LOOP AT lt_items
      INTO ls_item.

      IF lv_prev_type = ls_item-art_type
         AND lv_prev_name = ls_item-object_name.

        block_mfst(
          EXPORTING
            iv_reason =
              'Duplicate repository object name was generated.'

          CHANGING
            cs_mfst =
              cs_mfst
        ).

        RETURN.

      ENDIF.


      lv_prev_type =
        ls_item-art_type.

      lv_prev_name =
        ls_item-object_name.

    ENDLOOP.


    cs_mfst-status =
      zif_mig_types=>gc_art_ready.

    cs_mfst-manual_review =
      abap_false.

    cs_mfst-decision_reason =
      'Artifact manifest was built successfully.'.

  ENDMETHOD.

    METHOD block_mfst.

    cs_mfst-status =
      zif_mig_types=>gc_art_review.

    cs_mfst-manual_review =
      abap_true.

    cs_mfst-decision_reason =
      iv_reason.


    LOOP AT cs_mfst-items
      ASSIGNING FIELD-SYMBOL(<item>).

      <item>-gen_state =
        zif_mig_types=>gc_art_blocked.

      <item>-reason =
        iv_reason.

    ENDLOOP.


    cs_mfst-item_count =
      lines( cs_mfst-items ).

    cs_mfst-dep_count =
      lines( cs_mfst-dependencies ).

  ENDMETHOD.

ENDCLASS.
