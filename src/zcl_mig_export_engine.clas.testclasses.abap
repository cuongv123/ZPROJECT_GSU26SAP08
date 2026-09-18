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

**********************************************************************
* 5 test moi, khoa lai 5 hanh vi da sua ngay 02/09 trong
* zcl_mig_export_engine (header khong chong chu, PDF khong loi khi
* rong, CSV co ghi chu khi rong, PDF tach khoi cot, do rong cot co
* gian theo noi dung).
*
* Dan toan bo khoi ben duoi vao CUOI file testclasses.abap hien co
* cua ZCL_MIG_EXPORT_ENGINE (ngay sau class ltc_pdf_layout), roi
* activate lai class chinh.
**********************************************************************

CLASS ltc_export_nodata DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " Fixture du lieu that: 1 AnalysisId co that trong he thong, va
    " section ALV_OUTPUT duoc xac nhan la RONG (0 dong) cho analysis
    " nay tai thoi diem viet test (02/09). Neu sau nay co du lieu
    " ALV_OUTPUT cho chinh analysis nay, 2 test ben duoi se fail va
    " can doi lai fixture (chon AnalysisId/section rong khac).
    CONSTANTS gc_analysis_id TYPE sysuuid_x16 VALUE '8B95F36A4F271FD1A4E59A1A58522272'.
    CONSTANTS gc_job_id      TYPE sysuuid_x16 VALUE 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'.

    METHODS pdf_empty_section_succeeds FOR TESTING RAISING cx_static_check.
    METHODS csv_no_data_has_note FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_export_nodata IMPLEMENTATION.

  METHOD pdf_empty_section_succeeds.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    " export_pdf la private - phai goi qua method public duy nhat la
    " interface method generate() (chinh no se dispatch toi export_pdf).
    DATA(ls_result) = lo_cut->zif_mig_export_provider~generate(
      iv_job_id          = gc_job_id
      iv_analysis_id     = gc_analysis_id
      iv_report_type     = ''
      iv_file_format      = 'P'
      iv_export_section  = 'ALV_OUTPUT'
      iv_selected_fields = '' ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Export PDF cho section RONG (ALV_OUTPUT) phai THANH CONG - khong con bao loi cung nhu truoc khi sua'
      act = ls_result-success ).

    cl_abap_unit_assert=>assert_true(
      msg = 'File PDF sinh ra van phai co noi dung (trang thong bao), khong duoc rong'
      act = xsdbool( xstrlen( ls_result-content ) > 0 ) ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Ten file tra ve phai dung duoi .pdf'
      act = xsdbool( find( val = to_upper( CONV string( ls_result-file_name ) ) sub = '.PDF' ) >= 0 ) ).
  ENDMETHOD.

  METHOD csv_no_data_has_note.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(ls_result) = lo_cut->zif_mig_export_provider~generate(
      iv_job_id          = gc_job_id
      iv_analysis_id     = gc_analysis_id
      iv_report_type     = ''
      iv_file_format      = 'C'
      iv_export_section  = 'ALV_OUTPUT'
      iv_selected_fields = '' ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Export CSV cho section RONG (ALV_OUTPUT) phai THANH CONG'
      act = ls_result-success ).

    DATA(lv_csv_text) = cl_abap_codepage=>convert_from(
      source   = ls_result-content
      codepage = 'UTF-8' ).

    cl_abap_unit_assert=>assert_true(
      msg = 'CSV cho section rong phai co ghi chu "No data available" thay vi chi co dong header trong khong'
      act = xsdbool( find( val = lv_csv_text sub = 'No data available' ) >= 0 ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_export_pdf_layout_fix DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS long_header_gets_truncated FOR TESTING RAISING cx_static_check.
    METHODS wide_column_not_truncated FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_export_pdf_layout_fix IMPLEMENTATION.

  METHOD long_header_gets_truncated.
    " Test hanh vi khong phu thuoc cong thuc noi bo: 1 header rat dai
    " (200 ky tu) chia se trang PDF voi 7 cot khac -> du thuat toan chia
    " trong so co uu tien cot dai den dau, cot do cung chi chua duoc
    " toi da vai chuc ky tu trong 1 trang, nen header 200 ky tu nay
    " BAT BUOC phai bi cat bot, khong con hien nguyen ven.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    " Dung 200 ky tu (thay vi 60) de chac chan vuot nguong suc chua cua
    " cot du duoc uu tien nhieu khong gian nhat (theo thuat toan chia
    " trong so hien tai, cot dai nhat cung chi chua duoc ~60-70 ky tu
    " trong kich thuoc trang mac dinh) - tranh test nam sat bien, phu
    " thuoc vao sai so lam tron cua tung cong thuc cu the.
    DATA(lv_long_title) = repeat( val = 'A' occ = 200 ).

    DATA(lt_header_cols) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'F1' column_title = lv_long_title )
      ( fieldname = 'F2' column_title = 'B' )
      ( fieldname = 'F3' column_title = 'C' )
      ( fieldname = 'F4' column_title = 'D' )
      ( fieldname = 'F5' column_title = 'E' )
      ( fieldname = 'F6' column_title = 'F' )
      ( fieldname = 'F7' column_title = 'G' )
      ( fieldname = 'F8' column_title = 'H' ) ).

    " QUAN TRONG: it_lines[1] moi la hang CHU HEADER thuc su duoc ve len
    " PDF (xem render_section_pages: lt_header_cells = it_lines[ 1 ]).
    " it_header_cols o tren chi dung de dem SO COT, khong phai nguon
    " chu hien thi. Vi vay hang dau tien cua lt_lines PHAI chua
    " lv_long_title (khong duoc bo sot nhu ban truoc), roi moi den
    " hang du lieu '1'..'8'.
    DATA lt_lines TYPE zcl_mig_export_engine=>tt_row_cells.
    CLEAR lt_lines.

    DATA lt_header_row TYPE string_table.
    CLEAR lt_header_row.
    APPEND lv_long_title TO lt_header_row.
    APPEND 'B' TO lt_header_row.
    APPEND 'C' TO lt_header_row.
    APPEND 'D' TO lt_header_row.
    APPEND 'E' TO lt_header_row.
    APPEND 'F' TO lt_header_row.
    APPEND 'G' TO lt_header_row.
    APPEND 'H' TO lt_header_row.
    APPEND lt_header_row TO lt_lines.

    DATA lt_row1 TYPE string_table.
    CLEAR lt_row1.
    APPEND '1' TO lt_row1.
    APPEND '2' TO lt_row1.
    APPEND '3' TO lt_row1.
    APPEND '4' TO lt_row1.
    APPEND '5' TO lt_row1.
    APPEND '6' TO lt_row1.
    APPEND '7' TO lt_row1.
    APPEND '8' TO lt_row1.
    APPEND lt_row1 TO lt_lines.

    DATA(lt_pages) = lo_cut->render_section_pages(
      iv_title       = 'Test truncation header'
      it_header_cols = lt_header_cols
      it_lines       = lt_lines ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Phai sinh duoc it nhat 1 trang PDF'
      act = xsdbool( lines( lt_pages ) > 0 ) ).

    DATA(lv_all_pages) = concat_lines_of( table = lt_pages ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Header dai 200 ky tu chia se voi 7 cot khac PHAI bi cat bot - khong duoc xuat hien nguyen ven trong noi dung PDF'
      act = xsdbool( find( val = lv_all_pages sub = lv_long_title ) < 0 ) ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Van phai con lai 1 phan dau cua header (khong bi cat/an mat hoan toan, chi cat bot phan du)'
      act = xsdbool( find( val = lv_all_pages sub = 'AAAAA' ) >= 0 ) ).
  ENDMETHOD.
  METHOD wide_column_not_truncated.
    " CAP NHAT theo thiet ke moi: be rong cot (weight) gio tinh theo TU DAI
    " NHAT trong cot (header hoac data), khong con theo TONG DO DAI CA CHUOI
    " nhu truoc - muc dich la de FitToPage khong bao gio bop 1 cot hep hon
    " muc can de hien du 1 tu (tranh vo tu giua chung o cac bang nhieu cot).
    " He qua chap nhan duoc: 1 cot nhieu-tu-nhung-tung-tu-ngan (nhu lv_desc
    " duoi day, cac tu dai nhat chi ~4 ky tu) se KHONG con duoc "thuong" rong
    " hon cac cot 1-ky-tu khac nua - noi dung co the phai xuong dong (wrap)
    " thanh nhieu dong trong cung 1 o, thay vi hien tron ven tren 1 dong.
    " Vi vay test nay khong con doi hoi ca cau xuat hien NGUYEN VEN lien tuc
    " (dieu do khong con dung voi thiet ke moi), ma doi hoi dieu quan trong
    " hon: TUNG TU trong noi dung phai con nguyen ven, KHONG bi cat/vo giua
    " chung du phai xuong dong - dung muc tieu chinh cua fix nay.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lv_desc) = 'Mo ta chi tiet noi dung'.  "23 ky tu, khong dau

    DATA(lt_header_cols) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'F1' column_title = 'X' )
      ( fieldname = 'F2' column_title = 'B' )
      ( fieldname = 'F3' column_title = 'C' )
      ( fieldname = 'F4' column_title = 'D' )
      ( fieldname = 'F5' column_title = 'E' )
      ( fieldname = 'F6' column_title = 'F' )
      ( fieldname = 'F7' column_title = 'G' )
      ( fieldname = 'F8' column_title = 'H' ) ).

    DATA lt_lines TYPE zcl_mig_export_engine=>tt_row_cells.
    CLEAR lt_lines.
    DATA lt_row1 TYPE string_table.
    CLEAR lt_row1.
    APPEND lv_desc TO lt_row1.
    APPEND '1' TO lt_row1.
    APPEND '1' TO lt_row1.
    APPEND '1' TO lt_row1.
    APPEND '1' TO lt_row1.
    APPEND '1' TO lt_row1.
    APPEND '1' TO lt_row1.
    APPEND '1' TO lt_row1.
    APPEND lt_row1 TO lt_lines.

    DATA(lt_pages) = lo_cut->render_section_pages(
      iv_title       = 'Test do rong co gian'
      it_header_cols = lt_header_cols
      it_lines       = lt_lines ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Phai sinh duoc it nhat 1 trang PDF'
      act = xsdbool( lines( lt_pages ) > 0 ) ).

    DATA(lv_all_pages) = concat_lines_of( table = lt_pages ).

    SPLIT lv_desc AT space INTO TABLE DATA(lt_desc_words).
    LOOP AT lt_desc_words INTO DATA(lv_desc_word).
      cl_abap_unit_assert=>assert_true(
        msg = |Tu "{ lv_desc_word }" trong cot noi dung dai ({ strlen( lv_desc ) } ky tu, di kem 7 cot rat ngan) phai xuat hien nguyen ven trong PDF - khong duoc bi cat/vo giua chung du co the phai xuong dong|
        act = xsdbool( find( val = lv_all_pages sub = lv_desc_word ) >= 0 ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_export_column_block DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS gc_analysis_id TYPE sysuuid_x16 VALUE '8B95F36A4F271FD1A4E59A1A58522272'.
    CONSTANTS gc_job_id      TYPE sysuuid_x16 VALUE 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'.

    METHODS pdf_splits_into_column_blocks FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_export_column_block IMPLEMENTATION.

  METHOD pdf_splits_into_column_blocks.
    " UI_FILTER hien co 18 cot (> nguong lc_max_cols_per_block = 12),
    " nen PDF phai tu dong tach thanh nhieu khoi cot thay vi cat bot/an
    " mat cot cho vua trang. Danh dau nhan biet: tieu de moi khoi co
    " chua "(Columns" (vd "(Columns 1-12 of 18)").
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(ls_result) = lo_cut->zif_mig_export_provider~generate(
      iv_job_id          = gc_job_id
      iv_analysis_id     = gc_analysis_id
      iv_report_type     = ''
      iv_file_format      = 'P'
      iv_export_section  = 'UI_FILTER'
      iv_selected_fields = '' ).

    cl_abap_unit_assert=>assert_true(
      msg = 'Export PDF cho UI_FILTER (18 cot) phai thanh cong'
      act = ls_result-success ).

    DATA(lv_pdf_text) = cl_abap_codepage=>convert_from(
      source   = ls_result-content
      codepage = 'UTF-8' ).

    " Dem so lan xuat hien nhan "(Columns" - phai >= 2 vi 18 cot voi
    " nguong 12 cot/khoi se tach ra dung 2 khoi.
    DATA(lv_remainder) = lv_pdf_text.
    DATA(lv_count) = 0.
    DO.
      FIND '(Columns' IN lv_remainder MATCH OFFSET DATA(lv_off).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      lv_count = lv_count + 1.
      lv_remainder = lv_remainder+lv_off.
      lv_remainder = lv_remainder+8.
    ENDDO.

    cl_abap_unit_assert=>assert_true(
      msg = |UI_FILTER co 18 cot, vuot nguong 12 cot/khoi -> phai tach thanh it nhat 2 khoi (nhan "(Columns" xuat hien it nhat 2 lan, thuc te { lv_count } lan)|
      act = xsdbool( lv_count >= 2 ) ).
  ENDMETHOD.

ENDCLASS.
**********************************************************************
* Test moi cho split_row_for_excel (Buoc 3 - Split multi-value Excel).
* Dan vao CUOI file testclasses.abap hien co cua ZCL_MIG_EXPORT_ENGINE
* (ngay sau class ltc_export_column_block), roi activate lai class chinh.
**********************************************************************

CLASS ltc_export_excel_split DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_test_row,
             objectname     TYPE string,
             selectedfields TYPE string,
             joinedobjects  TYPE string,
           END OF ty_test_row.

    METHODS split_disabled_keeps_1_row FOR TESTING RAISING cx_static_check.
    METHODS non_flagged_column_not_split FOR TESTING RAISING cx_static_check.
    METHODS space_separator_splits FOR TESTING RAISING cx_static_check.
    METHODS comma_sep_survives_padding FOR TESTING RAISING cx_static_check.
    METHODS mismatched_counts_pad_blank FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_export_excel_split IMPLEMENTATION.

  METHOD split_disabled_keeps_1_row.
    " Ngay ca khi cot duoc danh dau IS_MULTI_VALUE va gia tri co dau
    " phan tach, neu iv_split_enabled = FALSE thi PHAI giu nguyen 1
    " dong duy nhat - dung y nghia "mac dinh khong doi hanh vi cu".
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_columns) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'OBJECTNAME'     column_title = 'Object' is_multi_value = abap_false )
      ( fieldname = 'SELECTEDFIELDS' column_title = 'Fields'  is_multi_value = abap_true value_separator = ' ' ) ).

    DATA(ls_row) = VALUE ty_test_row(
      objectname     = 'ZTB_ORDER'
      selectedfields = 'MATNR WERKS MENGE' ).

    DATA(lt_out) = lo_cut->split_row_for_excel(
      it_columns       = lt_columns
      is_row           = ls_row
      iv_split_enabled = abap_false ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'Khi tat split, phai giu dung 1 dong bat ke co multi-value hay khong'
      exp = 1
      act = lines( lt_out ) ).
  ENDMETHOD.

  METHOD non_flagged_column_not_split.
    " Cot khong duoc danh dau IS_MULTI_VALUE thi du gia tri co chua ky
    " tu giong dau phan tach cung khong bi tach - moi cot tu quyet
    " dinh rieng, khong anh huong lan nhau.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_columns) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'OBJECTNAME' column_title = 'Object' is_multi_value = abap_false ) ).

    DATA(ls_row) = VALUE ty_test_row( objectname = 'A, B, C' ).

    DATA(lt_out) = lo_cut->split_row_for_excel(
      it_columns       = lt_columns
      is_row           = ls_row
      iv_split_enabled = abap_true ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'Cot khong danh dau IS_MULTI_VALUE thi khong duoc tach, du bat split_enabled'
      exp = 1
      act = lines( lt_out ) ).
  ENDMETHOD.

  METHOD space_separator_splits.
    " Mo phong dung SELECTED_FIELDS: value_separator = ' ' (CHAR3, toan
    " khoang trang) - phai tach dung theo dau cach.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_columns) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'OBJECTNAME'     column_title = 'Object' is_multi_value = abap_false )
      ( fieldname = 'SELECTEDFIELDS' column_title = 'Fields'  is_multi_value = abap_true value_separator = ' ' ) ).

    DATA(ls_row) = VALUE ty_test_row(
      objectname     = 'ZTB_ORDER'
      selectedfields = 'MATNR WERKS MENGE' ).

    DATA(lt_out) = lo_cut->split_row_for_excel(
      it_columns       = lt_columns
      is_row           = ls_row
      iv_split_enabled = abap_true ).

    cl_abap_unit_assert=>assert_equals(
      msg = '3 gia tri cach nhau boi dau cach phai sinh dung 3 dong'
      exp = 3
      act = lines( lt_out ) ).

    DATA(lt_row1) = lt_out[ 1 ].
    DATA(lt_row2) = lt_out[ 2 ].
    DATA(lt_row3) = lt_out[ 3 ].

    cl_abap_unit_assert=>assert_equals( msg = 'Dong 1 - cot 1 (khong tach)' exp = 'ZTB_ORDER' act = lt_row1[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( msg = 'Dong 1 - cot 2 (phan tu 1)'  exp = 'MATNR'     act = lt_row1[ 2 ] ).
    cl_abap_unit_assert=>assert_equals( msg = 'Dong 2 - cot 1 (lap lai)'    exp = 'ZTB_ORDER' act = lt_row2[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( msg = 'Dong 2 - cot 2 (phan tu 2)'  exp = 'WERKS'     act = lt_row2[ 2 ] ).
    cl_abap_unit_assert=>assert_equals( msg = 'Dong 3 - cot 1 (lap lai)'    exp = 'ZTB_ORDER' act = lt_row3[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( msg = 'Dong 3 - cot 2 (phan tu 3)'  exp = 'MENGE'     act = lt_row3[ 2 ] ).
  ENDMETHOD.

  METHOD comma_sep_survives_padding.
    " Mo phong dung JOINED_OBJECTS: value_separator = ', ' luu vao
    " CHAR3 se bi dem them 1 khoang trang o cuoi (thanh ',  ' - 2 dau
    " cach thay vi 1). Neu dung nguyen gia tri padded de tim trong
    " chuoi goc (chi co 1 dau cach) se KHONG khop - day chinh la bug
    " da ne duoc trong split_row_for_excel. Test nay khoa lai hanh vi
    " dung (khong bi regress ve sau).
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_columns) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'JOINEDOBJECTS' column_title = 'Objects' is_multi_value = abap_true value_separator = ', ' ) ).

    DATA(ls_row) = VALUE ty_test_row( joinedobjects = 'MARA, MARC' ).

    DATA(lt_out) = lo_cut->split_row_for_excel(
      it_columns       = lt_columns
      is_row           = ls_row
      iv_split_enabled = abap_true ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'value_separator CHAR3 bi dem khoang trang khong duoc lam hong viec tach - van phai ra dung 2 dong'
      exp = 2
      act = lines( lt_out ) ).

    DATA(lt_row1) = lt_out[ 1 ].
    DATA(lt_row2) = lt_out[ 2 ].
    cl_abap_unit_assert=>assert_equals( exp = 'MARA' act = lt_row1[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = 'MARC' act = lt_row2[ 1 ] ).
  ENDMETHOD.

  METHOD mismatched_counts_pad_blank.
    " 2 cot multi-value cung dong nhung so phan tu khac nhau (3 vs 2)
    " -> so dong sinh ra = max(3,2) = 3, cot it phan tu hon de trong o
    " dong du.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(lt_columns) = VALUE zcl_mig_export_engine=>tt_col(
      ( fieldname = 'SELECTEDFIELDS' column_title = 'Fields'  is_multi_value = abap_true value_separator = ' ' )
      ( fieldname = 'JOINEDOBJECTS'  column_title = 'Objects' is_multi_value = abap_true value_separator = ', ' ) ).

    DATA(ls_row) = VALUE ty_test_row(
      selectedfields = 'MATNR WERKS MENGE'
      joinedobjects  = 'MARA, MARC' ).

    DATA(lt_out) = lo_cut->split_row_for_excel(
      it_columns       = lt_columns
      is_row           = ls_row
      iv_split_enabled = abap_true ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'So dong phai bang cot nhieu phan tu nhat (3), khong phai it nhat (2)'
      exp = 3
      act = lines( lt_out ) ).

    DATA(lt_row3) = lt_out[ 3 ].
    cl_abap_unit_assert=>assert_equals( msg = 'Dong 3 - SELECTEDFIELDS phan tu thu 3' exp = 'MENGE' act = lt_row3[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( msg = 'Dong 3 - JOINEDOBJECTS chi co 2 phan tu, phai de trong' exp = '' act = lt_row3[ 2 ] ).
  ENDMETHOD.

ENDCLASS.

CLASS ltc_export_split_wiring DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS gc_analysis_id TYPE sysuuid_x16 VALUE '8B95F36A4F271FD1A4E59A1A58522272'.
    CONSTANTS gc_job_id      TYPE sysuuid_x16 VALUE 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'.

    METHODS generate_accepts_split_flag FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_export_split_wiring IMPLEMENTATION.

  METHOD generate_accepts_split_flag.
    " Chi xac nhan viec truyen iv_split_multi_value qua generate()
    " khong lam vo export binh thuong (van thanh cong, van co noi
    " dung) - KHONG test lai logic tach dong, vi 5 test rieng cho
    " split_row_for_excel o Buoc 3 da khoa hanh vi do roi.
    DATA(lo_cut) = NEW zcl_mig_export_engine( ).

    DATA(ls_result) = lo_cut->zif_mig_export_provider~generate(
      iv_job_id             = gc_job_id
      iv_analysis_id        = gc_analysis_id
      iv_report_type        = ''
      iv_file_format         = 'X'
      iv_export_section     = 'UI_FILTER'
      iv_selected_fields    = ''
      iv_split_multi_value  = abap_true ).

    cl_abap_unit_assert=>assert_true(
      msg = 'generate() phai chap nhan iv_split_multi_value va van xuat Excel thanh cong'
      act = ls_result-success ).

    cl_abap_unit_assert=>assert_true(
      msg = 'File Excel sinh ra van phai co noi dung, khong duoc rong'
      act = xsdbool( xstrlen( ls_result-content ) > 0 ) ).
  ENDMETHOD.

ENDCLASS.
