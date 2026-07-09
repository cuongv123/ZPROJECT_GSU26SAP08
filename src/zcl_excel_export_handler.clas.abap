CLASS zcl_excel_export_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_business_logic,
             programname           TYPE string,
             objectname            TYPE string,
             description           TYPE string,
             objecttype            TYPE string,
             recommendation        TYPE string,
             migrationtarget       TYPE string,
             severity              TYPE string,
             remediationcomplexity TYPE string,
           END OF ty_business_logic.

    TYPES tt_business_logic TYPE STANDARD TABLE OF ty_business_logic WITH DEFAULT KEY.

    METHODS export_to_excel
      IMPORTING
        it_data           TYPE tt_business_logic
        ip_title          TYPE string
      RETURNING
        VALUE(rv_xstring) TYPE xstring
      RAISING
        zcx_excel.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_excel_export_handler IMPLEMENTATION.
  METHOD export_to_excel.
    DATA: lo_excel     TYPE REF TO zcl_excel,
          lo_worksheet TYPE REF TO zcl_excel_worksheet,
          lo_style_hdr TYPE REF TO zcl_excel_style,
          lo_style_hi  TYPE REF TO zcl_excel_style,
          lo_style_med TYPE REF TO zcl_excel_style,
          lv_row       TYPE i VALUE 4.

    CREATE OBJECT lo_excel.
    lo_worksheet = lo_excel->get_active_worksheet( ).

    DATA(lv_sheet_title) = CONV zexcel_sheet_title( ip_title ).
    lo_worksheet->set_title( lv_sheet_title ).

    " Định nghĩa các style màu sắc
    lo_style_hdr = lo_excel->add_new_style( ).
    lo_style_hdr->font->name        = zcl_excel_style_font=>c_name_arial.
    lo_style_hdr->font->color-rgb   = zcl_excel_style_color=>c_white.
    lo_style_hdr->fill->filltype    = zcl_excel_style_fill=>c_fill_solid.
    lo_style_hdr->fill->fgcolor-rgb = '003366'.

    lo_style_hi = lo_excel->add_new_style( ).
    lo_style_hi->font->color-rgb   = zcl_excel_style_color=>c_white.
    lo_style_hi->fill->filltype    = zcl_excel_style_fill=>c_fill_solid.
    lo_style_hi->fill->fgcolor-rgb = zcl_excel_style_color=>c_red.

    lo_style_med = lo_excel->add_new_style( ).
    lo_style_med->font->color-rgb   = zcl_excel_style_color=>c_black.
    lo_style_med->fill->filltype    = zcl_excel_style_fill=>c_fill_solid.
    lo_style_med->fill->fgcolor-rgb = '003366'.

    " Ghi tiêu đề Metadata đầu file
    lo_worksheet->set_cell( ip_column = 1 ip_row = 1 ip_value = 'MIGRATION ANALYSIS REPORT' ).
    lo_worksheet->set_cell( ip_column = 1 ip_row = 2 ip_value = 'Generated automatically via RAP Query Provider' ).

    " Ghi dòng tiêu đề cột
    lo_worksheet->set_cell( ip_column = 1 ip_row = lv_row ip_value = 'Program Name'          ip_style = lo_style_hdr ).
    lo_worksheet->set_cell( ip_column = 2 ip_row = lv_row ip_value = 'Object Name'           ip_style = lo_style_hdr ).
    lo_worksheet->set_cell( ip_column = 3 ip_row = lv_row ip_value = 'Description'           ip_style = lo_style_hdr ).
    lo_worksheet->set_cell( ip_column = 4 ip_row = lv_row ip_value = 'Object Type'           ip_style = lo_style_hdr ).
    lo_worksheet->set_cell( ip_column = 5 ip_row = lv_row ip_value = 'Recommendation'        ip_style = lo_style_hdr ).
    lo_worksheet->set_cell( ip_column = 6 ip_row = lv_row ip_value = 'Migration Target'      ip_style = lo_style_hdr ).
    lo_worksheet->set_cell( ip_column = 7 ip_row = lv_row ip_value = 'Severity'              ip_style = lo_style_hdr ).
    lo_worksheet->set_cell( ip_column = 8 ip_row = lv_row ip_value = 'Remediation Complexity' ip_style = lo_style_hdr ).

    " Đổ dữ liệu thực tế vào bảng Excel
    LOOP AT it_data INTO DATA(ls_data).
      lv_row = lv_row + 1.

      lo_worksheet->set_cell( ip_column = 1 ip_row = lv_row ip_value = ls_data-programname ).
      lo_worksheet->set_cell( ip_column = 2 ip_row = lv_row ip_value = ls_data-objectname ).
      lo_worksheet->set_cell( ip_column = 3 ip_row = lv_row ip_value = ls_data-description ).
      lo_worksheet->set_cell( ip_column = 4 ip_row = lv_row ip_value = ls_data-objecttype ).
      lo_worksheet->set_cell( ip_column = 5 ip_row = lv_row ip_value = ls_data-recommendation ).
      lo_worksheet->set_cell( ip_column = 6 ip_row = lv_row ip_value = ls_data-migrationtarget ).

      DATA(lv_severity_upper) = TO_UPPER( ls_data-severity ).
      IF lv_severity_upper = 'HIGH' OR lv_severity_upper = 'H'.
        lo_worksheet->set_cell( ip_column = 7 ip_row = lv_row ip_value = ls_data-severity ip_style = lo_style_hi ).
      ELSEIF lv_severity_upper = 'MEDIUM' OR lv_severity_upper = 'M'.
        lo_worksheet->set_cell( ip_column = 7 ip_row = lv_row ip_value = ls_data-severity ip_style = lo_style_med ).
      ELSE.
        lo_worksheet->set_cell( ip_column = 7 ip_row = lv_row ip_value = ls_data-severity ).
      ENDIF.

      lo_worksheet->set_cell( ip_column = 8 ip_row = lv_row ip_value = ls_data-remediationcomplexity ).
    ENDLOOP.

    " Biên dịch sang định dạng nhị phân xstring
    DATA: lo_writer TYPE REF TO zif_excel_writer.
    CREATE OBJECT lo_writer TYPE zcl_excel_writer_2007.
    rv_xstring = lo_writer->write_file( lo_excel ).
  ENDMETHOD.
ENDCLASS.
