CLASS ltc_analysis_aggregator DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS add_program
      IMPORTING
        iv_program_name TYPE progname
      CHANGING
        ct_source_units TYPE zif_mig_types=>tt_source_unit
      RAISING
        zcx_mig_analysis.

    METHODS get_result
      RETURNING
        VALUE(rs_result)
          TYPE zif_mig_types=>ty_analysis_result
      RAISING
        zcx_mig_analysis.

    METHODS aggregate_all_domains
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS preserve_alv_enrichment
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS use_single_analysis_id
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS merge_unique_evidence
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS build_overview
      FOR TESTING
      RAISING zcx_mig_analysis.


      METHODS analyze_source
  IMPORTING
    iv_program_name TYPE progname
    it_source       TYPE zif_mig_types=>tt_source_line
  RETURNING
    VALUE(rs_result)
      TYPE zif_mig_types=>ty_analysis_result
  RAISING
    zcx_mig_analysis.

METHODS completed_without_warning
  FOR TESTING
  RAISING zcx_mig_analysis.

METHODS warning_for_partial_alv
  FOR TESTING
  RAISING zcx_mig_analysis.

METHODS info_does_not_change_status
  FOR TESTING
  RAISING zcx_mig_analysis.

  METHODS preserve_source_objects
  FOR TESTING
  RAISING zcx_mig_analysis.
  METHODS preserve_nested_include
  FOR TESTING
  RAISING zcx_mig_analysis.


ENDCLASS.

