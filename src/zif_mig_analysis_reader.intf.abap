INTERFACE zif_mig_analysis_reader
  PUBLIC.

  METHODS read
    IMPORTING
      iv_analysis_id
        TYPE zif_mig_types=>ty_analysis_id

    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_analysis_result

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
