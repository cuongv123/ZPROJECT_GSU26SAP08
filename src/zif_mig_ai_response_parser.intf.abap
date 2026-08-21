INTERFACE zif_mig_ai_response_parser
  PUBLIC.


  METHODS parse

    IMPORTING

      iv_analysis_id
        TYPE zif_mig_types=>ty_analysis_id

      iv_program_name
        TYPE progname

      iv_response
        TYPE string

    RETURNING

      VALUE(rs_assessment)
        TYPE zif_mig_ai_types=>ty_assessment

    RAISING

      zcx_mig_analysis.


ENDINTERFACE.
