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

    METHODS resolve_table_field
      IMPORTING
        iv_tabname   TYPE tabname
        iv_fieldname TYPE fieldname
      CHANGING
        cs_symbol    TYPE zcl_parser_types=>ty_semantic_symbol.

    METHODS resolve_local_type
      IMPORTING
        iv_type_name TYPE string
      CHANGING
        cs_symbol    TYPE zcl_parser_types=>ty_semantic_symbol.

    METHODS resolve_local_table_type
      IMPORTING
        iv_type_name TYPE string
      CHANGING
        cs_symbol    TYPE zcl_parser_types=>ty_semantic_symbol.
ENDCLASS.

CLASS zcl_semantic_resolver IMPLEMENTATION.
  METHOD resolve_data_element.

    DATA:
      lv_domname  TYPE domname,
      lv_shlpname TYPE shlpname,
      lv_convexit TYPE convexit,
      lv_ddtext   TYPE ddtext,
      lv_datatype TYPE dd04l-datatype,
      lv_leng     TYPE dd04l-leng,
      lv_decimals TYPE dd04l-decimals.

    IF iv_rollname IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_rollname) =
      CONV rollname( to_upper( iv_rollname ) ).

    SELECT SINGLE
      domname,
      shlpname,
      convexit,
      datatype,
      leng,
      decimals
      FROM dd04l
      INTO (
        @lv_domname,
        @lv_shlpname,
        @lv_convexit,
        @lv_datatype,
        @lv_leng,
        @lv_decimals )
      WHERE rollname = @lv_rollname
        AND as4local = 'A'.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    cs_symbol-domain_name      = lv_domname.
    cs_symbol-search_help      = lv_shlpname.
    cs_symbol-conversion_exit = lv_convexit.
    cs_symbol-abap_type        = lv_datatype.
    cs_symbol-length           = lv_leng.
    cs_symbol-decimals         = lv_decimals.

    SELECT SINGLE
      ddtext
      FROM dd04t
      INTO @lv_ddtext
      WHERE rollname   = @lv_rollname
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

  METHOD resolve_table_field.
    DATA:
      lv_rollname TYPE rollname,
      lv_ddtext   TYPE ddtext.
    IF iv_tabname IS INITIAL
       OR iv_fieldname IS INITIAL.
      RETURN.
    ENDIF.

    "------------------------------------------
    " Read field definition
    "------------------------------------------
    SELECT SINGLE
           rollname
      FROM dd03l
      INTO @lv_rollname
     WHERE tabname   = @iv_tabname
       AND fieldname = @iv_fieldname
       AND as4local  = 'A'.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    cs_symbol-referenced_type = lv_rollname.
    resolve_data_element(
        EXPORTING
          iv_rollname = lv_rollname
        CHANGING
          cs_symbol   = cs_symbol ).
  ENDMETHOD.

  METHOD resolve_local_type.
    cs_symbol-ddic_object_type = 'LOCAL_STRUCTURE'.
    cs_symbol-ddic_object_name = iv_type_name.
    cs_symbol-abap_type = 'STRUCTURE'.
    cs_symbol-description = 'Local structure type'.
  ENDMETHOD.

  METHOD resolve_local_table_type.
    cs_symbol-ddic_object_type = 'LOCAL_TABLE_TYPE'.
    cs_symbol-ddic_object_name = iv_type_name.
    cs_symbol-abap_type = 'TABLE'.
    cs_symbol-description = 'Local table type'.
  ENDMETHOD.

  METHOD zif_semantic_resolver~resolve_symbols.
    DATA(lo_type_resolver) =
      NEW zcl_abap_type_resolver( ).
    LOOP AT it_symbols INTO DATA(ls_symbol).
      DATA(ls_semantic) =
        CORRESPONDING zcl_parser_types=>ty_semantic_symbol(
          ls_symbol ).
      CASE ls_symbol-symbol_kind.
          "============================================================
          " PARAMETERS / SELECT-OPTIONS
          "============================================================
        WHEN 'PARAMETER'
          OR 'SELECT_OPTION'.
          IF ls_symbol-referenced_type IS NOT INITIAL.
            DATA:
              lv_table TYPE tabname,
              lv_field TYPE fieldname.
            SPLIT ls_symbol-referenced_type
              AT '-'
              INTO lv_table lv_field.
            IF lv_table IS NOT INITIAL
               AND lv_field IS NOT INITIAL.
              resolve_table_field(
                EXPORTING
                  iv_tabname   = lv_table
                  iv_fieldname = lv_field
                CHANGING
                  cs_symbol = ls_semantic ).
            ELSE.
              resolve_data_element(
                EXPORTING
                  iv_rollname = CONV rollname(
                                  ls_symbol-referenced_type )
                CHANGING
                  cs_symbol = ls_semantic ).
            ENDIF.
          ENDIF.

          "============================================================
          " DATA
          "============================================================
        WHEN 'DATA'.
          IF ls_symbol-referenced_type IS NOT INITIAL.
            DATA(lv_ref_type) =
              to_upper( ls_symbol-referenced_type ).
            "------------------------------------------------------------
            " LIKE table-field
            " Example:
            " gv_name LIKE kna1-name1
            "------------------------------------------------------------
            IF lv_ref_type CS '-'.
              CLEAR:
                  lv_table,
                  lv_field.
              SPLIT lv_ref_type
                AT '-'
                INTO lv_table lv_field.
              IF lv_table IS NOT INITIAL
                 AND lv_field IS NOT INITIAL.
                resolve_table_field(
                  EXPORTING
                    iv_tabname   = lv_table
                    iv_fieldname = lv_field
                  CHANGING
                    cs_symbol = ls_semantic ).
              ENDIF.

              "------------------------------------------------------------
              " Local structure type
              "------------------------------------------------------------
            ELSEIF lv_ref_type CP 'TY_*'.
              resolve_local_type(
                EXPORTING
                  iv_type_name = lv_ref_type
                CHANGING
                  cs_symbol = ls_semantic ).

              "------------------------------------------------------------
              " Local table type
              "------------------------------------------------------------
            ELSEIF lv_ref_type CP 'TT_*'.
              resolve_local_table_type(
                EXPORTING
                  iv_type_name = lv_ref_type
                CHANGING
                  cs_symbol = ls_semantic ).

            ELSE.
              "----------------------------------------------------------
              " Check DDIC table
              "----------------------------------------------------------
              SELECT SINGLE tabname
                FROM dd02l
                WHERE tabname  = @lv_ref_type
                  AND as4local = 'A'
                INTO @DATA(lv_tabname).

              IF sy-subrc = 0.
                resolve_table(
                  EXPORTING
                    iv_tabname = lv_tabname
                  CHANGING
                    cs_symbol = ls_semantic ).

              ELSE.
                "--------------------------------------------------------
                " Check DDIC data element
                "--------------------------------------------------------
                resolve_data_element(
                  EXPORTING
                    iv_rollname = CONV rollname( lv_ref_type )
                  CHANGING
                    cs_symbol = ls_semantic ).
              ENDIF.
            ENDIF.
          ENDIF.
          "============================================================
          " CONSTANT
          "============================================================
        WHEN 'CONSTANT'.
          IF ls_symbol-referenced_type IS NOT INITIAL.
            resolve_data_element(
              EXPORTING
                iv_rollname = CONV rollname(
                                ls_symbol-referenced_type )
              CHANGING
                cs_symbol = ls_semantic ).
          ENDIF.
      ENDCASE.
      APPEND ls_semantic TO rt_semantic_symbols.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
