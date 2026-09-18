INTERFACE zif_mig_source_repo
  PUBLIC.

  METHODS read_program
    IMPORTING
      iv_program_name TYPE progname
    RETURNING
      VALUE(rt_source) TYPE zif_mig_types=>tt_source_line
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
