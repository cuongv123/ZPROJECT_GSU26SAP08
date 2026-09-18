INTERFACE zif_mig_service_blueprint
  PUBLIC.

  METHODS build
    IMPORTING
      is_analysis
        TYPE zif_mig_types=>ty_analysis_result
    RETURNING
      VALUE(rs_blueprint)
        TYPE zif_mig_types=>ty_service_blueprint_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
