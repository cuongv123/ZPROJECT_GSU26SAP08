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
      iv_program_name = 'ZRMIG_SAMPLE_ALV'
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
    exp = 'ZRMIG_SAMPLE_ALV'
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
      iv_program_name = 'ZRMIG_SAMPLE_ALV'
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
      iv_program_name = 'ZRMIG_SAMPLE_ALV'
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
      iv_program_name = 'ZRMIG_SAMPLE_ALV'
    ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'ZRMIG_SAMPLE_ALV'
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
      iv_program_name = 'ZRMIG_SAMPLE_ALV'
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
    exp = 'ZRMIG_SAMPLE_ALV'
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
      iv_program_name = 'ZRMIG_SAMPLE_ALV'
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
    iv_program_name = 'ZRMIG_SAMPLE_ALV'
    iv_analysis_id  = lv_analysis_id
  ).

  TRY.

      lo_service->zif_mig_analysis_service~analyze_and_save(
        iv_program_name = 'ZRMIG_SAMPLE_ALV'
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
      iv_program_name = 'ZRMIG_SAMPLE_ALV'
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
