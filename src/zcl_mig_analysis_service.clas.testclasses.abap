CLASS ltc_analysis_service DEFINITION
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

    METHODS setup.

    METHODS create_uuid
      RETURNING
        VALUE(rv_uuid)
          TYPE zif_mig_types=>ty_analysis_id
      RAISING
        zcx_mig_analysis.

    METHODS:
      analyze_existing_program
        FOR TESTING
        RAISING zcx_mig_analysis,

      use_requested_analysis_id
        FOR TESTING
        RAISING zcx_mig_analysis,

      return_complete_result
        FOR TESTING
        RAISING zcx_mig_analysis,

      preserve_root_program
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_missing_program
        FOR TESTING.


        METHODS:
          analyze_and_save_persists
            FOR TESTING
            RAISING zcx_mig_analysis,

          preserve_requested_saved_id
            FOR TESTING
            RAISING zcx_mig_analysis,

          reject_duplicate_saved_id
            FOR TESTING
            RAISING zcx_mig_analysis,

          analyze_program_stays_pure
            FOR TESTING
            RAISING zcx_mig_analysis.



ENDCLASS.

CLASS ltc_analysis_service IMPLEMENTATION.

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

  METHOD analyze_existing_program.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name = 'ZRMIG_TEST_FULL'
    ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-analysis_id
    msg = 'Analysis Service chưa tạo Analysis ID'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = zif_mig_types=>gc_status_completed
    act = ls_result-overview-status
    msg = 'Analysis chưa có trạng thái COMPLETED'
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'ZRMIG_TEST_FULL'
    act = ls_result-overview-program_name
  ).

ENDMETHOD.

METHOD use_requested_analysis_id.

  DATA(lv_analysis_id) =
    create_uuid( ).

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name = 'ZRMIG_TEST_FULL'
      iv_analysis_id  = lv_analysis_id
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = lv_analysis_id
    act = ls_result-analysis_id
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lv_analysis_id
    act = ls_result-overview-analysis_id
  ).


  LOOP AT ls_result-alv_outputs
    ASSIGNING FIELD-SYMBOL(<output>).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = <output>-analysis_id
    ).

  ENDLOOP.

ENDMETHOD.

METHOD return_complete_result.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name = 'ZRMIG_TEST_FULL'
    ).


  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-alv_outputs
    msg = 'Không có ALV outputs'
  ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-alv_columns
    msg = 'Không có ALV columns'
  ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-alv_sorts
    msg = 'Không có ALV sorts'
  ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-alv_filters
    msg = 'Không có ALV filters'
  ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-alv_events
    msg = 'Không có ALV events'
  ).

  cl_abap_unit_assert=>assert_true(
    act = xsdbool(
      ls_result-overview-complexity_score > 0
    )
    msg = 'Complexity Engine chưa chạy'
  ).

  cl_abap_unit_assert=>assert_true(
    act = xsdbool(
      ls_result-overview-readiness_score >= 0
      AND ls_result-overview-readiness_score <= 100
    )
    msg = 'Readiness Score không hợp lệ'
  ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-recommendations
    msg = 'Recommendation Engine chưa chạy'
  ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-annotations
    msg = 'Không có annotation proposals'
  ).

ENDMETHOD.

METHOD preserve_root_program.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name = 'ZRMIG_TEST_FULL'
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'ZRMIG_TEST_FULL'
    act = ls_result-overview-program_name
    msg = 'Overview phải giữ root program, không phải include'
  ).

  cl_abap_unit_assert=>assert_true(
    act = xsdbool(
      ls_result-overview-total_source_objects >= 1
    )
  ).

ENDMETHOD.

METHOD reject_missing_program.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  TRY.

      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = 'Z_PROGRAM_DOES_NOT_EXIST'
      ).

      cl_abap_unit_assert=>fail(
        msg = 'Phải ném ZCX_MIG_ANALYSIS cho program không tồn tại'
      ).

    CATCH zcx_mig_analysis.

      "Expected exception

  ENDTRY.

ENDMETHOD.

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

