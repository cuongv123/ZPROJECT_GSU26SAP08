CLASS zcl_source_repository DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS get_program_source
      IMPORTING
        iv_program_name TYPE program
      EXPORTING
        et_source_code  TYPE zcl_parser_types=>tt_source_code.

    METHODS get_program_description
      IMPORTING
                iv_program_name       TYPE program
      RETURNING VALUE(rv_description) TYPE string.

  PRIVATE SECTION.

    DATA mt_visited TYPE HASHED TABLE OF progname
                    WITH UNIQUE KEY table_line.

    METHODS expand_source
      IMPORTING iv_program_name TYPE progname
      CHANGING  ct_source_code  TYPE zcl_parser_types=>tt_source_code.
ENDCLASS.

CLASS zcl_source_repository IMPLEMENTATION.
  METHOD get_program_source.
    CLEAR mt_visited.
    CLEAR et_source_code.
    expand_source(
      EXPORTING
        iv_program_name = iv_program_name
      CHANGING
        ct_source_code  = et_source_code ).
  ENDMETHOD.

  METHOD expand_source.
  DATA:
    lt_local_source TYPE zcl_parser_types=>tt_source_code,
    lv_include      TYPE progname.
  IF line_exists(
       mt_visited[
         table_line = iv_program_name ] ).
    RETURN.
  ENDIF.

  INSERT iv_program_name
    INTO TABLE mt_visited.

  READ REPORT iv_program_name INTO lt_local_source.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  LOOP AT lt_local_source INTO DATA(lv_line).
    DATA(lv_work) = lv_line.
    SHIFT lv_work LEFT DELETING LEADING space.
    IF lv_work IS INITIAL.
      APPEND lv_line TO ct_source_code.
      CONTINUE.
    ENDIF.

    IF lv_work(1) = '*'
       OR lv_work(1) = '"'.
      APPEND lv_line TO ct_source_code.
      CONTINUE.
    ENDIF.

    CLEAR lv_include.

    SPLIT lv_work AT space
      INTO DATA(lv_keyword)
           lv_include.

    TRANSLATE lv_keyword TO UPPER CASE.

    IF lv_keyword = 'INCLUDE'
       AND lv_include IS NOT INITIAL.

      REPLACE ALL OCCURRENCES OF '.'
        IN lv_include WITH ''.

      CONDENSE lv_include.

      expand_source(
        EXPORTING
          iv_program_name = lv_include
        CHANGING
          ct_source_code  = ct_source_code ).

    ELSE.

      APPEND lv_line TO ct_source_code.
    ENDIF.

  ENDLOOP.
ENDMETHOD.

  METHOD get_program_description.
    SELECT SINGLE text
      INTO @rv_description
      FROM trdirt
     WHERE name  = @iv_program_name
       AND sprsl = @sy-langu.

    IF sy-subrc <> 0.
      rv_description = iv_program_name.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
