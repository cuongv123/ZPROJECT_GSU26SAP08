INTERFACE zif_mig_alv_fcat_analyzer
  PUBLIC.

  METHODS analyze
    IMPORTING
      iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id OPTIONAL
      it_source_units TYPE zif_mig_types=>tt_source_unit
      it_alv_outputs  TYPE zif_mig_types=>tt_alv_output
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_alv_fcat_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
