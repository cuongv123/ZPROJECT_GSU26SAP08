CLASS zcl_ce_business_logic_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_ce_business_logic_qp IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    "========================================
    " RAP Mandatory Calls
    "========================================
    DATA(lo_filter) = io_request->get_filter( ).
    DATA(lt_sort) =
      io_request->get_sort_elements( ).
    DATA(lv_top) =
      io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) =
      io_request->get_paging( )->get_offset( ).

    "========================================
    " RAP Filter
    "========================================
    DATA lv_program_name TYPE program.
    TRY.
        IF lo_filter IS BOUND.
          DATA(lt_ranges) =
            lo_filter->get_as_ranges( ).
          READ TABLE lt_ranges
          WITH KEY name = 'PROGRAMNAME'
          INTO DATA(ls_program).
          IF sy-subrc = 0.
            lv_program_name = ls_program-range[ 1 ]-low.
          ENDIF.
        ENDIF.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    "========================================
    " Read Program Source
    "========================================
    DATA:
      lt_source_code TYPE zcl_parser_types=>tt_source_code.
    DATA(lo_repo) = NEW zcl_source_repository( ).
    lo_repo->get_program_source(
      EXPORTING
        iv_program_name = lv_program_name
      IMPORTING
        et_source_code  = lt_source_code
    ).

    "========================================
    " Parser
    "========================================
    DATA:
      lt_raw_logic TYPE zcl_parser_types=>tt_raw_logic.
    DATA(lo_parser) = NEW zcl_abap_source_parser( ).
    lo_parser->zif_code_parser~analyze_program(
      EXPORTING
        iv_program_name = lv_program_name
        it_source_code  = lt_source_code
      IMPORTING
        et_logic        = lt_raw_logic
    ).

    "========================================
    " Recommendation Engine
    "========================================
    DATA:
      lt_final_logic TYPE zcl_parser_types=>tt_business_logic.
    DATA(lo_engine) = NEW zcl_recommendation_engine( ).
    lo_engine->zif_recommendation_engine~enrich_business_logic(
      EXPORTING
        iv_program_name   = lv_program_name
        it_raw_logic      = lt_raw_logic
      IMPORTING
        et_business_logic = lt_final_logic
    ).

    "========================================
    " DTO -> RAP Entity Mapping
    "========================================

    DATA:
      lt_rap_logic TYPE TABLE OF zce_business_logic.
    LOOP AT lt_final_logic INTO DATA(ls_logic).
      APPEND VALUE #(
        programname      = ls_logic-program_name
        objectname       = ls_logic-object_name
        description      = ls_logic-description
        objecttype       = ls_logic-object_type
        recommendation = ls_logic-recommendation
*        apireleasedflag  = ls_logic-api_released_flag
*        cloudcompliant   = ls_logic-cloud_compliant
        migrationtarget  = ls_logic-migration_target
        severity         = ls_logic-severity
        remediationcomplexity = ls_logic-remediation_complexity
      ) TO lt_rap_logic.
    ENDLOOP.

    "========================================
    " RAP Paging
    "========================================
    DATA lt_result TYPE TABLE OF zce_business_logic.

    IF lv_top > 0.
      DATA(lv_from) = lv_skip + 1.
      DATA(lv_to)   = lv_skip + lv_top.
      LOOP AT lt_rap_logic INTO DATA(ls_row)
           FROM lv_from
           TO lv_to.
        APPEND ls_row TO lt_result.
      ENDLOOP.

    ELSE.
      lt_result = lt_rap_logic.

    ENDIF.

    "========================================
    " RAP Response
    "========================================
    IF io_request->is_data_requested( ).
      io_response->set_data(
        lt_result
      ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records(
        lines( lt_rap_logic )
      ).
    ENDIF.
   "====================================================================
    " KHỐI TỰ ĐỘNG XUẤT EXCEL - FIX LỖI MIGRATION_TARGET & CONVERT FUNCTION
    "====================================================================
    IF lt_rap_logic IS NOT INITIAL.
      DATA: lt_excel_data TYPE zcl_excel_export_handler=>tt_business_logic,
            ls_excel_item LIKE LINE OF lt_excel_data.

      LOOP AT lt_rap_logic INTO DATA(ls_rap).
        CLEAR ls_excel_item.
        ls_excel_item-programname           = ls_rap-programname.
        ls_excel_item-objectname            = ls_rap-objectname.
        ls_excel_item-description           = ls_rap-description.
        ls_excel_item-objecttype            = ls_rap-objecttype.
        ls_excel_item-recommendation        = ls_rap-recommendation.
        ls_excel_item-migrationtarget       = ls_rap-migrationtarget. " FIX: Bỏ dấu gạch dưới gây lỗi dòng 150
        ls_excel_item-severity              = ls_rap-severity.
        ls_excel_item-remediationcomplexity = ls_rap-remediationcomplexity.
        APPEND ls_excel_item TO lt_excel_data.
      ENDLOOP.

      TRY.
          DATA(lo_excel_export) = NEW zcl_excel_export_handler( ).

          DATA(lv_excel_stream) = lo_excel_export->export_to_excel(
                                    it_data  = lt_excel_data
                                    ip_title = 'RAP Migration Report' ).

          DATA: lt_binary_tab TYPE solix_tab,
                lv_bin_length TYPE i.

          " FIX LỖI DÒNG 170: Sử dụng Function chuẩn của SAP thay thế cho CL_BCS_CONVERT lỗi
          CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
            EXPORTING
              buffer        = lv_excel_stream
            IMPORTING
              output_length = lv_bin_length
            TABLES
              binary_tab    = lt_binary_tab.

          DATA: lv_file_path TYPE string VALUE 'C:\temp\Ketqua_Fiori_Excel.xlsx'.

          cl_gui_frontend_services=>gui_download(
            EXPORTING
              filename              = lv_file_path
              filetype              = 'BIN'
              bin_filesize          = lv_bin_length
            CHANGING
              data_tab              = lt_binary_tab
            EXCEPTIONS
              OTHERS                = 1 ).

        CATCH cx_root.
      ENDTRY.
    ENDIF.
    "====================================================================
    " KẾT THÚC KHỐI XUẤT EXCEL
    "====================================================================
  ENDMETHOD.
ENDCLASS.
