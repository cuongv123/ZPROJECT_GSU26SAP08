CLASS zcl_ce_ui_filter_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider.

ENDCLASS.

CLASS zcl_ce_ui_filter_qp IMPLEMENTATION.
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
    " Read ProgramName from navigation filter
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
            lv_program_name =
              ls_program-range[ 1 ]-low.
          ENDIF.
        ENDIF.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    "========================================
    " Read Source
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
      lt_raw_filter TYPE zcl_parser_types=>tt_raw_ui_filter.
    DATA(lo_parser) = NEW zcl_abap_source_parser( ).
    lo_parser->zif_code_parser~analyze_program(
      EXPORTING
        iv_program_name = lv_program_name
        it_source_code  = lt_source_code
      IMPORTING
        et_ui_filter    = lt_raw_filter
    ).

    "========================================
    " Recommendation Engine
    "========================================
    DATA:
      lt_final_filter TYPE zcl_parser_types=>tt_ui_filter.
    DATA(lo_engine) =
      NEW zcl_recommendation_engine( ).
    lo_engine->zif_recommendation_engine~enrich_ui_filter(
      EXPORTING
        iv_program_name  = lv_program_name
        it_raw_ui_filter = lt_raw_filter
      IMPORTING
        et_ui_filter     = lt_final_filter
    ).

    "========================================
    " DTO -> RAP Entity Mapping
    "========================================
    DATA:
  lt_rap_filter TYPE TABLE OF zce_ui_filter.
    LOOP AT lt_final_filter INTO DATA(ls_filter).
      APPEND VALUE #(
        programname      = ls_filter-program_name
        fieldname        = ls_filter-field_name
        description      = ls_filter-description
        filtertype       = ls_filter-filter_type
        recommendation   = ls_filter-recommendation
        migrationtarget  = ls_filter-migration_target
        dataelement      = ls_filter-data_element
        mandatoryflag    = ls_filter-mandatory_flag
        multivalueflag   = ls_filter-multi_value_flag
        severity         = ls_filter-severity
        fioriadaptation  = ls_filter-fiori_adaptation
      ) TO lt_rap_filter.
    ENDLOOP.

    "========================================
    " RAP Paging
    "========================================
    DATA lt_result TYPE TABLE OF zce_ui_filter.
    IF lv_top > 0.
      DATA(lv_from) = lv_skip + 1.
      DATA(lv_to)   = lv_skip + lv_top.
      LOOP AT lt_rap_filter INTO DATA(ls_row)
           FROM lv_from
           TO lv_to.
        APPEND ls_row TO lt_result.
      ENDLOOP.

    ELSE.
      lt_result = lt_rap_filter.
    ENDIF.

    "========================================
    " Response
    "========================================
    IF io_request->is_data_requested( ).
      io_response->set_data(
        lt_result
      ).
    ENDIF.
    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records(
        lines( lt_rap_filter )
      ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
