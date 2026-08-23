CLASS lcl_tech_doc_service_fake DEFINITION
  FINAL.

  PUBLIC SECTION.

    INTERFACES
      zif_mig_tech_doc_service.

ENDCLASS.



CLASS lcl_tech_doc_service_fake IMPLEMENTATION.


  METHOD zif_mig_tech_doc_service~generate.

    CLEAR rs_result.


    rs_result-analysis_id =
      iv_analysis_id.


    rs_result-program_name =
      'ZRMIG_SAMPLE_FULL'.


    rs_result-file_name =
      'zrmig_sample_full_technical_analysis.md'.


    rs_result-mime_type =
      'text/markdown; charset=utf-8'.


    rs_result-markdown =
      `# Technical Analysis - ZRMIG_SAMPLE_FULL`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Database: T001`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Output: ALV Grid`.

  ENDMETHOD.


ENDCLASS.





CLASS ltc_ai_support_service DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.


  PRIVATE SECTION.

    DATA mo_cut
      TYPE REF TO zif_mig_ai_support_service.


    DATA mo_ai_client
      TYPE REF TO zcl_mig_ai_client_fake.


    METHODS setup.


    METHODS create_analysis_id
      RETURNING
        VALUE(rv_analysis_id)
          TYPE zif_mig_types=>ty_analysis_id
      RAISING
        zcx_mig_analysis.


    METHODS returns_fake_assessment
      FOR TESTING
      RAISING
        zcx_mig_analysis.


    METHODS preserves_analysis_identity
      FOR TESTING
      RAISING
        zcx_mig_analysis.


    METHODS forwards_technical_document
      FOR TESTING
      RAISING
        zcx_mig_analysis.


    METHODS rejects_empty_analysis_id
      FOR TESTING.


    METHODS propagates_fake_ai_error
      FOR TESTING.


ENDCLASS.





