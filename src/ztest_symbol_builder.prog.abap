*&---------------------------------------------------------------------*
*& Report ztest_symbol_builder
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_symbol_builder.

DATA lt_source TYPE zcl_parser_types=>tt_source_code.

APPEND `PARAMETERS: p_bukrs TYPE bukrs.` TO lt_source.
APPEND `SELECT-OPTIONS: s_vbeln FOR vbak-vbeln.` TO lt_source.

DATA(lo_builder) = NEW zcl_symbol_table_builder( ).

DATA(lt_symbols) =
  lo_builder->zif_symbol_table_builder~build_symbol_table(
    it_source_code = lt_source ).

BREAK-POINT.
