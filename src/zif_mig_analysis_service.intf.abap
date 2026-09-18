INTERFACE zif_mig_analysis_service
  PUBLIC.

  METHODS analyze_program
    IMPORTING
      iv_program_name TYPE zif_mig_types=>ty_program_name
      iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id OPTIONAL
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_analysis_result
    RAISING
      zcx_mig_analysis.

  METHODS analyze_and_save
    IMPORTING
      iv_program_name TYPE zif_mig_types=>ty_program_name
      iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id OPTIONAL
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_analysis_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
