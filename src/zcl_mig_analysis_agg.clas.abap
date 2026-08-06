CLASS zcl_mig_analysis_agg DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_analysis_agg.

  PRIVATE SECTION.
    TYPES:
      ty_message_type TYPE c LENGTH 10,
      ty_message_code TYPE c LENGTH 30.

    CONSTANTS:
      gc_msg_info    TYPE ty_message_type VALUE 'INFO',
      gc_msg_warning TYPE ty_message_type VALUE 'WARNING',
      gc_msg_error   TYPE ty_message_type VALUE 'ERROR'.

    TYPES:
      tt_evidence_id_set TYPE HASHED TABLE OF
        zif_mig_types=>ty_evidence_id
        WITH UNIQUE KEY table_line.

    METHODS append_evidences
      IMPORTING
        it_source TYPE zif_mig_types=>tt_evidence
      CHANGING
        ct_target TYPE zif_mig_types=>tt_evidence
        ct_seen   TYPE tt_evidence_id_set.

    METHODS append_messages
      IMPORTING
        it_source TYPE zif_mig_types=>tt_message
      CHANGING
        ct_target TYPE zif_mig_types=>tt_message.

    METHODS build_overview
      IMPORTING
        iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id
        it_source_units TYPE zif_mig_types=>tt_source_unit
        is_result       TYPE zif_mig_types=>ty_analysis_result
      RETURNING
        VALUE(rs_overview)
          TYPE zif_mig_types=>ty_overview.

    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

    METHODS build_quality_messages
      CHANGING
        cs_result TYPE zif_mig_types=>ty_analysis_result.

    METHODS add_quality_message
      IMPORTING
        iv_message_type  TYPE ty_message_type
        iv_message_code  TYPE ty_message_code
        iv_source_object TYPE progname
        iv_source_line   TYPE i
        iv_message_text  TYPE string
      CHANGING
        ct_messages TYPE zif_mig_types=>tt_message.

    METHODS get_evidence_location
      IMPORTING
        iv_evidence_id TYPE zif_mig_types=>ty_evidence_id
        it_evidences   TYPE zif_mig_types=>tt_evidence
      EXPORTING
        ev_source_object TYPE progname
        ev_source_line   TYPE i.

    METHODS determine_status
      IMPORTING
        it_messages TYPE zif_mig_types=>tt_message
      RETURNING
        VALUE(rv_status) TYPE zif_mig_types=>ty_status.

ENDCLASS.

