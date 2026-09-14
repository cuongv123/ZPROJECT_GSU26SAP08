CLASS ltc_ai_client_fake DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS returns_default_response
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS returns_configured_response
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS captures_prompt
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS raises_configured_error
      FOR TESTING.

ENDCLASS.



CLASS ltc_ai_client_fake IMPLEMENTATION.


  METHOD returns_default_response.

    "==========================================================
    " Given
    "==========================================================
    DATA(lo_client) =
      NEW zcl_mig_ai_client_fake( ).


    DATA(ls_prompt) =
      VALUE zif_mig_ai_types=>ty_prompt(

        system_prompt =
          `System instruction`

        user_prompt =
          `Technical document`
      ).


    "==========================================================
    " When
    "==========================================================
    DATA(lv_response) =
      lo_client->zif_mig_ai_client~execute(
        is_prompt =
          ls_prompt
      ).


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_not_initial(
      act =
        lv_response

      msg =
        'Fake AI client must return a response'
    ).


    FIND
      '"applicationSummary"'
      IN lv_response.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Default response must contain applicationSummary'
    ).


    FIND
      '"businessPurposeInference"'
      IN lv_response.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Default response must contain businessPurposeInference'
    ).


    FIND
      '"modernizationPlan"'
      IN lv_response.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Default response must contain modernizationPlan'
    ).

  ENDMETHOD.



  METHOD returns_configured_response.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_expected) =
      `{`
      &&
      `"applicationSummary":"CUSTOM_RESPONSE",`
      &&
      `"businessPurposeInference":{`
      &&
      `"text":"Custom purpose",`
      &&
      `"confidence":"HIGH",`
      &&
      `"reasoning":"Custom reasoning"`
      &&
      `},`
      &&
      `"legacyFlowExplanation":"Custom flow",`
      &&
      `"risks":[],`
      &&
      `"modernizationPlan":[],`
      &&
      `"targetArchitecture":[],`
      &&
      `"codeSuggestions":[],`
      &&
      `"manualReview":[]`
      &&
      `}`.


    DATA(lo_client) =
      NEW zcl_mig_ai_client_fake(
        iv_response =
          lv_expected
      ).


    DATA(ls_prompt) =
      VALUE zif_mig_ai_types=>ty_prompt(

        system_prompt =
          `System`

        user_prompt =
          `User`
      ).


    "==========================================================
    " When
    "==========================================================
    DATA(lv_actual) =
      lo_client->zif_mig_ai_client~execute(
        is_prompt =
          ls_prompt
      ).


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp =
        lv_expected

      act =
        lv_actual

      msg =
        'Fake client must return configured response unchanged'
    ).

  ENDMETHOD.



  METHOD captures_prompt.

    "==========================================================
    " Given
    "==========================================================
    DATA(lo_client) =
      NEW zcl_mig_ai_client_fake( ).


    DATA(ls_prompt) =
      VALUE zif_mig_ai_types=>ty_prompt(

        system_prompt =
          `GROUNDING_RULE_TEST`

        user_prompt =
          `# Technical Analysis - ZRMIG_SAMPLE_FULL`
      ).


    "==========================================================
    " When
    "==========================================================
    DATA(lv_response) =
      lo_client->zif_mig_ai_client~execute(
        is_prompt =
          ls_prompt
      ).


    "Response itself is not relevant to this test.
    cl_abap_unit_assert=>assert_not_initial(
      act = lv_response
    ).


    DATA(ls_captured) =
      lo_client->get_last_prompt( ).


    "==========================================================
    " Then
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp =
        `GROUNDING_RULE_TEST`

      act =
        ls_captured-system_prompt

      msg =
        'System prompt must be forwarded unchanged'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        `# Technical Analysis - ZRMIG_SAMPLE_FULL`

      act =
        ls_captured-user_prompt

      msg =
        'User prompt must be forwarded unchanged'
    ).

  ENDMETHOD.



  METHOD raises_configured_error.

    "==========================================================
    " Given
    "==========================================================
    DATA(lo_client) =
      NEW zcl_mig_ai_client_fake(
        iv_raise_error =
          abap_true
      ).


    DATA(ls_prompt) =
      VALUE zif_mig_ai_types=>ty_prompt(

        system_prompt =
          `System`

        user_prompt =
          `User`
      ).


    DATA lv_exception_raised
      TYPE abap_bool.

    lv_exception_raised =
      abap_false.


    "==========================================================
    " When
    "==========================================================
    TRY.

        DATA(lv_response) =
          lo_client->zif_mig_ai_client~execute(
            is_prompt =
              ls_prompt
          ).


        CLEAR lv_response.


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
        'Configured fake provider failure must raise ZCX_MIG_ANALYSIS'
    ).

  ENDMETHOD.


ENDCLASS.
