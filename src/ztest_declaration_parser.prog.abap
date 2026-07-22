*&---------------------------------------------------------------------*
*& Report ztest_declaration_parser
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_declaration_parser.

DATA:
  lt_symbols TYPE zcl_parser_types=>tt_symbol.

DATA(lo_parser) = NEW zcl_declaration_parser( ).

*-----------------------------------------------------------------------
* Test DATA
*-----------------------------------------------------------------------

lt_symbols =
  lo_parser->zif_declaration_parser~parse_statement(
    iv_statement_text =
      `DATA: gv_bukrs TYPE bukrs, gv_matnr TYPE matnr, gs_mara TYPE mara.`
    iv_statement_no = 1 ).

WRITE: / 'DATA TEST'.

LOOP AT lt_symbols INTO DATA(ls_symbol).

  WRITE:
    / 'Name      :', ls_symbol-symbol_name,
    / 'Kind      :', ls_symbol-symbol_kind,
    / 'Type      :', ls_symbol-referenced_type.

ENDLOOP.

SKIP 2.

*-----------------------------------------------------------------------
* Test PARAMETERS
*-----------------------------------------------------------------------

CLEAR lt_symbols.

lt_symbols =
  lo_parser->zif_declaration_parser~parse_statement(
    iv_statement_text =
      `PARAMETERS: p_bukrs TYPE bukrs OBLIGATORY, p_werks TYPE werks_d DEFAULT '1000'.`
    iv_statement_no = 2 ).

WRITE: / 'PARAMETERS TEST'.

LOOP AT lt_symbols INTO ls_symbol.

  WRITE:
    / 'Name      :', ls_symbol-symbol_name,
    / 'Kind      :', ls_symbol-symbol_kind,
    / 'Type      :', ls_symbol-referenced_type,
    / 'Mandatory :', ls_symbol-mandatory_flag,
    / 'Default   :', ls_symbol-default_value.

ENDLOOP.

SKIP 2.

*-----------------------------------------------------------------------
* Test SELECT-OPTIONS
*-----------------------------------------------------------------------

CLEAR lt_symbols.

lt_symbols =
  lo_parser->zif_declaration_parser~parse_statement(
    iv_statement_text =
      `SELECT-OPTIONS: s_vbeln FOR vbak-vbeln, s_matnr FOR mara-matnr.`
    iv_statement_no = 3 ).

WRITE: / 'SELECT-OPTIONS TEST'.

LOOP AT lt_symbols INTO ls_symbol.

  WRITE:
    / 'Name      :', ls_symbol-symbol_name,
    / 'Kind      :', ls_symbol-symbol_kind,
    / 'Reference :', ls_symbol-referenced_type.

ENDLOOP.
