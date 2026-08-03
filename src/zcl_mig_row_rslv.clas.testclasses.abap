CLASS lcl_row_repo DEFINITION
  FINAL.

  PUBLIC SECTION.

    INTERFACES zif_mig_row_repo.

ENDCLASS.


CLASS lcl_row_repo IMPLEMENTATION.

  METHOD zif_mig_row_repo~read_type.

    CLEAR rs_row.

    rs_row-type_name =
      iv_type.


    CASE iv_type.

      WHEN 'ZTT_RESULT'.

        rs_row-exists =
          abap_true.

        rs_row-structured =
          abap_true.

        rs_row-line_name =
          'ZS_RESULT'.


        APPEND VALUE #(
          comp_name = 'BUKRS'
          position  = 1
          abap_type = 'C'
          type_name = 'BUKRS'
          edm_type  = 'Edm.String'
        ) TO rs_row-components.


        APPEND VALUE #(
          comp_name = 'AMOUNT'
          position  = 2
          abap_type = 'P'
          type_name = 'WRBTR'
          edm_type  = 'Edm.Decimal'
        ) TO rs_row-components.


        APPEND VALUE #(
          comp_name = 'STATUS'
          position  = 3
          abap_type = 'C'
          type_name = 'CHAR10'
          edm_type  = 'Edm.String'
        ) TO rs_row-components.


      WHEN 'ZTT_PART'.

        rs_row-exists =
          abap_true.

        rs_row-structured =
          abap_true.

        rs_row-line_name =
          'ZS_PART'.


        APPEND VALUE #(
          comp_name = 'BUKRS'
          position  = 1
          abap_type = 'C'
          edm_type  = 'Edm.String'
        ) TO rs_row-components.


      WHEN 'ZTT_BAD'.

        rs_row-exists =
          abap_true.

        rs_row-structured =
          abap_true.

        rs_row-line_name =
          'ZS_BAD'.


        APPEND VALUE #(
          comp_name = 'BUKRS'
          position  = 1
          abap_type = 'I'
          edm_type  = 'Edm.Int32'
        ) TO rs_row-components.


      WHEN 'ZTT_DUP'.

        rs_row-exists =
          abap_true.

        rs_row-structured =
          abap_true.

        rs_row-line_name =
          'ZS_DUP'.


        APPEND VALUE #(
          comp_name = 'BUKRS'
          position  = 1
          edm_type  = 'Edm.String'
        ) TO rs_row-components.


        APPEND VALUE #(
          comp_name = 'Bukrs'
          position  = 2
          edm_type  = 'Edm.String'
        ) TO rs_row-components.


      WHEN 'ZSCALAR'.

        rs_row-exists =
          abap_true.

        rs_row-structured =
          abap_false.

        rs_row-line_name =
          'ZSCALAR'.


      WHEN OTHERS.

        rs_row-exists =
          abap_false.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.


