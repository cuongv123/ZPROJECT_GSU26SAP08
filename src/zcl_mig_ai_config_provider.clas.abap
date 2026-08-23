CLASS zcl_mig_ai_config_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.


  PUBLIC SECTION.

    INTERFACES
      zif_mig_ai_config_provider.


ENDCLASS.



CLASS zcl_mig_ai_config_provider IMPLEMENTATION.


  METHOD zif_mig_ai_config_provider~get_active_config.

    CLEAR rs_config.


    DATA(lv_provider) =
      to_upper(
        condense(
          iv_provider
        )
      ).


    IF lv_provider IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    DATA ls_db_config
      TYPE zmig_ai_cfg.


    SELECT SINGLE *
      FROM zmig_ai_cfg
      WHERE provider = @lv_provider
        AND active   = @abap_true
      INTO @ls_db_config.


    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " Configuration must be complete before constructing client
    "==========================================================

    IF ls_db_config-destination IS INITIAL
       OR ls_db_config-model IS INITIAL
       OR ls_db_config-api_key IS INITIAL
       OR ls_db_config-timeout_sec <= 0
       OR ls_db_config-max_output_tokens <= 0.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    rs_config-provider =
      ls_db_config-provider.


    rs_config-destination =
      ls_db_config-destination.


    rs_config-model =
      CONV string(
        ls_db_config-model
      ).


    rs_config-api_key =
      CONV string(
        ls_db_config-api_key
      ).


    rs_config-timeout_sec =
      ls_db_config-timeout_sec.


    rs_config-max_output_tokens =
      ls_db_config-max_output_tokens.

  ENDMETHOD.


ENDCLASS.
