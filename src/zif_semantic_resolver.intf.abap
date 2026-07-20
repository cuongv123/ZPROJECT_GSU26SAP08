INTERFACE zif_semantic_resolver
  PUBLIC .

  METHODS resolve_symbols
    IMPORTING
      it_symbols                 TYPE zcl_parser_types=>tt_symbol
    RETURNING
      VALUE(rt_semantic_symbols)
        TYPE zcl_parser_types=>tt_semantic_symbol.

ENDINTERFACE.
