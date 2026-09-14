CLASS ltc_std_language DEFINITION DEFERRED.
CLASS zcl_mig_prv_std_gen DEFINITION LOCAL FRIENDS ltc_std_language.

CLASS ltc_std_language DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS accepts_standard FOR TESTING.
    METHODS rejects_cloud FOR TESTING.
    METHODS rejects_unknown_enum FOR TESTING.
    METHODS rejects_long_value FOR TESTING.
ENDCLASS.

CLASS ltc_std_language IMPLEMENTATION.
  METHOD accepts_standard.
    DATA(ls_check) = NEW zcl_mig_prv_std_gen( )->inspect_language( CONV string( space ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = ls_check-allowed ).
    cl_abap_unit_assert=>assert_equals( exp = space act = ls_check-language_code ).
  ENDMETHOD.
  METHOD rejects_cloud.
    DATA(ls_check) = NEW zcl_mig_prv_std_gen( )->inspect_language( '5' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = ls_check-allowed ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*Standard ABAP*' act = ls_check-message ).
  ENDMETHOD.
  METHOD rejects_unknown_enum.
    DATA(ls_check) = NEW zcl_mig_prv_std_gen( )->inspect_language( 'X' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = ls_check-allowed ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*Standard ABAP*' act = ls_check-message ).
  ENDMETHOD.
  METHOD rejects_long_value.
    DATA(ls_check) = NEW zcl_mig_prv_std_gen( )->inspect_language( 'X5' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = ls_check-allowed ).
  ENDMETHOD.
ENDCLASS.
