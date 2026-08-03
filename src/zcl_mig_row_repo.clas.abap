CLASS zcl_mig_row_repo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_row_repo.

  PRIVATE SECTION.

    TYPES:
      ty_type_kind TYPE c LENGTH 1,
      ty_type_name TYPE c LENGTH 120,
      ty_edm_type  TYPE c LENGTH 30.


    METHODS get_type
      IMPORTING
        iv_type TYPE zif_mig_types=>ty_sig_name
      RETURNING
        VALUE(ro_type)
          TYPE REF TO cl_abap_datadescr.


    METHODS clean_name
      IMPORTING
        VALUE(iv_type) TYPE string
      RETURNING
        VALUE(rv_type) TYPE ty_type_name.


    METHODS map_edm
      IMPORTING
        iv_kind TYPE ty_type_kind
        iv_name TYPE zif_mig_types=>ty_sig_name
      RETURNING
        VALUE(rv_edm) TYPE ty_edm_type.

ENDCLASS.

CLASS zcl_mig_row_repo IMPLEMENTATION.

  METHOD zif_mig_row_repo~read_type.

    CLEAR rs_row.

    rs_row-type_name =
      iv_type.


    DATA(lo_type) =
      get_type(
        iv_type = iv_type
      ).


    IF lo_type IS NOT BOUND.

      rs_row-exists =
        abap_false.

      RETURN.

    ENDIF.


    rs_row-exists =
      abap_true.


    DATA lo_line
      TYPE REF TO cl_abap_datadescr.


    "==========================================================
    " Input là table type
    "==========================================================
    IF lo_type->kind =
         cl_abap_typedescr=>kind_table.

      TRY.

          DATA(lo_table) =
            CAST cl_abap_tabledescr(
              lo_type
            ).

          lo_line =
            lo_table->get_table_line_type( ).

        CATCH cx_root.

          rs_row-structured =
            abap_false.

          RETURN.

      ENDTRY.


    "==========================================================
    " Input đã là structure hoặc elementary type
    "==========================================================
    ELSE.

      lo_line =
        lo_type.

    ENDIF.


    IF lo_line IS NOT BOUND.

      rs_row-structured =
        abap_false.

      RETURN.

    ENDIF.


    rs_row-line_name =
      lo_line->absolute_name.


    IF rs_row-line_name IS INITIAL.

      rs_row-line_name =
        iv_type.

    ENDIF.


    "==========================================================
    " OData result cần line type là structure
    "==========================================================
    IF lo_line->kind <>
         cl_abap_typedescr=>kind_struct.

      rs_row-structured =
        abap_false.

      RETURN.

    ENDIF.


    rs_row-structured =
      abap_true.


    DATA lo_struct
      TYPE REF TO cl_abap_structdescr.


    TRY.

        lo_struct =
          CAST cl_abap_structdescr(
            lo_line
          ).

      CATCH cx_root.

        rs_row-structured =
          abap_false.

        RETURN.

    ENDTRY.


    DATA(lt_components) =
      lo_struct->get_components( ).


    LOOP AT lt_components
      INTO DATA(ls_component).

      DATA ls_row_comp
        TYPE zif_mig_types=>ty_row_comp.

      CLEAR ls_row_comp.


      ls_row_comp-comp_name =
        ls_component-name.

      ls_row_comp-position =
        sy-tabix.


      IF ls_component-type IS NOT BOUND.

        ls_row_comp-is_deep =
          abap_true.

        APPEND ls_row_comp
          TO rs_row-components.

        CONTINUE.

      ENDIF.


      ls_row_comp-abap_type =
        ls_component-type->type_kind.

      ls_row_comp-type_name =
        ls_component-type->absolute_name.


      ls_row_comp-edm_type =
        map_edm(
          iv_kind =
            ls_component-type->type_kind

          iv_name =
            CONV zif_mig_types=>ty_sig_name(
              ls_component-type->absolute_name
            )
        ).


      ls_row_comp-is_table =
        xsdbool(
          ls_component-type->kind =
            cl_abap_typedescr=>kind_table
        ).


      ls_row_comp-is_ref =
        xsdbool(
          ls_component-type->kind =
            cl_abap_typedescr=>kind_ref
        ).


      "Nested structure/table/reference chưa flatten tự động
      ls_row_comp-is_deep =
        xsdbool(
          ls_component-type->kind =
            cl_abap_typedescr=>kind_struct
          OR
          ls_component-type->kind =
            cl_abap_typedescr=>kind_table
          OR
          ls_component-type->kind =
            cl_abap_typedescr=>kind_ref
        ).


      APPEND ls_row_comp
        TO rs_row-components.

    ENDLOOP.


    SORT rs_row-components
      BY position
         comp_name.

  ENDMETHOD.

    METHOD get_type.

  DATA:
    lv_type TYPE zif_mig_types=>ty_sig_name,
    lo_desc TYPE REF TO cl_abap_typedescr.

  CLEAR ro_type.

  lv_type = iv_type.


  "============================================================
  " Lần 1: thử nguyên tên type
  "============================================================
  CLEAR lo_desc.

  CALL METHOD cl_abap_typedescr=>describe_by_name
    EXPORTING
      p_name      = lv_type
    RECEIVING
      p_descr_ref = lo_desc
    EXCEPTIONS
      type_not_found = 1
      OTHERS         = 2.

  IF sy-subrc = 0
     AND lo_desc IS BOUND
     AND lo_desc IS INSTANCE OF cl_abap_datadescr.

    ro_type ?= lo_desc.
    RETURN.

  ENDIF.


  "============================================================
  " Lần 2: chuẩn hóa \TYPE=Z... thành Z...
  "============================================================
  lv_type =
    clean_name(
      iv_type =
        CONV string( iv_type )
    ).


  IF lv_type IS INITIAL
     OR lv_type = iv_type.

    CLEAR ro_type.
    RETURN.

  ENDIF.


  CLEAR lo_desc.

  CALL METHOD cl_abap_typedescr=>describe_by_name
    EXPORTING
      p_name      = lv_type
    RECEIVING
      p_descr_ref = lo_desc
    EXCEPTIONS
      type_not_found = 1
      OTHERS         = 2.

  IF sy-subrc = 0
     AND lo_desc IS BOUND
     AND lo_desc IS INSTANCE OF cl_abap_datadescr.

    ro_type ?= lo_desc.

  ELSE.

    CLEAR ro_type.

  ENDIF.

