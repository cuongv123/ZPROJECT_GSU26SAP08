INTERFACE zif_mig_sig_rslv
  PUBLIC.

  METHODS resolve
    IMPORTING
      is_prv
        TYPE zif_mig_types=>ty_provider_contract
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_sig_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
