INTERFACE zif_mig_stmt_normalizer
  PUBLIC.

  METHODS normalize
    IMPORTING
      is_scan_result TYPE zif_mig_types=>ty_scan_result
    RETURNING
      VALUE(rs_result) TYPE zif_mig_types=>ty_scan_result.

ENDINTERFACE.
