CLASS zcl_abap_scanner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_abap_scanner.
ENDCLASS.

CLASS zcl_abap_scanner IMPLEMENTATION.
  METHOD zif_abap_scanner~scan_source.
    SCAN ABAP-SOURCE it_source_code
     WITH ANALYSIS
     TOKENS     INTO et_tokens
     STATEMENTS INTO et_statements.
  ENDMETHOD.
ENDCLASS.