CLASS ltc_analysis_aggregator IMPLEMENTATION.

  METHOD add_program.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lt_source) =
      lo_source_repo->zif_mig_source_repo~read_program(
        iv_program_name = iv_program_name
      ).

    DATA(ls_scan_result) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object = iv_program_name
        it_source        = lt_source
      ).

    DATA(ls_normalized) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result = ls_scan_result
      ).

    APPEND VALUE #(
      source_object = VALUE #(
        object_name  = iv_program_name
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized
    ) TO ct_source_units.

  ENDMETHOD.

    METHOD get_result.

    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.

    add_program(
      EXPORTING
        iv_program_name = 'ZRMIG_SAMPLE_FILTER'
      CHANGING
        ct_source_units = lt_source_units
    ).

    add_program(
      EXPORTING
        iv_program_name = 'ZRMIG_SAMPLE_DB'
      CHANGING
        ct_source_units = lt_source_units
    ).

    add_program(
      EXPORTING
        iv_program_name = 'ZRMIG_SAMPLE_LOGIC'
      CHANGING
        ct_source_units = lt_source_units
    ).

    add_program(
      EXPORTING
        iv_program_name = 'ZRMIG_SAMPLE_ALV'
      CHANGING
        ct_source_units = lt_source_units
    ).

    DATA(lo_aggregator) =
      NEW zcl_mig_analysis_agg( ).

    rs_result =
      lo_aggregator->zif_mig_analysis_agg~analyze(
        it_source_units = lt_source_units
      ).

  ENDMETHOD.

    METHOD aggregate_all_domains.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-analysis_id
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-ui_filters
      msg = 'Aggregator chưa gom UI filters'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-database_objects
      msg = 'Aggregator chưa gom database objects'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-business_logic
      msg = 'Aggregator chưa gom business logic'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_outputs
      msg = 'Aggregator chưa gom ALV outputs'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_columns
      msg = 'Aggregator chưa gom ALV columns'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_sorts
      msg = 'Aggregator chưa gom ALV sorts'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_filters
      msg = 'Aggregator chưa gom ALV filters'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-alv_events
      msg = 'Aggregator chưa gom ALV events'
    ).

  ENDMETHOD.

    METHOD preserve_alv_enrichment.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-alv_outputs
      WITH KEY
        framework = 'CL_GUI_ALV_GRID'
      INTO DATA(ls_grid).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy CL_GUI_ALV_GRID'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GO_GRID'
      act = ls_grid-control_object
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_grid-zebra
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_grid-auto_width
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_grid-editable
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'A'
      act = ls_grid-selection_mode
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_grid-layout_evidence_id
    ).

  ENDMETHOD.

   METHOD use_single_analysis_id.

  DATA(ls_result) = get_result( ).

  DATA(lv_analysis_id) =
    ls_result-analysis_id.


  "==========================================================
  " Các fact có ANALYSIS_ID trực tiếp
  "==========================================================
  LOOP AT ls_result-ui_filters
    ASSIGNING FIELD-SYMBOL(<ui_filter>).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = <ui_filter>-analysis_id
      msg = |UI filter dùng Analysis ID khác: {
        <ui_filter>-field_name }|
    ).

  ENDLOOP.


  LOOP AT ls_result-database_objects
    ASSIGNING FIELD-SYMBOL(<database_object>).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = <database_object>-analysis_id
      msg = |Database object dùng Analysis ID khác: {
        <database_object>-object_name }|
    ).

  ENDLOOP.


  LOOP AT ls_result-business_logic
    ASSIGNING FIELD-SYMBOL(<business_logic>).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = <business_logic>-analysis_id
      msg = |Business logic dùng Analysis ID khác: {
        <business_logic>-object_name }|
    ).

  ENDLOOP.


  LOOP AT ls_result-alv_outputs
    ASSIGNING FIELD-SYMBOL(<alv_output>).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = <alv_output>-analysis_id
      msg = |ALV output dùng Analysis ID khác: {
        <alv_output>-output_name }|
    ).

  ENDLOOP.


  "==========================================================
  " Tạo map OUTPUT_ID → ANALYSIS_ID
  "
  " ALV Column, Sort, Filter và Event không lưu ANALYSIS_ID
  " trực tiếp. Chúng liên kết thông qua OUTPUT_ID.
  "==========================================================
  TYPES:
    BEGIN OF ty_output_link,
      output_id   TYPE zif_mig_types=>ty_item_id,
      analysis_id TYPE zif_mig_types=>ty_analysis_id,
    END OF ty_output_link,

    tt_output_link TYPE HASHED TABLE OF ty_output_link
      WITH UNIQUE KEY output_id.

  DATA lt_output_links TYPE tt_output_link.

  LOOP AT ls_result-alv_outputs
    ASSIGNING <alv_output>.

    INSERT VALUE #(
      output_id   = <alv_output>-output_id
      analysis_id = <alv_output>-analysis_id
    ) INTO TABLE lt_output_links.

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'OUTPUT_ID bị trùng trong danh sách ALV outputs'
    ).

  ENDLOOP.


  "==========================================================
  " Kiểm tra ALV Columns
  "==========================================================
  LOOP AT ls_result-alv_columns
    ASSIGNING FIELD-SYMBOL(<alv_column>).

    READ TABLE lt_output_links
      WITH TABLE KEY
        output_id = <alv_column>-output_id
      INTO DATA(ls_column_link).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = |ALV column chưa liên kết với output: {
        <alv_column>-field_name }|
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = ls_column_link-analysis_id
      msg = |ALV column liên kết sai Analysis ID: {
        <alv_column>-field_name }|
    ).

  ENDLOOP.


  "==========================================================
  " Kiểm tra ALV Sorts
  "==========================================================
  LOOP AT ls_result-alv_sorts
    ASSIGNING FIELD-SYMBOL(<alv_sort>).

    READ TABLE lt_output_links
      WITH TABLE KEY
        output_id = <alv_sort>-output_id
      INTO DATA(ls_sort_link).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = |ALV sort chưa liên kết với output: {
        <alv_sort>-field_name }|
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = ls_sort_link-analysis_id
      msg = |ALV sort liên kết sai Analysis ID: {
        <alv_sort>-field_name }|
    ).

  ENDLOOP.


  "==========================================================
  " Kiểm tra ALV Filters
  "==========================================================
  LOOP AT ls_result-alv_filters
    ASSIGNING FIELD-SYMBOL(<alv_filter>).

    READ TABLE lt_output_links
      WITH TABLE KEY
        output_id = <alv_filter>-output_id
      INTO DATA(ls_filter_link).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = |ALV filter chưa liên kết với output: {
        <alv_filter>-field_name }|
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = ls_filter_link-analysis_id
      msg = |ALV filter liên kết sai Analysis ID: {
        <alv_filter>-field_name }|
    ).

  ENDLOOP.


  "==========================================================
  " Kiểm tra ALV Events
  "==========================================================
  LOOP AT ls_result-alv_events
    ASSIGNING FIELD-SYMBOL(<alv_event>).

    READ TABLE lt_output_links
      WITH TABLE KEY
        output_id = <alv_event>-output_id
      INTO DATA(ls_event_link).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = |ALV event chưa liên kết với output: {
        <alv_event>-event_name }|
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = ls_event_link-analysis_id
      msg = |ALV event liên kết sai Analysis ID: {
        <alv_event>-event_name }|
    ).

  ENDLOOP.

