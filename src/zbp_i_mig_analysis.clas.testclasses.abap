CLASS ltc_analysis_eml DEFINITION
  FINAL
  FOR TESTING
  DURATION MEDIUM
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

      execute_valid_action
        RETURNING
          VALUE(rv_analysis_id)
            TYPE zif_mig_types=>ty_analysis_id,

      action_waits_for_commit
        FOR TESTING,

      commit_persists_header
        FOR TESTING,

      commit_persists_children
        FOR TESTING
        RAISING zcx_mig_analysis,

      buffer_cleared_after_commit
        FOR TESTING,

      invalid_program_reported
        FOR TESTING.

        METHODS read_saved_root
          FOR TESTING.

       METHODS read_saved_alv_column
         FOR TESTING.

       METHODS read_missing_root
        FOR TESTING.

ENDCLASS.

CLASS ltc_analysis_eml IMPLEMENTATION.

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

    "Đảm bảo RAP transactional buffer được cleanup
    ROLLBACK ENTITIES.

    IF mo_sql_environment IS BOUND.
      mo_sql_environment->destroy( ).
    ENDIF.

  ENDMETHOD.


  METHOD setup.

    "Cleanup buffer còn lại từ test trước
    ROLLBACK ENTITIES.

    mo_sql_environment->clear_doubles( ).

  ENDMETHOD.

    METHOD execute_valid_action.

    MODIFY ENTITIES OF zi_mig_analysis
      ENTITY Analysis
      EXECUTE Analyze
      FROM VALUE #(
        (
          %cid = 'CID_VALID_ANALYZE'

          %param = VALUE #(
            ProgramName = 'ZRMIG_SAMPLE_ALV'
          )
        )
      )
      RESULT DATA(lt_result)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).


    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_failed-Analysis )
      msg = 'Analyze trả về FAILED cho chương trình hợp lệ'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_reported-Analysis )
      msg = 'Analyze trả về REPORTED error cho chương trình hợp lệ'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( lt_result )
      msg = 'Analyze phải trả đúng một root result'
    ).


    READ TABLE lt_result
      INDEX 1
      INTO DATA(ls_result).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    rv_analysis_id =
      ls_result-%param-AnalysisId.

    cl_abap_unit_assert=>assert_not_initial(
      act = rv_analysis_id
      msg = 'Action không trả AnalysisId'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_ALV'
      act = ls_result-%param-ProgramName
      msg = 'Action trả sai ProgramName'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_status_completed
      act = ls_result-%param-Status
      msg = 'Action chưa trả trạng thái COMPLETED'
    ).

  ENDMETHOD.

    METHOD action_waits_for_commit.

    DATA(lv_analysis_id) =
      execute_valid_action( ).


    SELECT COUNT( * )
      FROM zmig_anl_h
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_header_count).


    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lv_header_count
      msg = 'Action đã ghi database trước COMMIT ENTITIES'
    ).


    ROLLBACK ENTITIES.

  ENDMETHOD.

    METHOD commit_persists_header.

    DATA(lv_analysis_id) =
      execute_valid_action( ).


    COMMIT ENTITIES RESPONSE OF zi_mig_analysis
      FAILED DATA(lt_commit_failed)
      REPORTED DATA(lt_commit_reported).


    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_commit_failed-Analysis )
      msg = 'RAP save sequence trả FAILED'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_commit_reported-Analysis )
      msg = 'RAP save sequence trả REPORTED error'
    ).


    SELECT SINGLE *
      FROM zmig_anl_h
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(ls_header).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'COMMIT ENTITIES chưa lưu header'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = ls_header-analysis_id
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_ALV'
      act = ls_header-program_name
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_status_completed
      act = ls_header-status
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_header-created_at
      msg = 'Store chưa điền CREATED_AT'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_header-created_by
      msg = 'Store chưa điền CREATED_BY'
    ).

  ENDMETHOD.

    METHOD commit_persists_children.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).

    DATA(ls_expected) =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = 'ZRMIG_SAMPLE_ALV'
      ).


    DATA(lv_analysis_id) =
      execute_valid_action( ).


    COMMIT ENTITIES RESPONSE OF zi_mig_analysis
      FAILED DATA(lt_commit_failed)
      REPORTED DATA(lt_commit_reported).


    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_commit_failed-Analysis )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_commit_reported-Analysis )
    ).


    "========================================================
    " UI Filters
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_ui
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_ui_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-ui_filters )
      act = lv_ui_count
      msg = 'Sai số lượng UI filters'
    ).


    "========================================================
    " Database Objects
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_db
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_db_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-database_objects )
      act = lv_db_count
      msg = 'Sai số lượng database objects'
    ).


    "========================================================
    " Business Logic
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_log
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_logic_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-business_logic )
      act = lv_logic_count
      msg = 'Sai số lượng business logic'
    ).


    "========================================================
    " ALV Outputs
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_alv
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_alv_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-alv_outputs )
      act = lv_alv_count
      msg = 'Sai số lượng ALV outputs'
    ).


    "========================================================
    " ALV Columns
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_col
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_column_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-alv_columns )
      act = lv_column_count
      msg = 'Sai số lượng ALV columns'
    ).


    "========================================================
    " ALV Sorts
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_srt
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_sort_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-alv_sorts )
      act = lv_sort_count
      msg = 'Sai số lượng ALV sorts'
    ).


    "========================================================
    " ALV Filters
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_flt
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_filter_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-alv_filters )
      act = lv_filter_count
      msg = 'Sai số lượng ALV filters'
    ).


    "========================================================
    " ALV Events
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_evt
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_event_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-alv_events )
      act = lv_event_count
      msg = 'Sai số lượng ALV events'
    ).


    "========================================================
    " Evidences
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_evd
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_evidence_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-evidences )
      act = lv_evidence_count
      msg = 'Sai số lượng evidences'
    ).


    "========================================================
    " Recommendations
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_rec
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_recommendation_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-recommendations )
      act = lv_recommendation_count
      msg = 'Sai số lượng recommendations'
    ).


    "========================================================
    " Annotation Proposals
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_ann
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_annotation_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-annotations )
      act = lv_annotation_count
      msg = 'Sai số lượng annotation proposals'
    ).


    "========================================================
    " Messages
    "========================================================
    SELECT COUNT( * )
      FROM zmig_anl_msg
      WHERE analysis_id = @lv_analysis_id
      INTO @DATA(lv_message_count).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_expected-messages )
      act = lv_message_count
      msg = 'Sai số lượng analysis messages'
    ).

  ENDMETHOD.

    METHOD buffer_cleared_after_commit.

    DATA(lv_analysis_id_1) =
      execute_valid_action( ).

    COMMIT ENTITIES RESPONSE OF zi_mig_analysis
      FAILED DATA(lt_failed_1)
      REPORTED DATA(lt_reported_1).


    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_failed_1-Analysis )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_reported_1-Analysis )
    ).


    DATA(lv_analysis_id_2) =
      execute_valid_action( ).

    COMMIT ENTITIES RESPONSE OF zi_mig_analysis
      FAILED DATA(lt_failed_2)
      REPORTED DATA(lt_reported_2).


    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_failed_2-Analysis )
      msg = 'Commit thứ hai thất bại; buffer có thể chưa được clear'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_reported_2-Analysis )
    ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool(
        lv_analysis_id_1 <> lv_analysis_id_2
      )
      msg = 'Hai lần Analyze phải tạo hai AnalysisId khác nhau'
    ).


    SELECT COUNT( * )
      FROM zmig_anl_h
      INTO @DATA(lv_header_count).


    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lv_header_count
      msg = 'Hai commit phải tạo đúng hai analysis headers'
    ).

  ENDMETHOD.

    METHOD invalid_program_reported.

    MODIFY ENTITIES OF zi_mig_analysis
      ENTITY Analysis
      EXECUTE Analyze
      FROM VALUE #(
        (
          %cid = 'CID_INVALID_ANALYZE'

          %param = VALUE #(
            ProgramName = 'Z_PROGRAM_DOES_NOT_EXIST'
          )
        )
      )
      RESULT DATA(lt_result)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).


    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( lt_result )
      msg = 'Program lỗi không được trả action result'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( lt_failed-Analysis )
      msg = 'Program không tồn tại phải nằm trong FAILED'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( lt_reported-Analysis )
      msg = 'Program không tồn tại phải có error message'
    ).


    SELECT COUNT( * )
      FROM zmig_anl_h
      INTO @DATA(lv_header_count).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lv_header_count
      msg = 'Action lỗi không được ghi header'
    ).


    ROLLBACK ENTITIES.

  ENDMETHOD.

  METHOD read_saved_root.

  DATA(lv_analysis_id) =
    execute_valid_action( ).

  COMMIT ENTITIES RESPONSE OF zi_mig_analysis
    FAILED DATA(lt_commit_failed)
    REPORTED DATA(lt_commit_reported).

  cl_abap_unit_assert=>assert_initial(
    act = lt_commit_failed-Analysis
  ).

  READ ENTITIES OF zi_mig_analysis
    ENTITY Analysis
    ALL FIELDS
    WITH VALUE #(
      (
        AnalysisId = lv_analysis_id
      )
    )
    RESULT DATA(lt_analysis)
    FAILED DATA(lt_failed)
    REPORTED DATA(lt_reported).

  cl_abap_unit_assert=>assert_initial(
    act = lt_failed-Analysis
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 1
    act = lines( lt_analysis )
    msg = 'READ không trả về analysis đã lưu'
  ).

  READ TABLE lt_analysis
    INDEX 1
    INTO DATA(ls_analysis).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = lv_analysis_id
    act = ls_analysis-AnalysisId
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 'ZRMIG_SAMPLE_ALV'
    act = ls_analysis-ProgramName
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = zif_mig_types=>gc_status_completed
    act = ls_analysis-Status
  ).

  cl_abap_unit_assert=>assert_true(
    act = xsdbool(
      ls_analysis-TotalAlvOutputs > 0
    )
  ).

