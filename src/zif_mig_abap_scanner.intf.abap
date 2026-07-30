INTERFACE zif_mig_abap_scanner
  PUBLIC.

  METHODS scan
    IMPORTING
      iv_source_object TYPE progname
      it_source        TYPE zif_mig_types=>tt_source_line
    RETURNING
      VALUE(rs_result) TYPE zif_mig_types=>ty_scan_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
