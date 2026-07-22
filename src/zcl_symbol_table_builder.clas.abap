CLASS zcl_symbol_table_builder DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_symbol_table_builder.

  PRIVATE SECTION.
    METHODS build_statement_text
      IMPORTING
        is_statement   TYPE LINE OF zcl_parser_types=>tt_scan_statements
        it_source_code TYPE zcl_parser_types=>tt_source_code
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_symbol_table_builder IMPLEMENTATION.
  METHOD zif_symbol_table_builder~build_symbol_table.

    DATA(lo_parser) = NEW zcl_declaration_parser( ).

    DATA:
      lv_statement TYPE string,
      lv_stmt_no   TYPE i.

    CLEAR rt_symbols.

    LOOP AT it_source_code INTO DATA(lv_line).

      DATA(lv_trim) = condense( lv_line ).

      IF lv_trim IS INITIAL.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Skip ABAP comment line
      "------------------------------------------------------------
      IF lv_trim+0(1) = '*'.
        CONTINUE.
      ENDIF.

      IF lv_trim+0(1) = '"'.
        CONTINUE.
      ENDIF.

      "------------------------------------------------------------
      " Build statement
      "------------------------------------------------------------
      IF lv_statement IS INITIAL.
        lv_statement = lv_trim.
      ELSE.
        lv_statement = lv_statement && ` ` && lv_trim.
      ENDIF.

      "------------------------------------------------------------
      " Statement ends with period
      "------------------------------------------------------------
      IF lv_trim CS '.'.

        lv_stmt_no += 1.

        DATA(lt_symbols) =
          lo_parser->zif_declaration_parser~parse_statement(
            iv_statement_text = lv_statement
            iv_statement_no   = lv_stmt_no ).

        APPEND LINES OF lt_symbols TO rt_symbols.

        CLEAR lv_statement.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD build_statement_text.

    CLEAR rv_text.

    LOOP AT it_source_code INTO DATA(lv_line)
         FROM is_statement-trow.

      IF rv_text IS INITIAL.
        rv_text = lv_line.
      ELSE.
        rv_text = rv_text &&
                  cl_abap_char_utilities=>newline &&
                  lv_line.
      ENDIF.

      IF lv_line CS '.'.
        EXIT.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
