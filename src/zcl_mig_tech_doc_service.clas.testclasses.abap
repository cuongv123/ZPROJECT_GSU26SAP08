CLASS ltc_tech_doc_service DEFINITION
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


    METHODS:
      generate_saved_analysis
        FOR TESTING
        RAISING zcx_mig_analysis,

      preserve_analysis_identity
        FOR TESTING
        RAISING zcx_mig_analysis,

      generate_expected_markdown
        FOR TESTING
        RAISING zcx_mig_analysis,

      generate_delivery_metadata
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_missing_analysis
        FOR TESTING.

     METHODS:
  golden_inventory_and_source
    FOR TESTING
    RAISING zcx_mig_analysis,

  golden_application_flow
    FOR TESTING
    RAISING zcx_mig_analysis,

  golden_dependencies_and_alv
    FOR TESTING
    RAISING zcx_mig_analysis,

  golden_recommendations_limits
    FOR TESTING
    RAISING zcx_mig_analysis,

  golden_evidence
    FOR TESTING
    RAISING zcx_mig_analysis,

  deterministic_document
    FOR TESTING
    RAISING zcx_mig_analysis.


ENDCLASS.

CLASS ltc_tech_doc_service IMPLEMENTATION.


  METHOD class_setup.

    mo_sql_environment =
      cl_osql_test_environment=>create(
        i_dependency_list = VALUE #(

          ( 'ZMIG_ANL_H'   )
          ( 'ZMIG_ANL_SRC' )
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

    METHOD generate_saved_analysis.

    "==========================================================
    " Arrange
    "==========================================================
    DATA(lo_analysis_service) =
      NEW zcl_mig_analysis_service( ).


    DATA(ls_analysis) =
      lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'
      ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_analysis-analysis_id
    ).


    "==========================================================
    " Act
    "==========================================================
    DATA(lo_doc_service) =
      NEW zcl_mig_tech_doc_service( ).


    DATA(ls_document) =
      lo_doc_service->zif_mig_tech_doc_service~generate(
        iv_analysis_id =
          ls_analysis-analysis_id
      ).


    "==========================================================
    " Assert
    "==========================================================
    cl_abap_unit_assert=>assert_not_initial(
      act = ls_document-markdown
      msg = 'Technical Document không được rỗng'
    ).


  ENDMETHOD.

    METHOD preserve_analysis_identity.

    DATA(lo_analysis_service) =
      NEW zcl_mig_analysis_service( ).


    DATA(ls_analysis) =
      lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'
      ).


    DATA(lo_doc_service) =
      NEW zcl_mig_tech_doc_service( ).


    DATA(ls_document) =
      lo_doc_service->zif_mig_tech_doc_service~generate(
        iv_analysis_id =
          ls_analysis-analysis_id
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = ls_analysis-analysis_id
      act = ls_document-analysis_id
      msg = 'Technical Document phải giữ AnalysisId'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_FULL'
      act = ls_document-program_name
      msg = 'Technical Document phải giữ root program'
    ).


  ENDMETHOD.

    METHOD generate_expected_markdown.

    DATA(lo_analysis_service) =
      NEW zcl_mig_analysis_service( ).


    DATA(ls_analysis) =
      lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'
      ).


    DATA(lo_doc_service) =
      NEW zcl_mig_tech_doc_service( ).


    DATA(ls_document) =
      lo_doc_service->zif_mig_tech_doc_service~generate(
        iv_analysis_id =
          ls_analysis-analysis_id
      ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_document-markdown
      exp = '*# Technical Analysis - ZRMIG_SAMPLE_FULL*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_document-markdown
      exp = '*## 4. Legacy Application Flow*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_document-markdown
      exp = '*LOAD_DATA*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_document-markdown
      exp = '*T001*GT_RESULT*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_document-markdown
      exp = '*DISPLAY_DATA*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_document-markdown
      exp = '*CL_GUI_ALV_GRID*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = ls_document-markdown
      exp = '*## 12. Evidence Appendix*'
    ).


  ENDMETHOD.

    METHOD generate_delivery_metadata.

    DATA(lo_analysis_service) =
      NEW zcl_mig_analysis_service( ).


    DATA(ls_analysis) =
      lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'
      ).


    DATA(lo_doc_service) =
      NEW zcl_mig_tech_doc_service( ).


    DATA(ls_document) =
      lo_doc_service->zif_mig_tech_doc_service~generate(
        iv_analysis_id =
          ls_analysis-analysis_id
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'zrmig_sample_full_technical_analysis.md'
      act = ls_document-file_name
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'text/markdown; charset=utf-8'
      act = ls_document-mime_type
    ).


  ENDMETHOD.

    METHOD reject_missing_analysis.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.


    TRY.

        lv_analysis_id =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error.

        cl_abap_unit_assert=>fail(
          msg = 'Không tạo được UUID test'
        ).

    ENDTRY.


    DATA(lo_doc_service) =
      NEW zcl_mig_tech_doc_service( ).


    TRY.

        lo_doc_service->zif_mig_tech_doc_service~generate(
          iv_analysis_id =
            lv_analysis_id
        ).


        cl_abap_unit_assert=>fail(
          msg =
            'Analysis không tồn tại phải bị từ chối'
        ).


      CATCH zcx_mig_analysis.

        "Expected

    ENDTRY.


  ENDMETHOD.

  METHOD golden_inventory_and_source.

  DATA(lo_analysis_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_analysis) =
    lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_SAMPLE_FULL'
    ).

  DATA(lo_doc_service) =
    NEW zcl_mig_tech_doc_service( ).

  DATA(ls_document) =
    lo_doc_service->zif_mig_tech_doc_service~generate(
      iv_analysis_id = ls_analysis-analysis_id
    ).


  "==========================================================
  " Application Inventory
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 2. Application Inventory*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*Source Objects*3*'
    msg = 'Golden report phải có 3 source objects'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*Selection Fields*3*'
    msg = 'Golden report phải có 3 selection fields'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*Database Objects*1*'
    msg = 'Golden report phải có 1 primary DB fact'
  ).


  "==========================================================
  " Source Structure
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 3. Source Structure*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*ZRMIG_SAMPLE_FULL*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*ZRMIG_SAMPLE_FULL_TOP*'
    msg = 'Technical Document thiếu TOP include'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*ZRMIG_SAMPLE_FULL_F01*'
    msg = 'Technical Document thiếu F01 include'
  ).

