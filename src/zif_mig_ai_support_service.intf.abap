INTERFACE zif_mig_ai_support_service
  PUBLIC.


  METHODS analyze
    IMPORTING

      iv_analysis_id
        TYPE zif_mig_types=>ty_analysis_id

    RETURNING

      VALUE(rs_assessment)
        TYPE zif_mig_ai_types=>ty_assessment

    RAISING
      zcx_mig_analysis.


ENDINTERFACE.
