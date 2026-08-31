REPORT zrmig_odata_generate.

PARAMETERS:
  p_anlid TYPE zif_mig_types=>ty_analysis_id OBLIGATORY,
  p_pack  TYPE devclass OBLIGATORY,
  p_req   TYPE trkorr,
  p_exec  AS CHECKBOX DEFAULT abap_false.


AT SELECTION-SCREEN.

  IF p_exec = abap_true
     AND p_req IS INITIAL.

    MESSAGE 'Transport request is required when Execute is selected.'
      TYPE 'E'.

  ENDIF.


START-OF-SELECTION.

  TRY.

      DATA(ls_result) =
        NEW zcl_mig_odata_gen_svc(
          )->zif_mig_odata_gen_svc~generate(
            is_request = VALUE #(
              analysis_id = p_anlid
              package     = p_pack
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

  ENDTRY.