CLASS ltc_row_rslv DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS:
      gc_anl_id TYPE zif_mig_types=>ty_analysis_id
        VALUE '00000000000000000000000000000051',

      gc_item_1 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000052',

      gc_item_2 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000053'.


    METHODS make_bp
      RETURNING
        VALUE(rs_bp)
          TYPE zif_mig_types=>ty_service_blueprint_result.


    METHODS make_smap
      IMPORTING
        iv_type TYPE zif_mig_types=>ty_sig_name
      RETURNING
        VALUE(rs_map)
          TYPE zif_mig_types=>ty_svc_map_result.


    METHODS:
      map_row_ok
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_missing_comp
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_type_conflict
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_scalar_type
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_missing_type
        FOR TESTING
        RAISING zcx_mig_analysis,

      block_unready_map
        FOR TESTING
        RAISING zcx_mig_analysis,

      keep_unused_comp
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_ambig_comp
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_row_rslv IMPLEMENTATION.

  METHOD make_bp.

    rs_bp-blueprint-analysis_id =
      gc_anl_id.

    rs_bp-blueprint-source_program =
      'ZRMIG_TEST_FULL'.

    rs_bp-blueprint-strategy =
      zif_mig_types=>gc_svc_query.


    APPEND VALUE #(
      source_item_id = gc_item_1
      field_name     = 'BUKRS'
      label          = 'Company Code'
      edm_type       = 'Edm.String'
      position       = 1
      visible        = abap_true
    ) TO rs_bp-fields.


    APPEND VALUE #(
      source_item_id = gc_item_2
      field_name     = 'AMOUNT'
      label          = 'Amount'
      edm_type       = 'Edm.Decimal'
      position       = 2
      visible        = abap_true
    ) TO rs_bp-fields.

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
      iv_type.

    rs_map-selected_out-edm_type =
      'Collection'.

    rs_map-selected_out-is_table =
      abap_true.

  ENDMETHOD.


  METHOD map_row_ok.

    DATA(lo_rslv) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      ).

    DATA(ls_result) =
      lo_rslv->zif_mig_row_rslv~resolve(
        is_bp =
          make_bp( )

        is_smap =
          make_smap(
            iv_type = 'ZTT_RESULT'
          )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_ready
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = ls_result-mapped_fields
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = ls_result-issue_count
    ).

  ENDMETHOD.


  METHOD reject_missing_comp.

    DATA(ls_result) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      )->zif_mig_row_rslv~resolve(
        is_bp =
          make_bp( )

        is_smap =
          make_smap(
            iv_type = 'ZTT_PART'
          )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_review
      act = ls_result-status
    ).

    READ TABLE ls_result-field_maps
      WITH KEY svc_name = 'AMOUNT'
      INTO DATA(ls_map).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_missing
      act = ls_map-map_state
    ).

  ENDMETHOD.


  METHOD reject_type_conflict.

    DATA(ls_bp) =
      make_bp( ).

    DELETE ls_bp-fields
      WHERE field_name = 'AMOUNT'.


    DATA(ls_result) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      )->zif_mig_row_rslv~resolve(
        is_bp =
          ls_bp

        is_smap =
          make_smap(
            iv_type = 'ZTT_BAD'
          )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_type
      act = ls_result-field_maps[ 1 ]-map_state
    ).

  ENDMETHOD.


  METHOD reject_scalar_type.

    DATA(ls_result) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      )->zif_mig_row_rslv~resolve(
        is_bp =
          make_bp( )

        is_smap =
          make_smap(
            iv_type = 'ZSCALAR'
          )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-manual_review
    ).

  ENDMETHOD.


  METHOD reject_missing_type.

    DATA(ls_result) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      )->zif_mig_row_rslv~resolve(
        is_bp =
          make_bp( )

        is_smap =
          make_smap(
            iv_type = 'Z_NOT_EXIST'
          )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_not_found
      act = ls_result-status
    ).

  ENDMETHOD.


  METHOD block_unready_map.

    DATA(ls_map) =
      make_smap(
        iv_type = 'ZTT_RESULT'
      ).

    ls_map-status =
      zif_mig_types=>gc_smap_review.

    ls_map-manual_review =
      abap_true.


    DATA(ls_result) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      )->zif_mig_row_rslv~resolve(
        is_bp   = make_bp( )
        is_smap = ls_map
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_result-components
    ).

  ENDMETHOD.


  METHOD keep_unused_comp.

    DATA(ls_result) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      )->zif_mig_row_rslv~resolve(
        is_bp =
          make_bp( )

        is_smap =
          make_smap(
            iv_type = 'ZTT_RESULT'
          )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_ready
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-unused_comps )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'STATUS'
      act = ls_result-unused_comps[ 1 ]-comp_name
    ).

  ENDMETHOD.


  METHOD reject_ambig_comp.

    DATA(ls_bp) =
      make_bp( ).

    DELETE ls_bp-fields
      WHERE field_name = 'AMOUNT'.


    DATA(ls_result) =
      NEW zcl_mig_row_rslv(
        io_repo = NEW lcl_row_repo( )
      )->zif_mig_row_rslv~resolve(
        is_bp =
          ls_bp

        is_smap =
          make_smap(
            iv_type = 'ZTT_DUP'
          )
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_row_ambig
      act = ls_result-field_maps[ 1 ]-map_state
    ).

  ENDMETHOD.

ENDCLASS.
