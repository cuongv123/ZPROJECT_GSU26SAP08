CLASS zcl_mig_export_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_export_provider.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_report_data,
             header TYPE zmig_anl_h,
             ui     TYPE STANDARD TABLE OF zmig_anl_ui  WITH DEFAULT KEY,
             db     TYPE STANDARD TABLE OF zmig_anl_db  WITH DEFAULT KEY,
             logic  TYPE STANDARD TABLE OF zmig_anl_log WITH DEFAULT KEY,
           END OF ty_report_data.

    METHODS fetch_all_report_data
      IMPORTING iv_program_name TYPE zmig_anl_h-program_name
      RETURNING VALUE(rs_data)  TYPE ty_report_data.

    METHODS build_csv
      IMPORTING is_data TYPE ty_report_data
      RETURNING VALUE(rv_content) TYPE xstring.

    METHODS build_excel
  IMPORTING is_data TYPE ty_report_data
  RETURNING VALUE(rv_content) TYPE xstring
  RAISING zcx_excel.

    METHODS build_pdf
      IMPORTING is_data TYPE ty_report_data
      RETURNING VALUE(rv_content) TYPE xstring.

    METHODS build_pdf_from_lines
      IMPORTING it_lines TYPE string_table
      RETURNING VALUE(rv_content) TYPE xstring.

    METHODS pdf_escape
      IMPORTING iv_text TYPE string
      RETURNING VALUE(rv_text) TYPE string.

ENDCLASS.


