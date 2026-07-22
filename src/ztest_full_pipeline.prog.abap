*&---------------------------------------------------------------------*
*& Report ztest_full_pipeline
*&---------------------------------------------------------------------*
REPORT ztest_full_pipeline.

DATA:
  lt_source   TYPE zcl_parser_types=>tt_source_code,
  lt_symbols  TYPE zcl_parser_types=>tt_symbol,
  lt_semantic TYPE zcl_parser_types=>tt_semantic_symbol.

*-----------------------------------------------------------------------*
* Read source
*-----------------------------------------------------------------------*
READ REPORT 'ZTEST_ABAP_PARSER'
  INTO lt_source.

IF sy-subrc <> 0.
  WRITE: / 'Program not found'.
  RETURN.
ENDIF.

*-----------------------------------------------------------------------*
* Build Symbol Table
*-----------------------------------------------------------------------*
DATA(lo_builder) = NEW zcl_symbol_table_builder( ).

lt_symbols =
  lo_builder->zif_symbol_table_builder~build_symbol_table(
    it_source_code = lt_source ).

*-----------------------------------------------------------------------*
* Semantic Resolver
*-----------------------------------------------------------------------*
DATA(lo_resolver) = NEW zcl_semantic_resolver( ).

lt_semantic =
  lo_resolver->zif_semantic_resolver~resolve_symbols(
    it_symbols     = lt_symbols
    it_source_code = lt_source ).

*-----------------------------------------------------------------------*
* Summary
*-----------------------------------------------------------------------*
ULINE.
WRITE: / '================ PIPELINE SUMMARY ================'.
ULINE.

WRITE: / 'Source lines :', lines( lt_source ).
WRITE: / 'Symbols      :', lines( lt_symbols ).
WRITE: / 'Semantic     :', lines( lt_semantic ).

*-----------------------------------------------------------------------*
* Display Symbol Table
*-----------------------------------------------------------------------*
SKIP.
ULINE.
WRITE: / '================ SYMBOL TABLE ===================='.
ULINE.

LOOP AT lt_symbols INTO DATA(ls_symbol).

  WRITE:
    / 'Name        :', ls_symbol-symbol_name,
    / 'Kind        :', ls_symbol-symbol_kind,
    / 'Declaration :', ls_symbol-declaration_kind,
    / 'Reference   :', ls_symbol-referenced_type,
    / 'Stmt        :', ls_symbol-statement_index.

  ULINE.

ENDLOOP.

*-----------------------------------------------------------------------*
* Display Semantic Result
*-----------------------------------------------------------------------*
SKIP.
ULINE.
WRITE: / '============== SEMANTIC RESULT =================='.
ULINE.

LOOP AT lt_semantic INTO DATA(ls_sem).

  WRITE:
    / 'Name        :', ls_sem-symbol_name,
    / 'Kind        :', ls_sem-symbol_kind,
    / 'Declaration :', ls_sem-declaration_kind,
    / 'Reference   :', ls_sem-referenced_type,
    / 'Description :', ls_sem-description,
    / 'DDIC Type   :', ls_sem-ddic_object_type,
    / 'DDIC Name   :', ls_sem-ddic_object_name,
    / 'Domain      :', ls_sem-domain_name,
    / 'ABAP Type   :', ls_sem-abap_type,
    / 'Length      :', ls_sem-length,
    / 'Decimals    :', ls_sem-decimals,
    / 'SearchHelp  :', ls_sem-search_help,
    / 'Conv Exit   :', ls_sem-conversion_exit.

  ULINE.

ENDLOOP.

*-----------------------------------------------------------------------*
* Finish
*-----------------------------------------------------------------------*
WRITE: /.
WRITE: / 'Finished successfully.'.
