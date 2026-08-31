CLASS ltc_mig_xco_gen DEFINITION DEFERRED.
CLASS zcl_mig_xco_gen DEFINITION LOCAL FRIENDS ltc_mig_xco_gen.


CLASS ltc_mig_xco_gen DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS build_source_contract
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS reject_missing_row_map
      FOR TESTING.

    METHODS build_class_source
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS normalize_filter_names
      FOR TESTING.

    METHODS make_fields
      RETURNING
        VALUE(rt_fields) TYPE zif_mig_types=>tt_service_field.

    METHODS make_provider
      RETURNING
        VALUE(rs_provider) TYPE zif_mig_types=>ty_provider_contract.

    METHODS make_signature
      RETURNING
        VALUE(rs_signature) TYPE zif_mig_types=>ty_sig_result.

    METHODS make_service_map
      RETURNING
        VALUE(rs_map) TYPE zif_mig_types=>ty_svc_map_result.

    METHODS make_row_map
      RETURNING
        VALUE(rs_row) TYPE zif_mig_types=>ty_row_result.

ENDCLASS.


CLASS ltc_mig_xco_gen IMPLEMENTATION.

  METHOD normalize_filter_names.

    DATA(lo_cut) = NEW zcl_mig_xco_gen( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'BUKRS'
      act = lo_cut->norm_name( 'P_BUKRS' )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'BUKRS'
      act = lo_cut->norm_name( 'IV_BUKRS' )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'BUKRS'
      act = lo_cut->norm_name( 'BUKRS' )
    ).

  ENDMETHOD.

  METHOD make_fields.

    APPEND VALUE #(
      field_name = 'BUKRS'
      label      = 'Company Code'
      edm_type   = 'Edm.String'
      position   = 10
      key_field  = abap_true
      visible    = abap_true
      filterable = abap_true
      sortable   = abap_true
    ) TO rt_fields.

  ENDMETHOD.


  METHOD make_provider.

    rs_provider-service_strategy = zif_mig_types=>gc_svc_query.
    rs_provider-provider_kind = zif_mig_types=>gc_provider_function.
    rs_provider-provider_status = zif_mig_types=>gc_provider_signature.
    rs_provider-source_object_name = 'Z_READ_LEGACY_DATA'.
    rs_provider-manual_review = abap_false.

  ENDMETHOD.


  METHOD make_signature.

    rs_signature-provider_kind = zif_mig_types=>gc_provider_function.
    rs_signature-status = zif_mig_types=>gc_sig_ready.
    rs_signature-manual_review = abap_false.

    APPEND VALUE #(
      par_name   = 'IV_BUKRS'
      direction  = zif_mig_types=>gc_sig_imp
      type_name  = 'BUKRS'
      edm_type   = 'Edm.String'
      odata_role = zif_mig_types=>gc_sig_in
      optional   = abap_false
      is_table   = abap_false
    ) TO rs_signature-input_params.

    APPEND VALUE #(
      par_name   = 'ET_RESULT'
      direction  = zif_mig_types=>gc_sig_exp
      type_name  = 'ZTT_MIG_TEST_RESULT'
      odata_role = zif_mig_types=>gc_sig_out
      is_table   = abap_true
    ) TO rs_signature-output_params.

    rs_signature-all_params = rs_signature-input_params.
    APPEND LINES OF rs_signature-output_params
      TO rs_signature-all_params.

  ENDMETHOD.


  METHOD make_service_map.

    rs_map-status = zif_mig_types=>gc_smap_ready.
    rs_map-manual_review = abap_false.

    APPEND VALUE #(
      svc_name     = 'P_BUKRS'
      prv_name     = 'IV_BUKRS'
      svc_kind     = 'SCALAR'
      svc_edm      = 'Edm.String'
      prv_edm      = 'Edm.String'
      map_state    = zif_mig_types=>gc_smap_auto
      mandatory    = abap_true
      prv_optional = abap_false
    ) TO rs_map-input_maps.

    rs_map-selected_out = VALUE #(
      par_name   = 'ET_RESULT'
      direction  = zif_mig_types=>gc_sig_exp
      type_name  = 'ZTT_MIG_TEST_RESULT'
      odata_role = zif_mig_types=>gc_sig_out
      is_table   = abap_true
    ).

  ENDMETHOD.


  METHOD make_row_map.

    rs_row-status = zif_mig_types=>gc_row_ready.
    rs_row-manual_review = abap_false.

    APPEND VALUE #(
      svc_name  = 'BUKRS'
      comp_name = 'BUKRS'
      svc_edm   = 'Edm.String'
      comp_edm  = 'Edm.String'
      position  = 10
      map_state = zif_mig_types=>gc_row_auto
      type_match = abap_true
    ) TO rs_row-field_maps.

    APPEND VALUE #(
      comp_name = 'BUKRS'
      position  = 1
      abap_type = 'C'
      type_name = '\TYPE=BUKRS'
      edm_type  = 'Edm.String'
    ) TO rs_row-components.

  ENDMETHOD.


  METHOD build_source_contract.

    DATA(lt_source) =
      NEW zcl_mig_xco_gen( )->build_select_src(
        it_fields = make_fields( )
        is_prv    = make_provider( )
        is_sig    = make_signature( )
        is_smap   = make_service_map( )
        is_row    = make_row_map( )
      ).

    DATA:
      lv_has_mandatory_check TYPE abap_bool,
      lv_has_explicit_map    TYPE abap_bool,
      lv_has_exact_type      TYPE abap_bool,
      lv_has_query_error     TYPE abap_bool,
      lv_has_resolved_filter TYPE abap_bool,
      lv_has_wrong_filter    TYPE abap_bool.

    LOOP AT lt_source
      INTO DATA(lv_line).

      IF lv_line CS 'IF lv_f1_set = abap_false.'.
        lv_has_mandatory_check = abap_true.
      ENDIF.

      IF lv_line CS 'BUKRS = ls_provider-BUKRS'.
        lv_has_explicit_map = abap_true.
      ENDIF.

      IF lv_line CS 'BUKRS TYPE BUKRS'.
        lv_has_exact_type = abap_true.
      ENDIF.

      IF lv_line CS 'zcx_mig_query_error'.
        lv_has_query_error = abap_true.
      ENDIF.

      IF lv_line CS `WHEN 'BUKRS'.`.
        lv_has_resolved_filter = abap_true.
      ENDIF.

      IF lv_line CS `WHEN 'P_BUKRS'.`.
        lv_has_wrong_filter = abap_true.
      ENDIF.

    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_mandatory_check
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_explicit_map
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_exact_type
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_query_error
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_resolved_filter
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lv_has_wrong_filter
    ).

  ENDMETHOD.


  METHOD reject_missing_row_map.

    TRY.

        DATA(lt_source) =
          NEW zcl_mig_xco_gen( )->build_select_src(
            it_fields = make_fields( )
            is_prv    = make_provider( )
            is_sig    = make_signature( )
            is_smap   = make_service_map( )
            is_row    = VALUE #( )
          ).

        cl_abap_unit_assert=>fail(
          msg = 'Missing row mapping must block source generation'
        ).

      CATCH zcx_mig_analysis.
        "Expected

    ENDTRY.

  ENDMETHOD.


  METHOD build_class_source.

    DATA(ls_provider) =
      make_provider( ).

    ls_provider-provider_kind =
      zif_mig_types=>gc_provider_class_method.

    ls_provider-source_container_name =
      'ZCL_MIG_SAMPLE_RO_PROVIDER'.

    ls_provider-source_object_name =
      'GET_DATA'.


    DATA(ls_signature) =
      make_signature( ).

    ls_signature-provider_kind =
      zif_mig_types=>gc_provider_class_method.

    ls_signature-provider_static =
      abap_true.

    CLEAR ls_signature-output_params.

    APPEND VALUE #(
      par_name   = 'RT_RESULT'
      direction  = zif_mig_types=>gc_sig_ret
      type_name  = 'ZCL_MIG_SAMPLE_RO_PROVIDER=>TT_RESULT'
      odata_role = zif_mig_types=>gc_sig_out
      is_table   = abap_true
    ) TO ls_signature-output_params.

    ls_signature-all_params =
      ls_signature-input_params.

    APPEND LINES OF ls_signature-output_params
      TO ls_signature-all_params.


    DATA(ls_service_map) =
      make_service_map( ).

    ls_service_map-selected_out =
      VALUE #(
        par_name   = 'RT_RESULT'
        direction  = zif_mig_types=>gc_sig_ret
        type_name  = 'ZCL_MIG_SAMPLE_RO_PROVIDER=>TT_RESULT'
        odata_role = zif_mig_types=>gc_sig_out
        is_table   = abap_true
      ).


    DATA(lt_source) =
      NEW zcl_mig_xco_gen( )->build_select_src(
        it_fields = make_fields( )
        is_prv    = ls_provider
        is_sig    = ls_signature
        is_smap   = ls_service_map
        is_row    = make_row_map( )
      ).


    DATA:
      lv_has_class_call TYPE abap_bool,
      lv_has_receiving  TYPE abap_bool,
      lv_has_class_type TYPE abap_bool.

    LOOP AT lt_source
      INTO DATA(lv_line).

      IF lv_line CS
           'CALL METHOD (lv_provider_class)=>(lv_provider_method)'.

        lv_has_class_call =
          abap_true.

      ENDIF.

      IF lv_line CS
           'kind = cl_abap_objectdescr=>receiving'.

        lv_has_receiving =
          abap_true.

      ENDIF.

      IF lv_line CS
           'DATA lt_provider TYPE ZCL_MIG_SAMPLE_RO_PROVIDER=>TT_RESULT'.

        lv_has_class_type =
          abap_true.

      ENDIF.

    ENDLOOP.


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_class_call
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_receiving
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_class_type
    ).

  ENDMETHOD.

ENDCLASS.
