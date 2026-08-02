INTERFACE zif_mig_sig_repo
  PUBLIC.

  METHODS read_fm
    IMPORTING
      iv_fm TYPE zif_mig_types=>ty_sig_name
    RETURNING
      VALUE(rs_sig)
        TYPE zif_mig_types=>ty_sig_def
    RAISING
      zcx_mig_analysis.


  METHODS read_mth
    IMPORTING
      iv_class TYPE zif_mig_types=>ty_sig_name
      iv_mth   TYPE zif_mig_types=>ty_sig_name
    RETURNING
      VALUE(rs_sig)
        TYPE zif_mig_types=>ty_sig_def
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
