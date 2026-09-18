INTERFACE zif_mig_db_analyzer
  PUBLIC.

  METHODS analyze
    IMPORTING
      iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id OPTIONAL
      it_source_units TYPE zif_mig_types=>tt_source_unit
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_db_analysis_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
