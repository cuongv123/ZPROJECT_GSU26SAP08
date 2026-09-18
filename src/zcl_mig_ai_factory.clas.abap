CLASS zcl_mig_ai_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.


  PUBLIC SECTION.


    CLASS-METHODS create_fake_support_service
      RETURNING
        VALUE(ro_service)
          TYPE REF TO zif_mig_ai_support_service.


    CLASS-METHODS create_gemini_support_service
      RETURNING
        VALUE(ro_service)
          TYPE REF TO zif_mig_ai_support_service

      RAISING
        zcx_mig_analysis.


ENDCLASS.



CLASS zcl_mig_ai_factory IMPLEMENTATION.


  METHOD create_fake_support_service.

    DATA(lo_prompt_builder) =
      NEW zcl_mig_ai_prompt_builder( ).


    DATA(lo_ai_client) =
      NEW zcl_mig_ai_client_fake( ).


    DATA(lo_response_parser) =
      NEW zcl_mig_ai_response_parser( ).


    DATA(lo_ai_service) =
      NEW zcl_mig_ai_service(
        io_prompt_builder =
          lo_prompt_builder

        io_ai_client =
          lo_ai_client

        io_response_parser =
          lo_response_parser
      ).


    ro_service =
      NEW zcl_mig_ai_support_service(
        io_ai_service =
          lo_ai_service
      ).

  ENDMETHOD.



  METHOD create_gemini_support_service.

    "==========================================================
    " 1. Read provider configuration
    "==========================================================

    DATA(lo_config_provider) =
      NEW zcl_mig_ai_config_provider( ).


    DATA(ls_config) =
      lo_config_provider->zif_mig_ai_config_provider~get_active_config(
        iv_provider =
          'GEMINI'
      ).


    "==========================================================
    " 2. Deterministic prompt builder
    "==========================================================

    DATA(lo_prompt_builder) =
      NEW zcl_mig_ai_prompt_builder( ).


    "==========================================================
    " 3. REAL Gemini provider adapter
    "==========================================================

    DATA(lo_ai_client) =
      NEW zcl_mig_ai_client_gemini(
        iv_destination =
          ls_config-destination

        iv_api_key =
          ls_config-api_key

        iv_model =
          ls_config-model

        iv_timeout =
          ls_config-timeout_sec

        iv_max_output_tokens =
          ls_config-max_output_tokens
      ).


    "==========================================================
    " 4. Existing response parser
    "==========================================================

    DATA(lo_response_parser) =
      NEW zcl_mig_ai_response_parser( ).


    "==========================================================
    " 5. AI orchestration service
    "==========================================================

    DATA(lo_ai_service) =
      NEW zcl_mig_ai_service(
        io_prompt_builder =
          lo_prompt_builder

        io_ai_client =
          lo_ai_client

        io_response_parser =
          lo_response_parser
      ).


    "==========================================================
    " 6. Application/support service
    "
    " Technical Document Service is still created internally
    " by ZCL_MIG_AI_SUPPORT_SERVICE.
    "==========================================================

    ro_service =
      NEW zcl_mig_ai_support_service(
        io_ai_service =
          lo_ai_service
      ).

  ENDMETHOD.


ENDCLASS.
