INTERFACE zif_symbol_table_builder
  PUBLIC .

  METHODS build_symbol_table
    IMPORTING
      it_tokens         TYPE zcl_parser_types=>tt_scan_tokens
      it_statements     TYPE zcl_parser_types=>tt_scan_statements
    RETURNING
      VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

ENDINTERFACE.
