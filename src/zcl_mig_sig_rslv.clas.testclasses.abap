CLASS lcl_sig_repo DEFINITION
  FINAL.

  PUBLIC SECTION.

    INTERFACES zif_mig_sig_repo.

ENDCLASS.


CLASS lcl_sig_repo IMPLEMENTATION.

  METHOD zif_mig_sig_repo~read_fm.

    rs_sig-provider_kind =
      zif_mig_types=>gc_provider_function.

    rs_sig-obj_name =
      iv_fm.


    CASE iv_fm.

      WHEN 'Z_READ_DATA'.

        rs_sig-exists = abap_true.

        APPEND VALUE #(
          par_name  = 'IV_BUKRS'
          direction = zif_mig_types=>gc_sig_imp
          abap_type = 'C'
        ) TO rs_sig-params.

        APPEND VALUE #(
          par_name  = 'ET_RESULT'
          direction = zif_mig_types=>gc_sig_exp
          type_name = 'ZTT_RESULT'
          is_table  = abap_true
        ) TO rs_sig-params.


      WHEN 'Z_CHANGE_DATA'.

        rs_sig-exists = abap_true.

        APPEND VALUE #(
          par_name  = 'CS_DATA'
          direction = zif_mig_types=>gc_sig_chg
          type_name = 'ZS_DATA'
        ) TO rs_sig-params.


      WHEN 'Z_NO_OUTPUT'.

        rs_sig-exists = abap_true.

        APPEND VALUE #(
          par_name  = 'IV_BUKRS'
          direction = zif_mig_types=>gc_sig_imp
          abap_type = 'C'
        ) TO rs_sig-params.


      WHEN OTHERS.

        rs_sig-exists = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD zif_mig_sig_repo~read_mth.

    rs_sig-provider_kind =
      zif_mig_types=>gc_provider_class_method.

    rs_sig-class_name =
      iv_class.

    rs_sig-method_name =
      iv_mth.


    IF iv_class = 'ZCL_LEGACY_REPORT'
       AND iv_mth = 'READ_DATA'.

      rs_sig-exists =
        abap_true.

      rs_sig-is_static =
        abap_true.

      APPEND VALUE #(
        par_name  = 'IV_BUKRS'
        direction = zif_mig_types=>gc_sig_imp
        abap_type = 'C'
      ) TO rs_sig-params.

      APPEND VALUE #(
        par_name  = 'RT_RESULT'
        direction = zif_mig_types=>gc_sig_ret
        type_name = 'ZTT_RESULT'
        is_table  = abap_true
      ) TO rs_sig-params.

    ELSE.

      rs_sig-exists =
        abap_false.

    ENDIF.

  ENDMETHOD.

ENDCLASS.


