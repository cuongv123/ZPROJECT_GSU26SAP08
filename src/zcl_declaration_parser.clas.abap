CLASS zcl_declaration_parser DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_declaration_parser.

  PRIVATE SECTION.
    METHODS parse_parameters
      IMPORTING
        iv_statement      TYPE string
        iv_stmt_no        TYPE i
      RETURNING
        VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_select_options
      IMPORTING
        iv_statement      TYPE string
        iv_stmt_no        TYPE i
      RETURNING
        VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_data
      IMPORTING
        iv_statement      TYPE string
        iv_stmt_no        TYPE i
      RETURNING
        VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_constants
      IMPORTING
        iv_statement      TYPE string
        iv_stmt_no        TYPE i
      RETURNING
        VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_tables
      IMPORTING
        iv_statement      TYPE string
        iv_stmt_no        TYPE i
      RETURNING
        VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_types
      IMPORTING
        iv_statement      TYPE string
        iv_stmt_no        TYPE i
      RETURNING
        VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_field_symbols
      IMPORTING
        iv_statement      TYPE string
        iv_stmt_no        TYPE i
      RETURNING
        VALUE(rt_symbols) TYPE zcl_parser_types=>tt_symbol.

    METHODS tokenize_statement
      IMPORTING
        iv_statement     TYPE string
      RETURNING
        VALUE(rt_tokens) TYPE string_table.
ENDCLASS.

