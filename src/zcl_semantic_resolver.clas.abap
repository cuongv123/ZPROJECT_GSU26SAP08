CLASS zcl_semantic_resolver DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_semantic_resolver.

  PRIVATE SECTION.
    METHODS resolve_data_element
      IMPORTING
        iv_rollname TYPE rollname
      CHANGING
        cs_symbol   TYPE zcl_parser_types=>ty_semantic_symbol.

    METHODS resolve_table
      IMPORTING
        iv_tabname TYPE tabname
      CHANGING
        cs_symbol  TYPE zcl_parser_types=>ty_semantic_symbol.
ENDCLASS.

CLASS zcl_semantic_resolver IMPLEMENTATION.
  METHOD resolve_data_element.
    DATA:
      lv_domname  TYPE domname,
      lv_shlpname TYPE shlpname,
      lv_convexit TYPE convexit,
      lv_ddtext   TYPE ddtext.
    IF iv_rollname IS INITIAL.
      RETURN.
    ENDIF.

    "--------------------------------------------------------
    " Read Data Element definition
    "--------------------------------------------------------
    SELECT SINGLE
           domname,
           shlpname,
           convexit
      FROM dd04l
      INTO (
        @lv_domname,
        @lv_shlpname,
        @lv_convexit )
     WHERE rollname = @iv_rollname
       AND as4local = 'A'.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    cs_symbol-domain_name     = lv_domname.
    cs_symbol-search_help     = lv_shlpname.
    cs_symbol-conversion_exit = lv_convexit.

    "--------------------------------------------------------
    " Read Description
    "--------------------------------------------------------
    SELECT SINGLE
           ddtext
      FROM dd04t
      INTO @lv_ddtext
     WHERE rollname   = @iv_rollname
       AND ddlanguage = @sy-langu
       AND as4local   = 'A'.

    IF sy-subrc = 0.
      cs_symbol-description = lv_ddtext.
    ENDIF.
  ENDMETHOD.

  METHOD resolve_table.
    DATA:
      lv_ddtext TYPE dd02t-ddtext.
    IF iv_tabname IS INITIAL.
      RETURN.
    ENDIF.

    "------------------------------------------
    " Mark as DDIC Table
    "------------------------------------------
    cs_symbol-ddic_object_type = 'TABLE'.
    cs_symbol-ddic_object_name = iv_tabname.

    "------------------------------------------
    " Read table description
    "------------------------------------------
    SELECT SINGLE
           ddtext
      FROM dd02t
      INTO @lv_ddtext
     WHERE tabname    = @iv_tabname
       AND ddlanguage = @sy-langu
       AND as4local   = 'A'.
    IF sy-subrc = 0.
      cs_symbol-description = lv_ddtext.
    ENDIF.
  ENDMETHOD.

  METHOD zif_semantic_resolver~resolve_symbols.
    LOOP AT it_symbols INTO DATA(ls_symbol).
      DATA(ls_semantic) =
        CORRESPONDING zcl_parser_types=>ty_semantic_symbol( ls_symbol ).

      CASE ls_symbol-symbol_kind.
        WHEN 'PARAMETER'
          OR 'SELECT_OPTION'.

          IF ls_symbol-referenced_type IS NOT INITIAL.
            resolve_data_element(
              EXPORTING
                iv_rollname = CONV rollname( ls_symbol-referenced_type )
              CHANGING
                cs_symbol   = ls_semantic ).
          ENDIF.
        WHEN 'DATA'.

          IF ls_symbol-referenced_type IS NOT INITIAL.
            resolve_table(
              EXPORTING
                iv_tabname = CONV tabname( ls_symbol-referenced_type )
              CHANGING
                cs_symbol  = ls_semantic ).
          ENDIF.
      ENDCASE.
      APPEND ls_semantic TO rt_semantic_symbols.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
