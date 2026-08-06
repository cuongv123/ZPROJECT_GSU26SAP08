INTERFACE zif_mig_art_pref
  PUBLIC.

  METHODS apply
  IMPORTING
    is_mfst
      TYPE zif_mig_types=>ty_art_mfst

  RETURNING
    VALUE(rs_mfst)
      TYPE zif_mig_types=>ty_art_mfst

  RAISING
    zcx_mig_analysis.

ENDINTERFACE.
