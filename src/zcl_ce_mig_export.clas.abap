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

    DATA: lv_report_type    TYPE zmig_mail_job-report_type,
          lv_file_format    TYPE zmig_e_file_format,
          lv_export_section TYPE zif_mig_export_provider=>ty_export_section.

    TRY.
        " 1. LẤY DỮ LIỆU TỪ FILTER/KEY PARAMETERS CỦA ODATA REQUEST
        DATA(lt_filter_cond) = io_request->get_filter( )->get_as_ranges( ).

        LOOP AT lt_filter_cond INTO DATA(ls_filter).
          CASE ls_filter-name.
            WHEN 'REPORTTYPE' OR 'REPORT_TYPE'.
              READ TABLE ls_filter-range INDEX 1 INTO DATA(ls_r_rep).
              IF sy-subrc = 0. lv_report_type = ls_r_rep-low. ENDIF.

            WHEN 'FILEFORMAT' OR 'FILE_FORMAT'.
              READ TABLE ls_filter-range INDEX 1 INTO DATA(ls_r_fmt).
              IF sy-subrc = 0. lv_file_format = ls_r_fmt-low. ENDIF.

            WHEN 'EXPORTSECTION' OR 'EXPORT_SECTION'.
              READ TABLE ls_filter-range INDEX 1 INTO DATA(ls_r_sec).
              IF sy-subrc = 0. lv_export_section = ls_r_sec-low. ENDIF.
          ENDCASE.
        ENDLOOP.

        " Làm sạch giá trị nhận được
        lv_report_type    = condense( lv_report_type ).
        lv_file_format    = condense( lv_file_format ).
        lv_export_section = condense( lv_export_section ).

        " Nếu không truyền ExportSection thì mặc định lấy tất cả 'ALL'
        IF lv_export_section IS INITIAL.
          lv_export_section = 'ALL'.
        ENDIF.

        " 2. CHECK KIỂM TRA THAM SỐ BẮT BUỘC
        IF lv_report_type IS INITIAL OR lv_file_format IS INITIAL.
          " Trả về lỗi rõ ràng nếu bị khuyết tham số
          DATA(lv_error_msg) = |Missing parameters. ReportType: '{ lv_report_type }', FileFormat: '{ lv_file_format }'.|.

          " Gán dữ liệu rỗng và dừng lại
          io_response->set_total_number_of_records( 0 ).
          RETURN.
        ENDIF.

        " 3. GỌI ENGINE XỬ LÝ (EXPORT EXCEL / CSV / PDF)
        DATA(lo_engine) = NEW zcl_mig_export_engine( ).
        DATA(ls_result) = lo_engine->zif_mig_export_provider~generate(
            iv_job_id         = VALUE #( )
            iv_analysis_id    = VALUE #( )
            iv_report_type    = lv_report_type
            iv_file_format    = lv_file_format
            iv_export_section = lv_export_section ).

        " Kiểm tra xem Engine tạo file thành công không
        IF ls_result-success = abap_false.
          io_response->set_total_number_of_records( 0 ).
          RETURN.
        ENDIF.

        " 4. TRẢ KẾT QUẢ CHO CUSTOM ENTITY ODATA V4
        " Gán đúng tên các thành phần theo cấu trúc Custom Entity của bạn
        DATA lt_output TYPE STANDARD TABLE OF zce_mig_export.

        APPEND VALUE #(
          reporttype    = lv_report_type
          fileformat    = lv_file_format
          exportsection = lv_export_section
          content       = ls_result-content
          mimetype      = ls_result-mime_type
          filename      = ls_result-file_name
        ) TO lt_output.

        " Trả response về cho SAP Gateway
        io_response->set_data( lt_output ).
        io_response->set_total_number_of_records( lines( lt_output ) ).

      CATCH cx_root INTO DATA(lx_root).
        io_response->set_total_number_of_records( 0 ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