ENDMETHOD.

METHOD golden_application_flow.

  DATA(lo_analysis_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_analysis) =
    lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_SAMPLE_FULL'
    ).

  DATA(lo_doc_service) =
    NEW zcl_mig_tech_doc_service( ).

  DATA(ls_document) =
    lo_doc_service->zif_mig_tech_doc_service~generate(
      iv_analysis_id = ls_analysis-analysis_id
    ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 4. Legacy Application Flow*'
  ).


  "==========================================================
  " Validation flow
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*AT SELECTION-SCREEN*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*VALIDATE_INPUT*'
  ).


  "==========================================================
  " Main processing flow
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*START-OF-SELECTION*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*LOAD_DATA*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*PROCESS_DATA*'
  ).


  "==========================================================
  " DB → Result target
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*T001*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*T001K*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*T001W*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*GT_RESULT*'
    msg = 'Flow phải thể hiện result target GT_RESULT'
  ).


  "==========================================================
  " Display flow
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*END-OF-SELECTION*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*DISPLAY_DATA*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*CL_GUI_ALV_GRID*'
  ).

ENDMETHOD.

METHOD golden_dependencies_and_alv.

  DATA(lo_analysis_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_analysis) =
    lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_SAMPLE_FULL'
    ).

  DATA(lo_doc_service) =
    NEW zcl_mig_tech_doc_service( ).

  DATA(ls_document) =
    lo_doc_service->zif_mig_tech_doc_service~generate(
      iv_analysis_id = ls_analysis-analysis_id
    ).


  "==========================================================
  " Business Logic
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 7. Business Logic & Dependencies*'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*DDIF_FIELDINFO_GET*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*BAPI_USER_GET_DETAIL*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*BAPI_TRANSACTION_COMMIT*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*ENRICH_STATIC*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*LCL_WORKER*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*CALCULATE*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*LO_WORKER*'
  ).


  "==========================================================
  " ALV
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 8. ALV Output*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*CL_GUI_ALV_GRID*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*DISPLAY_DATA*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*GT_RESULT*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*GT_FCAT*'
  ).

  "GO_GRID nằm trong Flow ALV detail
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*GO_GRID*'
  ).

