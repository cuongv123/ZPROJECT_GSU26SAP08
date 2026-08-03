INTERFACE zif_mig_row_repo
  PUBLIC.

  METHODS read_type
    IMPORTING
      iv_type TYPE zif_mig_types=>ty_sig_name
    RETURNING
      VALUE(rs_row)
        TYPE zif_mig_types=>ty_row_def
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