METHOD analyze_and_save_persists.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_TEST_FULL'
    ).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_result-analysis_id
  ).


  DATA(lo_store) =
    NEW zcl_mig_analysis_store( ).

  cl_abap_unit_assert=>assert_equals(
    exp = abap_true
    act = lo_store->zif_mig_analysis_store~exists(
      iv_analysis_id = ls_result-analysis_id
    )
    msg = 'ANALYZE_AND_SAVE chưa persist analysis'
  ).


  DATA(ls_saved_result) =
    lo_store->zif_mig_analysis_store~read(
      iv_analysis_id = ls_result-analysis_id
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = ls_result-analysis_id
    act = ls_saved_result-analysis_id
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'ZRMIG_TEST_FULL'
    act = ls_saved_result-overview-program_name
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = zif_mig_types=>gc_status_completed
    act = ls_saved_result-overview-status
  ).

ENDMETHOD.

METHOD preserve_requested_saved_id.

  DATA(lv_analysis_id) =
    create_uuid( ).

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_TEST_FULL'
      iv_analysis_id  = lv_analysis_id
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = lv_analysis_id
    act = ls_result-analysis_id
  ).


  DATA(lo_store) =
    NEW zcl_mig_analysis_store( ).

  cl_abap_unit_assert=>assert_equals(
    exp = abap_true
    act = lo_store->zif_mig_analysis_store~exists(
      iv_analysis_id = lv_analysis_id
    )
  ).


  DATA(ls_saved_result) =
    lo_store->zif_mig_analysis_store~read(
      iv_analysis_id = lv_analysis_id
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = lv_analysis_id
    act = ls_saved_result-overview-analysis_id
  ).

ENDMETHOD.

METHOD reject_duplicate_saved_id.

  DATA(lv_analysis_id) =
    create_uuid( ).

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  lo_service->zif_mig_analysis_service~analyze_and_save(
    iv_program_name = 'ZRMIG_TEST_FULL'
    iv_analysis_id  = lv_analysis_id
  ).

  TRY.

      lo_service->zif_mig_analysis_service~analyze_and_save(
        iv_program_name = 'ZRMIG_TEST_FULL'
        iv_analysis_id  = lv_analysis_id
      ).

      cl_abap_unit_assert=>fail(
        msg = 'Analysis ID đã tồn tại phải bị từ chối'
      ).

    CATCH zcx_mig_analysis.

      "Expected

  ENDTRY.

ENDMETHOD.

METHOD analyze_program_stays_pure.

  DATA(lo_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_result) =
    lo_service->zif_mig_analysis_service~analyze_program(
      iv_program_name = 'ZRMIG_TEST_FULL'
    ).

  DATA(lo_store) =
    NEW zcl_mig_analysis_store( ).

  cl_abap_unit_assert=>assert_equals(
    exp = abap_false
    act = lo_store->zif_mig_analysis_store~exists(
      iv_analysis_id = ls_result-analysis_id
    )
    msg = 'ANALYZE_PROGRAM không được tự động persist'
  ).

ENDMETHOD.

ENDCLASS.

