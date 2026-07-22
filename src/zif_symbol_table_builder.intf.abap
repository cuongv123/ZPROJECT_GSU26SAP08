INTERFACE zif_symbol_table_builder
  PUBLIC .

  METHODS build_symbol_table
  IMPORTING
    it_source_code TYPE zcl_parser_types=>tt_source_code
  RETURNING
    VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

ENDINTERFACE.
