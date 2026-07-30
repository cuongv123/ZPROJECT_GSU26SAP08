INTERFACE zif_mig_analysis_store
  PUBLIC.

  METHODS save
    IMPORTING
      is_result TYPE zif_mig_types=>ty_analysis_result
    RAISING
      zcx_mig_analysis.

  METHODS read
    IMPORTING
      iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_analysis_result
    RAISING
      zcx_mig_analysis.

  METHODS exists
    IMPORTING
      iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
    RETURNING
      VALUE(rv_exists) TYPE abap_bool.

  METHODS delete
    IMPORTING
      iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
