CLASS ltc_export_pipe_char DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS build_row_line_keeps_pipe_char FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_export_pipe_char IMPLEMENTATION.

  METHOD build_row_line_keeps_pipe_char.
    TYPES: BEGIN OF ty_row,
             statement_text TYPE string,
             line_no        TYPE i,
           END OF ty_row.
    DATA(ls_row) = VALUE ty_row(
      statement_text = `DATA(lv_msg) = |Value: { lv_x }|.`
      line_no        = 42 ).

        DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_result) = lo_cut->build_row_line(
      it_cols = VALUE #( ( fieldname = 'STATEMENT_TEXT' column_title = 'SQL Statement' )
                          ( fieldname = 'LINE_NO'        column_title = 'Line Number' ) )
      is_row  = ls_row ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'build_row_line phai tra dung 2 cell du du lieu chua |'
      act = lines( lt_result )
      exp = 2 ).
  ENDMETHOD.

ENDCLASS.

CLASS ltc_export_plan DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resolve_plan_all_not_empty FOR TESTING RAISING cx_static_check.
    METHODS resolve_plan_single_section FOR TESTING RAISING cx_static_check.
    METHODS resolve_plan_unknown_sections FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_export_plan IMPLEMENTATION.

  METHOD resolve_plan_all_not_empty.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(ls_plan) = lo_cut->resolve_export_plan(
      iv_export_section  = 'ALL'
      iv_selected_fields = '' ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Luong ALL phai tra ve it nhat 1 section tu registry'
      act = xsdbool( lines( ls_plan-sections ) > 0 ) ).
  ENDMETHOD.

  METHOD resolve_plan_single_section .
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    " Lay 1 section_code THAT tu chinh registry (khong hardcode ten section)
    DATA(ls_all_plan) = lo_cut->resolve_export_plan(
      iv_export_section  = 'ALL'
      iv_selected_fields = '' ).

    IF ls_all_plan-sections IS INITIAL.
      cl_abap_unit_assert=>fail( 'Registry rong - khong the test luong 1 section' ).
    ENDIF.

    DATA(lv_section) = ls_all_plan-sections[ 1 ]-section_code.

    DATA(ls_plan) = lo_cut->resolve_export_plan(
      iv_export_section  = lv_section
      iv_selected_fields = '' ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'Luong 1 section phai tra dung 1 section, dung section_code da chon'
      act = lines( ls_plan-sections )
      exp = 1 ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'section_code tra ve phai khop voi section_code da truyen vao'
      act = ls_plan-sections[ 1 ]-section_code
      exp = lv_section ).
  ENDMETHOD.

  METHOD resolve_plan_unknown_sections.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    TRY.
        lo_cut->resolve_export_plan(
          iv_export_section  = 'ZZZ_KHONG_TON_TAI'
          iv_selected_fields = '' ).
        cl_abap_unit_assert=>fail( 'Phai raise zcx_mig_export_error khi section khong ton tai' ).
      CATCH zcx_mig_export_error.
        " dung nhu ky vong, khong lam gi them
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

CLASS ltc_pdf_layout DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
  METHODS escape_pdf_text_keeps_space FOR TESTING RAISING cx_static_check.
    METHODS pdf_layout_default_footer FOR TESTING RAISING cx_static_check.
    METHODS pdf_layout_custom_text FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_pdf_layout IMPLEMENTATION.

  METHOD pdf_layout_default_footer.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_header_cols) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'COL_A' column_title = 'Cot A' ) ).

    DATA(lt_lines) = VALUE zcl_mig_export_engine=>tt_row_cells(
      ( VALUE string_table( ( `Cot A` ) ) )
      ( VALUE string_table( ( `Gia tri 1` ) ) ) ).

    DATA(lt_pages) = lo_cut->render_section_pages(
      iv_title       = 'Bao cao test'
      it_header_cols = lt_header_cols
      it_lines       = lt_lines ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Khong truyen is_pdf_layout thi footer phai giu nguyen Generated:'
      act = xsdbool( lines( lt_pages ) > 0 AND find( val = lt_pages[ 1 ] sub = `Generated:` ) >= 0 ) ).
  ENDMETHOD.

  METHOD pdf_layout_custom_text.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_header_cols) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'COL_A' column_title = 'Cot A' ) ).

    DATA(lt_lines) = VALUE zcl_mig_export_engine=>tt_row_cells(
      ( VALUE string_table( ( `Cot A` ) ) )
      ( VALUE string_table( ( `Gia tri 1` ) ) ) ).

    DATA(ls_layout) = VALUE zcl_mig_export_engine=>ty_pdf_layout(
      header_text = 'TIEU DE TUY CHINH'
      footer_text = 'FOOTER TUY CHINH' ).



    DATA(lt_pages) = lo_cut->render_section_pages(
      iv_title       = 'Bao cao test'
      it_header_cols = lt_header_cols
      it_lines       = lt_lines
      is_pdf_layout  = ls_layout ).

    cl_abap_unit_assert=>assert_true(
      msg = 'header_text tuy chinh phai xuat hien trong noi dung trang PDF'
      act = xsdbool( lines( lt_pages ) > 0 AND find( val = lt_pages[ 1 ] sub = `TIEU DE TUY CHINH` ) >= 0 ) ).

    cl_abap_unit_assert=>assert_true(
      msg = 'footer_text tuy chinh phai xuat hien trong noi dung trang PDF'
      act = xsdbool( find( val = lt_pages[ 1 ] sub = `FOOTER TUY CHINH` ) >= 0 ) ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Khi da tuy chinh footer thi chu Generated mac dinh khong con xuat hien'
      act = xsdbool( find( val = lt_pages[ 1 ] sub = `Generated:` ) < 0 ) ).
  ENDMETHOD.
  METHOD escape_pdf_text_keeps_space.
  DATA(lo_cut) = NEW zcl_mig_export_engine( ).
  cl_abap_unit_assert=>assert_equals(
    msg = 'escape_pdf_text khong duoc lam mat khoang trang'
    act = lo_cut->escape_pdf_text( 'TIEU DE TUY CHINH' )
    exp = 'TIEU DE TUY CHINH' ).
ENDMETHOD.

ENDCLASS.
