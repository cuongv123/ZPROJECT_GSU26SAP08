CLASS ltc_ai_prompt_builder DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_cut
      TYPE REF TO zif_mig_ai_prompt_builder.


    METHODS setup.


    METHODS build_preserves_markdown
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS build_enforces_grounding
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS build_defines_json_contract
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS build_rejects_empty_markdown
      FOR TESTING.

ENDCLASS.



CLASS ltc_ai_prompt_builder IMPLEMENTATION.


  METHOD setup.

    mo_cut =
      NEW zcl_mig_ai_prompt_builder( ).

  ENDMETHOD.



  METHOD build_preserves_markdown.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_markdown) =
      `# Technical Analysis - ZRMIG_SAMPLE_FULL`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Database: T001`
      &&
      cl_abap_char_utilities=>newline
      &&
      `BAPI: BAPI_USER_GET_DETAIL`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Output: GT_RESULT via CL_GUI_ALV_GRID`.


    "==========================================================
    " When
    "==========================================================
    DATA(ls_prompt) =
      mo_cut->build(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_markdown =
          lv_markdown
      ).


    "==========================================================
    " Then - prompt exists
    "==========================================================
    cl_abap_unit_assert=>assert_not_initial(
      act =
        ls_prompt-system_prompt

      msg =
        'System prompt must not be empty'
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act =
        ls_prompt-user_prompt

      msg =
        'User prompt must not be empty'
    ).


    "==========================================================
    " Program name preserved
    "==========================================================
    FIND
      'ZRMIG_SAMPLE_FULL'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Program name must be included in AI prompt'
    ).


    "==========================================================
    " Markdown facts preserved
    "==========================================================
    FIND
      'Database: T001'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Database fact must be preserved'
    ).


    FIND
      'BAPI_USER_GET_DETAIL'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'BAPI fact must be preserved'
    ).


    FIND
      'GT_RESULT via CL_GUI_ALV_GRID'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'ALV fact must be preserved'
    ).


    "==========================================================
    " Markdown boundary present
    "==========================================================
    FIND
      'TECHNICAL DOCUMENT START'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Technical document start marker missing'
    ).


    FIND
      'TECHNICAL DOCUMENT END'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Technical document end marker missing'
    ).

  ENDMETHOD.



  METHOD build_enforces_grounding.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_markdown) =
      `# Technical Analysis`
      &&
      cl_abap_char_utilities=>newline
      &&
      `Database: T001`.


    "==========================================================
    " When
    "==========================================================
    DATA(ls_prompt) =
      mo_cut->build(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_markdown =
          lv_markdown
      ).


    "==========================================================
    " Then - AI must not invent facts
    "==========================================================
    FIND
      'Do not invent'
      IN ls_prompt-system_prompt
      IGNORING CASE.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Prompt must prohibit invented technical facts'
    ).


    "==========================================================
    " Technical document = factual source
    "==========================================================
    FIND
      'only source of technical facts'
      IN ls_prompt-system_prompt
      IGNORING CASE.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Prompt must define supplied document as fact source'
    ).


    "==========================================================
    " Business purpose must be inference
    "==========================================================
    FIND
      'Business purpose is an inference'
      IN ls_prompt-system_prompt
      IGNORING CASE.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Business purpose must be explicitly marked as inference'
    ).


    "==========================================================
    " Static flow is not full CFG
    "==========================================================
    FIND
      'runtime control-flow graph'
      IN ls_prompt-system_prompt
      IGNORING CASE.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Prompt must state static-flow limitation'
    ).


    "==========================================================
    " Manual review policy
    "==========================================================
    FIND
      'manual review'
      IN ls_prompt-system_prompt
      IGNORING CASE.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Prompt must require manual review for uncertain facts'
    ).


    "==========================================================
    " RAP transaction safety
    "==========================================================
    FIND
      'COMMIT WORK'
      IN ls_prompt-system_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Prompt must protect RAP transaction handling'
    ).

  ENDMETHOD.



  METHOD build_defines_json_contract.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_markdown) =
      `# Technical Analysis - ZRMIG_SAMPLE_FULL`.


    "==========================================================
    " When
    "==========================================================
    DATA(ls_prompt) =
      mo_cut->build(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_markdown =
          lv_markdown
      ).


    "==========================================================
    " Then - JSON-only output
    "==========================================================
    FIND
      'Return JSON only'
      IN ls_prompt-system_prompt
      IGNORING CASE.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'System prompt must require JSON-only output'
    ).


    "==========================================================
    " applicationSummary
    "==========================================================
    FIND
      '"applicationSummary"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'applicationSummary missing from JSON contract'
    ).


    "==========================================================
    " businessPurposeInference
    "==========================================================
    FIND
      '"businessPurposeInference"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'businessPurposeInference missing from JSON contract'
    ).


    "==========================================================
    " legacyFlowExplanation
    "==========================================================
    FIND
      '"legacyFlowExplanation"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'legacyFlowExplanation missing from JSON contract'
    ).


    "==========================================================
    " risks
    "==========================================================
    FIND
      '"risks"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'risks missing from JSON contract'
    ).


    "==========================================================
    " modernizationPlan
    "==========================================================
    FIND
      '"modernizationPlan"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'modernizationPlan missing from JSON contract'
    ).


    "==========================================================
    " targetArchitecture
    "==========================================================
    FIND
      '"targetArchitecture"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'targetArchitecture missing from JSON contract'
    ).


    "==========================================================
    " codeSuggestions
    "==========================================================
    FIND
      '"codeSuggestions"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'codeSuggestions missing from JSON contract'
    ).


    "==========================================================
    " manualReview
    "==========================================================
    FIND
      '"manualReview"'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'manualReview missing from JSON contract'
    ).


    "==========================================================
    " Confidence contract
    "==========================================================
    FIND
      'HIGH|MEDIUM|LOW'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Confidence enum missing from JSON contract'
    ).


    "==========================================================
    " Severity contract
    "==========================================================
    FIND
      'INFO|LOW|MEDIUM|HIGH|CRITICAL'
      IN ls_prompt-user_prompt.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Severity enum missing from JSON contract'
    ).

  ENDMETHOD.



  METHOD build_rejects_empty_markdown.

    DATA lv_exception_raised
      TYPE abap_bool.

    lv_exception_raised =
      abap_false.


    TRY.

        DATA(ls_prompt) =
          mo_cut->build(
            iv_program_name =
              'ZRMIG_SAMPLE_FULL'

            iv_markdown =
              ``
          ).


        "Should never reach this line.
        CLEAR ls_prompt.


      CATCH zcx_mig_analysis INTO DATA(lx_analysis).

        lv_exception_raised =
          abap_true.


        "======================================================
        " Verify context carried by exception
        "======================================================
        cl_abap_unit_assert=>assert_equals(
          exp =
            'ZRMIG_SAMPLE_FULL'

          act =
            lx_analysis->program_name

          msg =
            'Exception must preserve program name'
        ).

    ENDTRY.


    cl_abap_unit_assert=>assert_equals(
      exp =
        abap_true

      act =
        lv_exception_raised

      msg =
        'Empty Markdown must raise ZCX_MIG_ANALYSIS'
    ).

  ENDMETHOD.


ENDCLASS.
