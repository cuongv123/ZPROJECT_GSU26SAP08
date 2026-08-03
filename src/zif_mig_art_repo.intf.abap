INTERFACE zif_mig_art_repo
  PUBLIC.

  METHODS read_many
    IMPORTING
      it_items
        TYPE zif_mig_types=>tt_art_item

    RETURNING
      VALUE(rt_info)
        TYPE zif_mig_types=>tt_art_repo_info

    RAISING
      zcx_mig_analysis.


  METHODS read_info
    IMPORTING
      iv_type TYPE zif_mig_types=>ty_art_type
      iv_name TYPE zif_mig_types=>ty_art_name

    RETURNING
      VALUE(rs_info)
        TYPE zif_mig_types=>ty_art_repo_info

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