ENDMETHOD.

    METHOD merge_unique_evidence.

    DATA(ls_result) = get_result( ).

    DATA lt_evidence_ids
      TYPE HASHED TABLE OF
        zif_mig_types=>ty_evidence_id
        WITH UNIQUE KEY table_line.

    LOOP AT ls_result-evidences
      ASSIGNING FIELD-SYMBOL(<evidence>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <evidence>-evidence_id
      ).

      INSERT <evidence>-evidence_id
        INTO TABLE lt_evidence_ids.

      cl_abap_unit_assert=>assert_equals(
        exp = 0
        act = sy-subrc
        msg = 'Evidence ID bị trùng trong aggregate result'
      ).

      cl_abap_unit_assert=>assert_equals(
        exp = ls_result-analysis_id
        act = <evidence>-analysis_id
      ).

    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_result-evidences )
      act = lines( lt_evidence_ids )
    ).

  ENDMETHOD.

    METHOD build_overview.

  DATA(ls_result) = get_result( ).

  cl_abap_unit_assert=>assert_equals(
    exp = ls_result-analysis_id
    act = ls_result-overview-analysis_id
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'ZRMIG_SAMPLE_FILTER'
    act = ls_result-overview-program_name
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 4
    act = ls_result-overview-total_source_objects
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lines( ls_result-ui_filters )
    act = ls_result-overview-total_ui_filters
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lines( ls_result-database_objects )
    act = ls_result-overview-total_database_objects
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lines( ls_result-business_logic )
    act = ls_result-overview-total_business_logic
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lines( ls_result-alv_outputs )
    act = ls_result-overview-total_alv_outputs
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lines( ls_result-alv_columns )
    act = ls_result-overview-total_alv_columns
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lines( ls_result-recommendations )
    act = ls_result-overview-total_recommendations
  ).

      cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-overview-status
      msg = 'Overview status chưa được xác định'
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = '1.0'
    act = ls_result-overview-parser_version
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = '1.0'
    act = ls_result-overview-rule_version
  ).
  cl_abap_unit_assert=>assert_true(
  act = xsdbool(
    ls_result-overview-complexity_score > 0
  )
).

cl_abap_unit_assert=>assert_true(
  act = xsdbool(
    ls_result-overview-readiness_score >= 0
    AND ls_result-overview-readiness_score <= 100
  )
).
cl_abap_unit_assert=>assert_not_initial(
  act = ls_result-recommendations
  msg = 'Aggregator chưa sinh recommendations'
).

cl_abap_unit_assert=>assert_not_initial(
  act = ls_result-annotations
  msg = 'Aggregator chưa sinh annotation proposals'
).



ENDMETHOD.

METHOD analyze_source.

  DATA(lo_scanner) =
    NEW zcl_mig_abap_scanner( ).

  DATA(ls_scan_result) =
    lo_scanner->zif_mig_abap_scanner~scan(
      iv_source_object = iv_program_name
      it_source        = it_source
    ).

  DATA(lo_normalizer) =
    NEW zcl_mig_stmt_normalizer( ).

  DATA(ls_normalized) =
    lo_normalizer->zif_mig_stmt_normalizer~normalize(
      is_scan_result = ls_scan_result
    ).

  DATA lt_source_units
    TYPE zif_mig_types=>tt_source_unit.

  APPEND VALUE #(
    source_object = VALUE #(
      object_name  = iv_program_name
      object_type  = 'PROGRAM'
      source_lines = it_source
    )
    scan_result = ls_normalized
  ) TO lt_source_units.

  DATA(lo_aggregator) =
    NEW zcl_mig_analysis_agg( ).

  rs_result =
    lo_aggregator->zif_mig_analysis_agg~analyze(
      it_source_units = lt_source_units
    ).

ENDMETHOD.

METHOD completed_without_warning.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_COMPLETE'.

  DATA(lt_source) =
    VALUE zif_mig_types=>tt_source_line(
      (
        source_object = gc_program
        line_number   = 1
        source_text   = `REPORT zrmig_ut_complete.`
      )
      (
        source_object = gc_program
        line_number   = 2
        source_text   = `PARAMETERS p_max TYPE i DEFAULT 100.`
      )
    ).

  DATA(ls_result) =
    analyze_source(
      iv_program_name = gc_program
      it_source       = lt_source
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = zif_mig_types=>gc_status_completed
    act = ls_result-overview-status
    msg = 'Report fully analyzed phải có status COMPLETED'
  ).

  cl_abap_unit_assert=>assert_initial(
    act = ls_result-messages
    msg = 'Report đơn giản không được sinh quality warning'
  ).

