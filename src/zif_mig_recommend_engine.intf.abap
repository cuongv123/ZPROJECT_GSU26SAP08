INTERFACE zif_mig_recommend_engine
  PUBLIC.

  METHODS enrich
    CHANGING
      cs_result TYPE zif_mig_types=>ty_analysis_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
