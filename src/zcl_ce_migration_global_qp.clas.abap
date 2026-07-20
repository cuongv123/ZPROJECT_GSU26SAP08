CLASS zcl_ce_migration_global_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS:
      gc_param_program      TYPE string VALUE 'PROGRAMNAME',
      gc_param_program_alt  TYPE string VALUE 'PROGRAM_NAME',
      gc_fallback_program   TYPE program VALUE 'ZTEST_ABAP_PARSER_V2',
      gc_excel_mime         TYPE string VALUE 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      gc_excel_filename_pre TYPE string VALUE 'Comprehensive_Global_Report_',
      gc_excel_extension    TYPE string VALUE '.xlsx'.

    TYPES tt_filter_data  TYPE STANDARD TABLE OF ztmig_filter  WITH DEFAULT KEY.
    TYPES tt_dbtable_data TYPE STANDARD TABLE OF ztmig_dbtable WITH DEFAULT KEY.
    TYPES tt_logic_data   TYPE STANDARD TABLE OF ztmig_logic   WITH DEFAULT KEY.
    TYPES tt_roadmap_data TYPE STANDARD TABLE OF ztmig_obj_map WITH DEFAULT KEY.

ENDCLASS.



CLASS zcl_ce_migration_global_qp IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA: lt_ui_filters TYPE tt_filter_data,
          lt_db_tables  TYPE tt_dbtable_data,
          lt_bus_logic  TYPE tt_logic_data,
          lt_roadmap    TYPE tt_roadmap_data.

    DATA: lv_program_name TYPE program,
          lv_report_id    TYPE ztmig_overview-report_id.

    DATA: BEGIN OF ls_overview,
            report_id        TYPE ztmig_overview-report_id,
            program_name     TYPE ztmig_overview-program_name,
            description      TYPE ztmig_overview-description,
            analyzed_by      TYPE ztmig_overview-analyzed_by,
            analyzed_at      TYPE ztmig_overview-analyzed_at,
            total_tables     TYPE ztmig_overview-total_tables,
            total_filters    TYPE ztmig_overview-total_filters,
            total_objects    TYPE ztmig_overview-total_objects,
            complexity_score TYPE ztmig_overview-complexity_score,
            migration_score  TYPE ztmig_overview-migration_score,
            cloud_readiness  TYPE ztmig_overview-cloud_readiness,
            status           TYPE ztmig_overview-status,
          END OF ls_overview.

    " 1. LẤY THAM SỐ ĐẦU VÀO TỪ REQUEST (TƯƠNG THÍCH CẢ PARAMETER LẪN FILTER)
    TRY.
        DATA(lt_parameters) = io_request->get_parameters( ).
        LOOP AT lt_parameters INTO DATA(ls_para).
          DATA(lv_param_upper) = to_upper( ls_para-parameter_name ).
          IF lv_param_upper = gc_param_program OR lv_param_upper = gc_param_program_alt.
            lv_program_name = ls_para-value.
            EXIT.
          ENDIF.
        ENDLOOP.

        IF lv_program_name IS INITIAL.
          DATA(lo_filter) = io_request->get_filter( ).
          IF lo_filter IS BOUND.
            DATA(lt_ranges) = lo_filter->get_as_ranges( ).
            LOOP AT lt_ranges INTO DATA(ls_filter_line).
              DATA(lv_filter_name) = to_upper( ls_filter_line-name ).
              IF lv_filter_name = gc_param_program OR lv_filter_name = gc_param_program_alt.
                IF lines( ls_filter_line-range ) >= 1.
                  lv_program_name = ls_filter_line-range[ 1 ]-low.
                  EXIT.
                ENDIF.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.
      CATCH cx_root.
        CLEAR lv_program_name.
    ENDTRY.

    " Fallback nếu không tìm thấy chương trình nào
    IF lv_program_name IS INITIAL.
      SELECT SINGLE program_name FROM ztmig_overview INTO @lv_program_name.
    ENDIF.

    IF lv_program_name IS INITIAL.
      lv_program_name = gc_fallback_program.
    ENDIF.

    lv_program_name = to_upper( lv_program_name ).

    " 2. TRUY VẤN CƠ SỞ DỮ LIỆU CHỈ KHI UI THỰC SỰ YÊU CẦU DỮ LIỆU
    DATA: lv_data_error TYPE abap_bool VALUE abap_false,
          lv_error_text TYPE string.

    IF io_request->is_data_requested( ).
      SELECT SINGLE report_id, program_name, description, analyzed_by, analyzed_at,
                    total_tables, total_filters, total_objects,
                    complexity_score, migration_score, cloud_readiness, status
        FROM ztmig_overview
       WHERE program_name = @lv_program_name
        INTO CORRESPONDING FIELDS OF @ls_overview.

      IF sy-subrc = 0 AND ls_overview-report_id IS NOT INITIAL.
        lv_report_id = ls_overview-report_id.

        SELECT * FROM ztmig_filter  WHERE report_id = @lv_report_id INTO TABLE @lt_ui_filters.
        SELECT * FROM ztmig_dbtable WHERE report_id = @lv_report_id INTO TABLE @lt_db_tables.
        SELECT * FROM ztmig_logic   WHERE report_id = @lv_report_id INTO TABLE @lt_bus_logic.
        SELECT * FROM ztmig_obj_map WHERE report_id = @lv_report_id INTO TABLE @lt_roadmap.
      ELSE.
        " GUARD: chương trình không tồn tại / chưa được phân tích
        lv_data_error = abap_true.
        lv_error_text = |Program { lv_program_name } chua duoc phan tich hoac khong ton tai|.
      ENDIF.
    ENDIF.

    " 3. DỰNG FILE EXCEL TĨNH SỬ DỤNG BIND_TABLE CHUẨN
    DATA: lo_excel        TYPE REF TO zcl_excel,
          lo_worksheet    TYPE REF TO zcl_excel_worksheet,
          lv_excel_stream TYPE xstring.

    " Chỉ dựng Excel khi thực sự cần data VÀ report_id hợp lệ (tránh file rỗng)
    IF io_request->is_data_requested( ) AND lv_report_id IS NOT INITIAL AND lv_data_error = abap_false.
      TRY.
          CREATE OBJECT lo_excel.

          " ===== Convert timestamp analyzed_at sang chuỗi dễ đọc =====
          DATA: lv_analyzed_at_str TYPE string,
                lv_date            TYPE d,
                lv_time            TYPE t.

          IF ls_overview-analyzed_at IS NOT INITIAL.
            DATA(lv_user_tzone) = cl_abap_context_info=>get_user_time_zone( ).

            CONVERT TIME STAMP ls_overview-analyzed_at TIME ZONE lv_user_tzone
              INTO DATE lv_date TIME lv_time.
            lv_analyzed_at_str = |{ lv_date DATE = USER } { lv_time TIME = USER }|.
          ENDIF.

          " ===== Sheet 1: Overview =====
          lo_worksheet = lo_excel->get_active_worksheet( ).
          lo_worksheet->set_title( 'Overview' ).

          DATA(lo_style_title) = lo_excel->add_new_style( ).
          lo_style_title->font->bold = abap_true.
          lo_style_title->font->size = 14.

          DATA(lo_style_label) = lo_excel->add_new_style( ).
          lo_style_label->font->bold = abap_true.

          lo_worksheet->set_cell( ip_column = 'B' ip_row = 2 ip_value = 'MIGRATION COMPREHENSIVE EXECUTIVE SUMMARY' ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = 2 ip_style = lo_style_title->get_guid( ) ).

          DATA(lv_row_ov) = 4.

          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Program Name:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-program_name ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Description:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-description ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Analyzed By:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-analyzed_by ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Analyzed At:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = lv_analyzed_at_str ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Total Tables:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-total_tables ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Total Filters:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-total_filters ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Total Business Objects:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-total_objects ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Complexity Score:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-complexity_score ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Migration Score:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-migration_score ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Cloud Readiness:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-cloud_readiness ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lv_row_ov += 1.
          lo_worksheet->set_cell( ip_column = 'B' ip_row = lv_row_ov ip_value = 'Analysis Status:' ).
          lo_worksheet->set_cell( ip_column = 'C' ip_row = lv_row_ov ip_value = ls_overview-status ).
          lo_worksheet->set_cell_style( ip_column = 'B' ip_row = lv_row_ov ip_style = lo_style_label->get_guid( ) ).

          lo_worksheet->set_column_width( ip_column = 'B' ip_width_fix = 26 ).
          lo_worksheet->set_column_width( ip_column = 'C' ip_width_fix = 30 ).
          " ===== Sheet 2: UI Filters =====
          IF lt_ui_filters IS NOT INITIAL.
            lo_worksheet = lo_excel->add_new_worksheet( ).
            lo_worksheet->set_title( 'UI Filters' ).
            lo_worksheet->bind_table( ip_table = lt_ui_filters ).
          ENDIF.

          " ===== Sheet 3: Database Tables =====
          IF lt_db_tables IS NOT INITIAL.
            lo_worksheet = lo_excel->add_new_worksheet( ).
            lo_worksheet->set_title( 'Database Tables' ).
            lo_worksheet->bind_table( ip_table = lt_db_tables ).
          ENDIF.

          " ===== Sheet 4: Business Logic =====
          IF lt_bus_logic IS NOT INITIAL.
            lo_worksheet = lo_excel->add_new_worksheet( ).
            lo_worksheet->set_title( 'Business Logic' ).
            lo_worksheet->bind_table( ip_table = lt_bus_logic ).
          ENDIF.

          " ===== Sheet 5: Roadmap Data =====
          lo_worksheet = lo_excel->add_new_worksheet( ).
          lo_worksheet->set_title( 'Roadmap Data' ).

          IF lt_roadmap IS NOT INITIAL.
            lo_worksheet->bind_table( ip_table = lt_roadmap ).
          ELSE.
            lo_worksheet->set_cell( ip_column = 'A' ip_row = 1 ip_value = 'No items available.' ).
          ENDIF.

          " ===== Xuất Excel Stream =====
          DATA: lo_writer TYPE REF TO zif_excel_writer.
          CREATE OBJECT lo_writer TYPE zcl_excel_writer_2007.
          lv_excel_stream = lo_writer->write_file( lo_excel ).

        CATCH cx_root.
          CLEAR lv_excel_stream.
          lv_data_error = abap_true.
          lv_error_text = |Loi khi tao file Excel cho { lv_program_name }|.
      ENDTRY.
    ENDIF.

    " Chuẩn bị filename/mimetype: nếu có lỗi thì trả file báo lỗi thay vì Excel thật
    DATA(lv_final_filename) = COND string(
      WHEN lv_data_error = abap_true
      THEN |ERROR__{ lv_error_text }.txt|
      ELSE |{ gc_excel_filename_pre }{ lv_program_name }{ gc_excel_extension }| ).

    DATA(lv_final_mimetype) = COND string(
      WHEN lv_data_error = abap_true
      THEN 'text/plain'
      ELSE gc_excel_mime ).

    " 4. CHUẨN BỊ KẾT QUẢ TRẢ VỀ
    DATA lt_export_result TYPE TABLE OF zce_migration_global_excel.
    APPEND VALUE #(
      programname = lv_program_name
      content     = lv_excel_stream
      mimetype    = lv_final_mimetype
      filename    = lv_final_filename
    ) TO lt_export_result.

    " 5. ĐÁP ỨNG CÁC YÊU CẦU PHÂN TRANG VÀ ĐẾM DÒNG TỪ RAP ENGINE

    " A. Gửi tổng số bản ghi nếu có yêu cầu đếm ($count)
    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_export_result ) ).
    ENDIF.

    " B. Áp dụng Paging an toàn (Nếu Postman/Fiori giới hạn số dòng trả về)
    DATA(lo_paging) = io_request->get_paging( ).
    DATA(lv_offset) = lo_paging->get_offset( ).
    DATA(lv_page_size) = lo_paging->get_page_size( ).

    IF lv_offset IS NOT INITIAL OR lv_page_size IS NOT INITIAL.
      IF lv_offset >= lines( lt_export_result ).
        CLEAR lt_export_result.
      ENDIF.
    ENDIF.

    " C. Trả về dữ liệu cuối cùng
    IF io_request->is_data_requested( ).
      io_response->set_data( lt_export_result ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
