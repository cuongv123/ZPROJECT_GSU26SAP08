INTERFACE zif_mig_ai_prompt_builder
  PUBLIC.


  METHODS build

    IMPORTING

      iv_program_name
        TYPE progname

      iv_markdown
        TYPE string

    RETURNING

      VALUE(rs_prompt)
        TYPE zif_mig_ai_types=>ty_prompt

    RAISING

      zcx_mig_analysis.


ENDINTERFACE.
