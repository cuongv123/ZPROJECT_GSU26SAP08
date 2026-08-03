INTERFACE zif_mig_art_pref
  PUBLIC.

  METHODS apply
    IMPORTING
      is_mfst TYPE zif_mig_types=>ty_art_mfst

      iv_allow_update
        TYPE abap_bool
        DEFAULT abap_false

    RETURNING
      VALUE(rs_mfst)
        TYPE zif_mig_types=>ty_art_mfst

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
