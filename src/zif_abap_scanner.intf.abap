INTERFACE zif_abap_scanner

  PUBLIC.
  METHODS scan_source
    IMPORTING
      it_source_code TYPE zcl_parser_types=>tt_source_code
    EXPORTING
      et_tokens      TYPE zcl_parser_types=>tt_scan_tokens
      et_statements  TYPE zcl_parser_types=>tt_scan_statements.

ENDINTERFACE.
