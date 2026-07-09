CLASS zcl_ce_analysis_overview_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider.

ENDCLASS.

CLASS zcl_ce_analysis_overview_qp IMPLEMENTATION.
  METHOD if_rap_query_provider~select.

    "========================================
    " 1. RAP Filter (Bắt giá trị động từ UI)
    "========================================
    DATA lv_program_name TYPE program VALUE 'ZSD_SALES_REPORT'. " Giá trị mặc định

    TRY.
        IF io_request->get_filter( ) IS BOUND.
          DATA(lt_ranges) = io_request->get_filter( )->get_as_ranges( ).

          " Đọc giá trị người dùng tìm kiếm trên Fiori
          READ TABLE lt_ranges WITH KEY name = 'PROGRAMNAME' INTO DATA(ls_program).
          IF sy-subrc = 0 AND ls_program-range IS NOT INITIAL.
            lv_program_name = ls_program-range[ 1 ]-low.
          ENDIF.
        ENDIF.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    "=========================================
    " 2. RAP Paging
    "=========================================
    DATA(lv_top) = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).

    "=========================================
    " 3. Internal DTO & RAP Entity Types
    "=========================================
    DATA: lt_source_code TYPE zcl_parser_types=>tt_source_code,
          lt_raw_logic   TYPE zcl_parser_types=>tt_raw_logic,
          lt_raw_filter  TYPE zcl_parser_types=>tt_raw_ui_filter,
          lt_raw_table   TYPE zcl_parser_types=>tt_raw_db_table,
          lt_logic       TYPE zcl_parser_types=>tt_business_logic,
          lt_filter      TYPE zcl_parser_types=>tt_ui_filter,
          lt_table       TYPE zcl_parser_types=>tt_db_table,
          ls_overview    TYPE zce_analysis_overview,
          lt_overview    TYPE TABLE OF zce_analysis_overview,
          ls_agg         TYPE zcl_parser_types=>ty_overview.

    "=========================================
    " 4. Fake Source Code (Truyền giá trị động nếu cần)
    "=========================================
    DATA(lo_repo) =
      NEW zcl_source_repository( ).

    lo_repo->get_program_source(

      EXPORTING
        iv_program_name = lv_program_name

      IMPORTING
        et_source_code  = lt_source_code
    ).

    "=========================================
    " 5. Logic Core (Parser -> Engine -> Aggregator)
    "=========================================
    DATA(lo_parser) = NEW zcl_abap_source_parser( ).
    lo_parser->zif_code_parser~analyze_program(
      EXPORTING iv_program_name = lv_program_name
                it_source_code  = lt_source_code
      IMPORTING et_logic        = lt_raw_logic
                et_ui_filter    = lt_raw_filter
                et_db_table     = lt_raw_table ).

    DATA(lo_engine) = NEW zcl_recommendation_engine( ).
    lo_engine->zif_recommendation_engine~enrich_business_logic(
      EXPORTING iv_program_name   = lv_program_name
                it_raw_logic      = lt_raw_logic
      IMPORTING et_business_logic = lt_logic ).

    lo_engine->zif_recommendation_engine~enrich_ui_filter(
      EXPORTING iv_program_name  = lv_program_name
                it_raw_ui_filter = lt_raw_filter
      IMPORTING et_ui_filter     = lt_filter ).

    lo_engine->zif_recommendation_engine~enrich_db_table(
      EXPORTING iv_program_name = lv_program_name
                it_raw_db_table = lt_raw_table
      IMPORTING et_db_table     = lt_table ).

    DATA(lo_aggregator) = NEW zcl_analysis_aggregator( ).
    lo_aggregator->zif_analysis_aggregator~build_overview(
      EXPORTING iv_program_name  = lv_program_name
                it_business_logic = lt_logic
                it_ui_filter     = lt_filter
                it_db_table      = lt_table
      IMPORTING es_overview      = ls_agg ).

    "=========================================
    " 6. Mapping DTO -> RAP Entity
    "=========================================
    DATA lv_criticality TYPE i.

    CASE ls_agg-analysis_status.
      WHEN 'COMPLETED'.
        lv_criticality = 3.
      WHEN 'IN PROGRESS'.
        lv_criticality = 2.
      WHEN 'FAILED'.
        lv_criticality = 1.
      WHEN OTHERS.
        lv_criticality = 0.
    ENDCASE.

    DATA lv_program_description TYPE string.

    SELECT SINGLE text
      INTO @lv_program_description
      FROM trdirt
     WHERE name  = @lv_program_name
       AND sprsl = @sy-langu.

    IF sy-subrc <> 0.
      lv_program_description = lv_program_name.
    ENDIF.

    ls_overview = VALUE #(
      programname          = ls_agg-program_name
      programdescription        = lv_program_description
      analysisstatuscriticality = lv_criticality
      analysisstatus       = ls_agg-analysis_status
      totaltables          = ls_agg-total_tables
      totalfilters         = ls_agg-total_filters
      totalbusinessobjects = ls_agg-total_business_objects
      migrationscore       = ls_agg-migration_score
      complexityscore      = ls_agg-complexity_score
      cloudreadinessscore  = ls_agg-cloud_readiness_score
    ).

    APPEND ls_overview TO lt_overview.

    "=========================================
    " 7. RAP Response
    "=========================================
    IF io_request->is_data_requested( ). " Best practice: Chỉ trả data khi UI thực sự cần
      io_response->set_data( lt_overview ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_overview ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
