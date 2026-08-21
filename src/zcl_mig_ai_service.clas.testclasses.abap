CLASS ltc_ai_service DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_cut
      TYPE REF TO zif_mig_ai_service.


    METHODS setup.


    METHODS analyze_full_pipeline
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS rejects_empty_markdown
      FOR TESTING.


    METHODS preserves_analysis_identity
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS propagates_ai_error
      FOR TESTING.

ENDCLASS.



CLASS ltc_ai_service IMPLEMENTATION.


  METHOD setup.

    DATA(lo_prompt_builder) =
      NEW zcl_mig_ai_prompt_builder( ).


    DATA(lo_ai_client) =
      NEW zcl_mig_ai_client_fake( ).


    DATA(lo_response_parser) =
      NEW zcl_mig_ai_response_parser( ).


    mo_cut =
      NEW zcl_mig_ai_service(

        io_prompt_builder =
          lo_prompt_builder

        io_ai_client =
          lo_ai_client

        io_response_parser =
          lo_response_parser
      ).

  ENDMETHOD.



  METHOD analyze_full_pipeline.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.


    DATA(lv_markdown) =
      `# Technical Analysis`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Program: ZRMIG_SAMPLE_FULL`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Database: T001`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Output: ALV Grid`.


    DATA(ls_result) =
      mo_cut->analyze(
        iv_analysis_id =
          lv_analysis_id

        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_markdown =
          lv_markdown
      ).


    "==========================================================
    " AI result must exist
    "==========================================================
    cl_abap_unit_assert=>assert_not_initial(
      act =
        ls_result-application_summary

      msg =
        'AI service must return an assessment'
    ).


    "==========================================================
    " Parser result must be preserved
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp =
        'Fake application summary'

      act =
        ls_result-application_summary

      msg =
        'Assessment must originate from fake AI response'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        'Fake inferred business purpose'

      act =
        ls_result-business_purpose-text

      msg =
        'Business purpose must be parsed from AI response'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        'MEDIUM'

      act =
        ls_result-business_purpose-confidence

      msg =
        'Confidence must be normalized by parser'
    ).

  ENDMETHOD.



  METHOD rejects_empty_markdown.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    DATA lv_exception_raised
      TYPE abap_bool.

    lv_exception_raised =
      abap_false.


    TRY.

        DATA(ls_result) =
          mo_cut->analyze(
            iv_analysis_id =
              lv_analysis_id

            iv_program_name =
              'ZRMIG_SAMPLE_FULL'

            iv_markdown =
              ``
          ).

        CLEAR ls_result.


      CATCH zcx_mig_analysis.

        lv_exception_raised =
          abap_true.

    ENDTRY.


    cl_abap_unit_assert=>assert_equals(
      exp =
        abap_true

      act =
        lv_exception_raised

      msg =
        'Empty Markdown must be rejected'
    ).

  ENDMETHOD.



  METHOD preserves_analysis_identity.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.


    DATA(ls_result) =
      mo_cut->analyze(
        iv_analysis_id =
          lv_analysis_id

        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_markdown =
          `# Technical Analysis`
      ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        lv_analysis_id

      act =
        ls_result-analysis_id

      msg =
        'AnalysisId must be preserved through AI pipeline'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        'ZRMIG_SAMPLE_FULL'

      act =
        ls_result-program_name

      msg =
        'Program name must be preserved through AI pipeline'
    ).

  ENDMETHOD.



  METHOD propagates_ai_error.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.


    DATA(lo_prompt_builder) =
      NEW zcl_mig_ai_prompt_builder( ).


    DATA(lo_ai_client) =
      NEW zcl_mig_ai_client_fake(
        iv_raise_error =
          abap_true
      ).


    DATA(lo_response_parser) =
      NEW zcl_mig_ai_response_parser( ).


    DATA(lo_service) =
      NEW zcl_mig_ai_service(

        io_prompt_builder =
          lo_prompt_builder

        io_ai_client =
          lo_ai_client

        io_response_parser =
          lo_response_parser
      ).


    DATA lv_exception_raised
      TYPE abap_bool.

    lv_exception_raised =
      abap_false.


    TRY.

        DATA(ls_result) =
          lo_service->zif_mig_ai_service~analyze(
            iv_analysis_id =
              lv_analysis_id

            iv_program_name =
              'ZRMIG_SAMPLE_FULL'

            iv_markdown =
              `# Technical Analysis`
          ).

        CLEAR ls_result.


      CATCH zcx_mig_analysis.

        lv_exception_raised =
          abap_true.

    ENDTRY.


    cl_abap_unit_assert=>assert_equals(
      exp =
        abap_true

      act =
        lv_exception_raised

      msg =
        'AI provider error must propagate as ZCX_MIG_ANALYSIS'
    ).

  ENDMETHOD.


ENDCLASS.