CLASS zcl_mig_export_engine IMPLEMENTATION.

  METHOD zif_mig_export_provider~generate.

    TRY.
        DATA(ls_data) = fetch_all_report_data( CONV #( iv_report_type ) ).

        IF ls_data-header IS INITIAL.
          rs_result-success = abap_false.
          rs_result-message = |Khong tim thay du lieu phan tich cho { iv_report_type }|.
          RETURN.
        ENDIF.

        CASE iv_file_format.

          WHEN 'C'.
            rs_result-content     = build_csv( ls_data ).
            rs_result-file_name   = 'migration_report.csv'.
            rs_result-file_type   = 'CSV'.
            rs_result-file_format = 'C'.
            rs_result-mime_type   = 'text/csv'.

          WHEN 'X'.
            rs_result-content     = build_excel( ls_data ).
            rs_result-file_name   = 'migration_report.xlsx'.
            rs_result-file_type   = 'BIN'.
            rs_result-file_format = 'X'.
            rs_result-mime_type   =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.

          WHEN 'P'.
            rs_result-content     = build_pdf( ls_data ).
            rs_result-file_name   = 'migration_report.pdf'.
            rs_result-file_type   = 'PDF'.
            rs_result-file_format = 'P'.
            rs_result-mime_type   = 'application/pdf'.

          WHEN OTHERS.
            rs_result-success = abap_false.
            rs_result-message = |Unsupported file format { iv_file_format }.|.
            RETURN.
        ENDCASE.

        IF rs_result-content IS INITIAL.
          rs_result-success = abap_false.
          rs_result-message = |Generated { iv_file_format } content is empty.|.
          RETURN.
        ENDIF.

        rs_result-success = abap_true.
        rs_result-message = |Export format { iv_file_format } generated successfully.|.

      CATCH cx_root INTO DATA(lx_error).
        CLEAR: rs_result-content, rs_result-file_name,
               rs_result-file_type, rs_result-file_format, rs_result-mime_type.
        rs_result-success = abap_false.
        rs_result-message = lx_error->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD fetch_all_report_data.
    SELECT SINGLE * FROM zmig_anl_h
      WHERE program_name = @iv_program_name
      INTO @rs_data-header.

    IF rs_data-header IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_analysis_id) = rs_data-header-analysis_id.

    SELECT * FROM zmig_anl_ui  WHERE analysis_id = @lv_analysis_id INTO TABLE @rs_data-ui.
    SELECT * FROM zmig_anl_db  WHERE analysis_id = @lv_analysis_id INTO TABLE @rs_data-db.
    SELECT * FROM zmig_anl_log WHERE analysis_id = @lv_analysis_id INTO TABLE @rs_data-logic.
  ENDMETHOD.


  METHOD build_csv.
    DATA: lv_csv TYPE string.

    lv_csv = |[OVERVIEW]\r\n|.
    lv_csv = lv_csv && |Program Name;{ is_data-header-program_name }\r\n|.
    lv_csv = lv_csv && |Description;{ is_data-header-program_description }\r\n|.
    lv_csv = lv_csv && |Status;{ is_data-header-status }\r\n|.
    lv_csv = lv_csv && |Total Source Objects;{ is_data-header-total_source_objects }\r\n|.
    lv_csv = lv_csv && |Total UI Filters;{ is_data-header-total_ui_filters }\r\n|.
    lv_csv = lv_csv && |Total Database Objects;{ is_data-header-total_database_objects }\r\n|.
    lv_csv = lv_csv && |Total Business Logic;{ is_data-header-total_business_logic }\r\n|.
    lv_csv = lv_csv && |Complexity Score;{ is_data-header-complexity_score }\r\n|.
    lv_csv = lv_csv && |Readiness Score;{ is_data-header-readiness_score }\r\n|.
    lv_csv = lv_csv && |\r\n|.

    lv_csv = lv_csv && |[UI FILTERS]\r\n|.
    lv_csv = lv_csv && |Field Name;Field Kind;Description;Mandatory\r\n|.
    LOOP AT is_data-ui INTO DATA(ls_ui).
      lv_csv = lv_csv &&
        |{ ls_ui-field_name };{ ls_ui-field_kind };{ ls_ui-description };{ ls_ui-mandatory }\r\n|.
    ENDLOOP.
    lv_csv = lv_csv && |\r\n|.

    lv_csv = lv_csv && |[DATABASE OBJECTS]\r\n|.
    lv_csv = lv_csv && |Object Name;Object Type;Operation;Description\r\n|.
    LOOP AT is_data-db INTO DATA(ls_db).
      lv_csv = lv_csv &&
        |{ ls_db-object_name };{ ls_db-object_type };{ ls_db-operation };{ ls_db-description }\r\n|.
    ENDLOOP.
    lv_csv = lv_csv && |\r\n|.

    lv_csv = lv_csv && |[BUSINESS LOGIC]\r\n|.
    lv_csv = lv_csv && |Object Name;Object Type;Description;Reuse Feasibility\r\n|.
    LOOP AT is_data-logic INTO DATA(ls_logic).
      lv_csv = lv_csv &&
        |{ ls_logic-object_name };{ ls_logic-object_type };{ ls_logic-description };{ ls_logic-reuse_feasibility }\r\n|.
    ENDLOOP.

    DATA(lv_full) = cl_abap_char_utilities=>byte_order_mark_utf8 && lv_csv.
    rv_content = cl_abap_codepage=>convert_to( lv_full ).
  ENDMETHOD.


  METHOD build_excel.
    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lo_style_hdr) = lo_excel->add_new_style( ).
    lo_style_hdr->font->bold = abap_true.
    lo_style_hdr->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
    lo_style_hdr->fill->fgcolor-rgb = 'D9E1F2'.

    DATA(lo_sheet) = lo_excel->get_active_worksheet( ).
    lo_sheet->set_title( 'Overview' ).

    lo_sheet->set_cell( ip_column = 'B' ip_row = 2 ip_value = 'MIGRATION ANALYSIS OVERVIEW' ).
    lo_sheet->set_cell_style( ip_column = 'B' ip_row = 2 ip_style = lo_style_hdr->get_guid( ) ).

    DATA(lv_row) = 4.
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row     ip_value = 'Program Name:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row     ip_value = is_data-header-program_name ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 1 ip_value = 'Description:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 1 ip_value = is_data-header-program_description ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 2 ip_value = 'Status:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 2 ip_value = is_data-header-status ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 3 ip_value = 'Total Source Objects:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 3 ip_value = is_data-header-total_source_objects ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 4 ip_value = 'Total UI Filters:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 4 ip_value = is_data-header-total_ui_filters ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 5 ip_value = 'Total Database Objects:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 5 ip_value = is_data-header-total_database_objects ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 6 ip_value = 'Total Business Logic:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 6 ip_value = is_data-header-total_business_logic ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 7 ip_value = 'Complexity Score:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 7 ip_value = is_data-header-complexity_score ).
    lo_sheet->set_cell( ip_column = 'B' ip_row = lv_row + 8 ip_value = 'Readiness Score:' ).
    lo_sheet->set_cell( ip_column = 'C' ip_row = lv_row + 8 ip_value = is_data-header-readiness_score ).

    lo_sheet->set_column_width( ip_column = 'B' ip_width_fix = 26 ).
    lo_sheet->set_column_width( ip_column = 'C' ip_width_fix = 35 ).

    IF is_data-ui IS NOT INITIAL.
      lo_sheet = lo_excel->add_new_worksheet( ).
      lo_sheet->set_title( 'UI Filters' ).
      lo_sheet->bind_table( ip_table = is_data-ui ).
    ENDIF.

    IF is_data-db IS NOT INITIAL.
      lo_sheet = lo_excel->add_new_worksheet( ).
      lo_sheet->set_title( 'Database Objects' ).
      lo_sheet->bind_table( ip_table = is_data-db ).
    ENDIF.

    IF is_data-logic IS NOT INITIAL.
      lo_sheet = lo_excel->add_new_worksheet( ).
      lo_sheet->set_title( 'Business Logic' ).
      lo_sheet->bind_table( ip_table = is_data-logic ).
    ENDIF.

    DATA: lo_writer TYPE REF TO zif_excel_writer.
