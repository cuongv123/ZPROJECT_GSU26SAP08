INTERFACE zif_mig_ai_config_provider
  PUBLIC.


  TYPES:
    BEGIN OF ty_config,

      provider
        TYPE zmig_ai_cfg-provider,

      destination
        TYPE rfcdest,

      model
        TYPE string,

      api_key
        TYPE string,

      timeout_sec
        TYPE i,

      max_output_tokens
        TYPE i,

    END OF ty_config.


  METHODS get_active_config
    IMPORTING
      iv_provider
        TYPE zmig_ai_cfg-provider

    RETURNING
      VALUE(rs_config)
        TYPE ty_config

    RAISING
      zcx_mig_analysis.


ENDINTERFACE.
