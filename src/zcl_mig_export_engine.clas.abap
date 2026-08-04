CLASS zcl_mig_export_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_export_provider.

    " Method chính tiếp nhận request export từ UI5/Controller
    METHODS execute_export
      IMPORTING
        iv_selected_fields TYPE string
        iv_export_format   TYPE string
      RETURNING
        VALUE(rv_content)  TYPE xstring.

  PRIVATE SECTION.
    CONSTANTS:
      gc_format_excel TYPE zmig_e_file_format VALUE 'X',
      gc_format_csv   TYPE zmig_e_file_format VALUE 'C',
      gc_format_pdf   TYPE zmig_e_file_format VALUE 'P',
      gc_excel_name   TYPE string VALUE 'migration_report.xlsx',
      gc_csv_name     TYPE string VALUE 'migration_report.csv',
      gc_pdf_name     TYPE string VALUE 'migration_report.pdf'.

    " Bảng chứa dữ liệu UI Filters mẫu (Hoặc thay bằng cấu trúc của bạn)
    DATA gt_ui_filters TYPE STANDARD TABLE OF zmig_anl_ui.

    TYPES: BEGIN OF ty_fiori_col,
             fieldname   TYPE string,
             column_name TYPE string,
           END OF ty_fiori_col,
           tt_fiori_col TYPE STANDARD TABLE OF ty_fiori_col WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_section_registry,
             section_code TYPE zif_mig_export_provider=>ty_export_section,
             view_name    TYPE tabname,
             sheet_title  TYPE string,
           END OF ty_section_registry,
           tt_section_registry TYPE STANDARD TABLE OF ty_section_registry WITH NON-UNIQUE DEFAULT KEY.

    " Private Methods
    METHODS escape_pdf_text
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS get_fiori_columns
      IMPORTING
        iv_section_code TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rt_cols)  TYPE tt_fiori_col.

    METHODS get_section_registry
      RETURNING
        VALUE(rt_registry) TYPE tt_section_registry.

    METHODS prepare_export_lines
      IMPORTING
        iv_selected_fields TYPE string
      RETURNING
        VALUE(rt_lines)    TYPE string_table.

    METHODS get_analysis_id
      IMPORTING
        iv_analysis_id        TYPE sysuuid_x16
        iv_report_type        TYPE zmig_mail_job-report_type
      RETURNING
        VALUE(rv_analysis_id) TYPE sysuuid_x16
      RAISING
        cx_root.

    METHODS build_pdf_document
      IMPORTING
        it_lines          TYPE string_table
      RETURNING
        VALUE(rv_content) TYPE xstring
      RAISING
        cx_root.

    METHODS build_csv_document
      IMPORTING
        it_lines          TYPE string_table
      RETURNING
        VALUE(rv_content) TYPE xstring.

    METHODS build_excel_document
      IMPORTING
        it_lines          TYPE string_table
      RETURNING
        VALUE(rv_content) TYPE xstring
      RAISING
        zcx_excel.

    METHODS escape_csv_value
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS export_excel
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_analysis_id    TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    METHODS export_csv
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_analysis_id    TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    METHODS export_pdf
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_analysis_id    TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

ENDCLASS.

