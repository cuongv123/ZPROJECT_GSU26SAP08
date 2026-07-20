CLASS zcl_symbol_table_builder DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_symbol_table_builder.

  PRIVATE SECTION.

    METHODS parse_parameter
      IMPORTING
        is_statement TYPE LINE OF zcl_parser_types=>tt_scan_statements
        it_tokens    TYPE zcl_parser_types=>tt_scan_tokens
      CHANGING
        ct_symbols   TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_select_option
      IMPORTING
        is_statement TYPE LINE OF zcl_parser_types=>tt_scan_statements
        it_tokens    TYPE zcl_parser_types=>tt_scan_tokens
      CHANGING
        ct_symbols   TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_data
      IMPORTING
        is_statement TYPE LINE OF zcl_parser_types=>tt_scan_statements
        it_tokens    TYPE zcl_parser_types=>tt_scan_tokens
      CHANGING
        ct_symbols   TYPE zcl_parser_types=>tt_symbol.

    METHODS parse_constants
      IMPORTING
        is_statement TYPE LINE OF zcl_parser_types=>tt_scan_statements
        it_tokens    TYPE zcl_parser_types=>tt_scan_tokens
      CHANGING
        ct_symbols   TYPE zcl_parser_types=>tt_symbol.
ENDCLASS.

CLASS zcl_symbol_table_builder IMPLEMENTATION.
  METHOD zif_symbol_table_builder~build_symbol_table.
    CLEAR rt_symbols.
    LOOP AT it_statements INTO DATA(ls_stmt).
      " Token đầu tiên của statement
      READ TABLE it_tokens
        INTO DATA(ls_first_token)
        INDEX ls_stmt-from.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(lv_keyword) = to_upper( ls_first_token-str ).
      CASE lv_keyword.
        WHEN 'PARAMETERS'.
          parse_parameter(
            EXPORTING
              is_statement = ls_stmt
              it_tokens    = it_tokens
            CHANGING
              ct_symbols   = rt_symbols ).

        WHEN 'SELECT-OPTIONS'.
          parse_select_option(
            EXPORTING
              is_statement = ls_stmt
              it_tokens    = it_tokens
            CHANGING
              ct_symbols   = rt_symbols ).

        WHEN 'DATA'.
          parse_data(
            EXPORTING
              is_statement = ls_stmt
              it_tokens    = it_tokens
            CHANGING
              ct_symbols   = rt_symbols ).

        WHEN 'CONSTANTS'.
          parse_constants(
            EXPORTING
              is_statement = ls_stmt
              it_tokens    = it_tokens
            CHANGING
              ct_symbols   = rt_symbols ).
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_parameter.
    DATA:
      ls_symbol TYPE zcl_parser_types=>ty_symbol,
      lv_state  TYPE string.

    LOOP AT it_tokens INTO DATA(ls_token)
         FROM is_statement-from
         TO   is_statement-to.
      DATA(lv_token) = to_upper( ls_token-str ).

      CASE lv_token.
        WHEN 'PARAMETERS'.
          ls_symbol-symbol_kind = 'PARAMETER'.

        WHEN 'TYPE'.
          ls_symbol-declaration_kind = 'TYPE'.
          lv_state = 'TYPE'.

        WHEN 'LIKE'.
          ls_symbol-declaration_kind = 'LIKE'.
          lv_state = 'TYPE'.

        WHEN 'DEFAULT'.
          lv_state = 'DEFAULT'.

        WHEN 'OBLIGATORY'.
          ls_symbol-mandatory_flag = abap_true.

        WHEN 'MATCHCODE'.
          lv_state = 'MATCHCODE'.

        WHEN 'OBJECT'.
          IF lv_state = 'MATCHCODE'.
            lv_state = 'MATCHCODE_OBJECT'.
          ENDIF.

        WHEN 'LOWER'.
          lv_state = 'LOWER'.

        WHEN 'LOWER'.
          ls_symbol-lower_case_flag = abap_true.

        WHEN '.'.
          IF ls_symbol-symbol_name IS NOT INITIAL.
            ls_symbol-statement_index = is_statement-from.
            APPEND ls_symbol TO ct_symbols.
          ENDIF.
          EXIT.

        WHEN OTHERS.
          " Token đầu tiên sau PARAMETERS chính là tên biến
          IF ls_symbol-symbol_name IS INITIAL.
            ls_symbol-symbol_name = ls_token-str.
            CONTINUE.
          ENDIF.

          " Token sau TYPE hoặc LIKE là kiểu dữ liệu
          CASE lv_state.

            WHEN 'TYPE'.
              ls_symbol-referenced_type = ls_token-str.
              CLEAR lv_state.

            WHEN 'DEFAULT'.
              ls_symbol-default_value = ls_token-str.
              CLEAR lv_state.

            WHEN 'MATCHCODE_OBJECT'.
              ls_symbol-matchcode_object = ls_token-str.
              CLEAR lv_state.

          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_select_option.
  ENDMETHOD.

  METHOD parse_data.
  ENDMETHOD.

  METHOD parse_constants.
  ENDMETHOD.
ENDCLASS.
