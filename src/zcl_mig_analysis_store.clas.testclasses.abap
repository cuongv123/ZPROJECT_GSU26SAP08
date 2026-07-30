CLASS ltc_analysis_store DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA:
      mo_sql_environment
        TYPE REF TO if_osql_test_environment.

    CLASS-METHODS:
      class_setup,
      class_teardown.

    METHODS:
      setup,

      create_uuid
        RETURNING
          VALUE(rv_uuid)
            TYPE zif_mig_types=>ty_item_id
        RAISING
          zcx_mig_analysis,

      build_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_analysis_result
        RAISING
          zcx_mig_analysis,

      save_and_read
        FOR TESTING
        RAISING zcx_mig_analysis,

      check_exists
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_duplicate
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_missing
        FOR TESTING
        RAISING zcx_mig_analysis,

      delete_analysis
        FOR TESTING
        RAISING zcx_mig_analysis,

      preserve_all_children
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_analysis_store IMPLEMENTATION.

  METHOD class_setup.

    mo_sql_environment =
      cl_osql_test_environment=>create(
        i_dependency_list = VALUE #(
          ( 'ZMIG_ANL_H'   )
          ( 'ZMIG_ANL_UI'  )
          ( 'ZMIG_ANL_DB'  )
          ( 'ZMIG_ANL_LOG' )
          ( 'ZMIG_ANL_ALV' )
          ( 'ZMIG_ANL_COL' )
          ( 'ZMIG_ANL_SRT' )
          ( 'ZMIG_ANL_FLT' )
          ( 'ZMIG_ANL_EVT' )
          ( 'ZMIG_ANL_EVD' )
          ( 'ZMIG_ANL_REC' )
          ( 'ZMIG_ANL_ANN' )
          ( 'ZMIG_ANL_MSG' )
        )
      ).

  ENDMETHOD.


  METHOD class_teardown.

    IF mo_sql_environment IS BOUND.

      mo_sql_environment->destroy( ).

    ENDIF.

  ENDMETHOD.


  METHOD setup.

    mo_sql_environment->clear_doubles( ).

  ENDMETHOD.

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

    METHOD build_result.

    DATA(lv_analysis_id) =
      CONV zif_mig_types=>ty_analysis_id(
        create_uuid( )
      ).

    DATA(lv_evidence_id) =
      CONV zif_mig_types=>ty_evidence_id(
        create_uuid( )
      ).

    DATA(lv_ui_id) =
      create_uuid( ).

    DATA(lv_db_id) =
      create_uuid( ).

    DATA(lv_logic_id) =
      create_uuid( ).

    DATA(lv_output_id) =
      create_uuid( ).

    DATA(lv_column_id) =
      create_uuid( ).

    DATA(lv_sort_id) =
      create_uuid( ).

    DATA(lv_filter_id) =
      create_uuid( ).

    DATA(lv_event_id) =
      create_uuid( ).

    DATA(lv_recommendation_id) =
      CONV zif_mig_types=>ty_recommendation_id(
        create_uuid( )
      ).

    DATA(lv_annotation_id) =
      create_uuid( ).


    "========================================================
    " Result identity
    "========================================================
    rs_result-analysis_id =
      lv_analysis_id.


    "========================================================
    " Overview
    "========================================================
    rs_result-overview-analysis_id =
      lv_analysis_id.

    rs_result-overview-program_name =
      'ZRMIG_SAMPLE_ALV'.

    rs_result-overview-program_description =
      'Migration sample ALV report'.

    rs_result-overview-status =
      zif_mig_types=>gc_status_completed.

    rs_result-overview-total_source_objects =
      1.

    rs_result-overview-total_ui_filters =
      1.

    rs_result-overview-total_database_objects =
      1.

    rs_result-overview-total_business_logic =
      1.

    rs_result-overview-total_alv_outputs =
      1.

    rs_result-overview-total_alv_columns =
      1.

    rs_result-overview-total_recommendations =
      1.

    rs_result-overview-complexity_score =
      '42'.

    rs_result-overview-readiness_score =
      '78'.

    rs_result-overview-parser_version =
      '1.0'.

    rs_result-overview-rule_version =
      '1.0'.

    rs_result-overview-source_hash =
      '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF'.


    "========================================================
    " UI Filter
    "========================================================
    APPEND VALUE #(
      item_id            = lv_ui_id
      analysis_id        = lv_analysis_id
      evidence_id        = lv_evidence_id
      field_name         = 'P_BUKRS'
      field_kind         = 'PARAMETER'
      reference_table    = 'T001'
      reference_field    = 'BUKRS'
      data_element       = 'BUKRS'
      data_type          = 'CHAR'
      description        = 'Company Code'
      selection_block    = 'MAIN'
      mandatory          = abap_true
      hidden             = abap_false
      checkbox           = abap_false
      multiple_selection = abap_false
      range_supported    = abap_false
      default_value      = '1000'
      confidence         = zif_mig_types=>gc_conf_high
    ) TO rs_result-ui_filters.


    "========================================================
    " Database Object
    "========================================================
    APPEND VALUE #(
      item_id            = lv_db_id
      analysis_id        = lv_analysis_id
      evidence_id        = lv_evidence_id
      object_name        = 'VBAK'
      object_type        = 'TABLE'
      operation          = 'SELECT'
      selected_fields    = 'VBELN,ERDAT,AUART'
      where_fields       = 'BUKRS,ERDAT'
      joined_objects     = 'VBAP'
      join_condition     = 'VBAK~VBELN = VBAP~VBELN'
      aggregation        = 'COUNT'
      containing_routine = 'START-OF-SELECTION'
      dynamic_access     = abap_false
      read_only          = abap_true
      paging_capability  = 'SUPPORTED'
      description        = 'Sales document header'
      confidence         = zif_mig_types=>gc_conf_high
    ) TO rs_result-database_objects.


    "========================================================
    " Business Logic
    "========================================================
    APPEND VALUE #(
      item_id               = lv_logic_id
      analysis_id           = lv_analysis_id
      evidence_id           = lv_evidence_id
      object_name           = 'BAPI_SALESORDER_GETLIST'
      object_type           = 'BAPI'
      container_name        = 'START-OF-SELECTION'
      calling_routine       = 'LOAD_DATA'
      interface_summary     = 'CUSTOMER_NUMBER, SALES_ORGANIZATION'
      description           = 'Read sales orders'
      side_effect           = 'READ_ONLY'
      transaction_dependency = abap_false
      gui_dependency        = abap_false
      reuse_feasibility     = 'HIGH'
      confidence            = zif_mig_types=>gc_conf_high
    ) TO rs_result-business_logic.


    "========================================================
    " ALV Output
    "========================================================
    APPEND VALUE #(
      output_id          = lv_output_id
      analysis_id        = lv_analysis_id
      evidence_id        = lv_evidence_id
      layout_evidence_id = lv_evidence_id
      output_name        = 'RESULT_LIST'
      output_kind        = 'MAIN_ALV'
      framework          = 'CL_GUI_ALV_GRID'
      control_object     = 'GO_GRID'
      output_table       = 'GT_RESULT'
      row_type           = 'TY_RESULT'
      field_catalog      = 'GT_FIELDCAT'
      sort_table         = 'GT_SORT'
      filter_table       = 'GT_FILTER'
      layout_object      = 'GS_LAYOUT'
      variant_object     = 'GS_VARIANT'
      editable           = abap_true
      hierarchical       = abap_false
      zebra              = abap_true
      auto_width         = abap_true
      selection_mode     = 'A'
      confidence         = zif_mig_types=>gc_conf_high
    ) TO rs_result-alv_outputs.


    "========================================================
    " ALV Column
    "========================================================
    APPEND VALUE #(
      item_id         = lv_column_id
      analysis_id     = lv_analysis_id
      output_id       = lv_output_id
      evidence_id     = lv_evidence_id
      field_name      = 'AMOUNT'
      label           = 'Amount'
      position        = 3
      data_type       = 'CURR'
      data_element    = 'WRBTR'
      reference_table = 'BSEG'
      reference_field = 'WRBTR'
      length          = 15
      decimals        = 2
      visible         = abap_true
      key_field       = abap_false
      technical       = abap_false
      editable        = abap_true
      hotspot         = abap_false
      checkbox        = abap_false
      icon            = abap_false
      currency_field  = 'CURRENCY'
      aggregation     = 'SUM'
      source_mapping  = 'GT_RESULT-AMOUNT'
      confidence      = zif_mig_types=>gc_conf_high
    ) TO rs_result-alv_columns.


    "========================================================
    " ALV Sort
    "========================================================
    APPEND VALUE #(
      item_id     = lv_sort_id
      analysis_id = lv_analysis_id
      output_id   = lv_output_id
      evidence_id = lv_evidence_id
      field_name  = 'AMOUNT'
      position    = 1
      ascending   = abap_false
      descending  = abap_true
      subtotal    = abap_true
      confidence  = zif_mig_types=>gc_conf_high
    ) TO rs_result-alv_sorts.


    "========================================================
    " ALV Filter
    "========================================================
    APPEND VALUE #(
      item_id     = lv_filter_id
      analysis_id = lv_analysis_id
      output_id   = lv_output_id
      evidence_id = lv_evidence_id
      field_name  = 'STATUS'
      sign        = 'I'
      option      = 'EQ'
      low_value   = 'A'
      confidence  = zif_mig_types=>gc_conf_high
    ) TO rs_result-alv_filters.


    "========================================================
    " ALV Event
    "========================================================
    APPEND VALUE #(
      item_id        = lv_event_id
      analysis_id    = lv_analysis_id
      output_id      = lv_output_id
      evidence_id    = lv_evidence_id
      event_name     = 'DOUBLE_CLICK'
      handler_name   = 'GO_HANDLER->HANDLE_DOUBLE_CLICK'
      handler_kind   = 'INSTANCE_METHOD'
      control_object = 'GO_GRID'
      gui_dependency = abap_true
      confidence     = zif_mig_types=>gc_conf_high
    ) TO rs_result-alv_events.


    "========================================================
    " Evidence
    "========================================================
    APPEND VALUE #(
      evidence_id    = lv_evidence_id
      analysis_id    = lv_analysis_id
      source_object  = 'ZRMIG_SAMPLE_ALV'
      start_line     = 100
      end_line       = 110
      statement_id   = 25
      statement_text = 'GO_GRID->SET_TABLE_FOR_FIRST_DISPLAY( ).'
      confidence     = zif_mig_types=>gc_conf_high
    ) TO rs_result-evidences.


    "========================================================
    " Recommendation
    "========================================================
    APPEND VALUE #(
      recommendation_id = lv_recommendation_id
      analysis_id        = lv_analysis_id
      source_item_id     = lv_column_id
      evidence_id        = lv_evidence_id
      rule_id            = 'ALV_COLUMN_LINEITEM'
      rule_version       = '1.0'
      target_layer       = zif_mig_types=>gc_target_fiori
      title              = 'Map ALV column to line item'
      display_text       = 'Expose AMOUNT as a Fiori line item.'
      explanation        = 'Visible ALV columns should be represented by UI metadata.'
      severity           = zif_mig_types=>gc_sev_info
      confidence         = zif_mig_types=>gc_conf_high
      review_status      = 'NEW'
      manual_review      = abap_false
    ) TO rs_result-recommendations.


    "========================================================
    " Annotation Proposal
    "========================================================
    APPEND VALUE #(
      item_id           = lv_annotation_id
      analysis_id       = lv_analysis_id
      recommendation_id = lv_recommendation_id
      target_entity     = 'RESULT_LIST'
      target_element    = 'AMOUNT'
      annotation_name   = '@UI.lineItem'
      annotation_value  = 'position=3;label=Amount'
      sequence          = 10
    ) TO rs_result-annotations.


    "========================================================
    " Message
    "========================================================
    APPEND VALUE #(
      message_type  = 'INFO'
      message_code  = 'ANALYSIS_DONE'
      source_object = 'ZRMIG_SAMPLE_ALV'
      source_line   = 1
      message_text  = 'Analysis completed successfully'
    ) TO rs_result-messages.

  ENDMETHOD.

    METHOD save_and_read.

    DATA(ls_expected) =
      build_result( ).

    DATA(lo_store) =
      NEW zcl_mig_analysis_store( ).

    lo_store->zif_mig_analysis_store~save(
      is_result = ls_expected
    ).

    DATA(ls_actual) =
      lo_store->zif_mig_analysis_store~read(
        iv_analysis_id = ls_expected-analysis_id
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_expected-analysis_id
      act = ls_actual-analysis_id
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_expected-overview-program_name
      act = ls_actual-overview-program_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_expected-overview-status
      act = ls_actual-overview-status
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_expected-overview-complexity_score
      act = ls_actual-overview-complexity_score
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_expected-overview-readiness_score
      act = ls_actual-overview-readiness_score
    ).

  ENDMETHOD.

    METHOD check_exists.

    DATA(ls_result) =
      build_result( ).

    DATA(lo_store) =
      NEW zcl_mig_analysis_store( ).

    DATA(lv_exists_before) =
      lo_store->zif_mig_analysis_store~exists(
        iv_analysis_id = ls_result-analysis_id
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lv_exists_before
      msg = 'Analysis không được tồn tại trước SAVE'
    ).

    lo_store->zif_mig_analysis_store~save(
      is_result = ls_result
    ).

    DATA(lv_exists_after) =
      lo_store->zif_mig_analysis_store~exists(
        iv_analysis_id = ls_result-analysis_id
      ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_exists_after
      msg = 'EXISTS phải trả về TRUE sau SAVE'
    ).

  ENDMETHOD.

    METHOD reject_duplicate.

    DATA(ls_result) =
      build_result( ).

    DATA(lo_store) =
      NEW zcl_mig_analysis_store( ).

    lo_store->zif_mig_analysis_store~save(
      is_result = ls_result
    ).

    TRY.

        lo_store->zif_mig_analysis_store~save(
          is_result = ls_result
        ).

        cl_abap_unit_assert=>fail(
          msg = 'Store phải từ chối Analysis ID bị trùng'
        ).

      CATCH zcx_mig_analysis.

        "Expected exception

    ENDTRY.

  ENDMETHOD.

    METHOD reject_missing.

    DATA(lv_missing_analysis_id) =
      CONV zif_mig_types=>ty_analysis_id(
        create_uuid( )
      ).

    DATA(lo_store) =
      NEW zcl_mig_analysis_store( ).

    TRY.

        lo_store->zif_mig_analysis_store~read(
          iv_analysis_id = lv_missing_analysis_id
        ).

        cl_abap_unit_assert=>fail(
          msg = 'READ phải từ chối Analysis ID không tồn tại'
        ).

      CATCH zcx_mig_analysis.

        "Expected exception

    ENDTRY.

  ENDMETHOD.

    METHOD delete_analysis.

    DATA(ls_result) =
      build_result( ).

    DATA(lo_store) =
      NEW zcl_mig_analysis_store( ).

    lo_store->zif_mig_analysis_store~save(
      is_result = ls_result
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lo_store->zif_mig_analysis_store~exists(
        iv_analysis_id = ls_result-analysis_id
      )
    ).

    lo_store->zif_mig_analysis_store~delete(
      iv_analysis_id = ls_result-analysis_id
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_store->zif_mig_analysis_store~exists(
        iv_analysis_id = ls_result-analysis_id
      )
      msg = 'Header vẫn tồn tại sau DELETE'
    ).


    "Bảo đảm child records cũng đã bị xóa
    SELECT COUNT( * )
      FROM zmig_anl_col
      WHERE analysis_id = @ls_result-analysis_id
      INTO @DATA(lv_column_count).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lv_column_count
      msg = 'ALV columns chưa bị xóa'
    ).

    SELECT COUNT( * )
      FROM zmig_anl_rec
      WHERE analysis_id = @ls_result-analysis_id
      INTO @DATA(lv_recommendation_count).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lv_recommendation_count
      msg = 'Recommendations chưa bị xóa'
    ).

    SELECT COUNT( * )
      FROM zmig_anl_ann
      WHERE analysis_id = @ls_result-analysis_id
      INTO @DATA(lv_annotation_count).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lv_annotation_count
      msg = 'Annotations chưa bị xóa'
    ).

  ENDMETHOD.

    METHOD preserve_all_children.

    DATA(ls_expected) =
      build_result( ).

    DATA(lo_store) =
      NEW zcl_mig_analysis_store( ).

    lo_store->zif_mig_analysis_store~save(
      is_result = ls_expected
    ).

    DATA(ls_actual) =
      lo_store->zif_mig_analysis_store~read(
        iv_analysis_id = ls_expected-analysis_id
      ).


    "========================================================
    " Verify every child collection
    "========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-ui_filters )
      msg = 'UI filters không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-database_objects )
      msg = 'Database objects không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-business_logic )
      msg = 'Business logic không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-alv_outputs )
      msg = 'ALV outputs không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-alv_columns )
      msg = 'ALV columns không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-alv_sorts )
      msg = 'ALV sorts không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-alv_filters )
      msg = 'ALV filters không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-alv_events )
      msg = 'ALV events không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-evidences )
      msg = 'Evidences không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-recommendations )
      msg = 'Recommendations không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-annotations )
      msg = 'Annotations không được phục hồi'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_actual-messages )
      msg = 'Messages không được phục hồi'
    ).


    "========================================================
    " Verify renamed ALV column fields
    "========================================================
    READ TABLE ls_actual-alv_columns
      INDEX 1
      INTO DATA(ls_column).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Amount'
      act = ls_column-label
      msg = 'COLUMN_LABEL không được map về LABEL'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = ls_column-position
      msg = 'COLUMN_POSITION không được map về POSITION'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 15
      act = ls_column-length
      msg = 'FIELD_LENGTH không được map về LENGTH'
    ).


    "========================================================
    " Verify renamed ALV sort field
    "========================================================
    READ TABLE ls_actual-alv_sorts
      INDEX 1
      INTO DATA(ls_sort).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = ls_sort-position
      msg = 'SORT_POSITION không được map về POSITION'
    ).


    "========================================================
    " Verify renamed ALV filter field
    "========================================================
    READ TABLE ls_actual-alv_filters
      INDEX 1
      INTO DATA(ls_filter).

    cl_abap_unit_assert=>assert_equals(
      exp = 'EQ'
      act = ls_filter-option
      msg = 'FILTER_OPTION không được map về OPTION'
    ).


    "========================================================
    " Annotation SEQUENCE vẫn giữ nguyên
    "========================================================
    READ TABLE ls_actual-annotations
      INDEX 1
      INTO DATA(ls_annotation).

    cl_abap_unit_assert=>assert_equals(
      exp = 10
      act = ls_annotation-sequence
      msg = 'Annotation SEQUENCE không được bảo toàn'
    ).


    READ TABLE ls_actual-messages
      INDEX 1
      INTO DATA(ls_message).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ANALYSIS_DONE'
      act = ls_message-message_code
    ).

  ENDMETHOD.

ENDCLASS.