ENDMETHOD.

    METHOD clean_name.

    DATA lv_type TYPE string.

    lv_type =
      iv_type.

    CONDENSE lv_type NO-GAPS.


    IF lv_type CP '\TYPE=*'.

      rv_type =
        substring(
          val = lv_type
          off = 6
        ).


    ELSEIF lv_type CP 'TYPE=*'.

      rv_type =
        substring(
          val = lv_type
          off = 5
        ).


    ELSE.

      rv_type =
        lv_type.

    ENDIF.

  ENDMETHOD.

    METHOD map_edm.

    DATA(lv_name) =
      to_upper(
        CONV string( iv_name )
      ).


    "==========================================================
    " Boolean data elements
    "==========================================================
    IF lv_name CS 'ABAP_BOOL'
       OR lv_name CS 'BOOLE_D'
       OR lv_name CS 'XFELD'.

      rv_edm =
        'Edm.Boolean'.

      RETURN.

    ENDIF.


    CASE iv_kind.

      WHEN cl_abap_typedescr=>typekind_int
        OR cl_abap_typedescr=>typekind_int1
        OR cl_abap_typedescr=>typekind_int2.

        rv_edm =
          'Edm.Int32'.


      WHEN cl_abap_typedescr=>typekind_int8.

        rv_edm =
          'Edm.Int64'.


      WHEN cl_abap_typedescr=>typekind_packed
        OR cl_abap_typedescr=>typekind_decfloat16
        OR cl_abap_typedescr=>typekind_decfloat34.

        rv_edm =
          'Edm.Decimal'.


      WHEN cl_abap_typedescr=>typekind_float.

        rv_edm =
          'Edm.Double'.


      WHEN cl_abap_typedescr=>typekind_date.

        rv_edm =
          'Edm.Date'.


      WHEN cl_abap_typedescr=>typekind_time.

        rv_edm =
          'Edm.TimeOfDay'.


      WHEN cl_abap_typedescr=>typekind_hex
        OR cl_abap_typedescr=>typekind_xstring.

        rv_edm =
          'Edm.Binary'.


      WHEN cl_abap_typedescr=>typekind_char
        OR cl_abap_typedescr=>typekind_num
        OR cl_abap_typedescr=>typekind_string.

        rv_edm =
          'Edm.String'.


      WHEN OTHERS.

        rv_edm =
          'Edm.String'.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
