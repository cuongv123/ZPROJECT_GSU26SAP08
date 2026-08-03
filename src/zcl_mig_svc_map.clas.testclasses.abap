CLASS ltc_svc_map DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS:
      gc_anl_id TYPE zif_mig_types=>ty_analysis_id
        VALUE '00000000000000000000000000000041',

      gc_item_id TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000042'.


    METHODS make_bp
      RETURNING
        VALUE(rs_bp)
          TYPE zif_mig_types=>ty_service_blueprint_result.


    METHODS make_sig
      RETURNING
        VALUE(rs_sig)
          TYPE zif_mig_types=>ty_sig_result.


    METHODS:
      map_exact_input
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_prefix_input
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_range_input
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_req_input
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_type_conflict
        FOR TESTING
        RAISING zcx_mig_analysis,

      pick_one_output
        FOR TESTING
        RAISING zcx_mig_analysis,

      pick_named_output
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_multi_out
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_svc_map IMPLEMENTATION.

  METHOD make_bp.

    rs_bp-blueprint-analysis_id =
      gc_anl_id.

    rs_bp-blueprint-source_program =
      'ZRMIG_TEST_FULL'.

    rs_bp-blueprint-source_table =
      'GT_RESULT'.

    rs_bp-blueprint-strategy =
      zif_mig_types=>gc_svc_query.


    APPEND VALUE #(
      source_item_id =
        gc_item_id

      field_name =
        'BUKRS'

      label =
        'Company Code'

      edm_type =
        'Edm.String'

      position =
        1

      visible =
        abap_true
    ) TO rs_bp-fields.

  ENDMETHOD.


  METHOD make_sig.

    rs_sig-analysis_id =
      gc_anl_id.

    rs_sig-service_strategy =
      zif_mig_types=>gc_svc_query.

    rs_sig-provider_kind =
      zif_mig_types=>gc_provider_function.

    rs_sig-status =
      zif_mig_types=>gc_sig_ready.


    APPEND VALUE #(
      par_name =
        'ET_RESULT'

      direction =
        zif_mig_types=>gc_sig_exp

      edm_type =
        'Collection'

      odata_role =
        zif_mig_types=>gc_sig_out

      is_table =
        abap_true
    ) TO rs_sig-output_params.

  ENDMETHOD.


  METHOD map_exact_input.

    DATA(ls_bp) =
      make_bp( ).

    APPEND VALUE #(
      source_item_id =
        gc_item_id

      parameter_name =
        'P_MAX'

      source_kind =
        'PARAMETER'

      odata_kind =
        'PROPERTY'

      edm_type =
        'Edm.Int32'
    ) TO ls_bp-parameters.


    DATA(ls_sig) =
      make_sig( ).

    APPEND VALUE #(
      par_name =
        'P_MAX'

      direction =
        zif_mig_types=>gc_sig_imp

      edm_type =
        'Edm.Int32'

      odata_role =
        zif_mig_types=>gc_sig_in

      optional =
        abap_true
    ) TO ls_sig-input_params.


    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = ls_bp
          is_sig = ls_sig
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_ready
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_auto
      act = ls_map-input_maps[ 1 ]-map_state
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_map-input_maps[ 1 ]-exact_name
    ).

  ENDMETHOD.


  METHOD map_prefix_input.

    DATA(ls_bp) =
      make_bp( ).

    APPEND VALUE #(
      source_item_id =
        gc_item_id

      parameter_name =
        'P_BUKRS'

      source_kind =
        'PARAMETER'

      odata_kind =
        'PROPERTY'

      edm_type =
        'Edm.String'
    ) TO ls_bp-parameters.


    DATA(ls_sig) =
      make_sig( ).

    APPEND VALUE #(
      par_name =
        'IV_BUKRS'

      direction =
        zif_mig_types=>gc_sig_imp

      edm_type =
        'Edm.String'

      odata_role =
        zif_mig_types=>gc_sig_in

      optional =
        abap_true
    ) TO ls_sig-input_params.


    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = ls_bp
          is_sig = ls_sig
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_ready
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'IV_BUKRS'
      act = ls_map-input_maps[ 1 ]-prv_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_map-input_maps[ 1 ]-exact_name
    ).

  ENDMETHOD.


  METHOD map_range_input.

    DATA(ls_bp) =
      make_bp( ).

    APPEND VALUE #(
      source_item_id =
        gc_item_id

      parameter_name =
        'S_BUKRS'

      source_kind =
        'SELECT_OPTIONS'

      odata_kind =
        'RANGE'

      edm_type =
        'Edm.String'

      multiple_selection =
        abap_true

      range_supported =
        abap_true
    ) TO ls_bp-parameters.


    DATA(ls_sig) =
      make_sig( ).

    APPEND VALUE #(
      par_name =
        'IT_BUKRS'

      direction =
        zif_mig_types=>gc_sig_imp

      edm_type =
        'Collection'

      odata_role =
        zif_mig_types=>gc_sig_in

      optional =
        abap_true

      is_table =
        abap_true
    ) TO ls_sig-input_params.


    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = ls_bp
          is_sig = ls_sig
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_ready
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_map-input_maps[ 1 ]-type_match
    ).

  ENDMETHOD.


  METHOD reject_req_input.

    DATA(ls_bp) =
      make_bp( ).

    DATA(ls_sig) =
      make_sig( ).

    APPEND VALUE #(
      par_name =
        'IV_LANG'

      direction =
        zif_mig_types=>gc_sig_imp

      edm_type =
        'Edm.String'

      odata_role =
        zif_mig_types=>gc_sig_in

      optional =
        abap_false
    ) TO ls_sig-input_params.


    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = ls_bp
          is_sig = ls_sig
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_review
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_missing
      act = ls_map-input_maps[ 1 ]-map_state
    ).

  ENDMETHOD.


  METHOD reject_type_conflict.

    DATA(ls_bp) =
      make_bp( ).

    APPEND VALUE #(
      source_item_id =
        gc_item_id

      parameter_name =
        'P_MAX'

      odata_kind =
        'PROPERTY'

      edm_type =
        'Edm.Int32'
    ) TO ls_bp-parameters.


    DATA(ls_sig) =
      make_sig( ).

    APPEND VALUE #(
      par_name =
        'IV_MAX'

      direction =
        zif_mig_types=>gc_sig_imp

      edm_type =
        'Edm.String'

      odata_role =
        zif_mig_types=>gc_sig_in

      optional =
        abap_true
    ) TO ls_sig-input_params.


    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = ls_bp
          is_sig = ls_sig
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_review
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_type
      act = ls_map-input_maps[ 1 ]-map_state
    ).

  ENDMETHOD.


  METHOD pick_one_output.

    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = make_bp( )
          is_sig = make_sig( )
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_ready
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ET_RESULT'
      act = ls_map-selected_out-par_name
    ).

  ENDMETHOD.


  METHOD pick_named_output.

    DATA(ls_bp) =
      make_bp( ).

    DATA(ls_sig) =
      make_sig( ).

    CLEAR ls_sig-output_params.


    APPEND VALUE #(
      par_name =
        'ET_HEAD'

      direction =
        zif_mig_types=>gc_sig_exp

      edm_type =
        'Collection'

      odata_role =
        zif_mig_types=>gc_sig_out

      is_table =
        abap_true
    ) TO ls_sig-output_params.


    APPEND VALUE #(
      par_name =
        'ET_RESULT'

      direction =
        zif_mig_types=>gc_sig_exp

      edm_type =
        'Collection'

      odata_role =
        zif_mig_types=>gc_sig_out

      is_table =
        abap_true
    ) TO ls_sig-output_params.


    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = ls_bp
          is_sig = ls_sig
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_ready
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ET_RESULT'
      act = ls_map-selected_out-par_name
    ).

  ENDMETHOD.


  METHOD reject_multi_out.

    DATA(ls_bp) =
      make_bp( ).

    DATA(ls_sig) =
      make_sig( ).

    CLEAR ls_sig-output_params.


    APPEND VALUE #(
      par_name =
        'ET_HEAD'

      direction =
        zif_mig_types=>gc_sig_exp

      edm_type =
        'Collection'

      odata_role =
        zif_mig_types=>gc_sig_out

      is_table =
        abap_true
    ) TO ls_sig-output_params.


    APPEND VALUE #(
      par_name =
        'ET_ITEM'

      direction =
        zif_mig_types=>gc_sig_exp

      edm_type =
        'Collection'

      odata_role =
        zif_mig_types=>gc_sig_out

      is_table =
        abap_true
    ) TO ls_sig-output_params.


    DATA(ls_map) =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp  = ls_bp
          is_sig = ls_sig
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_smap_review
      act = ls_map-status
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_map-selected_out-par_name
    ).

  ENDMETHOD.

ENDCLASS.
