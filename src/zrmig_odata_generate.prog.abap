REPORT zrmig_odata_generate.

PARAMETERS:
  p_anlid TYPE zif_mig_types=>ty_analysis_id OBLIGATORY,
  p_pack  TYPE devclass OBLIGATORY,
  p_prvpk TYPE devclass,
  p_std   AS CHECKBOX DEFAULT abap_false,
  p_req   TYPE trkorr,
  p_exec  AS CHECKBOX DEFAULT abap_false.


AT SELECTION-SCREEN.

  IF p_std = abap_true AND p_prvpk IS INITIAL.
    MESSAGE 'Enter the Standard ABAP provider package in P_PRVPK.' TYPE 'E'.
  ENDIF.

  IF p_exec = abap_true
     AND p_req IS INITIAL.

    MESSAGE 'Transport request is required when Execute is selected.'
      TYPE 'E'.

  ENDIF.


START-OF-SELECTION.

  TRY.

      "Classic composition root; orchestration only knows the interface.
      DATA lo_provider_gen TYPE REF TO zif_mig_prv_clas_gen.
      DATA(lv_provider_language) = zif_mig_prv_clas_gen=>gc_cloud.
      IF p_std = abap_true.
        lo_provider_gen = NEW zcl_mig_prv_std_gen( ).
        lv_provider_language = zif_mig_prv_clas_gen=>gc_standard.
      ENDIF.

      DATA(ls_result) =
        NEW zcl_mig_odata_gen_svc(
            io_provider_gen = lo_provider_gen
          )->zif_mig_odata_gen_svc~generate(
            is_request = VALUE #(
              analysis_id = p_anlid
              package     = p_pack
              provider_package = p_prvpk
              provider_language = lv_provider_language
              transport   = p_req
              execute     = p_exec
            )
        ).


      WRITE:
        / 'Analysis ID        :', ls_result-analysis_id,
        / 'Status             :', ls_result-status,
        / 'Strategy           :', ls_result-strategy,
        / 'Manual review      :', ls_result-manual_review,
        / 'Provider kind      :', ls_result-provider_kind,
        / 'Provider object    :', ls_result-provider_object,
        / 'Artifacts to create:', ls_result-create_count,
        / 'Blocked artifacts  :', ls_result-block_count,
        / 'Query provider     :', ls_result-query_provider_class,
        / 'Provider package   :', ls_result-provider_package,
        / 'Provider language  :', ls_result-provider_language,
        / 'Custom entity      :', ls_result-entity_name,
        / 'Service definition :', ls_result-service_name,
        / 'Shared binding     :', ls_result-service_binding,
        / 'Message            :', ls_result-message.


      IF p_exec = abap_false
         AND ls_result-status =
               zif_mig_odata_gen_svc=>gc_status_ready.

        SKIP.

        WRITE:
          / 'Dry-run only: no repository object was created.',
          / 'Run again with Execute selected and a transport request.'.

      ENDIF.


      IF p_exec = abap_true
         AND ls_result-status =
               zif_mig_odata_gen_svc=>gc_status_generated.

        SKIP.

        WRITE:
          / 'Repository generation completed.',
          / 'Open the shared binding in ADT and publish it if required.'.

      ENDIF.


    CATCH zcx_mig_analysis INTO DATA(lx_analysis).

      WRITE:
        / 'Generation failed:',
        / lx_analysis->get_text( ).


    CATCH cx_xco_gen_put_exception INTO DATA(lx_xco).

  WRITE:
    / 'XCO repository generation failed:',
    / lx_xco->get_text( ).

  DATA(lt_messages) =
    lx_xco->if_xco_news~get_messages( ).

  IF lt_messages IS INITIAL.

    WRITE:
      / 'No detailed XCO message returned.'.

  ELSE.

    SKIP.
    WRITE:
      / 'Detailed XCO messages:'.

    LOOP AT lt_messages
      INTO DATA(lo_message).

      WRITE:
        / lo_message->get_text( ).

    ENDLOOP.

  ENDIF.

  ENDTRY.
