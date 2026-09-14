CLASS ltc_mig_xco_gen DEFINITION DEFERRED.
CLASS zcl_mig_xco_gen DEFINITION LOCAL FRIENDS ltc_mig_xco_gen.

CLASS lcl_std_generation_log DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA steps TYPE string_table.
    CLASS-DATA fail_stage TYPE string.
ENDCLASS.
CLASS lcl_std_generation_log IMPLEMENTATION.
ENDCLASS.

CLASS lcl_std_class_executor DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_mig_prv_clas_gen.
ENDCLASS.
CLASS lcl_std_class_executor IMPLEMENTATION.
  METHOD zif_mig_prv_clas_gen~check_target.
    rs_check = VALUE #( allowed = abap_true language_code = space ).
  ENDMETHOD.
  METHOD zif_mig_prv_clas_gen~generate.
    cl_abap_unit_assert=>assert_equals( exp = 'ZLEGACY_GEN' act = iv_package ).
    cl_abap_unit_assert=>assert_not_initial( act = it_select_source ).
    APPEND `CLAS` TO lcl_std_generation_log=>steps.
    IF lcl_std_generation_log=>fail_stage = 'CLAS'.
      RAISE EXCEPTION NEW zcx_mig_generation( iv_detail = 'Synthetic class activation failure' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_mig_xco_gen DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS standard_put_order FOR TESTING RAISING cx_static_check.
    METHODS standard_failure_stops FOR TESTING RAISING cx_static_check.
    METHODS odata_failure_has_progress FOR TESTING RAISING cx_static_check.
    METHODS binding_failure_has_progress FOR TESTING RAISING cx_static_check.
    METHODS run_standard
      IMPORTING iv_failure TYPE string OPTIONAL
      RAISING zcx_mig_analysis cx_xco_gen_put_exception.

    METHODS build_source_contract
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS reject_missing_row_map
      FOR TESTING.

    METHODS build_class_source
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS build_bapi_source
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS normalize_filter_names
      FOR TESTING.

    METHODS reject_unsupported_boundary
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

  METHOD run_standard.
    CLEAR lcl_std_generation_log=>steps.
    lcl_std_generation_log=>fail_stage = iv_failure.
    TEST-INJECTION prepare_odata.
      "No repository access: only the actual stage orchestration is tested.
    END-TEST-INJECTION.
    TEST-INJECTION execute_odata_put.
      APPEND `ODATA` TO lcl_std_generation_log=>steps.
      IF lcl_std_generation_log=>fail_stage = 'ODATA'.
        RAISE EXCEPTION NEW zcx_mig_generation( iv_detail = 'Synthetic OData activation failure' ).
      ENDIF.
    END-TEST-INJECTION.
    TEST-INJECTION execute_binding_put.
      APPEND `BINDING` TO lcl_std_generation_log=>steps.
      IF lcl_std_generation_log=>fail_stage = 'BINDING'.
        RAISE EXCEPTION NEW zcx_mig_generation( iv_detail = 'Synthetic binding activation failure' ).
      ENDIF.
    END-TEST-INJECTION.

    DATA(ls_mfst) = VALUE zif_mig_types=>ty_art_mfst(
      strategy = zif_mig_types=>gc_svc_query
      source_program = 'ZSTD_TEST' package = 'ZMIG_TEST'
      provider_package = 'ZLEGACY_GEN' provider_language = 'STANDARD'
      status = zif_mig_types=>gc_art_ready create_count = 3
      items = VALUE #(
        ( art_type = 'CLAS' art_role = zif_mig_types=>gc_art_query_prv
          object_name = 'ZCL_MIG_STD_TEST' package = 'ZLEGACY_GEN'
          required = abap_true gen_state = zif_mig_types=>gc_art_planned
          gen_mode = zif_mig_types=>gc_art_create )
        ( art_type = 'DDLS' art_role = zif_mig_types=>gc_art_entity
          object_name = 'ZC_MIG_STD_TEST' package = 'ZMIG_TEST'
          required = abap_true gen_state = zif_mig_types=>gc_art_planned
          gen_mode = zif_mig_types=>gc_art_create )
        ( art_type = 'SRVD' art_role = zif_mig_types=>gc_art_srv_def
          object_name = 'ZUI_MIG_STD_TEST' package = 'ZMIG_TEST'
          required = abap_true gen_state = zif_mig_types=>gc_art_planned
          gen_mode = zif_mig_types=>gc_art_create ) ) ).
    DATA(ls_bp) = VALUE zif_mig_types=>ty_service_blueprint_result(
      blueprint = VALUE #( strategy = zif_mig_types=>gc_svc_query
        source_program = 'ZSTD_TEST' entity_name = 'MigrationResult' )
      fields = make_fields( ) ).
    NEW zcl_mig_xco_gen( )->generate_query(
      is_mfst = ls_mfst is_bp = ls_bp is_prv = make_provider( )
      is_sig = make_signature( ) is_smap = make_service_map( )
      is_row = make_row_map( ) iv_request = 'DEVK900001' iv_execute = abap_true
      io_provider_gen = NEW lcl_std_class_executor( ) ).
  ENDMETHOD.

  METHOD standard_put_order.
    run_standard( ).
    cl_abap_unit_assert=>assert_equals(
      exp = VALUE string_table( ( `CLAS` ) ( `ODATA` ) ( `BINDING` ) )
      act = lcl_std_generation_log=>steps ).
  ENDMETHOD.

  METHOD standard_failure_stops.
    TRY.
        run_standard( 'CLAS' ).
        cl_abap_unit_assert=>fail( 'Class failure must stop OData generation' ).
      CATCH zcx_mig_analysis INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp(
          exp = '*Synthetic class activation failure*' act = lx_error->get_text( ) ).
    ENDTRY.
    cl_abap_unit_assert=>assert_equals(
      exp = VALUE string_table( ( `CLAS` ) ) act = lcl_std_generation_log=>steps ).
  ENDMETHOD.

  METHOD odata_failure_has_progress.
    TRY.
        run_standard( 'ODATA' ).
        cl_abap_unit_assert=>fail( 'OData failure must stop binding generation' ).
      CATCH zcx_mig_analysis INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp(
          exp = '*Activated CLAS ZCL_MIG_STD_TEST in ZLEGACY_GEN*' act = lx_error->get_text( ) ).
    ENDTRY.
    cl_abap_unit_assert=>assert_equals(
      exp = VALUE string_table( ( `CLAS` ) ( `ODATA` ) ) act = lcl_std_generation_log=>steps ).
  ENDMETHOD.

  METHOD binding_failure_has_progress.
    TRY.
        run_standard( 'BINDING' ).
        cl_abap_unit_assert=>fail( 'Binding failure must be reported' ).
      CATCH zcx_mig_analysis INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp(
          exp = '*Activated CLAS ZCL_MIG_STD_TEST, DDLS ZC_MIG_STD_TEST, SRVD ZUI_MIG_STD_TEST*'
          act = lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

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


  METHOD reject_unsupported_boundary.

    DATA(ls_type) =
      NEW zcl_mig_xco_gen( )->resolve_boundary_type(
        is_field = VALUE #(
          field_name = 'BINARY_DATA'
          edm_type   = 'Edm.Binary'
          length     = 16
          visible    = abap_true
        )
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_type-supported
      msg = 'Unsupported EDM types must not fall back to CHAR120'
    ).

  ENDMETHOD.

  METHOD make_fields.

    APPEND VALUE #(
      field_name = 'BUKRS'
      label      = 'Company Code'
      edm_type   = 'Edm.String'
      source_data_type = 'C'
      source_data_element = 'BUKRS'
      length     = 4
      position   = 10
      key_field  = abap_true
      visible    = abap_true
      filterable = abap_true
      sortable   = abap_true
    ) TO rt_fields.

    APPEND VALUE #(
      field_name = 'BUTXT'
      label      = 'Company Name'
      edm_type   = 'Edm.String'
      source_data_type = 'C'
      source_data_element = 'BUTXT'
      length     = 25
      position   = 20
      visible    = abap_true
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

    APPEND VALUE #(
      svc_name  = 'BUTXT'
      comp_name = 'BUTXT'
      svc_edm   = 'Edm.String'
      comp_edm  = 'Edm.String'
      position  = 20
      map_state = zif_mig_types=>gc_row_auto
      type_match = abap_true
    ) TO rs_row-field_maps.

    APPEND VALUE #(
      comp_name = 'BUTXT'
      position  = 2
      abap_type = 'C'
      type_name = '\TYPE=BUTXT'
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
      lv_has_boundary_type   TYPE abap_bool,
      lv_has_legacy_type     TYPE abap_bool,
      lv_has_query_error     TYPE abap_bool,
      lv_has_resolved_filter TYPE abap_bool,
      lv_has_wrong_filter    TYPE abap_bool,
      lv_has_fm_call         TYPE abap_bool,
      lv_has_fm_input_bind   TYPE abap_bool,
      lv_has_fm_output_bind  TYPE abap_bool,
      lv_has_fm_output_type  TYPE abap_bool.

    LOOP AT lt_source
      INTO DATA(lv_line).

      IF lv_line CS 'IF lv_f1_set = abap_false.'.
        lv_has_mandatory_check = abap_true.
      ENDIF.

      IF lv_line CS 'BUKRS = ls_provider-BUKRS'.
        lv_has_explicit_map = abap_true.
      ENDIF.

      IF lv_line CS 'BUTXT TYPE c LENGTH 25'.
        lv_has_boundary_type = abap_true.
      ENDIF.

      IF lv_line CS 'BUTXT TYPE BUTXT'.
        lv_has_legacy_type = abap_true.
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

      IF lv_line CS 'CALL FUNCTION lv_provider_fm'.
        lv_has_fm_call = abap_true.
      ENDIF.

      IF lv_line CS 'kind = abap_func_exporting'.
        lv_has_fm_input_bind = abap_true.
      ENDIF.

      IF lv_line CS 'kind = abap_func_importing'.
        lv_has_fm_output_bind = abap_true.
      ENDIF.

      IF lv_line CS
           'DATA lt_provider TYPE ZTT_MIG_TEST_RESULT'.

        lv_has_fm_output_type = abap_true.

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
      act = lv_has_boundary_type
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lv_has_legacy_type
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

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_fm_call
      msg = 'FM query source must contain a dynamic function call'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_fm_input_bind
      msg = 'FM IMPORTING input must be bound as function EXPORTING'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_fm_output_bind
      msg = 'FM EXPORTING output must be bound as function IMPORTING'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_fm_output_type
      msg = 'Generated provider table must keep the named FM table type'
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


  METHOD build_bapi_source.

    DATA(lt_fields) =
      VALUE zif_mig_types=>tt_service_field(
        (
          field_name      = 'PRODUCT_ID'
          label           = 'Product ID'
          edm_type        = 'Edm.String'
          source_data_type = 'C'
          length          = 10
          position        = 10
          key_field       = abap_true
          visible         = abap_true
          filterable      = abap_true
          sortable        = abap_true
        )
        (
          field_name      = 'NAME'
          label           = 'Product Name'
          edm_type        = 'Edm.String'
          source_data_type = 'C'
          length          = 255
          position        = 20
          visible         = abap_true
          sortable        = abap_true
        )
      ).

    DATA(ls_provider) =
      VALUE zif_mig_types=>ty_provider_contract(
        service_strategy   = zif_mig_types=>gc_svc_query
        provider_kind      = zif_mig_types=>gc_provider_bapi
        provider_status    = zif_mig_types=>gc_provider_ready
        source_object_name = 'BAPI_EPM_PRODUCT_GET_LIST'
      ).

    DATA(ls_signature) =
      VALUE zif_mig_types=>ty_sig_result(
        provider_kind = zif_mig_types=>gc_provider_bapi
        status        = zif_mig_types=>gc_sig_ready
        input_params  = VALUE #(
          (
            par_name   = 'SELPARAMPRODUCTID'
            direction  = zif_mig_types=>gc_sig_tab
            type_name  = 'BAPI_EPM_PRODUCT_ID_RANGE'
            edm_type   = 'Edm.String'
            odata_role = zif_mig_types=>gc_sig_in
            optional   = abap_true
            is_table   = abap_true
          )
        )
        output_params = VALUE #(
          (
            par_name   = 'HEADERDATA'
            direction  = zif_mig_types=>gc_sig_tab
            type_name  = 'BAPI_EPM_PRODUCT_HEADER'
            odata_role = zif_mig_types=>gc_sig_out
            is_table   = abap_true
          )
        )
      ).

    ls_signature-all_params =
      ls_signature-input_params.

    APPEND LINES OF ls_signature-output_params
      TO ls_signature-all_params.

    APPEND VALUE #(
      par_name   = 'RETURN'
      direction  = zif_mig_types=>gc_sig_tab
      type_name  = 'BAPIRET2'
      odata_role = zif_mig_types=>gc_sig_tech
      optional   = abap_true
      is_table   = abap_true
    ) TO ls_signature-all_params.

    DATA(ls_service_map) =
      VALUE zif_mig_types=>ty_svc_map_result(
        status = zif_mig_types=>gc_smap_ready
        input_maps = VALUE #(
          (
            svc_name     = 'PRODUCT_ID'
            prv_name     = 'SELPARAMPRODUCTID'
            svc_kind     = 'RANGE'
            svc_edm      = 'Edm.String'
            prv_edm      = 'Edm.String'
            map_state    = zif_mig_types=>gc_smap_auto
            prv_optional = abap_true
          )
        )
        selected_out = VALUE #(
          par_name   = 'HEADERDATA'
          direction  = zif_mig_types=>gc_sig_tab
          type_name  = 'BAPI_EPM_PRODUCT_HEADER'
          odata_role = zif_mig_types=>gc_sig_out
          is_table   = abap_true
        )
      ).

    DATA(ls_row) =
      VALUE zif_mig_types=>ty_row_result(
        status = zif_mig_types=>gc_row_ready
        field_maps = VALUE #(
          (
            svc_name   = 'PRODUCT_ID'
            comp_name  = 'PRODUCT_ID'
            svc_edm    = 'Edm.String'
            comp_edm   = 'Edm.String'
            position   = 10
            map_state  = zif_mig_types=>gc_row_auto
            type_match = abap_true
          )
          (
            svc_name   = 'NAME'
            comp_name  = 'NAME'
            svc_edm    = 'Edm.String'
            comp_edm   = 'Edm.String'
            position   = 20
            map_state  = zif_mig_types=>gc_row_auto
            type_match = abap_true
          )
        )
      ).

    DATA(lt_source) =
      NEW zcl_mig_xco_gen( )->build_select_src(
        it_fields = lt_fields
        is_prv    = ls_provider
        is_sig    = ls_signature
        is_smap   = ls_service_map
        is_row    = ls_row
      ).

    DATA:
      lv_has_range_table  TYPE abap_bool,
      lv_has_output_table TYPE abap_bool,
      lv_has_return_table TYPE abap_bool,
      lv_has_tables_bind  TYPE abap_bool,
      lv_has_return_check TYPE abap_bool.

    LOOP AT lt_source INTO DATA(lv_line).

      IF lv_line CS
           'DATA lt_f1 TYPE STANDARD TABLE OF BAPI_EPM_PRODUCT_ID_RANGE'.
        lv_has_range_table = abap_true.
      ENDIF.

      IF lv_line CS
           'DATA lt_provider TYPE STANDARD TABLE OF BAPI_EPM_PRODUCT_HEADER'.
        lv_has_output_table = abap_true.
      ENDIF.

      IF lv_line CS
           'DATA lt_bapi_return TYPE STANDARD TABLE OF BAPIRET2'.
        lv_has_return_table = abap_true.
      ENDIF.

      IF lv_line CS 'kind = abap_func_tables'.
        lv_has_tables_bind = abap_true.
      ENDIF.

      IF lv_line CS `<bapi_return>-type CA 'AEX'`.
        lv_has_return_check = abap_true.
      ENDIF.

    ENDLOOP.


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_range_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_output_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_return_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_tables_bind
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_has_return_check
    ).

  ENDMETHOD.

ENDCLASS.
