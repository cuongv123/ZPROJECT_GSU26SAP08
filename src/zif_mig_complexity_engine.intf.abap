INTERFACE zif_mig_complexity_engine
  PUBLIC.

  METHODS enrich
    CHANGING
      cs_result TYPE zif_mig_types=>ty_analysis_result.

ENDINTERFACE.
