CLASS zcl_mig_sig_rslv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_sig_rslv.

    METHODS constructor
      IMPORTING
        io_repo TYPE REF TO zif_mig_sig_repo.

  PRIVATE SECTION.

    TYPES:
      ty_abap_type TYPE c LENGTH 30,
      ty_edm_type  TYPE c LENGTH 30.


    DATA mo_repo
      TYPE REF TO zif_mig_sig_repo.


    METHODS read_sig
      IMPORTING
        is_prv TYPE zif_mig_types=>ty_provider_contract
      RETURNING
        VALUE(rs_sig)
          TYPE zif_mig_types=>ty_sig_def
      RAISING
        zcx_mig_analysis.


    METHODS map_params
      IMPORTING
        is_prv TYPE zif_mig_types=>ty_provider_contract
        is_sig TYPE zif_mig_types=>ty_sig_def
      CHANGING
        cs_result TYPE zif_mig_types=>ty_sig_result.


    METHODS map_edm
      IMPORTING
        iv_abap  TYPE ty_abap_type
        iv_table TYPE abap_bool
      RETURNING
        VALUE(rv_edm) TYPE ty_edm_type.


    METHODS set_status
      IMPORTING
        is_prv TYPE zif_mig_types=>ty_provider_contract
        is_sig TYPE zif_mig_types=>ty_sig_def
      CHANGING
        cs_result TYPE zif_mig_types=>ty_sig_result.

ENDCLASS.

