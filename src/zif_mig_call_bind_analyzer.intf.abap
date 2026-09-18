INTERFACE zif_mig_call_bind_analyzer
  PUBLIC.

  METHODS analyze
    IMPORTING
      iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id OPTIONAL
      it_source_units TYPE zif_mig_types=>tt_source_unit
      it_logic        TYPE zif_mig_types=>tt_business_logic
      it_evidences    TYPE zif_mig_types=>tt_evidence

    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_call_bind_analysis_result

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
