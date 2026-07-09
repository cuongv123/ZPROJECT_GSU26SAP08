CLASS zcl_ce_migration_global_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ce_migration_global_qp IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    " ====================================================================
    " 1. ĐỌC THAM SỐ PROGRAM NAME CHUẨN HÓA (ĐỌC CẢ PARAMETER VÀ FILTER)
    " ====================================================================
    DATA lv_program_name TYPE program.

    TRY.
        " Hướng 1: Đọc trực tiếp từ OData Parameters
        DATA(lt_parameters) = io_request->get_parameters( ).
        LOOP AT lt_parameters INTO DATA(ls_para).
          IF to_upper( ls_para-parameter_name ) = 'PROGRAMNAME' OR to_upper( ls_para-parameter_name ) = 'PROGRAM_NAME'.
            lv_program_name = ls_para-value.
            EXIT.
          ENDIF.
        ENDLOOP.

        " Hướng 2: Nếu Parameter trống, quét toàn bộ cây Filter URL (Fiori Elements Object Page)
        IF lv_program_name IS INITIAL.
          DATA(lo_filter) = io_request->get_filter( ).
          IF lo_filter IS BOUND.
            DATA(lt_ranges) = lo_filter->get_as_ranges( ).
            LOOP AT lt_ranges INTO DATA(ls_filter_line).
              DATA(lv_filter_name) = to_upper( ls_filter_line-name ).

              " Quét tất cả các biến thể tên cột có thể truyền xuống từ UI projection view
              IF lv_filter_name = 'PROGRAMNAME' OR lv_filter_name = 'PROGRAM_NAME'.
                READ TABLE ls_filter_line-range INTO DATA(ls_rg_line) INDEX 1.
                IF sy-subrc = 0 AND ls_rg_line-low IS NOT INITIAL.
                  lv_program_name = ls_rg_line-low.
                  EXIT.
                ENDIF.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.
      CATCH cx_root.
    ENDTRY.

    " Hướng 3: Nếu dữ liệu trên UI đang trống (chưa lưu vào DB), lấy bản ghi đầu tiên có sẵn trong hệ thống để test
    IF lv_program_name IS INITIAL.
      SELECT SINGLE program_name
        FROM ztmig_overview
        INTO @lv_program_name.
    ENDIF.

    " Fallback cuối cùng nếu DB hoàn toàn chưa có gì
    IF lv_program_name IS INITIAL.
      lv_program_name = 'ZTEST_ABAP_PARSER_V2'.
    ENDIF.

    " Chuyển đổi chữ hoa chữ thường để tránh khớp lệch chuỗi khi SELECT DB
    lv_program_name = to_upper( lv_program_name ).
   " ====================================================================
    " 2. ĐỌC DỮ LIỆU THẬT TỪ CÁC BẢNG VẬT LÝ MỚI THEO KIẾN TRÚC HEADER-ITEM
    " ====================================================================
    DATA: lt_ui_filters TYPE TABLE OF zce_ui_filter,
          lt_db_tables  TYPE TABLE OF zce_db_table,
          lt_bus_logic  TYPE TABLE OF zce_business_logic.

    " Tự động lấy đúng kiểu dữ liệu của cột trong bảng vật lý (RAW16/UUID/CHAR)
    DATA lv_report_id TYPE ztmig_overview-report_id.

    " Bước A: Tìm report_id từ bảng tổng quan (ztmig_overview) dựa theo tên chương trình
    SELECT SINGLE report_id
      FROM ztmig_overview
     WHERE program_name = @lv_program_name
      INTO @lv_report_id.

    " Bước B: Dùng report_id vừa tìm được để truy vấn chính xác dữ liệu ở các bảng con
    IF sy-subrc = 0 AND lv_report_id IS NOT INITIAL.
      SELECT * FROM ztmig_filter  WHERE report_id = @lv_report_id INTO CORRESPONDING FIELDS OF TABLE @lt_ui_filters.
      SELECT * FROM ztmig_dbtable WHERE report_id = @lv_report_id INTO CORRESPONDING FIELDS OF TABLE @lt_db_tables.
      SELECT * FROM ztmig_logic   WHERE report_id = @lv_report_id INTO CORRESPONDING FIELDS OF TABLE @lt_bus_logic.
    ENDIF.
    " ====================================================================
    " 3. THIẾT LẬP KIẾN TRÚC MẢNG CẤU HÌNH CHIA SHEET TỰ ĐỘNG
    " ====================================================================
    TYPES: BEGIN OF ty_sheet_config,
             title    TYPE string,
             data_ref TYPE REF TO data,
           END OF ty_sheet_config.
    DATA: lt_sheets TYPE STANDARD TABLE OF ty_sheet_config,
          ls_sheet  LIKE LINE OF lt_sheets.

    GET REFERENCE OF lt_ui_filters INTO ls_sheet-data_ref.
    ls_sheet-title = 'UI Filters'.
    APPEND ls_sheet TO lt_sheets.

    GET REFERENCE OF lt_db_tables INTO ls_sheet-data_ref.
    ls_sheet-title = 'Database Tables'.
    APPEND ls_sheet TO lt_sheets.

    GET REFERENCE OF lt_bus_logic INTO ls_sheet-data_ref.
    ls_sheet-title = 'Business Logic'.
    APPEND ls_sheet TO lt_sheets.

    " ====================================================================
    " 4. KHỞI TẠO FILE EXCEL VÀ CHIA SHEET BẰNG THƯ VIỆN ABAP2XLSX
    " ====================================================================
    DATA: lo_excel        TYPE REF TO zcl_excel,
          lo_worksheet    TYPE REF TO zcl_excel_worksheet,
          lv_excel_stream TYPE xstring,
          lv_row          TYPE i,
          lv_col          TYPE i.

    TRY.
        CREATE OBJECT lo_excel.

        " Sheet đầu tiên: Tổng quan (Overview)
        lo_worksheet = lo_excel->get_active_worksheet( ).
        lo_worksheet->set_title( 'Overview' ).
        lo_worksheet->set_cell( ip_column = 'B' ip_row = 2 ip_value = 'MIGRATION COMPREHENSIVE EXECUTIVE SUMMARY' ).
        lo_worksheet->set_cell( ip_column = 'B' ip_row = 4 ip_value = 'Target Program Name:' ).
        lo_worksheet->set_cell( ip_column = 'C' ip_row = 4 ip_value = lv_program_name ).
        lo_worksheet->set_cell( ip_column = 'B' ip_row = 5 ip_value = 'Total Analyzed Components:' ).
        lo_worksheet->set_cell( ip_column = 'C' ip_row = 5 ip_value = lines( lt_db_tables ) + lines( lt_bus_logic ) ).

        " Vòng lặp chia đa Sheet động dựa trên cấu trúc bảng thật
        FIELD-SYMBOLS: <lt_table> TYPE ANY TABLE,
                       <ls_row>   TYPE any,
                       <lv_field> TYPE any.

        LOOP AT lt_sheets INTO ls_sheet.
          ASSIGN ls_sheet-data_ref->* TO <lt_table>.
          IF <lt_table> IS ASSIGNED AND <lt_table> IS NOT INITIAL.
            TRY.
                lo_worksheet = lo_excel->add_new_worksheet( ).
                lo_worksheet->set_title( CONV zexcel_sheet_title( ls_sheet-title ) ).

                DATA(lo_type_desc) = cl_abap_tabledescr=>describe_by_data( <lt_table> ).
                DATA(lo_table_desc) = CAST cl_abap_tabledescr( lo_type_desc ).
                DATA(lo_struct) = CAST cl_abap_structdescr( lo_table_desc->get_table_line_type( ) ).

                lv_col = 1.
                LOOP AT lo_struct->components INTO DATA(ls_comp).
                  lo_worksheet->set_cell( ip_column = lv_col ip_row = 1 ip_value = ls_comp-name ).
                  lv_col = lv_col + 1.
                ENDLOOP.

                lv_row = 2.
                LOOP AT <lt_table> ASSIGNING <ls_row>.
                  lv_col = 1.
                  LOOP AT lo_struct->components INTO ls_comp.
                    DATA(lv_comp_upper) = to_upper( ls_comp-name ).
                    ASSIGN COMPONENT lv_comp_upper OF STRUCTURE <ls_row> TO <lv_field>.
                    IF <lv_field> IS NOT ASSIGNED.
                      ASSIGN COMPONENT ls_comp-name OF STRUCTURE <ls_row> TO <lv_field>.
                    ENDIF.

                    IF <lv_field> IS ASSIGNED.
                      lo_worksheet->set_cell( ip_column = lv_col ip_row = lv_row ip_value = <lv_field> ).
                    ENDIF.
                    lv_col = lv_col + 1.
                  ENDLOOP.
                  lv_row = lv_row + 1.
                ENDLOOP.
              CATCH cx_root.
                CONTINUE.
            ENDTRY.
          ENDIF.
        ENDLOOP.

        " Xuất dữ liệu Excel ra dạng chuỗi nhị phân XSTRING nguyên bản
        DATA: lo_writer TYPE REF TO zif_excel_writer.
        CREATE OBJECT lo_writer TYPE zcl_excel_writer_2007.
        lv_excel_stream = lo_writer->write_file( lo_excel ).

      CATCH cx_root.
        CLEAR lv_excel_stream.
    ENDTRY.

    " ====================================================================
    " 5. TRẢ DỮ LIỆU ĐÃ ĐƯỢC CHUẨN HÓA AN TOÀN CHO FRAMEWORK
    " ====================================================================
    DATA lt_export_result TYPE TABLE OF zce_migration_global_excel.

    APPEND VALUE #(
      programname = lv_program_name
      content     = lv_excel_stream
      mimetype    = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      filename    = 'Comprehensive_Global_Report.xlsx'
    ) TO lt_export_result.

    " Cung cấp đầy đủ số lượng bản ghi để tránh lỗi Dump 500 Unmanaged Query
    io_response->set_total_number_of_records( lines( lt_export_result ) ).

    " Trả dữ liệu thô ra ngoài phản hồi OData
    io_response->set_data( lt_export_result ).

  ENDMETHOD.
ENDCLASS.
