INTERFACE zif_semantic_enricher
  PUBLIC.

  METHODS enrich_ui_filters
    IMPORTING
      it_raw_ui_filters             TYPE zcl_parser_types=>tt_raw_ui_filter
    RETURNING
      VALUE(rt_semantic_ui_filters)
        TYPE zcl_parser_types=>tt_semantic_ui_filter.

  METHODS enrich_db_tables
    IMPORTING
      it_raw_db_tables             TYPE zcl_parser_types=>tt_raw_db_table
    RETURNING
      VALUE(rt_semantic_db_tables)
        TYPE zcl_parser_types=>tt_semantic_db_table.

  METHODS enrich_business_logic
    IMPORTING
      it_raw_logic             TYPE zcl_parser_types=>tt_raw_logic
    RETURNING
      VALUE(rt_semantic_logic)
        TYPE zcl_parser_types=>tt_semantic_business_logic.

ENDINTERFACE.
