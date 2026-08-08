CLASS zcl_mig_provider_contract DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_provider_contract.

  PRIVATE SECTION.

    TYPES:
      ty_target_name TYPE c LENGTH 30.


    METHODS build_candidates
      IMPORTING
        it_business_logic
          TYPE zif_mig_types=>tt_business_logic
      RETURNING
        VALUE(rt_candidates)
          TYPE zif_mig_types=>tt_provider_candidate.


    METHODS classify_candidate
      IMPORTING
        is_logic
          TYPE zif_mig_types=>ty_business_logic
      RETURNING
        VALUE(rs_candidate)
          TYPE zif_mig_types=>ty_provider_candidate.


    METHODS select_contract
      IMPORTING
        is_analysis
          TYPE zif_mig_types=>ty_analysis_result

        is_blueprint
          TYPE zif_mig_types=>ty_service_blueprint_result

      CHANGING
        cs_contract
          TYPE zif_mig_types=>ty_provider_contract

        ct_candidates
          TYPE zif_mig_types=>tt_provider_candidate.


    METHODS make_target_name
      IMPORTING
        iv_prefix       TYPE string
        iv_program_name TYPE progname
      RETURNING
        VALUE(rv_name) TYPE ty_target_name.

ENDCLASS.

CLASS zcl_mig_provider_contract IMPLEMENTATION.

  METHOD zif_mig_provider_contract~build.

    IF is_analysis-analysis_id IS INITIAL
       OR is_analysis-overview-program_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        program_name = is_analysis-overview-program_name
      ).

    ENDIF.


    IF is_blueprint-blueprint-analysis_id
         <> is_analysis-analysis_id.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        program_name = is_analysis-overview-program_name
      ).

    ENDIF.


    rs_result-contract-analysis_id =
      is_analysis-analysis_id.

    rs_result-contract-service_strategy =
      is_blueprint-blueprint-strategy.


    DATA lv_class_prefix TYPE string.

    IF is_blueprint-blueprint-strategy =
         zif_mig_types=>gc_svc_query.

      lv_class_prefix = 'ZCL_MIG_Q_'.

      rs_result-contract-proposed_method_name =
        'GET_DATA'.

    ELSEIF is_blueprint-blueprint-strategy =
             zif_mig_types=>gc_svc_action.

      lv_class_prefix = 'ZCL_MIG_A_'.

      rs_result-contract-proposed_method_name =
        'EXECUTE'.

    ELSE.

      lv_class_prefix = 'ZCL_MIG_P_'.

      rs_result-contract-proposed_method_name =
        'EXECUTE'.

    ENDIF.


    rs_result-contract-proposed_class_name =
      make_target_name(
        iv_prefix       = lv_class_prefix
        iv_program_name =
          is_analysis-overview-program_name
      ).


    rs_result-candidates =
      build_candidates(
        it_business_logic =
          is_analysis-business_logic
      ).


    select_contract(
      EXPORTING
        is_analysis  = is_analysis
        is_blueprint = is_blueprint
      CHANGING
        cs_contract   = rs_result-contract
        ct_candidates = rs_result-candidates
    ).

  ENDMETHOD.

    METHOD build_candidates.

    LOOP AT it_business_logic
      INTO DATA(ls_logic).

      DATA(ls_candidate) =
        classify_candidate(
          is_logic = ls_logic
        ).

      IF ls_candidate-provider_kind =
           zif_mig_types=>gc_provider_none.

        CONTINUE.

      ENDIF.

      APPEND ls_candidate
        TO rt_candidates.

    ENDLOOP.


    SORT rt_candidates
      BY priority
         provider_kind
         container_name
         object_name.


    DELETE ADJACENT DUPLICATES
      FROM rt_candidates
      COMPARING
        provider_kind
        container_name
        object_name.

  ENDMETHOD.

    METHOD classify_candidate.

    CLEAR rs_candidate.

    rs_candidate-source_item_id =
      is_logic-item_id.

    rs_candidate-object_name =
      is_logic-object_name.

    rs_candidate-object_type =
      is_logic-object_type.

    rs_candidate-container_name =
      is_logic-container_name.

    rs_candidate-calling_routine =
      is_logic-calling_routine.

    rs_candidate-interface_summary =
      is_logic-interface_summary.

    rs_candidate-side_effect =
      is_logic-side_effect.

    rs_candidate-transaction_dependency =
      is_logic-transaction_dependency.

    rs_candidate-gui_dependency =
      is_logic-gui_dependency.

    rs_candidate-reuse_feasibility =
      is_logic-reuse_feasibility.

    rs_candidate-selected =
      abap_false.


    "==========================================================
    " GUI objects không thể wrap trực tiếp
    "==========================================================
    IF is_logic-gui_dependency = abap_true
       OR is_logic-object_type = 'DYPRO'
       OR is_logic-object_type = 'TRANSACTION'
       OR is_logic-object_type = 'MODULE'.

      rs_candidate-provider_kind =
        zif_mig_types=>gc_provider_report_logic.

      rs_candidate-provider_status =
        zif_mig_types=>gc_provider_unsupported.

      rs_candidate-priority = 90.

      rs_candidate-decision_reason =
        'GUI-dependent object cannot be wrapped directly as OData.'.

      RETURN.

    ENDIF.

    IF is_logic-object_name CP 'CONVERSION_EXIT_*'.

      rs_candidate-provider_kind =
        zif_mig_types=>gc_provider_none.

      RETURN.

    ENDIF.

    IF is_logic-container_name CP 'CL_SALV_*'
       OR is_logic-container_name CP 'CL_GUI_ALV_*'
       OR is_logic-object_name = 'FACTORY'
       OR is_logic-object_name = 'DISPLAY'
       OR is_logic-object_name = 'GET_COLUMNS'
       OR is_logic-object_name = 'SET_OPTIMIZE'
       OR is_logic-object_name = 'GET_TEXT'.

      rs_candidate-provider_kind =
        zif_mig_types=>gc_provider_none.

      RETURN.

    ENDIF.

    DATA(lv_calling_routine) =
  to_upper(
    CONV string(
      is_logic-calling_routine
    )
  ).

    IF is_logic-object_type = 'BAPI'
       AND
       ( lv_calling_routine CP 'ENRICH*'
         OR lv_calling_routine CP 'CONVERT*'
         OR lv_calling_routine CP 'NORMALIZE*'
         OR lv_calling_routine CP 'FORMAT*'
         OR lv_calling_routine CP 'DISPLAY*'
         OR lv_calling_routine CP 'VALIDATE*'
         OR lv_calling_routine CP 'WRITE*' ).

      rs_candidate-provider_kind =
        zif_mig_types=>gc_provider_none.

      RETURN.

    ENDIF.
    IF is_logic-object_name CP 'Z_*'
       OR is_logic-object_name CP 'Y_*'.

      rs_candidate-priority = 10.

    ELSE.

      rs_candidate-priority = 30.

    ENDIF.

    CASE is_logic-object_type.

      "========================================================
      " Static class method
      "========================================================
      WHEN 'STATIC_METHOD'.

        rs_candidate-provider_kind =
          zif_mig_types=>gc_provider_class_method.

        IF is_logic-container_name CP 'ZCL_*'
           OR is_logic-container_name CP 'YCL_*'.

          rs_candidate-priority = 10.

          IF is_logic-interface_summary IS INITIAL.

            rs_candidate-provider_status =
              zif_mig_types=>gc_provider_signature.

            rs_candidate-decision_reason =
              'Global static method selected; interface signature must be resolved.'.

          ELSE.

            rs_candidate-provider_status =
              zif_mig_types=>gc_provider_ready.

            rs_candidate-decision_reason =
              'Global static method is reusable as provider target.'.

          ENDIF.

        ELSE.

          rs_candidate-priority = 40.

          rs_candidate-provider_status =
            zif_mig_types=>gc_provider_refactor.

          rs_candidate-decision_reason =
            'Local or unresolved static method must be extracted before generation.'.

        ENDIF.


      "========================================================
      " Instance method
      "========================================================
      WHEN 'INSTANCE_METHOD'.

        rs_candidate-provider_kind =
          zif_mig_types=>gc_provider_class_method.

        IF is_logic-container_name CP 'ZCL_*'
           OR is_logic-container_name CP 'YCL_*'.

          rs_candidate-priority = 20.

          IF is_logic-interface_summary IS INITIAL.

            rs_candidate-provider_status =
              zif_mig_types=>gc_provider_signature.

            rs_candidate-decision_reason =
              'Global instance method requires constructor and signature resolution.'.

          ELSE.

            rs_candidate-provider_status =
              zif_mig_types=>gc_provider_ready.

            rs_candidate-decision_reason =
              'Global instance method can be wrapped by an adapter.'.

          ENDIF.

        ELSE.

          rs_candidate-priority = 40.

          rs_candidate-provider_status =
            zif_mig_types=>gc_provider_refactor.

          rs_candidate-decision_reason =
            'Instance variable type could not be resolved to a global class.'.

        ENDIF.


      "========================================================
      " Function Module
      "========================================================
      WHEN 'FUNCTION_MODULE'.

        rs_candidate-provider_kind =
          zif_mig_types=>gc_provider_function.

        rs_candidate-priority = 20.

        IF is_logic-interface_summary IS INITIAL.

          rs_candidate-provider_status =
            zif_mig_types=>gc_provider_signature.

          rs_candidate-decision_reason =
            'Function module selected; interface signature must be resolved.'.

        ELSE.

          rs_candidate-provider_status =
            zif_mig_types=>gc_provider_ready.

          rs_candidate-decision_reason =
            'Function module can be wrapped by a provider adapter.'.

        ENDIF.


      "========================================================
      " BAPI
      "========================================================
      WHEN 'BAPI'.

        rs_candidate-provider_kind =
          zif_mig_types=>gc_provider_bapi.

        rs_candidate-priority = 20.

        IF is_logic-interface_summary IS INITIAL.

          rs_candidate-provider_status =
            zif_mig_types=>gc_provider_signature.

          rs_candidate-decision_reason =
            'BAPI selected; interface and transaction behavior must be resolved.'.

        ELSE.

          rs_candidate-provider_status =
            zif_mig_types=>gc_provider_ready.

          rs_candidate-decision_reason =
            'BAPI can be wrapped through a RAP action adapter.'.

        ENDIF.


      "========================================================
      " Logic nằm trực tiếp trong report
      "========================================================
      WHEN 'METHOD_DEFINITION'
        OR 'FORM_DEFINITION'
        OR 'FORM_CALL'
        OR 'FUNCTION_DEFINITION'.

        rs_candidate-provider_kind =
          zif_mig_types=>gc_provider_report_logic.

        rs_candidate-provider_status =
          zif_mig_types=>gc_provider_refactor.

        rs_candidate-priority = 50.

        rs_candidate-decision_reason =
          'Local report logic must be extracted into a reusable global class.'.


      "========================================================
      " SUBMIT report khác
      "========================================================
      WHEN 'REPORT_SUBMIT'.

        rs_candidate-provider_kind =
          zif_mig_types=>gc_provider_report_logic.

        rs_candidate-provider_status =
          zif_mig_types=>gc_provider_review.

        rs_candidate-priority = 60.

        rs_candidate-decision_reason =
          'SUBMIT dependency requires explicit provider design.'.


      WHEN OTHERS.

        rs_candidate-provider_kind =
          zif_mig_types=>gc_provider_none.

    ENDCASE.

  ENDMETHOD.

    METHOD select_contract.

    "==========================================================
    " Blueprint đã yêu cầu manual review thì không tự chọn target
    "==========================================================
    IF is_blueprint-blueprint-strategy =
         zif_mig_types=>gc_svc_manual.

      cs_contract-provider_kind =
        zif_mig_types=>gc_provider_none.

      cs_contract-provider_status =
        zif_mig_types=>gc_provider_review.

      cs_contract-manual_review =
        abap_true.

      cs_contract-decision_reason =
        'Service blueprint requires manual review before provider selection.'.

      RETURN.

    ENDIF.


    DATA:
      lv_best_priority TYPE i VALUE 999999,
      lv_best_count    TYPE i.


    "==========================================================
    " Chỉ READY và SIGNATURE_REQUIRED mới là target tự chọn được
    "==========================================================
    LOOP AT ct_candidates
      INTO DATA(ls_candidate).

      IF ls_candidate-provider_status
           <> zif_mig_types=>gc_provider_ready
         AND ls_candidate-provider_status
           <> zif_mig_types=>gc_provider_signature.

        CONTINUE.

      ENDIF.


      IF ls_candidate-priority < lv_best_priority.

        lv_best_priority =
          ls_candidate-priority.

        lv_best_count = 1.

      ELSEIF ls_candidate-priority = lv_best_priority.

        lv_best_count += 1.

      ENDIF.

    ENDLOOP.


    "==========================================================
    " Nhiều target cùng mức ưu tiên
    "==========================================================
    IF lv_best_count > 1.

      cs_contract-provider_kind =
        zif_mig_types=>gc_provider_none.

      cs_contract-provider_status =
        zif_mig_types=>gc_provider_review.

      cs_contract-manual_review =
        abap_true.

      cs_contract-decision_reason =
        'Multiple equally suitable provider targets were found.'.

      RETURN.

    ENDIF.


    "==========================================================
    " Một target duy nhất
    "==========================================================
    IF lv_best_count = 1.

      LOOP AT ct_candidates
        ASSIGNING FIELD-SYMBOL(<candidate>).

        IF <candidate>-priority <> lv_best_priority.

          CONTINUE.

        ENDIF.

        IF <candidate>-provider_status
             <> zif_mig_types=>gc_provider_ready
           AND <candidate>-provider_status
             <> zif_mig_types=>gc_provider_signature.

          CONTINUE.

        ENDIF.


        <candidate>-selected =
          abap_true.

        cs_contract-source_item_id =
          <candidate>-source_item_id.

        cs_contract-provider_kind =
          <candidate>-provider_kind.

        cs_contract-provider_status =
          <candidate>-provider_status.

        cs_contract-source_object_name =
          <candidate>-object_name.

        cs_contract-source_container_name =
          <candidate>-container_name.

        cs_contract-source_interface_summary =
          <candidate>-interface_summary.

        cs_contract-manual_review =
          abap_false.

        cs_contract-decision_reason =
          <candidate>-decision_reason.

        RETURN.

      ENDLOOP.

    ENDIF.


    "==========================================================
    " Không có callable target: logic cần extract/refactor
    "==========================================================
    LOOP AT ct_candidates
      TRANSPORTING NO FIELDS
      WHERE provider_status =
        zif_mig_types=>gc_provider_refactor.

      cs_contract-provider_kind =
        zif_mig_types=>gc_provider_report_logic.

      cs_contract-provider_status =
        zif_mig_types=>gc_provider_refactor.

      cs_contract-source_object_name =
        is_analysis-overview-program_name.

      cs_contract-manual_review =
        abap_true.

      cs_contract-decision_reason =
        'Report logic must be extracted into a reusable provider class.'.

      RETURN.

    ENDLOOP.


    "==========================================================
    " Không tìm thấy business object callable nào
    "==========================================================
    cs_contract-provider_kind =
      zif_mig_types=>gc_provider_report_logic.

    cs_contract-provider_status =
      zif_mig_types=>gc_provider_refactor.

    cs_contract-source_object_name =
      is_analysis-overview-program_name.

    cs_contract-manual_review =
      abap_true.

    cs_contract-decision_reason =
      'No reusable function module or class method was identified.'.

  ENDMETHOD.

    METHOD make_target_name.

    DATA lv_base TYPE string.

    lv_base =
      to_upper(
        CONV string(
          iv_program_name
        )
      ).

    CONDENSE lv_base NO-GAPS.

    REPLACE ALL OCCURRENCES OF '-'
      IN lv_base
      WITH '_'.


    DATA(lv_max_base_length) =
      30 - strlen( iv_prefix ).

    IF strlen( lv_base ) > lv_max_base_length.

      lv_base =
        substring(
          val = lv_base
          len = lv_max_base_length
        ).

    ENDIF.


    rv_name =
      |{ iv_prefix }{ lv_base }|.

  ENDMETHOD.

ENDCLASS.
