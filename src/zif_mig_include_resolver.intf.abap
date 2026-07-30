INTERFACE zif_mig_include_resolver
  PUBLIC.

  METHODS resolve
    IMPORTING
      iv_root_program TYPE progname
    RETURNING
      VALUE(rt_source_units)
        TYPE zif_mig_types=>tt_source_unit
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
