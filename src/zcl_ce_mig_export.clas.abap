CLASS zcl_ce_mig_export DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_ce_mig_export IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA: ls_result TYPE zce_mig_export,
          lt_result LIKE STANDARD TABLE OF ls_result.

    TRY.
        DATA(lt_filter_cond) = io_request->get_filter( )->get_as_ranges( ).

        " --- Đọc đúng 3 key: ReportType / FileFormat / ExportSection ---
        DATA(lv_report_type) = VALUE zmig_mail_job-report_type( ).
        READ TABLE lt_filter_cond WITH KEY name = 'REPORTTYPE' INTO DATA(ls_rt_filter).
        IF sy-subrc = 0 AND ls_rt_filter-range IS NOT INITIAL.
          lv_report_type = ls_rt_filter-range[ 1 ]-low.
        ENDIF.

        DATA(lv_format) = CONV zmig_e_file_format( 'X' ).
        READ TABLE lt_filter_cond WITH KEY name = 'FILEFORMAT' INTO DATA(ls_format_filter).
        IF sy-subrc = 0 AND ls_format_filter-range IS NOT INITIAL.
          lv_format = ls_format_filter-range[ 1 ]-low.
        ENDIF.

        DATA(lv_export_section) = CONV zif_mig_export_provider=>ty_export_section( 'ALL' ).
        READ TABLE lt_filter_cond WITH KEY name = 'EXPORTSECTION' INTO DATA(ls_section_filter).
        IF sy-subrc = 0 AND ls_section_filter-range IS NOT INITIAL.
          lv_export_section = ls_section_filter-range[ 1 ]-low.
        ENDIF.

        IF lv_report_type IS INITIAL.
          RAISE EXCEPTION TYPE zcx_mig_export_error
            EXPORTING
              mv_message = 'ReportType is required.'.
        ENDIF.

        " --- Gọi đúng engine chuẩn: theo report_type -> resolve analysis_id
        "     bên trong get_analysis_id(), theo đúng section registry. ---
        DATA(lo_engine) = NEW zcl_mig_export_engine( ).
        DATA(ls_export_result) = CAST zif_mig_export_provider( lo_engine )->generate(
          iv_job_id         = VALUE #( )
          iv_analysis_id    = VALUE #( )
          iv_report_type    = lv_report_type
          iv_file_format    = lv_format
          iv_export_section = lv_export_section ).

        IF ls_export_result-success = abap_false.
          RAISE EXCEPTION TYPE zcx_mig_export_error
            EXPORTING
              mv_message = ls_export_result-message.
        ENDIF.

        ls_result-reporttype    = lv_report_type.
        ls_result-fileformat    = lv_format.
        ls_result-exportsection = lv_export_section.
        ls_result-mimetype      = ls_export_result-mime_type.
        ls_result-filename      = ls_export_result-file_name.
        ls_result-content       = ls_export_result-content.

        APPEND ls_result TO lt_result.

        IF io_request->is_data_requested( ).
          io_response->set_data( lt_result ).
        ENDIF.

        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lines( lt_result ) ).
        ENDIF.

      CATCH cx_root INTO DATA(lx_exc).
        " Không nuốt lỗi âm thầm -> client nhận được HTTP error thay vì
        " response 200 rỗng. cx_rap_query_provider là abstract nên phải
        " raise qua class con ZCX_MIG_EXPORT_ERROR.
        IF lx_exc IS INSTANCE OF zcx_mig_export_error.
          RAISE EXCEPTION lx_exc.
        ENDIF.

        RAISE EXCEPTION TYPE zcx_mig_export_error
          EXPORTING
            previous   = lx_exc
            mv_message = lx_exc->get_text( ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