ENDMETHOD.

METHOD golden_recommendations_limits.

  DATA(lo_analysis_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_analysis) =
    lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_SAMPLE_FULL'
    ).


  cl_abap_unit_assert=>assert_not_initial(
    act = ls_analysis-recommendations
    msg = 'Golden analysis phải có modernization recommendations'
  ).


  DATA(lo_doc_service) =
    NEW zcl_mig_tech_doc_service( ).

  DATA(ls_document) =
    lo_doc_service->zif_mig_tech_doc_service~generate(
      iv_analysis_id = ls_analysis-analysis_id
    ).


  "==========================================================
  " Recommendation section
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 10. Modernization Recommendations*'
  ).


  "Ít nhất recommendation đầu tiên phải được preserve
  READ TABLE ls_analysis-recommendations
    INDEX 1
    INTO DATA(ls_recommendation).

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = |*{ ls_recommendation-title }*|
    msg = 'Recommendation bị mất khi build Technical Document'
  ).


  "==========================================================
  " Tool limitation
  "==========================================================
  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 11. Manual Review & Limitations*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*Static Analysis Boundary*'
    msg = 'Document phải mô tả boundary của Parser V1'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*Dynamic runtime values*'
  ).

  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*inter-procedural data flow*'
  ).

ENDMETHOD.

METHOD golden_evidence.

  DATA(lo_analysis_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_analysis) =
    lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_SAMPLE_FULL'
    ).

  DATA(lo_doc_service) =
    NEW zcl_mig_tech_doc_service( ).

  DATA(ls_document) =
    lo_doc_service->zif_mig_tech_doc_service~generate(
      iv_analysis_id = ls_analysis-analysis_id
    ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*## 12. Evidence Appendix*'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*ZRMIG_SAMPLE_FULL_F01*'
    msg = 'Evidence phải giữ source include'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*SELECT*'
    msg = 'Evidence appendix thiếu DB statement'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*BAPI_USER_GET_DETAIL*'
    msg = 'Evidence appendix thiếu BAPI statement'
  ).


  cl_abap_unit_assert=>assert_char_cp(
    act = ls_document-markdown
    exp = '*CL_GUI_ALV_GRID*'
    msg = 'Evidence appendix thiếu ALV evidence'
  ).

ENDMETHOD.

METHOD deterministic_document.

  DATA(lo_analysis_service) =
    NEW zcl_mig_analysis_service( ).

  DATA(ls_analysis) =
    lo_analysis_service->zif_mig_analysis_service~analyze_and_save(
      iv_program_name = 'ZRMIG_SAMPLE_FULL'
    ).


  DATA(lo_doc_service) =
    NEW zcl_mig_tech_doc_service( ).


  DATA(ls_first) =
    lo_doc_service->zif_mig_tech_doc_service~generate(
      iv_analysis_id = ls_analysis-analysis_id
    ).


  DATA(ls_second) =
    lo_doc_service->zif_mig_tech_doc_service~generate(
      iv_analysis_id = ls_analysis-analysis_id
    ).


  cl_abap_unit_assert=>assert_equals(
    exp = ls_first-markdown
    act = ls_second-markdown
    msg = 'Cùng AnalysisId phải sinh cùng Technical Document'
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = ls_first-file_name
    act = ls_second-file_name
  ).


  cl_abap_unit_assert=>assert_equals(
    exp = ls_first-mime_type
    act = ls_second-mime_type
  ).

ENDMETHOD.

ENDCLASS.
