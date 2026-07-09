INTERFACE zif_analysis_aggregator
  PUBLIC .

  METHODS build_overview

    IMPORTING
      iv_program_name   TYPE programm
      it_ui_filter      TYPE zcl_parser_types=>tt_ui_filter
      it_db_table       TYPE zcl_parser_types=>tt_db_table
      it_business_logic TYPE zcl_parser_types=>tt_business_logic
    EXPORTING
      es_overview       TYPE zcl_parser_types=>ty_overview.
ENDINTERFACE.
