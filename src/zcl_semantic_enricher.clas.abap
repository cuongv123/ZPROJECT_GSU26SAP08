CLASS zcl_semantic_enricher DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_semantic_enricher.

  PRIVATE SECTION.
    METHODS enrich_data_element
      IMPORTING iv_rollname  TYPE rollname
      CHANGING  cs_ui_filter TYPE zcl_parser_types=>ty_semantic_ui_filter.

    METHODS enrich_table
      IMPORTING iv_tabname  TYPE tabname
      CHANGING  cs_db_table TYPE zcl_parser_types=>ty_semantic_db_table.

    METHODS enrich_logic_object
      IMPORTING
                iv_object_name TYPE string
                iv_object_type TYPE string
      CHANGING  cs_logic       TYPE zcl_parser_types=>ty_semantic_business_logic.
ENDCLASS.

CLASS zcl_semantic_enricher IMPLEMENTATION.
  METHOD enrich_data_element.
    DATA:
      ls_dd04l TYPE dd04l,
      ls_dd04t TYPE dd04t.
    IF iv_rollname IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE *
      INTO @ls_dd04l
      FROM dd04l
      WHERE rollname = @iv_rollname
        AND as4local = 'A'.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    SELECT SINGLE *
      INTO @ls_dd04t
      FROM dd04t
      WHERE rollname = @iv_rollname
        AND ddlanguage = @sy-langu.
    cs_ui_filter-description     = ls_dd04t-ddtext.
    cs_ui_filter-domain_name     = ls_dd04l-domname.
    cs_ui_filter-data_type       = ls_dd04l-datatype.
    cs_ui_filter-length          = ls_dd04l-leng.
    cs_ui_filter-decimals        = ls_dd04l-decimals.
    cs_ui_filter-conversion_exit = ls_dd04l-convexit.
  ENDMETHOD.

  METHOD enrich_table.
  ENDMETHOD.

  METHOD enrich_logic_object.
  ENDMETHOD.

  METHOD zif_semantic_enricher~enrich_ui_filters.
    LOOP AT it_raw_ui_filters INTO DATA(ls_raw).
      DATA(ls_semantic) =
        CORRESPONDING zcl_parser_types=>ty_semantic_ui_filter( ls_raw ).
      enrich_data_element(
        EXPORTING iv_rollname = ls_raw-data_element
        CHANGING cs_ui_filter = ls_semantic
        ).
      APPEND ls_semantic TO rt_semantic_ui_filters.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_semantic_enricher~enrich_db_tables.
    LOOP AT it_raw_db_tables INTO DATA(ls_raw).
      DATA(ls_semantic) =
        CORRESPONDING zcl_parser_types=>ty_semantic_db_table( ls_raw ).
      enrich_table(
        EXPORTING iv_tabname  = ls_raw-table_name
        CHANGING cs_db_table = ls_semantic
        ).
      APPEND ls_semantic TO rt_semantic_db_tables.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_semantic_enricher~enrich_business_logic.
    LOOP AT it_raw_logic INTO DATA(ls_raw).
      DATA(ls_semantic) =
        CORRESPONDING zcl_parser_types=>ty_semantic_business_logic( ls_raw ).
      enrich_logic_object(
        EXPORTING
          iv_object_name = ls_raw-object_name
          iv_object_type = ls_raw-object_type
        CHANGING
          cs_logic       = ls_semantic
          ).
      APPEND ls_semantic TO rt_semantic_logic.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
