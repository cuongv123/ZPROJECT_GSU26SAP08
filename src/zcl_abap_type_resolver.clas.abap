CLASS zcl_abap_type_resolver DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Trả về tên Structure (ZST_...) hoặc TableName dựa trên tên biến
    METHODS resolve_type
      IMPORTING iv_variable_name    TYPE string
                it_source_code      TYPE zcl_parser_types=>tt_source_code
      RETURNING VALUE(rv_structure) TYPE string.

    METHODS resolve_local_type
      IMPORTING
        iv_type_name   TYPE string
        it_source_code TYPE zcl_parser_types=>tt_source_code
      EXPORTING
        ev_type_kind   TYPE string
        ev_description TYPE string.
ENDCLASS.

CLASS zcl_abap_type_resolver IMPLEMENTATION.
  METHOD resolve_type.
    DATA: lv_line_upper TYPE string.

    DATA(lv_var) = to_upper( iv_variable_name ).

    " Sử dụng backtick ` để định nghĩa Regex, tránh xung đột | trong String Template
    " Regex này bóc tách: [Tên biến] [TYPE/LIKE] [TABLE OF] [Tên_Structure]
    DATA(lv_regex) = `\s*(TYPE|LIKE)\s+(TABLE\s+OF)?\s*([\w\/]+)`.
    DATA(lv_pattern) = lv_var && lv_regex.

    LOOP AT it_source_code INTO DATA(lv_line).
      lv_line_upper = to_upper( condense( lv_line ) ).

      " Chỉ scan các dòng có chứa tên biến
      IF lv_line_upper CS lv_var.
        FIND PCRE lv_pattern IN lv_line_upper SUBMATCHES DATA(lv_dummy) DATA(lv_found_structure).

        IF sy-subrc = 0.
          rv_structure = lv_found_structure.
          RETURN.
        ENDIF.
      ENDIF.
    ENDLOOP.
    CLEAR rv_structure.
  ENDMETHOD.

  METHOD resolve_local_type.

    DATA(lv_type_name) = to_upper( iv_type_name ).

    LOOP AT it_source_code INTO DATA(lv_line).

      DATA(lv_upper) = to_upper( condense( lv_line ) ).

      "--------------------------------------------------
      " TYPES: BEGIN OF ty_demo
      "--------------------------------------------------
      IF lv_upper CS 'BEGIN OF'.

        IF lv_upper CS lv_type_name.

          ev_type_kind = 'STRUCTURE'.
          ev_description = 'Local structure type'.
          RETURN.

        ENDIF.

      ENDIF.

      "--------------------------------------------------
      " tt_demo TYPE STANDARD TABLE OF ty_demo
      "--------------------------------------------------
      DATA(lv_pattern) =
        lv_type_name && `\s+TYPE\s+(STANDARD|SORTED|HASHED)\s+TABLE`.

      FIND PCRE lv_pattern
        IN lv_upper.

      IF sy-subrc = 0.

        ev_type_kind = 'TABLE'.
        ev_description = 'Local table type'.
        RETURN.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
