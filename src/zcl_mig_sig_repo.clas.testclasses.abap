CLASS ltc_sig_repo DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      read_fm_real
        FOR TESTING
        RAISING zcx_mig_analysis,

      read_mth_real
        FOR TESTING
        RAISING zcx_mig_analysis,

      missing_fm
        FOR TESTING
        RAISING zcx_mig_analysis,

      missing_mth
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_sig_repo IMPLEMENTATION.

  METHOD read_fm_real.

    DATA(lo_repo) =
      NEW zcl_mig_sig_repo( ).

    DATA(ls_sig) =
      lo_repo->zif_mig_sig_repo~read_fm(
        iv_fm = 'FUNCTION_IMPORT_INTERFACE'
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_sig-exists
      msg = 'Function signature must exist'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_sig-params
      msg = 'Function parameters are empty'
    ).


    READ TABLE ls_sig-params
      WITH KEY par_name = 'FUNCNAME'
      INTO DATA(ls_funcname).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'FUNCNAME parameter not found'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_imp
      act = ls_funcname-direction
      msg = 'FUNCNAME must be importing'
    ).


    READ TABLE ls_sig-params
      WITH KEY par_name = 'IMPORT_PARAMETER'
      INTO DATA(ls_import_tab).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'IMPORT_PARAMETER not found'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_import_tab-is_table
      msg = 'IMPORT_PARAMETER must be table'
    ).

  ENDMETHOD.


  METHOD read_mth_real.

    DATA(lo_repo) =
      NEW zcl_mig_sig_repo( ).

    DATA(ls_sig) =
      lo_repo->zif_mig_sig_repo~read_mth(
        iv_class = 'ZCL_MIG_SIG_RSLV'
        iv_mth   = 'CONSTRUCTOR'
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_sig-exists
      msg = 'Constructor signature must exist'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_sig-is_static
      msg = 'Constructor must be instance method'
    ).


    READ TABLE ls_sig-params
      WITH KEY par_name = 'IO_REPO'
      INTO DATA(ls_repo_par).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'IO_REPO parameter not found'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_imp
      act = ls_repo_par-direction
      msg = 'IO_REPO must be importing'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_repo_par-is_ref
      msg = 'IO_REPO must be reference type'
    ).

  ENDMETHOD.


  METHOD missing_fm.

    DATA(lo_repo) =
      NEW zcl_mig_sig_repo( ).

    DATA(ls_sig) =
      lo_repo->zif_mig_sig_repo~read_fm(
        iv_fm = 'Z_MIG_FM_NOT_EXIST'
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_sig-exists
      msg = 'Unknown FM must not exist'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_sig-params
      msg = 'Unknown FM must have no parameters'
    ).

  ENDMETHOD.


  METHOD missing_mth.

    DATA(lo_repo) =
      NEW zcl_mig_sig_repo( ).

    DATA(ls_sig) =
      lo_repo->zif_mig_sig_repo~read_mth(
        iv_class = 'ZCL_MIG_SIG_RSLV'
        iv_mth   = 'NOT_EXIST'
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_sig-exists
      msg = 'Unknown method must not exist'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_sig-params
      msg = 'Unknown method must have no parameters'
    ).

  ENDMETHOD.

ENDCLASS.
