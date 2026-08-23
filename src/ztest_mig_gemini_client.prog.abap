REPORT ztest_mig_ai_cfg_setup.


PARAMETERS:
  p_key   TYPE c LENGTH 255 LOWER CASE OBLIGATORY,
  p_dest  TYPE rfcdest DEFAULT 'ZGEMINI_API',
  p_model TYPE c LENGTH 80 LOWER CASE
          DEFAULT 'gemini-3.5-flash-lite',
  p_time  TYPE i DEFAULT 120,
  p_token TYPE i DEFAULT 8192.


START-OF-SELECTION.


  "============================================================
  " 1. Validate input
  "============================================================

  IF p_key IS INITIAL
     OR p_dest IS INITIAL
     OR p_model IS INITIAL
     OR p_time <= 0
     OR p_token <= 0.

    WRITE: / 'Invalid configuration.'.
    RETURN.

  ENDIF.


  "============================================================
  " 2. Save / update GEMINI configuration
  "============================================================

  DATA ls_config
    TYPE zmig_ai_cfg.


  ls_config-mandt =
    sy-mandt.

  ls_config-provider =
    'GEMINI'.

  ls_config-active =
    abap_true.

  ls_config-destination =
    p_dest.

  ls_config-model =
    p_model.

  ls_config-api_key =
    p_key.

  ls_config-timeout_sec =
    p_time.

  ls_config-max_output_tokens =
    p_token.


  MODIFY zmig_ai_cfg
    FROM @ls_config.


  IF sy-subrc <> 0.

    ROLLBACK WORK.

    WRITE: / 'Failed to save Gemini configuration.'.
    RETURN.

  ENDIF.


  COMMIT WORK AND WAIT.


  "============================================================
  " 3. Test Config Provider
  "============================================================

  TRY.

      DATA(lo_provider) =
        NEW zcl_mig_ai_config_provider( ).


      DATA(ls_loaded_config) =
        lo_provider->zif_mig_ai_config_provider~get_active_config(
          iv_provider =
            'GEMINI'
        ).


      WRITE: / '=== AI CONFIG PROVIDER TEST SUCCESS ==='.

      SKIP.

      WRITE: / 'Provider:'.
      WRITE: / ls_loaded_config-provider.

      WRITE: / 'Destination:'.
      WRITE: / ls_loaded_config-destination.

      WRITE: / 'Model:'.
      WRITE: / ls_loaded_config-model.

      WRITE: / 'Timeout:'.
      WRITE: / ls_loaded_config-timeout_sec.

      WRITE: / 'Max Output Tokens:'.
      WRITE: / ls_loaded_config-max_output_tokens.


      "========================================================
      " Never display actual API key
      "========================================================

      IF ls_loaded_config-api_key IS NOT INITIAL.

        WRITE: / 'API Key:'.
        WRITE: / '*** CONFIGURED ***'.

      ENDIF.


    CATCH zcx_mig_analysis INTO DATA(lx_analysis).

      WRITE: / 'CONFIG ERROR:'.
      WRITE: / lx_analysis->get_text( ).

  ENDTRY.