CLASS ltc_ai_support_service IMPLEMENTATION.


  METHOD setup.

    "==========================================================
    " Prompt builder
    "==========================================================
    DATA(lo_prompt_builder) =
      NEW zcl_mig_ai_prompt_builder( ).


    "==========================================================
    " Fake AI provider
    "==========================================================
    mo_ai_client =
      NEW zcl_mig_ai_client_fake( ).


    "==========================================================
    " Response parser
    "==========================================================
    DATA(lo_response_parser) =
      NEW zcl_mig_ai_response_parser( ).


    "==========================================================
    " AI pipeline
    "==========================================================
    DATA(lo_ai_service) =
      NEW zcl_mig_ai_service(

        io_prompt_builder =
          lo_prompt_builder

        io_ai_client =
          mo_ai_client

        io_response_parser =
          lo_response_parser
      ).


    "==========================================================
    " Fake Technical Document service
    " No database access
    "==========================================================
    DATA(lo_tech_doc_service) =
      NEW lcl_tech_doc_service_fake( ).


    "==========================================================
    " Class under test
    "==========================================================
    mo_cut =
      NEW zcl_mig_ai_support_service(

        io_ai_service =
          lo_ai_service

        io_tech_doc_service =
          lo_tech_doc_service
      ).

  ENDMETHOD.





  METHOD create_analysis_id.

    TRY.

        rv_analysis_id =
          cl_system_uuid=>create_uuid_x16_static( ).


      CATCH cx_uuid_error INTO DATA(lx_uuid).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed

          previous =
            lx_uuid
        ).

    ENDTRY.

  ENDMETHOD.





  METHOD returns_fake_assessment.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_analysis_id) =
      create_analysis_id( ).


    "==========================================================
    " When
    "==========================================================
    DATA(ls_assessment) =
      mo_cut->analyze(
        iv_analysis_id =
          lv_analysis_id
      ).


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_not_initial(
      act =
        ls_assessment-application_summary

      msg =
        'AI Support must return an assessment'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        'Fake application summary'

      act =
        ls_assessment-application_summary

      msg =
        'Assessment must come from Fake AI client'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        'Fake inferred business purpose'

      act =
        ls_assessment-business_purpose-text

      msg =
        'Business purpose must be parsed from Fake AI response'
    ).

  ENDMETHOD.





  METHOD preserves_analysis_identity.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_analysis_id) =
      create_analysis_id( ).


    "==========================================================
    " When
    "==========================================================
    DATA(ls_assessment) =
      mo_cut->analyze(
        iv_analysis_id =
          lv_analysis_id
      ).


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp =
        lv_analysis_id

      act =
        ls_assessment-analysis_id

      msg =
        'AI Support must preserve AnalysisId'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        'ZRMIG_SAMPLE_FULL'

      act =
        ls_assessment-program_name

      msg =
        'AI Support must preserve ProgramName from Technical Document'
    ).

  ENDMETHOD.





  METHOD forwards_technical_document.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_analysis_id) =
      create_analysis_id( ).


    "==========================================================
    " When
    "==========================================================
    DATA(ls_assessment) =
      mo_cut->analyze(
        iv_analysis_id =
          lv_analysis_id
      ).


    cl_abap_unit_assert=>assert_not_initial(
      act =
        ls_assessment-application_summary
    ).


    "==========================================================
    " Inspect prompt captured by Fake AI client
    "==========================================================
    DATA(ls_prompt) =
      mo_ai_client->get_last_prompt( ).


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_not_initial(
      act =
        ls_prompt-user_prompt

      msg =
        'AI client must receive user prompt'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act =
        ls_prompt-user_prompt

      exp =
        '*ZRMIG_SAMPLE_FULL*'

      msg =
        'Technical Document program must reach AI prompt'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act =
        ls_prompt-user_prompt

      exp =
        '*T001*'

      msg =
        'Technical Document content must reach AI prompt'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act =
        ls_prompt-user_prompt

      exp =
        '*ALV Grid*'

      msg =
        'Technical Document output information must reach AI prompt'
    ).

  ENDMETHOD.





  METHOD rejects_empty_analysis_id.

    "==========================================================
    " Given
    "==========================================================
    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.


    DATA lv_exception_raised
      TYPE abap_bool.

    lv_exception_raised =
      abap_false.


    "==========================================================
    " When
    "==========================================================
    TRY.

        DATA(ls_assessment) =
          mo_cut->analyze(
            iv_analysis_id =
              lv_analysis_id
          ).

        CLEAR ls_assessment.


      CATCH zcx_mig_analysis.

        lv_exception_raised =
          abap_true.

    ENDTRY.


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp =
        abap_true

      act =
        lv_exception_raised

      msg =
        'Empty AnalysisId must be rejected'
    ).

  ENDMETHOD.





  METHOD propagates_fake_ai_error.

    "==========================================================
    " Build failing Fake AI provider
    "==========================================================
    DATA(lo_prompt_builder) =
      NEW zcl_mig_ai_prompt_builder( ).


    DATA(lo_failed_ai_client) =
      NEW zcl_mig_ai_client_fake(
        iv_raise_error =
          abap_true
      ).


    DATA(lo_response_parser) =
      NEW zcl_mig_ai_response_parser( ).


    DATA(lo_ai_service) =
      NEW zcl_mig_ai_service(

        io_prompt_builder =
          lo_prompt_builder

        io_ai_client =
          lo_failed_ai_client

        io_response_parser =
          lo_response_parser
      ).


    DATA(lo_tech_doc_service) =
      NEW lcl_tech_doc_service_fake( ).


    DATA(lo_support_service) =
      NEW zcl_mig_ai_support_service(

        io_ai_service =
          lo_ai_service

        io_tech_doc_service =
          lo_tech_doc_service
      ).


    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.


    TRY.

        lv_analysis_id =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error.

        cl_abap_unit_assert=>fail(
          msg =
            'Unable to create test AnalysisId'
        ).

    ENDTRY.


    DATA lv_exception_raised
      TYPE abap_bool.

    lv_exception_raised =
      abap_false.


    "==========================================================
    " When
    "==========================================================
    TRY.

        DATA(ls_assessment) =
          lo_support_service->zif_mig_ai_support_service~analyze(
            iv_analysis_id =
              lv_analysis_id
          ).

        CLEAR ls_assessment.


      CATCH zcx_mig_analysis.

        lv_exception_raised =
          abap_true.

    ENDTRY.


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp =
        abap_true

      act =
        lv_exception_raised

      msg =
        'AI provider failure must propagate through AI Support'
    ).

  ENDMETHOD.


ENDCLASS.
