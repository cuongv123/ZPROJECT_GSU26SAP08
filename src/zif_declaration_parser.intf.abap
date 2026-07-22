INTERFACE zif_declaration_parser
  PUBLIC .
  METHODS parse_statement
    IMPORTING
      iv_statement_text TYPE string
      iv_statement_no   TYPE i
    RETURNING
      VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

ENDINTERFACE.
