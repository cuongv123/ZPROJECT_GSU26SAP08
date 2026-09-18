CLASS lcl_generator DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_mig_odata_gen_svc.
    DATA received TYPE zif_mig_odata_gen_svc=>ty_request.
ENDCLASS.
CLASS lcl_generator IMPLEMENTATION.
  METHOD zif_mig_odata_gen_svc~generate.
    received = is_request.
    rs_result-status = 'READY'.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_api DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS dry_run_never_executes FOR TESTING RAISING cx_static_check.
    METHODS execute_needs_transport FOR TESTING.
    METHODS standard_needs_package FOR TESTING.
    METHODS invalid_language_rejected FOR TESTING.
    METHODS cloud_default FOR TESTING RAISING cx_static_check.
ENDCLASS.
CLASS ltc_api IMPLEMENTATION.
  METHOD dry_run_never_executes.
    DATA(lo_fake) = NEW lcl_generator( ).
    DATA(ls_result) = zcl_mig_gen_api=>preflight(
      is_request = VALUE #( analysis_id = '11111111111111111111111111111111'
        package = 'ZTEST' execute = abap_true )
      io_generator = lo_fake ).
    cl_abap_unit_assert=>assert_initial( lo_fake->received-execute ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status exp = 'READY' ).
  ENDMETHOD.
  METHOD execute_needs_transport.
    TRY.
        DATA(ls_request) = zcl_mig_gen_api=>normalize( VALUE #(
          analysis_id = '11111111111111111111111111111111' package = 'ZTEST'
          execute = abap_true ) ).
        cl_abap_unit_assert=>fail( 'Execute without transport must fail.' ).
      CATCH zcx_mig_analysis.
    ENDTRY.
  ENDMETHOD.
  METHOD standard_needs_package.
    TRY.
        DATA(ls_request) = zcl_mig_gen_api=>normalize( VALUE #(
          analysis_id = '11111111111111111111111111111111' package = 'ZTEST'
          provider_language = 'STANDARD' ) ).
        cl_abap_unit_assert=>fail( 'Standard provider package is required.' ).
      CATCH zcx_mig_analysis.
    ENDTRY.
  ENDMETHOD.
  METHOD invalid_language_rejected.
    TRY.
        DATA(ls_request) = zcl_mig_gen_api=>normalize( VALUE #(
          analysis_id = '11111111111111111111111111111111' package = 'ZTEST'
          provider_language = 'INVALID' ) ).
        cl_abap_unit_assert=>fail( 'Unknown language must not silently become CLOUD.' ).
      CATCH zcx_mig_analysis.
    ENDTRY.
  ENDMETHOD.
  METHOD cloud_default.
    DATA(ls_request) = zcl_mig_gen_api=>normalize( VALUE #(
      analysis_id = '11111111111111111111111111111111' package = 'ztest' ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_request-provider_language exp = 'CLOUD' ).
    cl_abap_unit_assert=>assert_equals( act = ls_request-package exp = 'ZTEST' ).
  ENDMETHOD.
ENDCLASS.