CREATE OBJECT lo_writer TYPE zcl_excel_writer_2007.
rv_content = lo_writer->write_file( lo_excel ).
  ENDMETHOD.


  METHOD build_pdf.
    DATA: lt_lines TYPE string_table.

    APPEND 'MIGRATION ANALYSIS REPORT' TO lt_lines.
    APPEND |Program: { is_data-header-program_name }| TO lt_lines.
    APPEND |Description: { is_data-header-program_description }| TO lt_lines.
    APPEND |Status: { is_data-header-status }| TO lt_lines.
    APPEND |Total Source Objects: { is_data-header-total_source_objects }| TO lt_lines.
    APPEND |Total UI Filters: { is_data-header-total_ui_filters }| TO lt_lines.
    APPEND |Total Database Objects: { is_data-header-total_database_objects }| TO lt_lines.
    APPEND |Total Business Logic: { is_data-header-total_business_logic }| TO lt_lines.
    APPEND |Complexity Score: { is_data-header-complexity_score }| TO lt_lines.
    APPEND |Readiness Score: { is_data-header-readiness_score }| TO lt_lines.
    APPEND '' TO lt_lines.

    APPEND 'SECTION: UI FILTERS' TO lt_lines.
    LOOP AT is_data-ui INTO DATA(ls_ui).
      APPEND |{ ls_ui-field_name } | && |- { ls_ui-description }| TO lt_lines.
    ENDLOOP.
    APPEND '' TO lt_lines.

    APPEND 'SECTION: DATABASE OBJECTS' TO lt_lines.
    LOOP AT is_data-db INTO DATA(ls_db).
      APPEND |{ ls_db-object_name } | && |- { ls_db-operation }| TO lt_lines.
    ENDLOOP.
    APPEND '' TO lt_lines.

    APPEND 'SECTION: BUSINESS LOGIC' TO lt_lines.
    LOOP AT is_data-logic INTO DATA(ls_logic).
      APPEND |{ ls_logic-object_name } | && |- { ls_logic-description }| TO lt_lines.
    ENDLOOP.

    rv_content = build_pdf_from_lines( lt_lines ).
  ENDMETHOD.


  METHOD pdf_escape.
    rv_text = replace( val = iv_text sub = '\' with = '\\' occ = 0 ).
    rv_text = replace( val = rv_text sub = '(' with = '\(' occ = 0 ).
    rv_text = replace( val = rv_text sub = ')' with = '\)' occ = 0 ).
  ENDMETHOD.


  METHOD build_pdf_from_lines.
    CONSTANTS: c_lines_per_page TYPE i VALUE 55.

    DATA: lv_pdf        TYPE string,
          lv_page_count TYPE i,
          lt_page_objs  TYPE TABLE OF string.

    lv_page_count = ceil( lines( it_lines ) / c_lines_per_page ).
    IF lv_page_count = 0.
      lv_page_count = 1.
    ENDIF.

    DATA(lv_line_idx) = 1.
    DO lv_page_count TIMES.
      DATA(lv_content_stream) = |BT /F1 10 Tf 40 800 Td 14 TL\r\n|.

      DATA(lv_lines_in_page) = 0.
      WHILE lv_lines_in_page < c_lines_per_page AND lv_line_idx <= lines( it_lines ).
        DATA(lv_text) = pdf_escape( it_lines[ lv_line_idx ] ).
        lv_content_stream = lv_content_stream && |({ lv_text }) Tj T*\r\n|.
        lv_line_idx = lv_line_idx + 1.
        lv_lines_in_page = lv_lines_in_page + 1.
      ENDWHILE.

      lv_content_stream = lv_content_stream && |ET|.
      APPEND lv_content_stream TO lt_page_objs.
    ENDDO.

    DATA(lv_obj1) = |1 0 obj\r\n<< /Type /Catalog /Pages 2 0 R >>\r\nendobj\r\n|.

    DATA(lv_kids) = ``.
    DATA(lv_obj_num) = 4.
    DO lv_page_count TIMES.
      lv_kids = lv_kids && |{ lv_obj_num } 0 R |.
      lv_obj_num = lv_obj_num + 2.
    ENDDO.

    DATA(lv_obj2) = |2 0 obj\r\n<< /Type /Pages /Kids [ { lv_kids }] /Count { lv_page_count } >>\r\nendobj\r\n|.
    DATA(lv_obj3) = |3 0 obj\r\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\r\nendobj\r\n|.

    lv_pdf = |%PDF-1.4\r\n| && lv_obj1 && lv_obj2 && lv_obj3.

    lv_obj_num = 4.
    LOOP AT lt_page_objs INTO DATA(lv_stream).
      DATA(lv_page_obj) =
        |{ lv_obj_num } 0 obj\r\n| &&
        |<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 3 0 R >> >> | &&
        |/MediaBox [0 0 595 842] /Contents { lv_obj_num + 1 } 0 R >>\r\nendobj\r\n|.

      DATA(lv_content_obj) =
        |{ lv_obj_num + 1 } 0 obj\r\n| &&
        |<< /Length { strlen( lv_stream ) } >>\r\nstream\r\n| &&
        lv_stream && |\r\nendstream\r\nendobj\r\n|.

      lv_pdf = lv_pdf && lv_page_obj && lv_content_obj.
      lv_obj_num = lv_obj_num + 2.
    ENDLOOP.

    lv_pdf = lv_pdf && |trailer\r\n<< /Root 1 0 R /Size { lv_obj_num } >>\r\n%%EOF|.

    rv_content = cl_abap_codepage=>convert_to( lv_pdf ).
  ENDMETHOD.

ENDCLASS.