CLASS zcl_declaration_parser IMPLEMENTATION.
  METHOD zif_declaration_parser~parse_statement.
    DATA(lv_stmt) = iv_statement_text.
    REPLACE ALL OCCURRENCES OF
      cl_abap_char_utilities=>newline
      IN lv_stmt
      WITH space.
    CONDENSE lv_stmt.
    TRANSLATE lv_stmt TO UPPER CASE.
    IF lv_stmt CP 'PARAMETERS*'.
      rt_symbols = parse_parameters(
                      iv_statement = iv_statement_text
                      iv_stmt_no   = iv_statement_no ).

    ELSEIF lv_stmt CP 'SELECT-OPTIONS*'.
      rt_symbols = parse_select_options(
                      iv_statement = iv_statement_text
                      iv_stmt_no   = iv_statement_no ).

    ELSEIF lv_stmt CP 'DATA*'.
      rt_symbols = parse_data(
                      iv_statement = iv_statement_text
                      iv_stmt_no   = iv_statement_no ).

    ELSEIF lv_stmt CP 'TYPES*'.
      rt_symbols = parse_types(
                      iv_statement = iv_statement_text
                      iv_stmt_no   = iv_statement_no ).

    ELSEIF lv_stmt CP 'CONSTANTS*'.
      rt_symbols = parse_constants(
                      iv_statement = iv_statement_text
                      iv_stmt_no   = iv_statement_no ).
    ELSEIF lv_stmt CP 'TABLES*'.
      rt_symbols = parse_tables(
          iv_statement = iv_statement_text
          iv_stmt_no   = iv_statement_no ).

    ELSEIF lv_stmt CP 'TYPES*'.
      rt_symbols = parse_types(
          iv_statement = iv_statement_text
          iv_stmt_no   = iv_statement_no ).

    ELSEIF lv_stmt CP 'FIELD-SYMBOLS*'.
      rt_symbols = parse_field_symbols(
          iv_statement = iv_statement_text
          iv_stmt_no   = iv_statement_no ).
    ENDIF.
  ENDMETHOD.

  METHOD parse_parameters.
    DATA:
      lt_tokens TYPE string_table,
      ls_symbol TYPE zcl_parser_types=>ty_symbol,
      lv_state  TYPE string.
    lt_tokens = tokenize_statement( iv_statement ).
    LOOP AT lt_tokens INTO DATA(lv_token).
      DATA(lv_upper) = to_upper( lv_token ).

      CASE lv_upper.
        WHEN 'PARAMETERS' OR ':'.
          CONTINUE.

        WHEN 'TYPE' OR 'LIKE'.
          ls_symbol-declaration_kind = lv_upper.
          lv_state = 'TYPE'.

        WHEN 'DEFAULT'.
          lv_state = 'DEFAULT'.

        WHEN 'OBLIGATORY'.
          ls_symbol-mandatory_flag = abap_true.

        WHEN 'LOWER'.
          lv_state = 'LOWER'.

        WHEN 'CASE'.

          IF lv_state = 'LOWER'.
            ls_symbol-lower_case_flag = abap_true.
            CLEAR lv_state.
          ENDIF.

        WHEN ',' OR '.'.
          IF ls_symbol-symbol_name IS NOT INITIAL.
            ls_symbol-symbol_kind = 'PARAMETER'.
            ls_symbol-statement_index = iv_stmt_no.
            APPEND ls_symbol TO rt_symbols.
          ENDIF.

          CLEAR ls_symbol.
          CLEAR lv_state.
        WHEN OTHERS.
          CASE lv_state.
            WHEN ''.
              IF ls_symbol-symbol_name IS INITIAL.
                ls_symbol-symbol_name = lv_token.
              ENDIF.

            WHEN 'TYPE'.
              ls_symbol-referenced_type = lv_token.
              CLEAR lv_state.

            WHEN 'DEFAULT'.
              ls_symbol-default_value = lv_token.
              CLEAR lv_state.

          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_select_options.
    DATA:
      lt_tokens TYPE string_table,
      ls_symbol TYPE zcl_parser_types=>ty_symbol,
      lv_state  TYPE string.
    lt_tokens = tokenize_statement( iv_statement ).
    LOOP AT lt_tokens INTO DATA(lv_token).
      DATA(lv_upper) = to_upper( lv_token ).
      CASE lv_upper.
        WHEN 'SELECT-OPTIONS' OR ':'.
          CONTINUE.

        WHEN 'FOR'.
          lv_state = 'FOR'.

        WHEN 'MATCHCODE'.
          lv_state = 'MATCHCODE'.

        WHEN 'OBLIGATORY'.
          ls_symbol-mandatory_flag = abap_true.

        WHEN ',' OR '.'.
          IF ls_symbol-symbol_name IS NOT INITIAL.
            ls_symbol-symbol_kind = 'SELECT_OPTION'.
            ls_symbol-statement_index = iv_stmt_no.
            APPEND ls_symbol TO rt_symbols.
          ENDIF.
          CLEAR ls_symbol.
          CLEAR lv_state.

        WHEN OTHERS.
          CASE lv_state.
            WHEN ''.
              IF ls_symbol-symbol_name IS INITIAL.
                ls_symbol-symbol_name = lv_token.
              ENDIF.

            WHEN 'FOR'.
              ls_symbol-referenced_type = lv_token.
              CLEAR lv_state.

            WHEN 'MATCHCODE'.
              ls_symbol-matchcode_object = lv_token.
              CLEAR lv_state.
          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_data.
    DATA:
      lt_tokens TYPE string_table,
      ls_symbol TYPE zcl_parser_types=>ty_symbol,
      lv_state  TYPE string.
    lt_tokens = tokenize_statement( iv_statement ).
    LOOP AT lt_tokens INTO DATA(lv_token).
      DATA(lv_upper) = to_upper( lv_token ).
      CASE lv_upper.
        WHEN 'DATA' OR ':'.
          CONTINUE.
        WHEN 'TYPE' OR 'LIKE'.
          ls_symbol-declaration_kind = lv_upper.
          lv_state = 'TYPE'.

        WHEN ',' OR '.'.
          IF ls_symbol-symbol_name IS NOT INITIAL.
            ls_symbol-symbol_kind = 'DATA'.
            ls_symbol-statement_index = iv_stmt_no.
            APPEND ls_symbol TO rt_symbols.
          ENDIF.

          CLEAR ls_symbol.
          CLEAR lv_state.

        WHEN OTHERS.
          CASE lv_state.
            WHEN ''.
              IF ls_symbol-symbol_name IS INITIAL.
                ls_symbol-symbol_name = lv_token.
              ENDIF.
            WHEN 'TYPE'.
              IF to_upper( lv_token ) = 'TABLE'.
                lv_state = 'TABLE'.
              ELSE.
                ls_symbol-referenced_type = lv_token.
                CLEAR lv_state.
              ENDIF.
            WHEN 'TABLE'.
              IF to_upper( lv_token ) = 'OF'.
                lv_state = 'TABLE_OF'.
              ELSE.
                CLEAR lv_state.
              ENDIF.

            WHEN 'TABLE_OF'.
              ls_symbol-referenced_type = lv_token.
              CLEAR lv_state.
          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_constants.
    DATA:
      lt_tokens TYPE string_table,
      ls_symbol TYPE zcl_parser_types=>ty_symbol,
      lv_state  TYPE string.
    lt_tokens = tokenize_statement( iv_statement ).
    LOOP AT lt_tokens INTO DATA(lv_token).
      DATA(lv_upper) = to_upper( lv_token ).
      CASE lv_upper.
        WHEN 'CONSTANTS' OR ':'.
          CONTINUE.

        WHEN 'TYPE'.
          lv_state = 'TYPE'.

        WHEN 'VALUE'.
          lv_state = 'VALUE'.

        WHEN ',' OR '.'.
          IF ls_symbol-symbol_name IS NOT INITIAL.
            ls_symbol-symbol_kind = 'CONSTANT'.
            ls_symbol-statement_index = iv_stmt_no.
            APPEND ls_symbol TO rt_symbols.
          ENDIF.
          CLEAR ls_symbol.
          CLEAR lv_state.

        WHEN OTHERS.

          CASE lv_state.
            WHEN ''.
              IF ls_symbol-symbol_name IS INITIAL.
                ls_symbol-symbol_name = lv_token.
              ENDIF.

            WHEN 'TYPE'.
              ls_symbol-referenced_type = lv_token.
              CLEAR lv_state.

            WHEN 'VALUE'.
              ls_symbol-default_value = lv_token.
              CLEAR lv_state.

          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_tables.
    DATA:
      lt_tokens TYPE string_table,
      ls_symbol TYPE zcl_parser_types=>ty_symbol.
    lt_tokens = tokenize_statement( iv_statement ).
    LOOP AT lt_tokens INTO DATA(lv_token).
      DATA(lv_upper) = to_upper( lv_token ).
      CASE lv_upper.
        WHEN 'TABLES' OR ':'.
          CONTINUE.

        WHEN ',' OR '.'.
          IF ls_symbol-symbol_name IS NOT INITIAL.
            ls_symbol-symbol_kind = 'TABLE'.
            ls_symbol-referenced_type = ls_symbol-symbol_name.
            ls_symbol-statement_index = iv_stmt_no.
            APPEND ls_symbol TO rt_symbols.
          ENDIF.
          CLEAR ls_symbol.
        WHEN OTHERS.
          IF ls_symbol-symbol_name IS INITIAL.
            ls_symbol-symbol_name = lv_token.
          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_types.
    DATA:
      lt_tokens TYPE string_table,
      ls_symbol TYPE zcl_parser_types=>ty_symbol,
      lv_index  TYPE i.
    lt_tokens = tokenize_statement( iv_statement ).
    LOOP AT lt_tokens INTO DATA(lv_token).
      DATA(lv_upper) = to_upper( lv_token ).
      CASE lv_upper.
        WHEN 'TYPES' OR ':'.
          CONTINUE.
        WHEN 'BEGIN'.
          READ TABLE lt_tokens
            INDEX sy-tabix + 2
            INTO DATA(lv_structure_name).
          IF sy-subrc = 0.
            CLEAR ls_symbol.
            ls_symbol-symbol_name     = lv_structure_name.
            ls_symbol-symbol_kind     = 'TYPE'.
            ls_symbol-referenced_type = 'STRUCTURE'.
            ls_symbol-statement_index = iv_stmt_no.
            APPEND ls_symbol TO rt_symbols.
          ENDIF.
        WHEN 'TYPE'.

          DATA(lv_type_index) = sy-tabix.

          " Token ngay trước TYPE = tên type
          READ TABLE lt_tokens
            INDEX lv_type_index - 1
            INTO DATA(lv_name).

          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          CLEAR ls_symbol.

          ls_symbol-symbol_name      = lv_name.
          ls_symbol-symbol_kind      = 'TYPE'.
          ls_symbol-statement_index  = iv_stmt_no.

          " Token sau TYPE
          READ TABLE lt_tokens
            INDEX lv_type_index + 1
            INTO DATA(lv_next).

          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          DATA(lv_next_upper) = to_upper( lv_next ).

          IF lv_next_upper = 'STANDARD'
             OR lv_next_upper = 'SORTED'
             OR lv_next_upper = 'HASHED'.

            " STANDARD TABLE OF <line_type>
            READ TABLE lt_tokens
              INDEX lv_type_index + 4
              INTO DATA(lv_line_type).

            IF sy-subrc = 0.
              ls_symbol-referenced_type = lv_line_type.
            ENDIF.

          ELSEIF lv_next_upper = 'TABLE'.

            " TABLE OF <line_type>
            READ TABLE lt_tokens
              INDEX lv_type_index + 3
              INTO lv_line_type.

            IF sy-subrc = 0.
              ls_symbol-referenced_type = lv_line_type.
            ENDIF.

          ELSE.

            " TYPE <simple_type>
            ls_symbol-referenced_type = lv_next.

          ENDIF.

          APPEND ls_symbol TO rt_symbols.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_field_symbols.
    DATA:
      lt_tokens TYPE string_table,
      ls_symbol TYPE zcl_parser_types=>ty_symbol,
      lv_state  TYPE string.
    lt_tokens = tokenize_statement( iv_statement ).
    LOOP AT lt_tokens INTO DATA(lv_token).
      DATA(lv_upper) = to_upper( lv_token ).
      CASE lv_upper.
        WHEN 'FIELD-SYMBOLS' OR ':'.

        WHEN 'TYPE'.
          lv_state = 'TYPE'.

        WHEN ',' OR '.'.
          IF ls_symbol-symbol_name IS NOT INITIAL.
            ls_symbol-symbol_kind = 'FIELD_SYMBOL'.
            ls_symbol-statement_index = iv_stmt_no.
            APPEND ls_symbol TO rt_symbols.
          ENDIF.
          CLEAR ls_symbol.
          CLEAR lv_state.

        WHEN OTHERS.
          CASE lv_state.
            WHEN ''.
              IF ls_symbol-symbol_name IS INITIAL.
                ls_symbol-symbol_name = lv_token.
              ENDIF.

            WHEN 'TYPE'.
              ls_symbol-referenced_type = lv_token.
              CLEAR lv_state.
          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD tokenize_statement.
    DATA(lv_stmt) = iv_statement.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline
        IN lv_stmt WITH space.
    REPLACE ALL OCCURRENCES OF ',' IN lv_stmt WITH ' , '.
    REPLACE ALL OCCURRENCES OF '.' IN lv_stmt WITH ' . '.
    REPLACE ALL OCCURRENCES OF ':' IN lv_stmt WITH ' : '.
    CONDENSE lv_stmt.
    SPLIT lv_stmt AT space INTO TABLE rt_tokens.
    DELETE rt_tokens WHERE table_line IS INITIAL.
    LOOP AT rt_tokens ASSIGNING FIELD-SYMBOL(<token>).
      SHIFT <token> LEFT DELETING LEADING ':'.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