ENDMETHOD.

METHOD read_saved_alv_column.

  DATA(lv_analysis_id) =
    execute_valid_action( ).

  COMMIT ENTITIES RESPONSE OF zi_mig_analysis
    FAILED DATA(lt_commit_failed)
    REPORTED DATA(lt_commit_reported).

  SELECT SINGLE
         analysis_id,
         output_id,
         item_id
    FROM zmig_anl_col
    WHERE analysis_id = @lv_analysis_id
    INTO @DATA(ls_column_key).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không có ALV column fixture'
  ).

  READ ENTITIES OF zi_mig_analysis
    ENTITY AlvColumn
    ALL FIELDS
    WITH VALUE #(
      (
        AnalysisId = ls_column_key-analysis_id
        OutputId   = ls_column_key-output_id
        ItemId     = ls_column_key-item_id
      )
    )
    RESULT DATA(lt_columns)
    FAILED DATA(lt_failed)
    REPORTED DATA(lt_reported).

  cl_abap_unit_assert=>assert_initial(
    act = lt_failed-AlvColumn
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = 1
    act = lines( lt_columns )
  ).

  READ TABLE lt_columns
    INDEX 1
    INTO DATA(ls_column).

  cl_abap_unit_assert=>assert_not_initial(
    act = ls_column-FieldName
  ).

  cl_abap_unit_assert=>assert_equals(
    exp = ls_column_key-output_id
    act = ls_column-OutputId
  ).

ENDMETHOD.

METHOD read_missing_root.

  DATA lv_missing_id
    TYPE zif_mig_types=>ty_analysis_id.

  TRY.

      lv_missing_id =
        cl_system_uuid=>create_uuid_x16_static( ).

    CATCH cx_uuid_error.

      cl_abap_unit_assert=>fail(
        msg = 'Không tạo được UUID cho test'
      ).

  ENDTRY.

  READ ENTITIES OF zi_mig_analysis
    ENTITY Analysis
    ALL FIELDS
    WITH VALUE #(
      (
        AnalysisId = lv_missing_id
      )
    )
    RESULT DATA(lt_analysis)
    FAILED DATA(lt_failed)
    REPORTED DATA(lt_reported).

  cl_abap_unit_assert=>assert_initial(
    act = lt_analysis
    msg = 'READ trả dữ liệu cho khóa không tồn tại'
  ).

ENDMETHOD.

ENDCLASS.
