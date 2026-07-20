INTERFACE zif_recommendation_engine
  PUBLIC .

  METHODS enrich_ui_filter
    IMPORTING
      iv_program_name  TYPE programm
      it_raw_ui_filter TYPE zcl_parser_types=>tt_raw_ui_filter
    EXPORTING
      et_ui_filter     TYPE zcl_parser_types=>tt_ui_filter.

  METHODS enrich_db_table
   IMPORTING
    iv_program_name TYPE programm
    it_raw_db_table type zcl_parser_types=>tt_raw_db_table
 EXPORTING
  et_db_table     type zcl_parser_types=>tt_db_table.

  METHODS enrich_business_logic
    IMPORTING
      iv_program_name   TYPE programm
      it_raw_logic      TYPE zcl_parser_types=>tt_raw_logic
    EXPORTING
      et_business_logic TYPE zcl_parser_types=>tt_business_logic.

  METHODS build_object_mapping
    IMPORTING
      it_ui_filter  TYPE zcl_parser_types=>tt_ui_filter
      it_db_table   TYPE zcl_parser_types=>tt_db_table
      it_logic      TYPE zcl_parser_types=>tt_business_logic
    RETURNING
      VALUE(rt_map) TYPE zcl_parser_types=>tt_object_map.

ENDINTERFACE.
