CLASS lhc_Run DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING
        REQUEST requested_authorizations
        FOR Run
      RESULT result.

    METHODS ExecuteComparison
      FOR MODIFY
      IMPORTING
        keys FOR ACTION Run~ExecuteComparison.

ENDCLASS.


CLASS lhc_Run IMPLEMENTATION.

  METHOD get_global_authorizations.

    IF requested_authorizations-%action-ExecuteComparison
       = if_abap_behv=>mk-on.

      result-%action-ExecuteComparison =
        if_abap_behv=>auth-allowed.

    ENDIF.

  ENDMETHOD.


  METHOD ExecuteComparison.

    LOOP AT keys INTO DATA(ls_key).

      TRY.

          DATA(lo_comparator) =
            NEW zcl_mig_comparator( ).

          lo_comparator->execute(
            iv_analysis_id = ls_key-%param-AnalysisId
          ).

          APPEND VALUE #(
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'Migration comparison completed successfully'
            )
          ) TO reported-Run.

        CATCH zcx_mig_comparison INTO DATA(lx_comparison).

          APPEND VALUE #(
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = lx_comparison->message
            )
          ) TO reported-Run.

      ENDTRY.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