CLASS ltc_parser_checkpoint1 DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS gc_program
      TYPE progname
      VALUE 'ZRMIG_SAMPLE_FULL'.

    METHODS get_result
      RETURNING
        VALUE(rs_result)
          TYPE zif_mig_types=>ty_analysis_result
      RAISING
        zcx_mig_analysis.

    METHODS verify_inventory
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS verify_relationship_baseline
      FOR TESTING
      RAISING zcx_mig_analysis.

    METHODS verify_alv_baseline
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_parser_checkpoint1 IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).

    rs_result =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = gc_program
      ).

  ENDMETHOD.


  METHOD verify_inventory.

    DATA(ls_result) =
      get_result( ).


    cl_abap_unit_assert=>assert_equals(
      exp = gc_program
      act = ls_result-overview-program_name
      msg = 'Sai root program'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = lines( ls_result-source_objects )
      msg = 'Expected root + TOP + F01'
    ).


    READ TABLE ls_result-source_objects
      WITH KEY object_name = 'ZRMIG_SAMPLE_FULL_TOP'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không resolve TOP include'
    ).


    READ TABLE ls_result-source_objects
      WITH KEY object_name = 'ZRMIG_SAMPLE_FULL_F01'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không resolve F01 include'
    ).


    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_BUKRS'
      INTO DATA(ls_bukrs).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect P_BUKRS'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_bukrs-mandatory
      msg = 'P_BUKRS phải mandatory'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'B1'
      act = ls_bukrs-selection_block
    ).


    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'S_WERKS'
      INTO DATA(ls_werks).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect S_WERKS'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'T001W'
      act = ls_werks-reference_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'WERKS'
      act = ls_werks-reference_field
    ).


    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_COMMIT'
      INTO DATA(ls_commit).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect P_COMMIT'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_commit-checkbox
      msg = 'P_COMMIT phải là checkbox'
    ).


    READ TABLE ls_result-database_objects
      WITH KEY
        operation   = 'SELECT'
        object_name = 'T001'
      INTO DATA(ls_db).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect SELECT T001'
    ).

    cl_abap_unit_assert=>assert_char_cp(
      act = to_upper( ls_db-joined_objects )
      exp = '*T001W*'
      msg = 'Không detect JOIN T001W'
    ).

  ENDMETHOD.


  METHOD verify_relationship_baseline.

    DATA(ls_result) =
      get_result( ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_CALL'
        object_name = 'LOAD_DATA'
      INTO DATA(ls_load).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect PERFORM LOAD_DATA'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'START-OF-SELECTION'
      act = ls_load-calling_routine
      msg = 'LOAD_DATA sai caller'
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_CALL'
        object_name = 'PROCESS_DATA'
      INTO DATA(ls_process).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'START-OF-SELECTION'
      act = ls_process-calling_routine
      msg = 'PROCESS_DATA sai caller'
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_CALL'
        object_name = 'DISPLAY_DATA'
      INTO DATA(ls_display).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'END-OF-SELECTION'
      act = ls_display-calling_routine
      msg = 'DISPLAY_DATA sai caller'
    ).


    READ TABLE ls_result-database_objects
      WITH KEY
        operation   = 'SELECT'
        object_name = 'T001'
      INTO DATA(ls_db).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'LOAD_DATA'
      act = ls_db-containing_routine
      msg = 'SELECT T001 phải thuộc LOAD_DATA'
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FUNCTION_MODULE'
        object_name = 'DDIF_FIELDINFO_GET'
      INTO DATA(ls_fm).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect DDIF_FIELDINFO_GET'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_fm-calling_routine
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'BAPI'
        object_name = 'BAPI_USER_GET_DETAIL'
      INTO DATA(ls_bapi).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect BAPI_USER_GET_DETAIL'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_bapi-calling_routine
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type    = 'STATIC_METHOD'
        object_name    = 'ENRICH_STATIC'
        container_name = 'LCL_WORKER'
      INTO DATA(ls_static).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect static method'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_static-calling_routine
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type    = 'INSTANCE_METHOD'
        object_name    = 'CALCULATE'
        container_name = 'LO_WORKER'
      INTO DATA(ls_instance).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect instance method'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_instance-calling_routine
    ).

  ENDMETHOD.


  METHOD verify_alv_baseline.

    DATA(ls_result) =
      get_result( ).


    READ TABLE ls_result-alv_outputs
      WITH KEY framework = 'CL_GUI_ALV_GRID'
      INTO DATA(ls_alv).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect CL_GUI_ALV_GRID'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GO_GRID'
      act = ls_alv-control_object
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_alv-output_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_FCAT'
      act = ls_alv-field_catalog
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_SORT'
      act = ls_alv-sort_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_FILTER'
      act = ls_alv-filter_table
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GS_LAYOUT'
      act = ls_alv-layout_object
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GS_VARIANT'
      act = ls_alv-variant_object
    ).


    READ TABLE ls_result-alv_columns
      WITH KEY
        output_id  = ls_alv-output_id
        field_name = 'BUKRS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect ALV column BUKRS'
    ).


    READ TABLE ls_result-alv_sorts
      WITH KEY
        output_id  = ls_alv-output_id
        field_name = 'BUKRS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect ALV sort BUKRS'
    ).


    READ TABLE ls_result-alv_filters
      WITH KEY
        output_id  = ls_alv-output_id
        field_name = 'BUKRS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect ALV filter BUKRS'
    ).


    READ TABLE ls_result-alv_events
      WITH KEY
        output_id  = ls_alv-output_id
        event_name = 'DOUBLE_CLICK'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không detect DOUBLE_CLICK'
    ).


    cl_abap_unit_assert=>assert_true(
      act = ls_alv-zebra
      msg = 'Không enrich ZEBRA'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_alv-auto_width
      msg = 'Không enrich CWIDTH_OPT'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'A'
      act = ls_alv-selection_mode
      msg = 'Không enrich selection mode'
    ).

  ENDMETHOD.