CLASS zcl_mig_analysis_agg IMPLEMENTATION.

  METHOD zif_mig_analysis_agg~analyze.

    IF it_source_units IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        program_name = ''
      ).

    ENDIF.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    lv_analysis_id = iv_analysis_id.

    IF lv_analysis_id IS INITIAL.

      READ TABLE it_source_units
        INDEX 1
        INTO DATA(ls_first_source_unit).

      DATA lv_root_program TYPE progname.

      IF sy-subrc = 0.

        lv_root_program =
          ls_first_source_unit-source_object-object_name.

      ENDIF.

      lv_analysis_id =
        create_uuid(
          iv_source_object = lv_root_program
        ).

    ENDIF.

    rs_result-analysis_id =
      lv_analysis_id.

    "==========================================================
    " Preserve source tree
    "==========================================================
    CLEAR rs_result-source_objects.

    LOOP AT it_source_units
      ASSIGNING FIELD-SYMBOL(<source_unit_for_result>).

      DATA(ls_source_object) =
        <source_unit_for_result>-source_object.

      "Toàn bộ source objects thuộc cùng analysis snapshot
      ls_source_object-analysis_id =
        lv_analysis_id.

      "Caller có thể chưa tạo ItemId, ví dụ Aggregator unit test
      IF ls_source_object-item_id IS INITIAL.

        ls_source_object-item_id =
          create_uuid(
            iv_source_object =
              ls_source_object-object_name
          ).

      ENDIF.

      "Luôn tính lại để metadata khớp runtime source
      ls_source_object-line_count =
        lines(
          ls_source_object-source_lines
        ).

      APPEND ls_source_object
        TO rs_result-source_objects.

    ENDLOOP.

    SORT rs_result-source_objects
      BY include_depth
         parent_object
         object_name.


    "========================================================
    " Analyzer instances
    "========================================================
    DATA(lo_ui_analyzer) =
      NEW zcl_mig_ui_filter_analyzer( ).

    DATA(lo_db_analyzer) =
      NEW zcl_mig_db_analyzer( ).

    DATA(lo_logic_analyzer) =
      NEW zcl_mig_logic_analyzer( ).

    DATA(lo_alv_analyzer) =
      NEW zcl_mig_alv_analyzer( ).

    DATA(lo_fcat_analyzer) =
      NEW zcl_mig_alv_fcat_analyzer( ).

    DATA(lo_row_analyzer) =
      NEW zcl_mig_alv_row_analyzer( ).

    DATA(lo_sf_analyzer) =
      NEW zcl_mig_alv_sf_analyzer( ).

    DATA(lo_le_analyzer) =
      NEW zcl_mig_alv_le_analyzer( ).


    "========================================================
    " 1. UI & Selection Screen
    "========================================================
    DATA(ls_ui_result) =
      lo_ui_analyzer->zif_mig_ui_filter_analyzer~analyze(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
      ).

    rs_result-ui_filters =
      ls_ui_result-ui_filters.


    "========================================================
    " 2. Database
    "========================================================
    DATA(ls_db_result) =
      lo_db_analyzer->zif_mig_db_analyzer~analyze(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
      ).

    rs_result-database_objects =
      ls_db_result-database_objects.


    "========================================================
    " 3. Business Logic
    "========================================================
    DATA(ls_logic_result) =
      lo_logic_analyzer->zif_mig_logic_analyzer~analyze(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
      ).

    rs_result-business_logic =
      ls_logic_result-business_logic.


    "========================================================
    " 4. ALV Invocation
    "
    " Phải chạy trước các ALV analyzer khác vì bước này tạo:
    " - OUTPUT_ID
    " - FIELD_CATALOG
    " - SORT_TABLE
    " - FILTER_TABLE
    " - LAYOUT_OBJECT
    " - CONTROL_OBJECT
    "========================================================
    DATA(ls_alv_result) =
      lo_alv_analyzer->zif_mig_alv_analyzer~analyze(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
      ).


    "========================================================
    " 5. ALV Field Catalog
    "========================================================
    DATA(ls_fcat_result) =
      lo_fcat_analyzer->zif_mig_alv_fcat_analyzer~analyze(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
        it_alv_outputs  = ls_alv_result-alv_outputs
      ).

    rs_result-alv_columns =
      ls_fcat_result-alv_columns.

     "Fallback for SALV / ALV without explicit field catalog
        DATA(ls_row_result) =
          lo_row_analyzer->zif_mig_alv_fcat_analyzer~analyze(
            iv_analysis_id  = lv_analysis_id
            it_source_units = it_source_units
            it_alv_outputs  = ls_alv_result-alv_outputs
          ).

        APPEND LINES OF
          ls_row_result-alv_columns
          TO rs_result-alv_columns.


    "========================================================
    " 6. ALV Sort & Filter
    "========================================================
    DATA(ls_sf_result) =
      lo_sf_analyzer->zif_mig_alv_sf_analyzer~analyze(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
        it_alv_outputs  = ls_alv_result-alv_outputs
      ).

    rs_result-alv_sorts =
      ls_sf_result-alv_sorts.

    rs_result-alv_filters =
      ls_sf_result-alv_filters.


    "========================================================
    " 7. ALV Layout & Event
    "
    " Analyzer này trả lại ALV_OUTPUT đã enrich:
    " - ZEBRA
    " - AUTO_WIDTH
    " - EDITABLE
    " - SELECTION_MODE
    " - LAYOUT_EVIDENCE_ID
    "========================================================
    DATA(ls_le_result) =
      lo_le_analyzer->zif_mig_alv_le_analyzer~analyze(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
        it_alv_outputs  = ls_alv_result-alv_outputs
      ).

    "Phải lấy output từ LE result, không lấy lại ALV result cũ
    rs_result-alv_outputs =
      ls_le_result-alv_outputs.

    rs_result-alv_events =
      ls_le_result-alv_events.


    "========================================================
    " Merge Evidence
    "========================================================
    DATA lt_seen_evidence_ids
      TYPE tt_evidence_id_set.

    append_evidences(
      EXPORTING
        it_source = ls_ui_result-evidences
      CHANGING
        ct_target = rs_result-evidences
        ct_seen   = lt_seen_evidence_ids
    ).

    append_evidences(
      EXPORTING
        it_source = ls_db_result-evidences
      CHANGING
        ct_target = rs_result-evidences
        ct_seen   = lt_seen_evidence_ids
    ).

    append_evidences(
      EXPORTING
        it_source = ls_logic_result-evidences
      CHANGING
        ct_target = rs_result-evidences
        ct_seen   = lt_seen_evidence_ids
    ).

    append_evidences(
      EXPORTING
        it_source = ls_alv_result-evidences
      CHANGING
        ct_target = rs_result-evidences
        ct_seen   = lt_seen_evidence_ids
    ).

    append_evidences(
      EXPORTING
        it_source = ls_fcat_result-evidences
      CHANGING
        ct_target = rs_result-evidences
        ct_seen   = lt_seen_evidence_ids
    ).

    append_evidences(
      EXPORTING
        it_source = ls_sf_result-evidences
      CHANGING
        ct_target = rs_result-evidences
        ct_seen   = lt_seen_evidence_ids
    ).

    append_evidences(
      EXPORTING
        it_source = ls_le_result-evidences
      CHANGING
        ct_target = rs_result-evidences
        ct_seen   = lt_seen_evidence_ids
    ).


    "========================================================
    " Merge Messages
    "========================================================
    append_messages(
      EXPORTING
        it_source = ls_ui_result-messages
      CHANGING
        ct_target = rs_result-messages
    ).

    append_messages(
      EXPORTING
        it_source = ls_db_result-messages
      CHANGING
        ct_target = rs_result-messages
    ).

    append_messages(
      EXPORTING
        it_source = ls_logic_result-messages
      CHANGING
        ct_target = rs_result-messages
    ).

    append_messages(
      EXPORTING
        it_source = ls_alv_result-messages
      CHANGING
        ct_target = rs_result-messages
    ).

    append_messages(
      EXPORTING
        it_source = ls_fcat_result-messages
      CHANGING
        ct_target = rs_result-messages
    ).

    append_messages(
      EXPORTING
        it_source = ls_sf_result-messages
      CHANGING
        ct_target = rs_result-messages
    ).

    append_messages(
      EXPORTING
        it_source = ls_le_result-messages
      CHANGING
        ct_target = rs_result-messages
    ).

    "==========================================================
    " Build quality/limitation messages
    "==========================================================
    build_quality_messages(
      CHANGING
        cs_result = rs_result
    ).

    SORT rs_result-messages
      BY message_type
         message_code
         source_object
         source_line.


        "========================================================
        " Stable sorting
        "========================================================
        SORT rs_result-ui_filters
          BY field_name.

        SORT rs_result-database_objects
          BY object_name
             operation.

        SORT rs_result-business_logic
          BY object_type
             object_name.

        SORT rs_result-alv_outputs
          BY framework
             output_name.

        SORT rs_result-alv_columns
          BY output_id
             position
             field_name.

        SORT rs_result-alv_sorts
          BY output_id
             position
             field_name.

        SORT rs_result-alv_filters
          BY output_id
             field_name
             option.

        SORT rs_result-alv_events
          BY output_id
             event_name
             handler_name.

        SORT rs_result-evidences
          BY source_object
             start_line
             statement_id.

    "==========================================================
    " Build Overview
    "==========================================================
    rs_result-overview =
      build_overview(
        iv_analysis_id  = lv_analysis_id
        it_source_units = it_source_units
        is_result       = rs_result
      ).


    "==========================================================
    " Calculate Complexity and Readiness
    "
    " Phải chạy sau BUILD_OVERVIEW vì engine cập nhật trực tiếp:
    " - OVERVIEW-COMPLEXITY_SCORE
    " - OVERVIEW-READINESS_SCORE
    "==========================================================
    DATA(lo_complexity_engine) =
      NEW zcl_mig_complexity_engine( ).

    lo_complexity_engine->zif_mig_complexity_engine~enrich(
      CHANGING
        cs_result = rs_result
    ).
    DATA(lo_recommend_engine) =
      NEW zcl_mig_recommend_engine( ).

    lo_recommend_engine->zif_mig_recommend_engine~enrich(
      CHANGING
        cs_result = rs_result
    ).

  ENDMETHOD.

    METHOD append_evidences.

    LOOP AT it_source
      ASSIGNING FIELD-SYMBOL(<evidence>).

      INSERT <evidence>-evidence_id
        INTO TABLE ct_seen.

      IF sy-subrc <> 0.

        "Evidence ID đã tồn tại
        CONTINUE.

      ENDIF.

      APPEND <evidence>
        TO ct_target.

    ENDLOOP.

  ENDMETHOD.

    METHOD append_messages.

    APPEND LINES OF it_source
      TO ct_target.

  ENDMETHOD.

    METHOD build_overview.

  CLEAR rs_overview.

  "==========================================================
  " Analysis identity
  "==========================================================
  rs_overview-analysis_id =
    iv_analysis_id.


  "==========================================================
  " Root program
  "
  " Source unit đầu tiên được xem là chương trình gốc.
  " Các dòng sau có thể là INCLUDE hoặc source bổ sung.
  "==========================================================
  READ TABLE it_source_units
    INDEX 1
    INTO DATA(ls_root_source).

  IF sy-subrc = 0.

    rs_overview-program_name =
      ls_root_source-source_object-object_name.

  ENDIF.


  "Hiện Source Object chưa cung cấp description ổn định.
  "Application Service sẽ bổ sung metadata ở bước sau.
  CLEAR rs_overview-program_description.


  "==========================================================
  " Aggregate counters
  "==========================================================
  rs_overview-total_source_objects =
    lines( it_source_units ).

  rs_overview-total_ui_filters =
    lines( is_result-ui_filters ).

  rs_overview-total_database_objects =
    lines( is_result-database_objects ).

  rs_overview-total_business_logic =
    lines( is_result-business_logic ).

  rs_overview-total_alv_outputs =
    lines( is_result-alv_outputs ).

  rs_overview-total_alv_columns =
    lines( is_result-alv_columns ).

  rs_overview-total_recommendations =
    lines( is_result-recommendations ).


  "==========================================================
  " Analysis status
  "==========================================================
  rs_overview-status =
  determine_status(
    it_messages = is_result-messages
  ).


  "==========================================================
  " Versioning
  "==========================================================
  rs_overview-parser_version =
    '1.0'.

  rs_overview-rule_version =
    '1.0'.


  "==========================================================
  " Scores
  "
  " Sẽ được Complexity và Recommendation Engine tính ở bước
  " tiếp theo. Aggregator không tự tạo score giả.
  "==========================================================
  CLEAR:
    rs_overview-complexity_score,
    rs_overview-readiness_score.


  "==========================================================
  " Source hash
  "
  " Sẽ được Hash Service/Application Service tính từ toàn bộ
  " source program và INCLUDE.
  "==========================================================
  CLEAR rs_overview-source_hash.