ENDMETHOD.

METHOD warning_for_partial_alv.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_PARTIAL_ALV'.

  DATA(lt_source) =
    VALUE zif_mig_types=>tt_source_line(
      (
        source_object = gc_program
        line_number   = 1
        source_text   = `REPORT zrmig_ut_partial_alv.`
      )
      (
        source_object = gc_program
        line_number   = 2
        source_text   = `DATA gt_data TYPE STANDARD TABLE OF t001 WITH EMPTY KEY.`
      )
      (
        source_object = gc_program
        line_number   = 3
        source_text   = `START-OF-SELECTION.`
      )
      (
        source_object = gc_program
        line_number   = 4
        source_text   =
          `cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_salv) CHANGING t_table = gt_data ).`
      )
    ).

  DATA(ls_result) =
    analyze_source(
      iv_program_name = gc_program
      it_source       = lt_source
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = zif_mig_types=>gc_status_warning
    act = ls_result-overview-status
    msg = 'SALV columns chưa resolve phải có status WARNING'
  ).

  READ TABLE ls_result-messages
    WITH KEY
      message_code = 'ALV_COLUMNS_UNRESOLVED'
    TRANSPORTING NO FIELDS.

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Thiếu message ALV_COLUMNS_UNRESOLVED'
  ).

ENDMETHOD.

METHOD info_does_not_change_status.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_INFO_ONLY'.

  DATA(lt_source) =
    VALUE zif_mig_types=>tt_source_line(
      (
        source_object = gc_program
        line_number   = 1
        source_text   = `REPORT zrmig_ut_info_only.`
      )
      (
        source_object = gc_program
        line_number   = 2
        source_text   = `START-OF-SELECTION.`
      )
      (
        source_object = gc_program
        line_number   = 3
        source_text   = `lo_service->save_document( ).`
      )
    ).

  DATA(ls_result) =
    analyze_source(
      iv_program_name = gc_program
      it_source       = lt_source
    ).

  READ TABLE ls_result-messages
    WITH KEY
      message_code = 'LOGIC_SIDE_EFFECT_REVIEW'
    TRANSPORTING NO FIELDS.

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Thiếu INFO message cho side-effect review'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = zif_mig_types=>gc_status_completed
    act = ls_result-overview-status
    msg = 'INFO message không được đổi status thành WARNING'
  ).

ENDMETHOD.

METHOD preserve_source_objects.

  DATA(ls_result) =
    get_result( ).

  cl_abap_unit_assert=>assert_equals(
    exp = ls_result-overview-total_source_objects
    act = lines( ls_result-source_objects )
    msg = 'Source object list không khớp Overview total'
  ).

  LOOP AT ls_result-source_objects
    ASSIGNING FIELD-SYMBOL(<source_object>).

    cl_abap_unit_assert=>assert_not_initial(
      act = <source_object>-item_id
      msg = |Source object chưa có ItemId: {
        <source_object>-object_name }|
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_result-analysis_id
      act = <source_object>-analysis_id
      msg = |Source object dùng sai AnalysisId: {
        <source_object>-object_name }|
    ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool(
        <source_object>-line_count >= 0
      )
      msg = |LineCount không hợp lệ: {
        <source_object>-object_name }|
    ).

  ENDLOOP.

ENDMETHOD.

METHOD preserve_nested_include.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name = 'ZRMIG_TEST_FULL'
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = 6
    act = lines( ls_result-source_objects )
    msg = 'Phải trả đủ root và nested includes'
  ).

  READ TABLE ls_result-source_objects
    WITH KEY
      object_name = 'ZRMIG_TEST_FULL'
    INTO DATA(ls_root).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không tìm thấy root program'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 0
    act = ls_root-include_depth
  ).

  cl_abap_unit_assert=>assert_initial(
    act = ls_root-parent_object
  ).

  READ TABLE ls_result-source_objects
    WITH KEY
      object_name = 'ZRMIG_TEST_FULL_TYPES'
    INTO DATA(ls_nested_include).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không tìm thấy nested include TYPES'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'ZRMIG_TEST_FULL_TOP'
    act = ls_nested_include-parent_object
    msg = 'Nested include có ParentObject không đúng'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 2
    act = ls_nested_include-include_depth
    msg = 'Nested include phải có depth bằng 2'
  ).

  cl_abap_unit_assert=>assert_true(
    act = xsdbool(
      ls_nested_include-line_count > 0
    )
    msg = 'Nested include chưa có LineCount'
  ).

ENDMETHOD.

ENDCLASS.