ENDCLASS.

CLASS ltc_cp2_evidence_links DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS verify_evidence_links
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_cp2_evidence_links IMPLEMENTATION.

  METHOD verify_evidence_links.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).

    DATA(ls_result) =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = 'ZRMIG_SAMPLE_FULL'
      ).


    "==========================================================
    " UI Filters
    "==========================================================
    LOOP AT ls_result-ui_filters
      ASSIGNING FIELD-SYMBOL(<ui>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <ui>-evidence_id
        msg = |UI filter không có evidence: { <ui>-field_name }|
      ).

      READ TABLE ls_result-evidences
        WITH KEY
          evidence_id = <ui>-evidence_id
        INTO DATA(ls_ui_evidence).

      cl_abap_unit_assert=>assert_subrc(
        exp = 0
        msg = |Không tìm thấy evidence của UI: { <ui>-field_name }|
      ).

      cl_abap_unit_assert=>assert_not_initial(
        act = ls_ui_evidence-statement_text
      ).

      cl_abap_unit_assert=>assert_true(
        act = xsdbool(
          ls_ui_evidence-start_line > 0
        )
      ).

    ENDLOOP.


    "==========================================================
    " Database
    "==========================================================
    LOOP AT ls_result-database_objects
      ASSIGNING FIELD-SYMBOL(<db>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <db>-evidence_id
        msg = |DB finding không có evidence: {
                 <db>-object_name }|
      ).

      READ TABLE ls_result-evidences
        WITH KEY
          evidence_id = <db>-evidence_id
        INTO DATA(ls_db_evidence).

      cl_abap_unit_assert=>assert_subrc(
        exp = 0
        msg = |Không tìm thấy evidence của DB: {
                 <db>-object_name }|
      ).

      cl_abap_unit_assert=>assert_not_initial(
        act = ls_db_evidence-statement_text
      ).

      cl_abap_unit_assert=>assert_true(
        act = xsdbool(
          ls_db_evidence-start_line > 0
        )
      ).

    ENDLOOP.


    "==========================================================
    " Business Logic
    "==========================================================
    LOOP AT ls_result-business_logic
      ASSIGNING FIELD-SYMBOL(<logic>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <logic>-evidence_id
        msg = |Logic finding không có evidence: {
                 <logic>-object_name }|
      ).

      READ TABLE ls_result-evidences
        WITH KEY
          evidence_id = <logic>-evidence_id
        INTO DATA(ls_logic_evidence).

      cl_abap_unit_assert=>assert_subrc(
        exp = 0
        msg = |Không tìm thấy evidence của logic: {
                 <logic>-object_name }|
      ).

      cl_abap_unit_assert=>assert_not_initial(
        act = ls_logic_evidence-statement_text
      ).

      cl_abap_unit_assert=>assert_true(
        act = xsdbool(
          ls_logic_evidence-start_line > 0
        )
      ).

    ENDLOOP.


    "==========================================================
    " ALV Output
    "==========================================================
    LOOP AT ls_result-alv_outputs
      ASSIGNING FIELD-SYMBOL(<alv>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <alv>-evidence_id
        msg = |ALV output không có evidence: {
                 <alv>-output_name }|
      ).

      READ TABLE ls_result-evidences
        WITH KEY
          evidence_id = <alv>-evidence_id
        INTO DATA(ls_alv_evidence).

      cl_abap_unit_assert=>assert_subrc(
        exp = 0
        msg = |Không tìm thấy evidence của ALV: {
                 <alv>-output_name }|
      ).

      cl_abap_unit_assert=>assert_not_initial(
        act = ls_alv_evidence-statement_text
      ).

      cl_abap_unit_assert=>assert_true(
        act = xsdbool(
          ls_alv_evidence-start_line > 0
        )
      ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS ltc_cp3_result_target DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS golden_result_target
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_cp3_result_target IMPLEMENTATION.

  METHOD golden_result_target.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).

    DATA(ls_result) =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = 'ZRMIG_SAMPLE_FULL'
      ).


    READ TABLE ls_result-database_objects
      WITH KEY
        object_name = 'T001'
        operation   = 'SELECT'
      INTO DATA(ls_db).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy SELECT T001'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'LOAD_DATA'
      act = ls_db-containing_routine
      msg = 'SELECT phải thuộc LOAD_DATA'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_db-result_target
      msg = 'SELECT phải đưa dữ liệu vào GT_RESULT'
    ).

  ENDMETHOD.

