CLASS zcl_ce_mig_export DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_ce_mig_export IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    " 1. Khai báo biến kết quả chuẩn theo Custom Entity ZCE_MIG_EXPORT
    DATA: ls_result TYPE zce_mig_export,
          lt_result LIKE STANDARD TABLE OF ls_result.

    TRY.
        " 2. Đọc Filter / Range từ Request
        DATA(lt_filter_cond) = io_request->get_filter( )->get_as_ranges( ).

        DATA: lv_format         TYPE string VALUE 'X',   " Default Excel
              lv_export_section TYPE string VALUE 'ALL', " Default ALL
              lv_fields         TYPE string.             " Sẽ động hóa theo Filter/ALL

        " --- Đọc FileFormat từ URL Filter ---
        READ TABLE lt_filter_cond WITH KEY name = 'FILEFORMAT' INTO DATA(ls_format_filter).
        IF sy-subrc = 0 AND ls_format_filter-range IS NOT INITIAL.
          lv_format = ls_format_filter-range[ 1 ]-low.
        ENDIF.

        " --- Đọc ExportSection từ URL Filter (ALL hay FILTER) ---
        READ TABLE lt_filter_cond WITH KEY name = 'EXPORTSECTION' INTO DATA(ls_section_filter).
        IF sy-subrc = 0 AND ls_section_filter-range IS NOT INITIAL.
          lv_export_section = ls_section_filter-range[ 1 ]-low.
        ENDIF.

        " --- 3. ĐỘNG HÓA danh sách Fields gửi sang Engine ---
        IF to_upper( lv_export_section ) = 'ALL' OR lv_export_section IS INITIAL.
          " Nếu ExportSection = 'ALL': Truyền '*' hoặc RỖNG để Engine hiểu là lấy FULL TẤT CẢ CỘT
          lv_fields = '*'.
        ELSE.
          " Nếu ExportSection = 'FILTER': Lấy danh sách field mà UI đang hiển thị
          DATA(lt_req_elements) = io_request->get_requested_elements( ).
          IF lt_req_elements IS NOT INITIAL.
            lv_fields = concat_lines_of( table = lt_req_elements sep = `,` ).
          ELSE.
            lv_fields = 'FIELDNAME,REFERENCE_TABLE,CONFIDENCE'. " Fallback
          ENDIF.
        ENDIF.

        " 4. Gọi Export Engine core
        DATA: lo_engine TYPE REF TO zcl_mig_export_engine.
        lo_engine = NEW zcl_mig_export_engine( ).

        DATA(lv_content) = lo_engine->execute_export(
                             iv_selected_fields = lv_fields
                             iv_export_format   = lv_format ).

        " 5. Mapping dữ liệu trả về cho Custom Entity
        ls_result-reporttype    = 'MIGRATION_REPORT'.
        ls_result-fileformat    = lv_format.
        ls_result-exportsection = lv_export_section.

        " Mapping MimeType theo Domain Fixed Values (P, X, C)
        ls_result-mimetype = COND #(
          WHEN to_upper( lv_format ) = 'P' OR to_upper( lv_format ) = 'PDF'
            THEN 'application/pdf'
          WHEN to_upper( lv_format ) = 'X' OR to_upper( lv_format ) = 'EXCEL' OR to_upper( lv_format ) = 'XLSX'
            THEN 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          ELSE 'text/csv' ).

        " Mapping Filename động
        ls_result-filename = COND #(
          WHEN to_upper( lv_format ) = 'P' OR to_upper( lv_format ) = 'PDF' THEN 'migration_report.pdf'
          WHEN to_upper( lv_format ) = 'X' OR to_upper( lv_format ) = 'EXCEL' OR to_upper( lv_format ) = 'XLSX' THEN 'migration_report.xlsx'
          ELSE 'migration_report.csv' ).

        ls_result-content = lv_content. " Binary Stream

        CLEAR lt_result.
        APPEND ls_result TO lt_result.

        " 6. Set Response cho RAP Framework
        IF io_request->is_data_requested( ).
          io_response->set_data( lt_result ).
        ENDIF.

        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lines( lt_result ) ).
        ENDIF.

      CATCH cx_root INTO DATA(lx_exc).
        " Handling exception nếu có
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
