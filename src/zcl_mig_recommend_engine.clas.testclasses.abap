CLASS ltc_recommend_engine DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS create_uuid
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

    METHODS:
      create_ui_recommendation
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_database_recommendation
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_logic_recommendations
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_alv_annotations
        FOR TESTING
        RAISING zcx_mig_analysis,

      update_overview
        FOR TESTING
        RAISING zcx_mig_analysis,

      idempotent_result
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_recommend_engine IMPLEMENTATION.

  METHOD create_uuid.

    TRY.

        rv_uuid =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid   = zcx_mig_analysis=>analysis_failed
          previous = lx_uuid
        ).

    ENDTRY.

  ENDMETHOD.

    METHOD create_ui_recommendation.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    ls_result-analysis_id =
      create_uuid( ).

    ls_result-overview-program_name =
      'ZTEST_REPORT'.

    APPEND VALUE #(
      item_id            = create_uuid( )
      analysis_id        = ls_result-analysis_id
      evidence_id        = create_uuid( )
      field_name         = 'S_BUKRS'
      field_kind         = 'SELECT_OPTIONS'
      mandatory          = abap_true
      multiple_selection = abap_true
      range_supported    = abap_true
      confidence         = zif_mig_types=>gc_conf_high
    ) TO ls_result-ui_filters.

    DATA(lo_engine) =
      NEW zcl_mig_recommend_engine( ).

    lo_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    READ TABLE ls_result-recommendations
      WITH KEY rule_id = 'UI_FILTER_RANGE'
      INTO DATA(ls_recommendation).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tạo UI_FILTER_RANGE recommendation'
    ).

    READ TABLE ls_result-annotations
      WITH KEY
        recommendation_id =
          ls_recommendation-recommendation_id
        annotation_name =
          '@Consumption.filter.selectionType'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tạo selectionType annotation'
    ).

  ENDMETHOD.

    METHOD create_database_recommendation.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    ls_result-analysis_id =
      create_uuid( ).

    APPEND VALUE #(
      item_id     = create_uuid( )
      analysis_id = ls_result-analysis_id
      evidence_id = create_uuid( )
      object_name = 'VBAK'
      operation   = 'SELECT'
      read_only   = abap_true
      confidence  = zif_mig_types=>gc_conf_high
    ) TO ls_result-database_objects.

    APPEND VALUE #(
      item_id     = create_uuid( )
      analysis_id = ls_result-analysis_id
      evidence_id = create_uuid( )
      object_name = 'ZTABLE'
      operation   = 'UPDATE'
      confidence  = zif_mig_types=>gc_conf_high
    ) TO ls_result-database_objects.

    DATA(lo_engine) =
      NEW zcl_mig_recommend_engine( ).

    lo_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    READ TABLE ls_result-recommendations
      WITH KEY rule_id = 'DB_READ_CDS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    READ TABLE ls_result-recommendations
      WITH KEY rule_id = 'DB_WRITE_RAP'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

  ENDMETHOD.

    METHOD create_logic_recommendations.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    ls_result-analysis_id =
      create_uuid( ).

    APPEND VALUE #(
      item_id        = create_uuid( )
      analysis_id    = ls_result-analysis_id
      evidence_id    = create_uuid( )
      object_name    = 'DISPLAY_SCREEN'
      object_type    = 'FORM_DEFINITION'
      gui_dependency = abap_true
      confidence     = zif_mig_types=>gc_conf_high
    ) TO ls_result-business_logic.

    DATA(lo_engine) =
      NEW zcl_mig_recommend_engine( ).

    lo_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    READ TABLE ls_result-recommendations
      WITH KEY rule_id = 'LOGIC_GUI_REDESIGN'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    READ TABLE ls_result-recommendations
      WITH KEY rule_id = 'LOGIC_FORM_CLASS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

  ENDMETHOD.

    METHOD create_alv_annotations.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    ls_result-analysis_id =
      create_uuid( ).

    DATA(lv_output_id) =
      create_uuid( ).

    APPEND VALUE #(
      output_id   = lv_output_id
      analysis_id = ls_result-analysis_id
      output_name = 'RESULT_LIST'
      confidence  = zif_mig_types=>gc_conf_high
    ) TO ls_result-alv_outputs.

    APPEND VALUE #(
      item_id        = create_uuid( )
      analysis_id    = ls_result-analysis_id
      output_id      = lv_output_id
      evidence_id    = create_uuid( )
      field_name     = 'AMOUNT'
      label          = 'Amount'
      position       = 3
      visible        = abap_true
      currency_field = 'CURRENCY'
      aggregation    = 'SUM'
      confidence     = zif_mig_types=>gc_conf_high
    ) TO ls_result-alv_columns.

    DATA(lo_engine) =
      NEW zcl_mig_recommend_engine( ).

    lo_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    READ TABLE ls_result-annotations
      WITH KEY
        target_element  = 'AMOUNT'
        annotation_name = '@UI.lineItem'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    READ TABLE ls_result-annotations
      WITH KEY
        target_element  = 'AMOUNT'
        annotation_name = '@Semantics.amount.currencyCode'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    READ TABLE ls_result-annotations
      WITH KEY
        target_element  = 'AMOUNT'
        annotation_name = '@Aggregation.default'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

  ENDMETHOD.

    METHOD update_overview.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    ls_result-analysis_id =
      create_uuid( ).

    APPEND VALUE #(
      item_id     = create_uuid( )
      analysis_id = ls_result-analysis_id
      evidence_id = create_uuid( )
      field_name  = 'P_BUKRS'
      field_kind  = 'PARAMETER'
      confidence  = zif_mig_types=>gc_conf_high
    ) TO ls_result-ui_filters.

    DATA(lo_engine) =
      NEW zcl_mig_recommend_engine( ).

    lo_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_result-recommendations )
      act = ls_result-overview-total_recommendations
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = '1.0'
      act = ls_result-overview-rule_version
    ).

  ENDMETHOD.

    METHOD idempotent_result.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    ls_result-analysis_id =
      create_uuid( ).

    APPEND VALUE #(
      item_id     = create_uuid( )
      analysis_id = ls_result-analysis_id
      evidence_id = create_uuid( )
      field_name  = 'P_BUKRS'
      field_kind  = 'PARAMETER'
      confidence  = zif_mig_types=>gc_conf_high
    ) TO ls_result-ui_filters.

    DATA(lo_engine) =
      NEW zcl_mig_recommend_engine( ).

    lo_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    DATA(lv_recommendation_count) =
      lines( ls_result-recommendations ).

    DATA(lv_annotation_count) =
      lines( ls_result-annotations ).

    lo_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_recommendation_count
      act = lines( ls_result-recommendations )
      msg = 'Chạy lại engine không được tạo recommendation trùng'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_annotation_count
      act = lines( ls_result-annotations )
      msg = 'Chạy lại engine không được tạo annotation trùng'
    ).

  ENDMETHOD.

ENDCLASS.