ENDCLASS.

CLASS ltc_cp4_alv_relationship DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS golden_alv_relationship
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_cp4_alv_relationship IMPLEMENTATION.

  METHOD golden_alv_relationship.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).

    DATA(ls_result) =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = 'ZRMIG_SAMPLE_FULL'
      ).


    READ TABLE ls_result-alv_outputs
      WITH KEY
        framework = 'CL_GUI_ALV_GRID'
      INTO DATA(ls_alv).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy CL_GUI_ALV_GRID'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'DISPLAY_DATA'
      act = ls_alv-containing_routine
      msg = 'ALV phải được gọi trong DISPLAY_DATA'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_alv-output_table
      msg = 'ALV phải hiển thị GT_RESULT'
    ).

  ENDMETHOD.

ENDCLASS.

CLASS ltc_parser_v1_acceptance DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS:
      gc_full_program TYPE progname
        VALUE 'ZRMIG_SAMPLE_FULL'.

    METHODS:
      get_full_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_analysis_result
        RAISING
          zcx_mig_analysis,

      analyze_dynamic_case
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_analysis_result
        RAISING
          zcx_mig_analysis,

      gate_01_source_structure
        FOR TESTING
        RAISING zcx_mig_analysis,

      gate_02_selection_screen
        FOR TESTING
        RAISING zcx_mig_analysis,

      gate_03_processing_entry
        FOR TESTING
        RAISING zcx_mig_analysis,

      gate_04_logic_dependencies
        FOR TESTING
        RAISING zcx_mig_analysis,

      gate_05_routine_to_db
        FOR TESTING
        RAISING zcx_mig_analysis,

      gate_06_db_result_target
        FOR TESTING
        RAISING zcx_mig_analysis,

      gate_07_routine_to_alv
        FOR TESTING
        RAISING zcx_mig_analysis,

      gate_08_manual_review
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_parser_v1_acceptance IMPLEMENTATION.

  "============================================================
  " Golden report
  "============================================================
  METHOD get_full_result.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).

    rs_result =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = gc_full_program
      ).

  ENDMETHOD.


  "============================================================
  " Dynamic / unresolved acceptance fixture
  "
  " Không tạo program vật lý.
  " Fixture này chỉ tồn tại trong ABAP Unit.
  "============================================================
  METHOD analyze_dynamic_case.

    CONSTANTS gc_program TYPE progname
      VALUE 'ZRMIG_UT_V1_DYNAMIC'.


    DATA(lt_source) =
      VALUE zif_mig_types=>tt_source_line(

        (
          source_object = gc_program
          line_number   = 1
          source_text   =
            `REPORT zrmig_ut_v1_dynamic.`
        )

        (
          source_object = gc_program
          line_number   = 2
          source_text   =
            `DATA lv_table TYPE tabname VALUE 'T001'.`
        )

        (
          source_object = gc_program
          line_number   = 3
          source_text   =
            `DATA lt_data TYPE STANDARD TABLE OF t001 WITH EMPTY KEY.`
        )

        (
          source_object = gc_program
          line_number   = 4
          source_text   =
            `DATA lv_fm TYPE rs38l_fnam VALUE 'DDIF_FIELDINFO_GET'.`
        )

        (
          source_object = gc_program
          line_number   = 5
          source_text   =
            `FORM dynamic_process.`
        )

        (
          source_object = gc_program
          line_number   = 6
          source_text   =
            `SELECT * FROM (lv_table) INTO TABLE @lt_data.`
        )

        (
          source_object = gc_program
          line_number   = 7
          source_text   =
            `CALL FUNCTION (lv_fm).`
        )

        (
          source_object = gc_program
          line_number   = 8
          source_text   =
            `ENDFORM.`
        )

        (
          source_object = gc_program
          line_number   = 9
          source_text   =
            `FORM display_data.`
        )

        (
          source_object = gc_program
          line_number   = 10
          source_text   =
            `CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'.`
        )

        (
          source_object = gc_program
          line_number   = 11
          source_text   =
            `ENDFORM.`
        )

      ).


    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(ls_scan) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object = gc_program
        it_source        = lt_source
      ).


    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(ls_normalized) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result = ls_scan
      ).


    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.

    APPEND VALUE #(
      source_object = VALUE #(
        object_name  = gc_program
        object_type  = 'PROGRAM'
        source_lines = lt_source
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


  "============================================================
  " GATE 01
  "
  " Root program + includes
  "============================================================
  METHOD gate_01_source_structure.

    DATA(ls_result) =
      get_full_result( ).


    cl_abap_unit_assert=>assert_equals(
      exp = gc_full_program
      act = ls_result-overview-program_name
      msg = 'Root program không đúng'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = lines( ls_result-source_objects )
      msg = 'ZRMIG_SAMPLE_FULL phải có root + 2 includes'
    ).


    READ TABLE ls_result-source_objects
      WITH KEY
        object_name = 'ZRMIG_SAMPLE_FULL'
      INTO DATA(ls_root).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy root source'
    ).


    READ TABLE ls_result-source_objects
      WITH KEY
        object_name = 'ZRMIG_SAMPLE_FULL_TOP'
      INTO DATA(ls_top).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy TOP include'
    ).


    READ TABLE ls_result-source_objects
      WITH KEY
        object_name = 'ZRMIG_SAMPLE_FULL_F01'
      INTO DATA(ls_f01).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy F01 include'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = gc_full_program
      act = ls_top-parent_object
      msg = 'TOP include không liên kết với root'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = gc_full_program
      act = ls_f01-parent_object
      msg = 'F01 include không liên kết với root'
    ).

  ENDMETHOD.


  "============================================================
  " GATE 02
  "
  " Selection screen
  "============================================================
  METHOD gate_02_selection_screen.

    DATA(ls_result) =
      get_full_result( ).


    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_BUKRS'
      INTO DATA(ls_bukrs).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện P_BUKRS'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_bukrs-mandatory
      msg = 'P_BUKRS phải là OBLIGATORY'
    ).


    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'S_WERKS'
      INTO DATA(ls_werks).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện S_WERKS'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_werks-multiple_selection
      msg = 'S_WERKS phải support multiple selection'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_werks-range_supported
      msg = 'S_WERKS phải support range'
    ).


    READ TABLE ls_result-ui_filters
      WITH KEY field_name = 'P_COMMIT'
      INTO DATA(ls_commit).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện P_COMMIT'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_commit-checkbox
      msg = 'P_COMMIT phải được nhận diện là checkbox'
    ).

  ENDMETHOD.


  "============================================================
  " GATE 03
  "
  " Processing Event → entry routine
  "============================================================
  METHOD gate_03_processing_entry.

    DATA(ls_result) =
      get_full_result( ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_CALL'
        object_name = 'LOAD_DATA'
      INTO DATA(ls_load).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện PERFORM LOAD_DATA'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'START-OF-SELECTION'
      act = ls_load-calling_routine
      msg = 'LOAD_DATA phải được gọi từ START-OF-SELECTION'
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_CALL'
        object_name = 'PROCESS_DATA'
      INTO DATA(ls_process).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện PERFORM PROCESS_DATA'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'START-OF-SELECTION'
      act = ls_process-calling_routine
      msg = 'PROCESS_DATA phải được gọi từ START-OF-SELECTION'
    ).


    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FORM_CALL'
        object_name = 'DISPLAY_DATA'
      INTO DATA(ls_display).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện PERFORM DISPLAY_DATA'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'END-OF-SELECTION'
      act = ls_display-calling_routine
      msg = 'DISPLAY_DATA phải được gọi từ END-OF-SELECTION'
    ).

  ENDMETHOD.


  "============================================================
  " GATE 04
  "
  " Caller → FORM / FM / BAPI / Method
  "============================================================
  METHOD gate_04_logic_dependencies.

    DATA(ls_result) =
      get_full_result( ).


    "----------------------------------------------------------
    " Function Module
    "----------------------------------------------------------
    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'FUNCTION_MODULE'
        object_name = 'DDIF_FIELDINFO_GET'
      INTO DATA(ls_fm).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện DDIF_FIELDINFO_GET'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_fm-calling_routine
    ).


    "----------------------------------------------------------
    " BAPI
    "----------------------------------------------------------
    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'BAPI'
        object_name = 'BAPI_USER_GET_DETAIL'
      INTO DATA(ls_bapi).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện BAPI_USER_GET_DETAIL'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_bapi-calling_routine
    ).


    "----------------------------------------------------------
    " Static method
    "----------------------------------------------------------
    READ TABLE ls_result-business_logic
      WITH KEY
        object_type    = 'STATIC_METHOD'
        object_name    = 'ENRICH_STATIC'
        container_name = 'LCL_WORKER'
      INTO DATA(ls_static).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện LCL_WORKER=>ENRICH_STATIC'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_static-calling_routine
    ).


    "----------------------------------------------------------
    " Instance method
    "----------------------------------------------------------
    READ TABLE ls_result-business_logic
      WITH KEY
        object_type    = 'INSTANCE_METHOD'
        object_name    = 'CALCULATE'
        container_name = 'LO_WORKER'
      INTO DATA(ls_instance).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện LO_WORKER->CALCULATE'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'PROCESS_DATA'
      act = ls_instance-calling_routine
    ).

  ENDMETHOD.


  "============================================================
  " GATE 05
  "
  " Routine → Database
  "============================================================
  METHOD gate_05_routine_to_db.

    DATA(ls_result) =
      get_full_result( ).


    READ TABLE ls_result-database_objects
      WITH KEY
        object_name = 'T001'
        operation   = 'SELECT'
      INTO DATA(ls_db).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện SELECT T001'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'LOAD_DATA'
      act = ls_db-containing_routine
      msg = 'SELECT T001 phải thuộc LOAD_DATA'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = to_upper( ls_db-joined_objects )
      exp = '*T001K*'
      msg = 'Không phát hiện JOIN T001K'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = to_upper( ls_db-joined_objects )
      exp = '*T001W*'
      msg = 'Không phát hiện JOIN T001W'
    ).

  ENDMETHOD.


  "============================================================
  " GATE 06
  "
  " Database → Result Target
  "============================================================
  METHOD gate_06_db_result_target.

    DATA(ls_result) =
      get_full_result( ).


    READ TABLE ls_result-database_objects
      WITH KEY
        object_name = 'T001'
        operation   = 'SELECT'
      INTO DATA(ls_db).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy SELECT T001'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_db-result_target
      msg = 'SELECT phải map tới GT_RESULT'
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_db-evidence_id
      msg = 'DB result target phải có evidence'
    ).

  ENDMETHOD.


  "============================================================
  " GATE 07
  "
  " Routine → ALV → Output Table
  "============================================================
  METHOD gate_07_routine_to_alv.

    DATA(ls_result) =
      get_full_result( ).


    READ TABLE ls_result-alv_outputs
      WITH KEY
        framework = 'CL_GUI_ALV_GRID'
      INTO DATA(ls_alv).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện CL_GUI_ALV_GRID'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'DISPLAY_DATA'
      act = ls_alv-containing_routine
      msg = 'ALV phải thuộc DISPLAY_DATA'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_alv-output_table
      msg = 'ALV phải hiển thị GT_RESULT'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GO_GRID'
      act = ls_alv-control_object
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_FCAT'
      act = ls_alv-field_catalog
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_SORT'
      act = ls_alv-sort_table
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_FILTER'
      act = ls_alv-filter_table
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_alv-evidence_id
      msg = 'ALV relationship phải có evidence'
    ).

  ENDMETHOD.


  "============================================================
  " GATE 08
  "
  " Dynamic / unresolved
  "
  " Parser không được đoán runtime target.
  " Phải:
  " - preserve finding
  " - lower confidence
  " - warning/manual review
  " - preserve evidence
  "============================================================
  METHOD gate_08_manual_review.

    DATA(ls_result) =
      analyze_dynamic_case( ).


    "==========================================================
    " Dynamic Database
    "==========================================================
    READ TABLE ls_result-database_objects
      WITH KEY operation = 'SELECT'
      INTO DATA(ls_db).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Dynamic SELECT phải được giữ lại'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_db-dynamic_access
      msg = 'Dynamic SELECT phải có DYNAMIC_ACCESS'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_conf_medium
      act = ls_db-confidence
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'REVIEW'
      act = ls_db-paging_capability
    ).


    READ TABLE ls_result-evidences
      WITH KEY
        evidence_id = ls_db-evidence_id
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Dynamic DB phải có evidence hợp lệ'
    ).


    "==========================================================
    " Dynamic Function Module
    "==========================================================
    READ TABLE ls_result-business_logic
      WITH KEY
        object_type = 'DYNAMIC_FUNCTION_MODULE'
        object_name = 'LV_FM'
      INTO DATA(ls_dynamic_fm).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Dynamic FM phải được giữ thành finding'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'DYNAMIC_PROCESS'
      act = ls_dynamic_fm-calling_routine
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_conf_medium
      act = ls_dynamic_fm-confidence
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ADAPTER_REVIEW'
      act = ls_dynamic_fm-reuse_feasibility
    ).


    READ TABLE ls_result-evidences
      WITH KEY
        evidence_id = ls_dynamic_fm-evidence_id
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Dynamic FM phải có evidence hợp lệ'
    ).


    "==========================================================
    " Unresolved ALV
    "==========================================================
    READ TABLE ls_result-alv_outputs
      WITH KEY
        framework = 'REUSE_ALV_GRID_DISPLAY'
      INTO DATA(ls_alv).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Unresolved ALV invocation phải được giữ lại'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_alv-output_table
      msg = 'Fixture này cố ý không có output table'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_conf_medium
      act = ls_alv-confidence
    ).


    READ TABLE ls_result-evidences
      WITH KEY
        evidence_id = ls_alv-evidence_id
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Unresolved ALV phải có evidence hợp lệ'
    ).


    "==========================================================
    " Required warning messages
    "==========================================================
    READ TABLE ls_result-messages
      WITH KEY
        message_code = 'DB_DYNAMIC_ACCESS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu DB_DYNAMIC_ACCESS'
    ).


    READ TABLE ls_result-messages
      WITH KEY
        message_code = 'LOGIC_DYNAMIC_CALL'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu LOGIC_DYNAMIC_CALL'
    ).


    READ TABLE ls_result-messages
      WITH KEY
        message_code = 'ALV_TABLE_UNRESOLVED'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu ALV_TABLE_UNRESOLVED'
    ).


    "==========================================================
    " Analysis overall status
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_status_warning
      act = ls_result-overview-status
      msg = 'Dynamic/unresolved analysis phải có WARNING'
    ).

  ENDMETHOD.

ENDCLASS.
