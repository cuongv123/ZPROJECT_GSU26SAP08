CLASS zcl_ce_db_table_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.

CLASS zcl_ce_db_table_qp IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).
    DATA lv_program_name TYPE program.

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

    " ĐỌC TỪ DATABASE (Cực kỳ nhanh)
    DATA lt_rap_table TYPE TABLE OF zce_db_table.

    IF lv_program_name IS NOT INITIAL.
      SELECT SINGLE report_id FROM ztmig_overview WHERE program_name = @lv_program_name INTO @DATA(lv_report_id).
      IF sy-subrc = 0.
        SELECT * FROM ztmig_dbtable WHERE report_id = @lv_report_id INTO TABLE @DATA(lt_db).

        LOOP AT lt_db INTO DATA(ls_db).
          APPEND VALUE #(
            programname       = lv_program_name
            tablename         = ls_db-table_name
            description       = ls_db-description
            operations        = ls_db-operations
            fields            = ls_db-fields
            recommendation    = ls_db-recommendation
            cdscandidate      = ls_db-cds_candidate
            priority          = ls_db-priority
            migrationapproach = ls_db-migration_approach
          ) TO lt_rap_table.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " PHÂN TRANG (PAGING)
    DATA lt_result TYPE TABLE OF zce_db_table.
    IF lv_top > 0.
      DATA(lv_from) = lv_skip + 1.
      DATA(lv_to)   = lv_skip + lv_top.
      LOOP AT lt_rap_table INTO DATA(ls_row) FROM lv_from TO lv_to.
        APPEND ls_row TO lt_result.
      ENDLOOP.
    ELSE.
      lt_result = lt_rap_table.
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result ).
    ENDIF.
    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_rap_table ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
