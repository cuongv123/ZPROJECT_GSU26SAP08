CLASS zcl_ce_analysis_overview_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider.

ENDCLASS.

CLASS zcl_ce_analysis_overview_qp IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).
    DATA lv_program_name TYPE program.

    " 1. LẤY TÊN CHƯƠNG TRÌNH TỪ FIORI
    TRY.
        IF io_request->get_filter( ) IS BOUND.
          DATA(lt_ranges) = io_request->get_filter( )->get_as_ranges( ).
          READ TABLE lt_ranges WITH KEY name = 'PROGRAMNAME' INTO DATA(ls_program).
          IF sy-subrc = 0.
            lv_program_name = ls_program-range[ 1 ]-low.
          ENDIF.
        ENDIF.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    lv_program_name = to_upper( lv_program_name ).

    " 2. ĐỌC THẲNG TỪ DATABASE
    DATA lt_overview TYPE TABLE OF zce_analysis_overview.

    IF lv_program_name IS NOT INITIAL.
      SELECT SINGLE * FROM ztmig_overview
        WHERE program_name = @lv_program_name
        INTO @DATA(ls_db).

      IF sy-subrc = 0.
        DATA lv_criticality TYPE i.
        CASE ls_db-status.
          WHEN 'COMPLETED'.   lv_criticality = 3.
          WHEN 'IN PROGRESS'. lv_criticality = 2.
          WHEN 'FAILED'.      lv_criticality = 1.
          WHEN OTHERS.        lv_criticality = 0.
        ENDCASE.

        APPEND VALUE #(
          programname               = ls_db-program_name
          programdescription        = ls_db-description
          analysisstatuscriticality = lv_criticality
          analysisstatus            = ls_db-status
          totaltables               = ls_db-total_tables
          totalfilters              = ls_db-total_filters
          totalbusinessobjects      = ls_db-total_objects
          migrationscore            = ls_db-migration_score
          complexityscore           = ls_db-complexity_score
          cloudreadinessscore       = ls_db-cloud_readiness
        ) TO lt_overview.
      ENDIF.
    ENDIF.

    " 3. TRẢ KẾT QUẢ VỀ UI
    IF io_request->is_data_requested( ).
      io_response->set_data( lt_overview ).
    ENDIF.
    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_overview ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
