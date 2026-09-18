INTERFACE zif_mig_provider_contract
  PUBLIC.

  METHODS build
    IMPORTING
      is_analysis
        TYPE zif_mig_types=>ty_analysis_result

      is_blueprint
        TYPE zif_mig_types=>ty_service_blueprint_result

    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_provider_contract_result

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