CLASS zcl_mig_sig_rslv IMPLEMENTATION.

  METHOD constructor.

    mo_repo = io_repo.

  ENDMETHOD.


  METHOD zif_mig_sig_rslv~resolve.

    rs_result-analysis_id =
      is_prv-analysis_id.

    rs_result-service_strategy =
      is_prv-service_strategy.

    rs_result-provider_kind =
      is_prv-provider_kind.

    rs_result-object_name =
      is_prv-source_object_name.

    rs_result-container_name =
      is_prv-source_container_name.


    IF mo_repo IS NOT BOUND.

      rs_result-status =
        zif_mig_types=>gc_sig_unsup.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Signature repository is not available.'.

      RETURN.

    ENDIF.


    IF is_prv-provider_status =
         zif_mig_types=>gc_provider_refactor.

      rs_result-status =
        zif_mig_types=>gc_sig_review.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Provider must be refactored before signature resolution.'.

      RETURN.

    ENDIF.


    IF is_prv-provider_status =
         zif_mig_types=>gc_provider_review
       OR is_prv-provider_status =
         zif_mig_types=>gc_provider_unsupported.

      rs_result-status =
        zif_mig_types=>gc_sig_unsup.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Provider contract does not allow automatic resolution.'.

      RETURN.

    ENDIF.


    DATA(ls_sig) =
      read_sig(
        is_prv = is_prv
      ).


    IF ls_sig-exists = abap_false.

      rs_result-status =
        zif_mig_types=>gc_sig_not_found.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Provider signature was not found.'.

      RETURN.

    ENDIF.


    map_params(
      EXPORTING
        is_prv = is_prv
        is_sig = ls_sig
      CHANGING
        cs_result = rs_result
    ).


    set_status(
      EXPORTING
        is_prv = is_prv
        is_sig = ls_sig
      CHANGING
        cs_result = rs_result
    ).

  ENDMETHOD.


  METHOD read_sig.

    CASE is_prv-provider_kind.

      WHEN zif_mig_types=>gc_provider_function
        OR zif_mig_types=>gc_provider_bapi.

        rs_sig =
          mo_repo->read_fm(
            iv_fm = is_prv-source_object_name
          ).


      WHEN zif_mig_types=>gc_provider_class_method.

        rs_sig =
          mo_repo->read_mth(
            iv_class =
              is_prv-source_container_name

            iv_mth =
              is_prv-source_object_name
          ).


      WHEN OTHERS.

        CLEAR rs_sig.

    ENDCASE.

  ENDMETHOD.


  METHOD map_params.

    LOOP AT is_sig-params
      INTO DATA(ls_par).

      IF ls_par-edm_type IS INITIAL.

        ls_par-edm_type =
          map_edm(
            iv_abap  = ls_par-abap_type
            iv_table = ls_par-is_table
          ).

      ENDIF.


      CASE ls_par-direction.

        WHEN zif_mig_types=>gc_sig_imp.

          ls_par-odata_role =
            zif_mig_types=>gc_sig_in.


        WHEN zif_mig_types=>gc_sig_exp
          OR zif_mig_types=>gc_sig_ret.

          ls_par-odata_role =
            zif_mig_types=>gc_sig_out.


        WHEN zif_mig_types=>gc_sig_chg.

          ls_par-odata_role =
            zif_mig_types=>gc_sig_both.


        WHEN zif_mig_types=>gc_sig_tab.

          IF is_prv-service_strategy =
               zif_mig_types=>gc_svc_query.

            ls_par-odata_role =
              zif_mig_types=>gc_sig_out.

          ELSE.

            ls_par-odata_role =
              zif_mig_types=>gc_sig_both.

          ENDIF.


        WHEN OTHERS.

          CONTINUE.

      ENDCASE.


      APPEND ls_par
        TO cs_result-all_params.


      IF ls_par-odata_role =
           zif_mig_types=>gc_sig_in
         OR ls_par-odata_role =
           zif_mig_types=>gc_sig_both.

        APPEND ls_par
          TO cs_result-input_params.

      ENDIF.


      IF ls_par-odata_role =
           zif_mig_types=>gc_sig_out
         OR ls_par-odata_role =
           zif_mig_types=>gc_sig_both.

        APPEND ls_par
          TO cs_result-output_params.

      ENDIF.

    ENDLOOP.


    SORT cs_result-all_params
      BY direction
         par_name.

    SORT cs_result-input_params
      BY par_name.

    SORT cs_result-output_params
      BY par_name.

  ENDMETHOD.


  METHOD map_edm.

    IF iv_table = abap_true.

      rv_edm = 'Collection'.
      RETURN.

    ENDIF.


    DATA(lv_type) =
      to_upper(
        CONV string( iv_abap )
      ).

    CONDENSE lv_type NO-GAPS.


    CASE lv_type.

      WHEN 'I'
        OR 'INT1'
        OR 'INT2'
        OR 'INT4'.

        rv_edm = 'Edm.Int32'.


      WHEN 'INT8'.

        rv_edm = 'Edm.Int64'.


      WHEN 'P'
        OR 'DEC'
        OR 'CURR'
        OR 'QUAN'
        OR 'DECFLOAT16'
        OR 'DECFLOAT34'.

        rv_edm = 'Edm.Decimal'.


      WHEN 'D'
        OR 'DATS'.

        rv_edm = 'Edm.Date'.


      WHEN 'T'
        OR 'TIMS'.

        rv_edm = 'Edm.TimeOfDay'.


      WHEN 'F'
        OR 'FLTP'.

        rv_edm = 'Edm.Double'.


      WHEN 'ABAP_BOOL'
        OR 'BOOLE_D'
        OR 'XFELD'.

        rv_edm = 'Edm.Boolean'.


      WHEN OTHERS.

        rv_edm = 'Edm.String'.

    ENDCASE.

  ENDMETHOD.


  METHOD set_status.

    IF cs_result-all_params IS INITIAL.

      cs_result-status =
        zif_mig_types=>gc_sig_review.

      cs_result-manual_review =
        abap_true.

      cs_result-decision_reason =
        'Provider signature has no parameters.'.

      RETURN.

    ENDIF.


    LOOP AT cs_result-all_params
      TRANSPORTING NO FIELDS
      WHERE is_ref  = abap_true
         OR is_deep = abap_true.

      cs_result-status =
        zif_mig_types=>gc_sig_review.

      cs_result-manual_review =
        abap_true.

      cs_result-decision_reason =
        'Reference or deep parameters require manual mapping.'.

      RETURN.

    ENDLOOP.


    IF is_prv-service_strategy =
         zif_mig_types=>gc_svc_query
       AND cs_result-output_params IS INITIAL.

      cs_result-status =
        zif_mig_types=>gc_sig_review.

      cs_result-manual_review =
        abap_true.

      cs_result-decision_reason =
        'Query provider has no output parameter.'.

      RETURN.

    ENDIF.


    cs_result-status =
      zif_mig_types=>gc_sig_ready.

    cs_result-manual_review =
      abap_false.

    cs_result-decision_reason =
      'Provider signature was resolved successfully.'.

  ENDMETHOD.

ENDCLASS.
