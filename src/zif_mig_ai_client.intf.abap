INTERFACE zif_mig_ai_client
  PUBLIC.


  METHODS execute

    IMPORTING

      is_prompt
        TYPE zif_mig_ai_types=>ty_prompt

    RETURNING

      VALUE(rv_response)
        TYPE string

    RAISING

      zcx_mig_analysis.


ENDINTERFACE.