CLASS ltc_sig_rslv DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS:
      gc_anl_id TYPE zif_mig_types=>ty_analysis_id
        VALUE '00000000000000000000000000000031'.


    METHODS make_prv
      IMPORTING
        iv_kind TYPE zif_mig_types=>ty_provider_kind
        iv_obj  TYPE zif_mig_types=>ty_sig_name
        iv_cls  TYPE zif_mig_types=>ty_sig_name OPTIONAL
        iv_stat TYPE zif_mig_types=>ty_provider_status
          DEFAULT zif_mig_types=>gc_provider_signature
        iv_svc  TYPE zif_mig_types=>ty_service_strategy
          DEFAULT zif_mig_types=>gc_svc_query
      RETURNING
        VALUE(rs_prv)
          TYPE zif_mig_types=>ty_provider_contract.


    METHODS:
      resolve_fm_sig
        FOR TESTING
        RAISING zcx_mig_analysis,

      resolve_mth_sig
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_change_both
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_no_output
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_missing_sig
        FOR TESTING
        RAISING zcx_mig_analysis,

      skip_refactor
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_sig_rslv IMPLEMENTATION.

  METHOD make_prv.

    rs_prv-analysis_id =
      gc_anl_id.

    rs_prv-service_strategy =
      iv_svc.

    rs_prv-provider_kind =
      iv_kind.

    rs_prv-provider_status =
      iv_stat.

    rs_prv-source_object_name =
      iv_obj.

    rs_prv-source_container_name =
      iv_cls.

  ENDMETHOD.


  METHOD resolve_fm_sig.

    DATA(ls_prv) =
      make_prv(
        iv_kind =
          zif_mig_types=>gc_provider_function

        iv_obj =
          'Z_READ_DATA'
      ).


    DATA(lo_repo) =
      NEW lcl_sig_repo( ).

    DATA(lo_rslv) =
      NEW zcl_mig_sig_rslv(
        io_repo = lo_repo
      ).


    DATA(ls_result) =
      lo_rslv->zif_mig_sig_rslv~resolve(
        is_prv = ls_prv
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_ready
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-input_params )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-output_params )
    ).


    READ TABLE ls_result-output_params
      INDEX 1
      INTO DATA(ls_out).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ET_RESULT'
      act = ls_out-par_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Collection'
      act = ls_out-edm_type
    ).

  ENDMETHOD.


  METHOD resolve_mth_sig.

    DATA(ls_prv) =
      make_prv(
        iv_kind =
          zif_mig_types=>gc_provider_class_method

        iv_obj =
          'READ_DATA'

        iv_cls =
          'ZCL_LEGACY_REPORT'
      ).


    DATA(lo_rslv) =
      NEW zcl_mig_sig_rslv(
        io_repo = NEW lcl_sig_repo( )
      ).


    DATA(ls_result) =
      lo_rslv->zif_mig_sig_rslv~resolve(
        is_prv = ls_prv
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_ready
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'RT_RESULT'
      act = ls_result-output_params[ 1 ]-par_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_out
      act = ls_result-output_params[ 1 ]-odata_role
    ).

  ENDMETHOD.


  METHOD map_change_both.

    DATA(ls_prv) =
      make_prv(
        iv_kind =
          zif_mig_types=>gc_provider_function

        iv_obj =
          'Z_CHANGE_DATA'

        iv_svc =
          zif_mig_types=>gc_svc_action
      ).


    DATA(lo_rslv) =
      NEW zcl_mig_sig_rslv(
        io_repo = NEW lcl_sig_repo( )
      ).


    DATA(ls_result) =
      lo_rslv->zif_mig_sig_rslv~resolve(
        is_prv = ls_prv
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-input_params )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-output_params )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_both
      act = ls_result-all_params[ 1 ]-odata_role
    ).

  ENDMETHOD.


  METHOD reject_no_output.

    DATA(ls_prv) =
      make_prv(
        iv_kind =
          zif_mig_types=>gc_provider_function

        iv_obj =
          'Z_NO_OUTPUT'
      ).


    DATA(lo_rslv) =
      NEW zcl_mig_sig_rslv(
        io_repo = NEW lcl_sig_repo( )
      ).


    DATA(ls_result) =
      lo_rslv->zif_mig_sig_rslv~resolve(
        is_prv = ls_prv
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-manual_review
    ).

  ENDMETHOD.


  METHOD reject_missing_sig.

    DATA(ls_prv) =
      make_prv(
        iv_kind =
          zif_mig_types=>gc_provider_function

        iv_obj =
          'Z_MISSING'
      ).


    DATA(lo_rslv) =
      NEW zcl_mig_sig_rslv(
        io_repo = NEW lcl_sig_repo( )
      ).


    DATA(ls_result) =
      lo_rslv->zif_mig_sig_rslv~resolve(
        is_prv = ls_prv
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_not_found
      act = ls_result-status
    ).

  ENDMETHOD.


  METHOD skip_refactor.

    DATA(ls_prv) =
      make_prv(
        iv_kind =
          zif_mig_types=>gc_provider_report_logic

        iv_obj =
          'ZRMIG_TEST_FULL'

        iv_stat =
          zif_mig_types=>gc_provider_refactor
      ).


    DATA(lo_rslv) =
      NEW zcl_mig_sig_rslv(
        io_repo = NEW lcl_sig_repo( )
      ).


    DATA(ls_result) =
      lo_rslv->zif_mig_sig_rslv~resolve(
        is_prv = ls_prv
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_sig_review
      act = ls_result-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-manual_review
    ).

  ENDMETHOD.

ENDCLASS.