CLASS zcl_mig_export_engine IMPLEMENTATION.

  METHOD execute_export.
    " 1. Gom data tinh gọn
    DATA(lt_export_lines) = me->prepare_export_lines( iv_selected_fields = iv_selected_fields ).

    " 2. Điều hướng Engine theo đúng Fixed Values của Domain ZMIG_D_FILE_FORMAT
    CASE to_upper( iv_export_format ).
      WHEN 'P' OR 'PDF'.
        TRY.
            rv_content = me->build_pdf_document( it_lines = lt_export_lines ).
          CATCH cx_root.
            CLEAR rv_content.
        ENDTRY.

      WHEN 'X' OR 'EXCEL' OR 'XLSX'.
        TRY.
            rv_content = me->build_excel_document( it_lines = lt_export_lines ).
          CATCH zcx_excel cx_root.
            CLEAR rv_content.
        ENDTRY.

      WHEN 'C' OR 'CSV'.
        rv_content = me->build_csv_document( it_lines = lt_export_lines ).
    ENDCASE.
  ENDMETHOD.
  METHOD prepare_export_lines.
    DATA: lt_visible_cols TYPE STANDARD TABLE OF string,
          lv_header_row   TYPE string,
          lv_data_row     TYPE string.

    " 1. Tách chuỗi selected fields từ UI5
    SPLIT iv_selected_fields AT ',' INTO TABLE lt_visible_cols.

    " ==================================================================
    " SECTION: UI FILTERS
    " ==================================================================
    APPEND '=== UI Filters ===' TO rt_lines.

    " A. Dòng Field Header
    CLEAR lv_header_row.
    LOOP AT lt_visible_cols INTO DATA(lv_col_name).
      CONDENSE lv_col_name.
      IF lv_col_name IS NOT INITIAL.
        lv_header_row = COND #( WHEN lv_header_row IS INITIAL
                                THEN lv_col_name
                                ELSE lv_header_row && '|' && lv_col_name ).
      ENDIF.
    ENDLOOP.

    IF lv_header_row IS NOT INITIAL.
      APPEND lv_header_row TO rt_lines.
    ENDIF.

    " B. Dòng Data Rows (Dùng Dynamic Assignment - Không lo lỗi tên field cứng)
    LOOP AT gt_ui_filters INTO DATA(ls_item).
      CLEAR lv_data_row.

      LOOP AT lt_visible_cols INTO lv_col_name.
        DATA(lv_field_upper) = to_upper( condense( lv_col_name ) ).

        " Map nhanh nếu UI5 gửi tên ngắn gọn nhưng DB dùng tên đầy đủ
        IF lv_field_upper = 'REF_TABLE'.
          lv_field_upper = 'REFERENCE_TABLE'.
        ENDIF.

        " Gán động component từ tên field
        ASSIGN COMPONENT lv_field_upper OF STRUCTURE ls_item TO FIELD-SYMBOL(<lv_val>).

        IF sy-subrc = 0 AND <lv_val> IS ASSIGNED.
          DATA(lv_val_str) = CONV string( <lv_val> ).
          lv_data_row = COND #( WHEN lv_data_row IS INITIAL
                                THEN lv_val_str
                                ELSE lv_data_row && '|' && lv_val_str ).
        ELSE.
          " Trường hợp không tìm thấy field trong structure thì bỏ trống ô đó
          lv_data_row = COND #( WHEN lv_data_row IS INITIAL
                                THEN ''
                                ELSE lv_data_row && '|' ).
        ENDIF.

        UNASSIGN <lv_val>.
      ENDLOOP.

      IF lv_data_row IS NOT INITIAL.
        APPEND lv_data_row TO rt_lines.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_csv_document.
    DATA lv_csv_string TYPE string.

    LOOP AT it_lines INTO DATA(lv_line).
      " Thay thế phân cách pipe | thành phẩy ,
      DATA(lv_csv_line) = lv_line.
      REPLACE ALL OCCURRENCES OF '|' IN lv_csv_line WITH ','.

      lv_csv_string = lv_csv_string && lv_csv_line && cl_abap_char_utilities=>cr_lf.
    ENDLOOP.

    " Chuyển sang UTF-8 Binary Stream
    rv_content = cl_abap_codepage=>convert_to(
                   source   = lv_csv_string
                   codepage = 'UTF-8' ).
  ENDMETHOD.


  METHOD build_excel_document.
    " Render Excel đơn giản từ it_lines
    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lo_sheet) = lo_excel->get_active_worksheet( ).
    lo_sheet->set_title( ip_title = 'Report' ).

    DATA(lv_row_idx) = 1.
    DATA lt_cols TYPE string_table.

    LOOP AT it_lines INTO DATA(lv_line).
      CLEAR lt_cols.
      SPLIT lv_line AT '|' INTO TABLE lt_cols.

      DATA(lv_col_idx) = 1.
      LOOP AT lt_cols INTO DATA(lv_val).
        lo_sheet->set_cell( ip_column = lv_col_idx ip_row = lv_row_idx ip_value = lv_val ).
        lv_col_idx = lv_col_idx + 1.
      ENDLOOP.

      lv_row_idx = lv_row_idx + 1.
    ENDLOOP.

    DATA(lo_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ).
    rv_content = lo_writer->write_file( io_excel = lo_excel ).
  ENDMETHOD.


  METHOD zif_mig_export_provider~generate.
    TRY.
        DATA(lv_format) = to_upper( condense( CONV string( iv_file_format ) ) ).

        CASE lv_format.
          WHEN gc_format_excel OR 'EXCEL' OR 'E' OR 'XLSX' OR 'X'.
            rs_result = export_excel(
              iv_job_id         = iv_job_id
              iv_analysis_id    = iv_analysis_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN gc_format_csv OR 'CSV' OR 'C'.
            rs_result = export_csv(
              iv_job_id         = iv_job_id
              iv_analysis_id    = iv_analysis_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN gc_format_pdf OR 'PDF' OR 'P'.
            rs_result = export_pdf(
              iv_job_id         = iv_job_id
              iv_analysis_id    = iv_analysis_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN OTHERS.
            rs_result-success = abap_false.
            rs_result-message = |Unsupported export format { iv_file_format }.|.
        ENDCASE.

        IF rs_result-success = abap_true.
          rs_result-file_format = iv_file_format.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).
        CLEAR: rs_result-content, rs_result-file_name, rs_result-file_type, rs_result-file_format, rs_result-mime_type.
        rs_result-success = abap_false.
        rs_result-message = lx_error->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_fiori_columns.
    CLEAR rt_cols.
    SELECT fieldname, column_title AS column_name
      FROM ztb_exp_col
      WHERE section_code = @iv_section_code
      ORDER BY seq_no ASCENDING
      INTO CORRESPONDING FIELDS OF TABLE @rt_cols.
  ENDMETHOD.


  METHOD get_section_registry.
    CLEAR rt_registry.

    SELECT section_code, view_name, sheet_title
      FROM ztb_exp_section
      WHERE is_active = 'X'
      ORDER BY sort_order ASCENDING
      INTO CORRESPONDING FIELDS OF TABLE @rt_registry.

    IF rt_registry IS INITIAL.
      rt_registry = VALUE #(
        ( section_code = 'OVERVIEW'    view_name = 'ZMIG_ANL_H'   sheet_title = 'Overview' )
        ( section_code = 'SRC_STRUCT'  view_name = 'ZMIG_ANL_SRC' sheet_title = 'Source Structure' )
        ( section_code = 'UI_FILTER'   view_name = 'ZMIG_ANL_UI'  sheet_title = 'UI Filters' )
        ( section_code = 'DB_OBJ'      view_name = 'ZMIG_ANL_DB'  sheet_title = 'Database Objects' )
        ( section_code = 'BUS_LOGIC'   view_name = 'ZMIG_ANL_LOG' sheet_title = 'Business Logic' )
        ( section_code = 'ALV_OUTPUT'  view_name = 'ZMIG_ANL_ALV' sheet_title = 'ALV Outputs' )
        ( section_code = 'SRC_EVIDEN'  view_name = 'ZMIG_ANL_EVD' sheet_title = 'Source Evidences' )
        ( section_code = 'RECOMMEN'    view_name = 'ZMIG_ANL_REC' sheet_title = 'Recommendations' )
        ( section_code = 'MESSAGE'     view_name = 'ZMIG_ANL_MSG' sheet_title = 'Messages' )
      ).
    ENDIF.
  ENDMETHOD.


  METHOD get_analysis_id.
    IF iv_analysis_id IS NOT INITIAL.
      rv_analysis_id = iv_analysis_id.
      RETURN.
    ENDIF.

    SELECT SINGLE analysis_id
      FROM zmig_anl_h
      WHERE program_name = @iv_report_type
      INTO @rv_analysis_id.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
  ENDMETHOD.


  METHOD escape_csv_value.
    DATA(lv_escaped) = replace( val = iv_value sub = '"' with = '""' occ = 0 ).
    rv_value = |"{ lv_escaped }"|.
  ENDMETHOD.


  METHOD export_excel.
    DATA(lt_registry) = get_section_registry( ).

    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root.
        lv_analysis_id = VALUE #( ).
    ENDTRY.

    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lv_sheet_count) = 0.

    DATA(lo_style_bold) = lo_excel->add_new_style( ).
    lo_style_bold->font->bold = abap_true.

    TRY.
        LOOP AT lt_registry INTO DATA(ls_section).

          IF iv_export_section <> 'ALL' AND ls_section-section_code <> iv_export_section.
            CONTINUE.
          ENDIF.

          TRY.
              DATA(lo_struct) = CAST cl_abap_structdescr(
                cl_abap_typedescr=>describe_by_name( ls_section-view_name ) ).
            CATCH cx_root.
              CONTINUE.
          ENDTRY.

          DATA(lo_table_type) = cl_abap_tabledescr=>create( lo_struct ).
          DATA lr_data TYPE REF TO data.
          CREATE DATA lr_data TYPE HANDLE lo_table_type.
          ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

          IF lv_analysis_id IS NOT INITIAL.
            SELECT * FROM (ls_section-view_name)
              WHERE analysis_id = @lv_analysis_id
              INTO TABLE @<lt_data>.

            IF ls_section-section_code = 'RECOMMEN' AND <lt_data> IS NOT INITIAL.
              SORT <lt_data> BY ('TARGET_LAYER') DESCENDING ('SEVERITY') ASCENDING.
            ENDIF.
          ENDIF.

          DATA(lo_sheet) = COND #(
            WHEN lv_sheet_count = 0
            THEN lo_excel->get_active_worksheet( )
            ELSE lo_excel->add_new_worksheet( ) ).

          lo_sheet->set_title( ip_title = CONV #( ls_section-sheet_title ) ).

          IF <lt_data> IS INITIAL.
            lo_sheet->set_cell( ip_column = 1 ip_row = 1 ip_value = |No data available for section { ls_section-sheet_title }.| ).
          ELSE.

            SELECT seq_no, fieldname, column_title
              FROM ztb_exp_col
              WHERE section_code = @ls_section-section_code
              ORDER BY seq_no ASCENDING
              INTO TABLE @DATA(lt_columns).

            IF lt_columns IS INITIAL.
              DATA(lt_components) = lo_struct->get_components( ).
              LOOP AT lt_components INTO DATA(ls_comp).
                APPEND VALUE #( fieldname    = ls_comp-name
                                column_title = ls_comp-name ) TO lt_columns.
              ENDLOOP.
            ENDIF.

            DATA(lv_col) = 1.

            LOOP AT lt_columns INTO DATA(ls_col).
              DATA(lv_header_text) = CONV string( ls_col-column_title ).

              lo_sheet->set_cell(
                ip_column = lv_col
                ip_row    = 1
                ip_value  = lv_header_text ).

              lo_sheet->set_cell_style(
                ip_column = lv_col
                ip_row    = 1
                ip_style  = lo_style_bold->get_guid( ) ).

              DATA(lv_init_len) = strlen( lv_header_text ) + 4.
              DATA(lo_col_obj)  = lo_sheet->get_column( ip_column = lv_col ).
              IF lo_col_obj IS BOUND.
                lo_col_obj->set_width( ip_width = lv_init_len ).
              ENDIF.

              lv_col = lv_col + 1.
            ENDLOOP.

            DATA(lv_row) = 2.
            LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
              lv_col = 1.
              LOOP AT lt_columns INTO ls_col.

                DATA(lv_field_tech) = to_upper( condense( CONV string( ls_col-fieldname ) ) ).
                ASSIGN COMPONENT lv_field_tech OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_val>).

                IF sy-subrc = 0 AND <lv_val> IS ASSIGNED.
                  DATA(lv_val_str) = CONV string( <lv_val> ).

                  lo_sheet->set_cell(
                    ip_column = lv_col
                    ip_row    = lv_row
                    ip_value  = <lv_val> ).

                  DATA(lv_val_len) = strlen( lv_val_str ) + 3.
                  DATA(lo_column)  = lo_sheet->get_column( ip_column = lv_col ).

                  IF lo_column IS BOUND AND lv_val_len > lo_column->get_width( ).
                    DATA(lv_new_width) = COND i( WHEN lv_val_len > 60 THEN 60 ELSE lv_val_len ).
                    lo_column->set_width( ip_width = lv_new_width ).
                  ENDIF.
                ENDIF.

                UNASSIGN <lv_val>.
                lv_col = lv_col + 1.
              ENDLOOP.
              lv_row = lv_row + 1.
            ENDLOOP.

            DATA(lv_total_row) = lv_row + 1.
            lo_sheet->set_cell( ip_column = 1 ip_row = lv_total_row ip_value = 'TOTAL ROWS' ).
            lo_sheet->set_cell( ip_column = 2 ip_row = lv_total_row ip_value = lines( <lt_data> ) ).

            lo_sheet->calculate_column_widths( ).

          ENDIF.

          lv_sheet_count = lv_sheet_count + 1.

        ENDLOOP.

      CATCH zcx_excel INTO DATA(lx_excel_build).
        rs_result-success = abap_false.
        rs_result-message = |Excel build error: { lx_excel_build->get_text( ) }.|.
        RETURN.
    ENDTRY.

    IF lv_sheet_count = 0.
      DATA(lo_empty_sheet) = lo_excel->get_active_worksheet( ).
      lo_empty_sheet->set_title( ip_title = 'Report' ).
      lo_empty_sheet->set_cell( ip_column = 1 ip_row = 1 ip_value = |No data available for program { iv_report_type }.| ).
    ENDIF.

    DATA(lo_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ).

    TRY.
        DATA(lv_content) = lo_writer->write_file( io_excel = lo_excel ).
      CATCH zcx_excel INTO DATA(lx_excel).
        rs_result-success = abap_false.
        rs_result-message = |Excel writer error: { lx_excel->get_text( ) }.|.
        RETURN.
    ENDTRY.

    rs_result-success     = abap_true.
    rs_result-content     = lv_content.
    rs_result-file_name   = gc_excel_name.
    rs_result-file_type   = 'BIN'.
    rs_result-file_format = gc_format_excel.
    rs_result-mime_type   = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
    rs_result-message     = 'Excel export generated successfully.'.

  ENDMETHOD.


  METHOD export_csv.
    " Sử dụng chung prepare_export_lines
    DATA(lt_lines) = prepare_export_lines( iv_selected_fields = 'FIELD,KIND,REF_TABLE,CONFIDENCE' ).

    IF lt_lines IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'No data available for export.'.
      RETURN.
    ENDIF.

    DATA(lv_content) = build_csv_document( lt_lines ).

    rs_result-success     = abap_true.
    rs_result-content     = lv_content.
    rs_result-file_name   = gc_csv_name.
    rs_result-file_type   = 'CSV'.
    rs_result-file_format = gc_format_csv.
    rs_result-mime_type   = 'text/csv'.
    rs_result-message     = 'CSV export generated successfully.'.

  ENDMETHOD.


  METHOD export_pdf.
    " 1. Gom dữ liệu theo cột được chọn
    DATA(lt_lines) = prepare_export_lines( iv_selected_fields = 'FIELD,KIND,REF_TABLE,CONFIDENCE' ).

    IF lt_lines IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'No data available for PDF generation.'.
      RETURN.
    ENDIF.

    " 2. Render PDF Document
    TRY.
        rs_result-content = build_pdf_document( lt_lines ).
        rs_result-success     = abap_true.
        rs_result-file_name   = gc_pdf_name.
        rs_result-file_type   = 'PDF'.
        rs_result-file_format = gc_format_pdf.
        rs_result-mime_type   = 'application/pdf'.
        rs_result-message     = 'PDF generated successfully.'.
      CATCH cx_root INTO DATA(lx_pdf).
        rs_result-success = abap_false.
        rs_result-message = |PDF_BUILD_ERROR: { lx_pdf->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD escape_pdf_text.
    DATA(lv_escaped) = iv_text.

    lv_escaped = replace( val = lv_escaped sub = '\' with = '\\' occ = 0 ).
    lv_escaped = replace( val = lv_escaped sub = '(' with = '\(' occ = 0 ).
    lv_escaped = replace( val = lv_escaped sub = ')' with = '\)' occ = 0 ).

    lv_escaped = replace(
      regex = '[^\x20-\x7E]'
      val   = lv_escaped
      with  = ' '
      occ   = 0 ).

    rv_text = lv_escaped.
  ENDMETHOD.


  METHOD build_pdf_document.
    CONSTANTS: lc_lines_per_page TYPE i VALUE 18,
               lc_page_width     TYPE i VALUE 792, " Landscape
               lc_page_height    TYPE i VALUE 612.

    DATA lt_pages TYPE string_table.
    DATA(lv_total_lines) = lines( it_lines ).
    DATA(lv_total_pages) = COND i(
      WHEN lv_total_lines = 0 THEN 1
      ELSE ( ( lv_total_lines - 1 ) DIV lc_lines_per_page ) + 1 ).

    DATA lv_idx TYPE i VALUE 0.
    DATA lv_page_num TYPE i VALUE 1.

    DATA lt_cols TYPE string_table.
    DATA lt_col_widths TYPE STANDARD TABLE OF i.
    DATA lv_num_cols TYPE i VALUE 0.

    DATA(lv_left_margin) = 20.
    DATA(lv_table_width) = 752.

    DO lv_total_pages TIMES.
      DATA(lv_from) = lv_idx + 1.
      DATA(lv_to)   = nmin( val1 = lv_total_lines val2 = lv_idx + lc_lines_per_page ).

      DATA lv_page_content TYPE string.
      CLEAR lv_page_content.

      " Header trang
      lv_page_content = |BT\n/F1 11 Tf\n1 0 0 1 20 { lc_page_height - 25 } Tm\n|.
      lv_page_content = lv_page_content && |({ escape_pdf_text( |ABAP Migration Analysis Report| ) }) Tj\nET\n|.

      DATA(lv_y) = lc_page_height - 50.
      DATA(lv_row_height) = 22.

      IF lv_from <= lv_to.
        DATA(lv_line_counter) = lv_from.

        WHILE lv_line_counter <= lv_to.
          DATA(lv_curr_str) = it_lines[ lv_line_counter ].
          CONDENSE lv_curr_str.

          " Detect Section Header
          IF lv_curr_str CS '===' OR lv_curr_str CS 'Source Structure' OR lv_curr_str CS 'UI Filters' OR lv_curr_str CS 'Database Objects'.

            lv_page_content = lv_page_content && |0.2 0.3 0.4 rg\n|.
            lv_page_content = lv_page_content && |{ lv_left_margin } { lv_y - 4 } { lv_table_width } { lv_row_height } re f\n|.

            DATA(lv_section_name) = lv_curr_str.
            REPLACE ALL OCCURRENCES OF '=' IN lv_section_name WITH ''.
            CONDENSE lv_section_name.

            lv_page_content = lv_page_content && |BT\n/F1 9 Tf\n1 1 1 rg\n|.
            lv_page_content = lv_page_content && |1 0 0 1 { lv_left_margin + 8 } { lv_y + 4 } Tm\n|.
            lv_page_content = lv_page_content && |({ escape_pdf_text( lv_section_name ) }) Tj\nET\n0 g\n|.

            lv_y = lv_y - lv_row_height.
            lv_line_counter = lv_line_counter + 1.
            CONTINUE.
          ENDIF.

          " Split Data Column
          CLEAR lt_cols.
          SPLIT lv_curr_str AT '|' INTO TABLE lt_cols.
          lv_num_cols = lines( lt_cols ).
          IF lv_num_cols = 0. lv_num_cols = 1. ENDIF.

          DATA(lv_is_field_header) = COND abap_bool(
            WHEN lv_curr_str CS 'Field' OR lv_curr_str CS 'Object' OR lv_curr_str CS 'Source Object' OR lv_curr_str CS 'Type'
            THEN abap_true
            ELSE abap_false ).

          IF lv_is_field_header = abap_true OR lt_col_widths IS INITIAL.
            CLEAR lt_col_widths.
            DATA(lv_c_idx) = 1.
            WHILE lv_c_idx <= lv_num_cols.
              DATA(lv_fname) = COND string( WHEN lv_c_idx <= lines( lt_cols ) THEN lt_cols[ lv_c_idx ] ELSE '' ).
              CONDENSE lv_fname.

              IF lv_fname CS 'Object' OR lv_fname CS 'Table' OR lv_fname CS 'Routine'.
                APPEND 120 TO lt_col_widths.
              ELSEIF lv_fname CS 'Field' OR lv_fname CS 'Element' OR lv_fname CS 'Kind'.
                APPEND 90 TO lt_col_widths.
              ELSE.
                APPEND ( lv_table_width / lv_num_cols ) TO lt_col_widths.
              ENDIF.

              lv_c_idx = lv_c_idx + 1.
            ENDWHILE.
          ENDIF.

          IF lv_is_field_header = abap_true.
            lv_page_content = lv_page_content && |0.90 0.92 0.95 rg\n|.
            lv_page_content = lv_page_content && |{ lv_left_margin } { lv_y - 4 } { lv_table_width } { lv_row_height } re f\n|.
            lv_page_content = lv_page_content && |0 g\n|.
          ENDIF.

          lv_page_content = lv_page_content && |0.80 0.80 0.80 RG\n0.5 w\n|.
          lv_page_content = lv_page_content && |{ lv_left_margin } { lv_y - 4 } m { lv_left_margin + lv_table_width } { lv_y - 4 } l S\n|.

          DATA(lv_x) = lv_left_margin.
          DATA(lv_col_idx) = 1.

          WHILE lv_col_idx <= lv_num_cols.
            DATA(lv_cell_txt) = COND string( WHEN lv_col_idx <= lines( lt_cols ) THEN lt_cols[ lv_col_idx ] ELSE '' ).
            CONDENSE lv_cell_txt.

            DATA(lv_w) = COND i( WHEN lv_col_idx <= lines( lt_col_widths ) THEN lt_col_widths[ lv_col_idx ] ELSE ( lv_table_width / lv_num_cols ) ).

            DATA(lv_max_char) = CONV i( lv_w / 5 ) - 1.
            IF lv_max_char > 0 AND strlen( lv_cell_txt ) > lv_max_char.
              lv_cell_txt = lv_cell_txt(lv_max_char) && '..'.
            ENDIF.

            DATA(lv_font_sz) = COND string( WHEN lv_is_field_header = abap_true THEN '7.5' ELSE '6.5' ).
            lv_page_content = lv_page_content && |BT\n/F1 { lv_font_sz } Tf\n|.
            lv_page_content = lv_page_content && |1 0 0 1 { lv_x + 4 } { lv_y + 3 } Tm\n|.
            lv_page_content = lv_page_content && |({ escape_pdf_text( lv_cell_txt ) }) Tj\nET\n|.

            lv_page_content = lv_page_content && |{ lv_x + lv_w } { lv_y - 4 } m { lv_x + lv_w } { lv_y + lv_row_height - 4 } l S\n|.

            lv_x = lv_x + lv_w.
            lv_col_idx = lv_col_idx + 1.
          ENDWHILE.

          lv_y = lv_y - lv_row_height.
          lv_line_counter = lv_line_counter + 1.
        ENDWHILE.
      ENDIF.

      " Footer trang
      lv_page_content = lv_page_content && |BT\n/F1 8 Tf\n1 0 0 1 { lc_page_width - 80 } 15 Tm\n|.
      lv_page_content = lv_page_content && |({ escape_pdf_text( |Page { lv_page_num } / { lv_total_pages }| ) }) Tj\nET\n|.

      APPEND lv_page_content TO lt_pages.

      lv_idx = lv_idx + lc_lines_per_page.
      lv_page_num = lv_page_num + 1.
    ENDDO.

    " === RENDER BINARY STREAM ===
    DATA lv_pdf TYPE string.
    DATA lt_offsets TYPE STANDARD TABLE OF i.

    lv_pdf = |%PDF-1.4\n|.
    DATA(lv_pdf_xstring) = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).

    APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
    lv_pdf = lv_pdf && |1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n|.

    DATA lv_kids TYPE string.
    DATA(lv_num_pages) = lines( lt_pages ).
    DO lv_num_pages TIMES.
      DATA(lv_page_obj_num) = 4 + ( sy-index - 1 ) * 2.
      lv_kids = lv_kids && |{ lv_page_obj_num } 0 R |.
    ENDDO.

    lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
    APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
    lv_pdf = lv_pdf && |2 0 obj\n<< /Type /Pages /Kids [ { lv_kids }] /Count { lv_num_pages } >>\nendobj\n|.

    lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
    APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
    lv_pdf = lv_pdf && |3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n|.

    LOOP AT lt_pages INTO DATA(lv_page_text).
      DATA(lv_this_page_obj) = 4 + ( sy-tabix - 1 ) * 2.
      DATA(lv_this_cont_obj) = lv_this_page_obj + 1.

      lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
      APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
      lv_pdf = lv_pdf && |{ lv_this_page_obj } 0 obj\n|
        && |<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 3 0 R >> >> |
        && |/MediaBox [0 0 { lc_page_width } { lc_page_height }] /Contents { lv_this_cont_obj } 0 R >>\nendobj\n|.

      " ĐO BẰNG XSTRLEN THAY VÌ STRLEN LÀM LỖI BYTE UTF-8
      DATA(lv_page_xstr) = cl_abap_codepage=>convert_to( source = lv_page_text codepage = 'UTF-8' ).
      DATA(lv_stream_len) = xstrlen( lv_page_xstr ).

      lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
      APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.

      lv_pdf = lv_pdf && |{ lv_this_cont_obj } 0 obj\n<< /Length { lv_stream_len } >>\nstream\n|
        && lv_page_text && |endstream\nendobj\n|.
    ENDLOOP.

    lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
    DATA(lv_xref_offset) = xstrlen( lv_pdf_xstring ).
    DATA(lv_total_objects) = lines( lt_offsets ) + 1.

    lv_pdf = lv_pdf && |xref\n0 { lv_total_objects }\n0000000000 65535 f \n|.

    LOOP AT lt_offsets INTO DATA(lv_offset).
      DATA(lv_offset_str) = |{ lv_offset }|.
      WHILE strlen( lv_offset_str ) < 10.
        lv_offset_str = |0{ lv_offset_str }|.
      ENDWHILE.
      lv_pdf = lv_pdf && |{ lv_offset_str } 00000 n \n|.
    ENDLOOP.

    lv_pdf = lv_pdf && |trailer\n<< /Size { lv_total_objects } /Root 1 0 R >>\nstartxref\n{ lv_xref_offset }\n%%EOF|.

    rv_content = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
  ENDMETHOD.

ENDCLASS.


