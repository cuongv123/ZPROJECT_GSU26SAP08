INTERFACE zif_mig_xco_executor PUBLIC.

  METHODS execute_query
    IMPORTING
      is_mfst
        TYPE zif_mig_types=>ty_art_mfst

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

      iv_transport
        TYPE trkorr

    RAISING
      zcx_mig_analysis
      cx_xco_gen_put_exception.

ENDINTERFACE.
