INTERFACE zif_mig_row_rslv
  PUBLIC.

  METHODS resolve
    IMPORTING
      is_bp
        TYPE zif_mig_types=>ty_service_blueprint_result

      is_smap
        TYPE zif_mig_types=>ty_svc_map_result

    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_row_result

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