ENDMETHOD.

METHOD get_evidence_location.

  CLEAR:
    ev_source_object,
    ev_source_line.

  IF iv_evidence_id IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE it_evidences
    WITH KEY
      evidence_id = iv_evidence_id
    INTO DATA(ls_evidence).

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  ev_source_object =
    ls_evidence-source_object.

  ev_source_line =
    ls_evidence-start_line.

ENDMETHOD.

METHOD add_quality_message.

  IF iv_message_code IS INITIAL
     OR iv_message_text IS INITIAL.

    RETURN.

  ENDIF.

  READ TABLE ct_messages
    WITH KEY
      message_type  = iv_message_type
      message_code  = iv_message_code
      source_object = iv_source_object
      source_line   = iv_source_line
    TRANSPORTING NO FIELDS.

  IF sy-subrc = 0.
    RETURN.
  ENDIF.

  APPEND VALUE #(
    message_type  = iv_message_type
    message_code  = iv_message_code
    source_object = iv_source_object
    source_line   = iv_source_line
    message_text  = iv_message_text
  ) TO ct_messages.

ENDMETHOD.

METHOD build_quality_messages.

  "==========================================================
  " UI: SELECT-OPTIONS reference chưa resolve
  "==========================================================
  LOOP AT cs_result-ui_filters
    ASSIGNING FIELD-SYMBOL(<ui_filter>)
    WHERE field_kind = 'SELECT_OPTIONS'.

    IF <ui_filter>-reference_table IS NOT INITIAL
       AND <ui_filter>-reference_field IS NOT INITIAL.

      CONTINUE.

    ENDIF.

    DATA:
      lv_ui_source TYPE progname,
      lv_ui_line   TYPE i.

    get_evidence_location(
      EXPORTING
        iv_evidence_id = <ui_filter>-evidence_id
        it_evidences   = cs_result-evidences
      IMPORTING
        ev_source_object = lv_ui_source
        ev_source_line   = lv_ui_line
    ).

    add_quality_message(
      EXPORTING
        iv_message_type  = gc_msg_warning
        iv_message_code  = 'UI_REFERENCE_UNRESOLVED'
        iv_source_object = lv_ui_source
        iv_source_line   = lv_ui_line
        iv_message_text  =
          |Reference type of selection field {
             <ui_filter>-field_name } could not be resolved completely.|
      CHANGING
        ct_messages = cs_result-messages
    ).

  ENDLOOP.


  "==========================================================
  " Database: dynamic table/view access
  "==========================================================
  LOOP AT cs_result-database_objects
    ASSIGNING FIELD-SYMBOL(<database_object>)
    WHERE dynamic_access = abap_true.

    DATA:
      lv_db_source TYPE progname,
      lv_db_line   TYPE i.

    get_evidence_location(
      EXPORTING
        iv_evidence_id = <database_object>-evidence_id
        it_evidences   = cs_result-evidences
      IMPORTING
        ev_source_object = lv_db_source
        ev_source_line   = lv_db_line
    ).

    add_quality_message(
      EXPORTING
        iv_message_type  = gc_msg_warning
        iv_message_code  = 'DB_DYNAMIC_ACCESS'
        iv_source_object = lv_db_source
        iv_source_line   = lv_db_line
        iv_message_text  =
          |Dynamic database access requires manual review: {
             <database_object>-object_name }.|
      CHANGING
        ct_messages = cs_result-messages
    ).

  ENDLOOP.


  "==========================================================
  " Business logic: side effect chỉ là heuristic hint
  "
  "INFO không làm status thành WARNING.
  "==========================================================
  LOOP AT cs_result-business_logic
    ASSIGNING FIELD-SYMBOL(<business_logic>)
    WHERE side_effect = 'REVIEW'.

    DATA:
      lv_logic_source TYPE progname,
      lv_logic_line   TYPE i.

    get_evidence_location(
      EXPORTING
        iv_evidence_id = <business_logic>-evidence_id
        it_evidences   = cs_result-evidences
      IMPORTING
        ev_source_object = lv_logic_source
        ev_source_line   = lv_logic_line
    ).

    add_quality_message(
      EXPORTING
        iv_message_type  = gc_msg_info
        iv_message_code  = 'LOGIC_SIDE_EFFECT_REVIEW'
        iv_source_object = lv_logic_source
        iv_source_line   = lv_logic_line
        iv_message_text  =
          |Side effect of {
             <business_logic>-object_name
           } requires manual review.|
      CHANGING
        ct_messages = cs_result-messages
    ).

  ENDLOOP.


  "==========================================================
  " ALV output completeness
  "==========================================================
  LOOP AT cs_result-alv_outputs
    ASSIGNING FIELD-SYMBOL(<alv_output>).

    DATA:
      lv_alv_source TYPE progname,
      lv_alv_line   TYPE i.

    get_evidence_location(
      EXPORTING
        iv_evidence_id = <alv_output>-evidence_id
        it_evidences   = cs_result-evidences
      IMPORTING
        ev_source_object = lv_alv_source
        ev_source_line   = lv_alv_line
    ).


    "--------------------------------------------------------
    " Không resolve được output table
    "--------------------------------------------------------
    IF <alv_output>-output_table IS INITIAL.

      add_quality_message(
        EXPORTING
          iv_message_type  = gc_msg_warning
          iv_message_code  = 'ALV_TABLE_UNRESOLVED'
          iv_source_object = lv_alv_source
          iv_source_line   = lv_alv_line
          iv_message_text  =
            |Output table of {
               <alv_output>-framework
             } could not be resolved.|
        CHANGING
          ct_messages = cs_result-messages
      ).

    ENDIF.


    "--------------------------------------------------------
    " Không có column fact cho output
    "--------------------------------------------------------
    READ TABLE cs_result-alv_columns
      WITH KEY
        output_id = <alv_output>-output_id
      TRANSPORTING NO FIELDS.

    IF sy-subrc <> 0.

      add_quality_message(
        EXPORTING
          iv_message_type  = gc_msg_warning
          iv_message_code  = 'ALV_COLUMNS_UNRESOLVED'
          iv_source_object = lv_alv_source
          iv_source_line   = lv_alv_line
          iv_message_text  =
            |No static column metadata could be resolved for {
               <alv_output>-output_name }.|
        CHANGING
          ct_messages = cs_result-messages
      ).

    ENDIF.

  ENDLOOP.

ENDMETHOD.

METHOD determine_status.

  rv_status =
    zif_mig_types=>gc_status_completed.

  LOOP AT it_messages
    ASSIGNING FIELD-SYMBOL(<message>).

    DATA(lv_message_type) =
      to_upper(
        CONV string(
          <message>-message_type
        )
      ).

    CASE lv_message_type.

      WHEN 'ERROR'
        OR 'E'.

        rv_status =
          zif_mig_types=>gc_status_failed.

        RETURN.


      WHEN 'WARNING'
        OR 'W'.

        rv_status =
          zif_mig_types=>gc_status_warning.

    ENDCASE.

  ENDLOOP.

ENDMETHOD.

    METHOD create_uuid.

    TRY.

        rv_uuid =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid       = zcx_mig_analysis=>analysis_failed
          previous     = lx_uuid
          program_name = iv_source_object
        ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
