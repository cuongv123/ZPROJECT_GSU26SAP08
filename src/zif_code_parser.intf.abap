INTERFACE zif_code_parser
  PUBLIC .
  METHODS analyze_program

    IMPORTING
      iv_program_name TYPE programm
      it_source_code  TYPE zcl_parser_types=>tt_source_code

    EXPORTING
      et_ui_filter    TYPE zcl_parser_types=>tt_raw_ui_filter
      et_logic        TYPE zcl_parser_types=>tt_raw_logic
      et_db_table     TYPE zcl_parser_types=>tt_raw_db_table.
ENDINTERFACE.
