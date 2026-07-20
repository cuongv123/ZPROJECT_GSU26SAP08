CLASS zcl_analysis_aggregator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_analysis_aggregator.

  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_analysis_aggregator IMPLEMENTATION.
  METHOD zif_analysis_aggregator~build_overview.
    DATA: lv_total_items     TYPE f,
          lv_ready_items     TYPE f,
          lv_complexity_base TYPE i.

    " 1. Khởi tạo thông tin Header cơ bản
    CLEAR es_overview.
    es_overview-program_name = iv_program_name.

    " Sử dụng API chuẩn của ABAP Cloud để lấy User và Time
    TRY.
        es_overview-analyzed_by = cl_abap_context_info=>get_user_technical_name( ).
        es_overview-analyzed_at = utclong_current( ).
      CATCH cx_abap_context_info_error.
        es_overview-analyzed_by = 'SYSTEM'.
    ENDTRY.

    es_overview-analysis_status        = zif_mig_constants=>c_status-analyzed. " <--- Đã sửa
    es_overview-total_filters          = lines( it_ui_filter ).
    es_overview-total_tables           = lines( it_db_table ).
    es_overview-total_business_objects = lines( it_business_logic ).           " <--- Đã sửa

    lv_total_items = es_overview-total_filters + es_overview-total_tables + es_overview-total_business_objects. " <--- Đã sửa

    " NẾU PROGRAM RỖNG -> FAIL
    IF lv_total_items = 0.
      es_overview-analysis_status          = zif_mig_constants=>c_status-failed. " <--- Đã sửa
      es_overview-migration_score          = 0.
      es_overview-cloud_readiness_score    = 0.                                  " <--- Đã sửa
      es_overview-complexity_score         = zif_mig_constants=>c_complexity-low.
      RETURN.
    ENDIF.

    " =====================================================================
    " 2. TÍNH TOÁN CLOUD READINESS & MIGRATION SCORE
    " =====================================================================

    " A. Đánh giá Table (Nếu có CDS thay thế -> +1 điểm Ready)
    LOOP AT it_db_table INTO DATA(ls_table).
      IF ls_table-cds_candidate IS NOT INITIAL AND ls_table-cds_candidate <> 'NO_RULE_FOUND'.
        lv_ready_items = lv_ready_items + 1.
      ELSE.
        lv_complexity_base = lv_complexity_base + 1. " Tăng độ khó nếu phải tự build CDS mới
      ENDIF.
    ENDLOOP.

    " B. Đánh giá Logic (Nếu Call Screen/Dynpro -> Gây rủi ro nặng cho Fiori)
    LOOP AT it_business_logic INTO DATA(ls_logic).
      IF ls_logic-object_type = 'FUNCTION MODULE' AND ls_logic-migration_target IS NOT INITIAL.
        lv_ready_items = lv_ready_items + 1.
      ELSEIF ls_logic-object_type = 'CALL SCREEN'.
        lv_complexity_base = lv_complexity_base + 3. " Trọng số rủi ro rất cao
      ELSE.
        lv_complexity_base = lv_complexity_base + 1.
      ENDIF.
    ENDLOOP.

    " C. Đánh giá Filter (Filter luôn dễ migrate lên Fiori Elements)
    lv_ready_items = lv_ready_items + es_overview-total_filters.

    " Tính % trung bình
    DATA(lv_percentage) = ( lv_ready_items / lv_total_items ) * 100.
    es_overview-migration_score = round( val = lv_percentage dec = 0 ).
    es_overview-cloud_readiness_score = es_overview-migration_score. " <--- Đã sửa

    " =====================================================================
    " 3. XẾP LOẠI ĐỘ PHỨC TẠP (COMPLEXITY DISTRIBUTION)
    " =====================================================================
    " Complexity phụ thuộc vào tổng số lượng object và các "Dead code" (như CALL SCREEN)
    DATA(lv_total_complexity_points) = lv_total_items + lv_complexity_base.

    IF lv_total_complexity_points <= 5.
      es_overview-complexity_score = zif_mig_constants=>c_complexity-low.
    ELSEIF lv_total_complexity_points <= 15.
      es_overview-complexity_score = zif_mig_constants=>c_complexity-medium.
    ELSEIF lv_total_complexity_points <= 30.
      es_overview-complexity_score = zif_mig_constants=>c_complexity-high.
    ELSE.
      es_overview-complexity_score = zif_mig_constants=>c_complexity-severe.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
