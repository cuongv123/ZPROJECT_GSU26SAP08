INTERFACE zif_mig_analysis_service
  PUBLIC.

  TYPES:
    BEGIN OF ty_analysis_result,
      overview       TYPE zcl_parser_types=>ty_overview,
      ui_filters     TYPE zcl_parser_types=>tt_ui_filter,
      db_tables      TYPE zcl_parser_types=>tt_db_table,
      business_logic TYPE zcl_parser_types=>tt_business_logic,
      object_map     TYPE zcl_parser_types=>tt_object_map,
    END OF ty_analysis_result.

  METHODS analyze
    IMPORTING
      iv_program TYPE program
    RETURNING
      VALUE(rs_result) TYPE ty_analysis_result
    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
