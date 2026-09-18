INTERFACE zif_mig_svc_map
  PUBLIC.

  METHODS build
    IMPORTING
      is_bp
        TYPE zif_mig_types=>ty_service_blueprint_result

      is_sig
        TYPE zif_mig_types=>ty_sig_result

    RETURNING
      VALUE(rs_map)
        TYPE zif_mig_types=>ty_svc_map_result

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
