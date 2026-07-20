*&---------------------------------------------------------------------*
*& Report ztest_semantic_resolver
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_semantic_resolver.

DATA:
  lt_source     TYPE zcl_parser_types=>tt_source_code,
  lt_tokens     TYPE zcl_parser_types=>tt_scan_tokens,
  lt_statements TYPE zcl_parser_types=>tt_scan_statements,
  lt_symbols    TYPE zcl_parser_types=>tt_symbol,
  lt_semantic   TYPE zcl_parser_types=>tt_semantic_symbol.

*----------------------------------------------------------------------
* Read program source
*----------------------------------------------------------------------
READ REPORT 'ZTEST_ABAP_PARSER'
  INTO lt_source.

IF sy-subrc <> 0.
  WRITE: / 'Program not found'.
  RETURN.
ENDIF.

*----------------------------------------------------------------------
* Scanner
*----------------------------------------------------------------------
DATA(lo_scanner) = NEW zcl_abap_scanner( ).

lo_scanner->zif_abap_scanner~scan_source(
  EXPORTING
    it_source_code = lt_source
  IMPORTING
    et_tokens      = lt_tokens
    et_statements  = lt_statements ).

*----------------------------------------------------------------------
* Symbol Builder
*----------------------------------------------------------------------
DATA(lo_builder) = NEW zcl_symbol_table_builder( ).

lt_symbols =
  lo_builder->zif_symbol_table_builder~build_symbol_table(
    it_tokens     = lt_tokens
    it_statements = lt_statements ).

*----------------------------------------------------------------------
* Semantic Resolver
*----------------------------------------------------------------------
DATA(lo_resolver) = NEW zcl_semantic_resolver( ).

lt_semantic =
  lo_resolver->zif_semantic_resolver~resolve_symbols(
    it_symbols = lt_symbols ).

*----------------------------------------------------------------------
* Debug here
*----------------------------------------------------------------------
BREAK-POINT.

WRITE: / 'Semantic Resolver finished.'.
