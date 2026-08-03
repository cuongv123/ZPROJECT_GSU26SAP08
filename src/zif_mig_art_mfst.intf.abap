INTERFACE zif_mig_art_mfst
  PUBLIC.

  METHODS build
    IMPORTING
      iv_package TYPE devclass

      is_bp
        TYPE zif_mig_types=>ty_service_blueprint_result

      is_prv
        TYPE zif_mig_types=>ty_provider_contract

      is_sig
        TYPE zif_mig_types=>ty_sig_result

      is_smap
        TYPE zif_mig_types=>ty_svc_map_result

      is_row
        TYPE zif_mig_types=>ty_row_result

    RETURNING
      VALUE(rs_mfst)
        TYPE zif_mig_types=>ty_art_mfst

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
