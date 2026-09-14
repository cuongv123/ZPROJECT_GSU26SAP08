CLASS ltc_ai_response_parser DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_cut
      TYPE REF TO zif_mig_ai_response_parser.


    METHODS setup.


    METHODS parses_complete_response
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS parses_fake_client_response
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS normalizes_unknown_values
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS rejects_empty_response
      FOR TESTING.


    METHODS rejects_missing_summary
      FOR TESTING.


    METHODS accepts_markdown_fence
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.



CLASS ltc_ai_response_parser IMPLEMENTATION.


  METHOD setup.

    mo_cut =
      NEW zcl_mig_ai_response_parser( ).

  ENDMETHOD.



  METHOD parses_complete_response.

    "==========================================================
    " Given
    "==========================================================
    DATA(lv_json) =
      `{`
      &&
      `"applicationSummary":"Legacy report reads company and plant data.",`
      &&
      `"businessPurposeInference":{`
      &&
      `"text":"The report appears to display company and plant information.",`
      &&
      `"confidence":"MEDIUM",`
      &&
      `"reasoning":"Supported by T001, T001W and ALV output."`
      &&
      `},`
      &&
      `"legacyFlowExplanation":"Selection is validated, data is loaded, processed and displayed.",`
      &&
      `"risks":[`
      &&
      `{`
      &&
      `"title":"Explicit transaction commit",`
      &&
      `"description":"Legacy flow calls BAPI_TRANSACTION_COMMIT.",`
      &&
      `"severity":"HIGH",`
      &&
      `"confidence":"HIGH",`
      &&
      `"evidence":"BAPI_TRANSACTION_COMMIT in PROCESS_DATA",`
      &&
      `"manualReview":true`
      &&
      `}`
      &&
      `],`
      &&
      `"modernizationPlan":[`
      &&
      `{`
      &&
      `"sequence":2,`
      &&
      `"title":"Expose UI",`
      &&
      `"description":"Expose migrated model through Fiori Elements.",`
      &&
      `"targetLayer":"FIORI",`
      &&
      `"confidence":"MEDIUM",`
      &&
      `"manualReview":false`
      &&
      `},`
      &&
      `{`
      &&
      `"sequence":1,`
      &&
      `"title":"Create CDS model",`
      &&
      `"description":"Model database read through CDS.",`
      &&
      `"targetLayer":"CDS",`
      &&
      `"confidence":"HIGH",`
      &&
      `"manualReview":false`
      &&
      `}`
      &&
      `],`
      &&
      `"targetArchitecture":[`
      &&
      `{`
      &&
      `"legacyComponent":"SELECT T001",`
      &&
      `"targetComponent":"CDS View Entity",`
      &&
      `"rationale":"Move reusable read model to CDS.",`
      &&
      `"confidence":"HIGH"`
      &&
      `}`
      &&
      `],`
      &&
      `"codeSuggestions":[`
      &&
      `{`
      &&
      `"title":"CDS skeleton",`
      &&
      `"targetObject":"ZI_SAMPLE",`
      &&
      `"suggestion":"Create CDS view entity.",`
      &&
      `"code":"define view entity ZI_SAMPLE as select from t001 { key bukrs };",`
      &&
      `"language":"ABAP",`
      &&
      `"confidence":"MEDIUM",`
      &&
      `"manualReview":true`
      &&
      `}`
      &&
      `],`
      &&
      `"manualReview":[`
      &&
      `{`
      &&
      `"title":"Validate transaction behavior",`
      &&
      `"description":"Confirm required LUW semantics.",`
      &&
      `"severity":"HIGH",`
      &&
      `"confidence":"MEDIUM",`
      &&
      `"evidence":"BAPI_TRANSACTION_COMMIT",`
      &&
      `"manualReview":true`
      &&
      `}`
      &&
      `]`
      &&
      `}`.


    "==========================================================
    " When
    "==========================================================
    DATA(ls_result) =
      mo_cut->parse(
        iv_analysis_id =
          CONV #(
            '00000000000000000000000000000001'
          )

        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_response =
          lv_json
      ).


    "==========================================================
    " Then - identity
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_FULL'
      act = ls_result-program_name
    ).


    "==========================================================
    " Main result
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp =
        'Legacy report reads company and plant data.'

      act =
        ls_result-application_summary
    ).


    cl_abap_unit_assert=>assert_equals(
      exp =
        'MEDIUM'

      act =
        ls_result-business_purpose-confidence
    ).


    "==========================================================
    " Risks
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-risks )
    ).


    READ TABLE ls_result-risks
      INDEX 1
      INTO DATA(ls_risk).


    cl_abap_unit_assert=>assert_equals(
      exp = 'HIGH'
      act = ls_risk-severity
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_risk-manual_review
    ).


    "==========================================================
    " Migration plan must be sorted by sequence
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( ls_result-modernization_plan )
    ).


    READ TABLE ls_result-modernization_plan
      INDEX 1
      INTO DATA(ls_step).


    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = ls_step-sequence
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'Create CDS model'
      act = ls_step-title
    ).


    "==========================================================
    " Architecture
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-target_architecture )
    ).


    "==========================================================
    " Code suggestion
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-code_suggestions )
    ).


    READ TABLE ls_result-code_suggestions
      INDEX 1
      INTO DATA(ls_code).


    cl_abap_unit_assert=>assert_equals(
      exp = 'ZI_SAMPLE'
      act = ls_code-target_object
    ).


    "==========================================================
    " Manual review
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-manual_review )
    ).

  ENDMETHOD.



  METHOD parses_fake_client_response.

  DATA lv_analysis_id
    TYPE zif_mig_types=>ty_analysis_id.


  DATA(lo_fake) =
    NEW zcl_mig_ai_client_fake( ).


  DATA(lv_json) =
    lo_fake->zif_mig_ai_client~execute(
      is_prompt =
        VALUE #(
          system_prompt = `SYSTEM`
          user_prompt   = `USER`
        )
    ).


  DATA(ls_result) =
    mo_cut->parse(
      iv_analysis_id =
        lv_analysis_id

      iv_program_name =
        'ZRMIG_SAMPLE_FULL'

      iv_response =
        lv_json
    ).


  cl_abap_unit_assert=>assert_equals(
    exp =
      'Fake application summary'

    act =
      ls_result-application_summary
  ).


  cl_abap_unit_assert=>assert_equals(
    exp =
      'Fake inferred business purpose'

    act =
      ls_result-business_purpose-text
  ).


  cl_abap_unit_assert=>assert_equals(
    exp =
      'MEDIUM'

    act =
      ls_result-business_purpose-confidence
  ).

ENDMETHOD.



  METHOD normalizes_unknown_values.
    DATA lv_analysis_id
  TYPE zif_mig_types=>ty_analysis_id.

    DATA(lv_json) =
      `{`
      &&
      `"applicationSummary":"Summary",`
      &&
      `"businessPurposeInference":{`
      &&
      `"text":"Purpose",`
      &&
      `"confidence":"UNKNOWN",`
      &&
      `"reasoning":"Reason"`
      &&
      `},`
      &&
      `"legacyFlowExplanation":"Flow",`
      &&
      `"risks":[`
      &&
      `{`
      &&
      `"title":"Risk",`
      &&
      `"description":"Description",`
      &&
      `"severity":"UNKNOWN",`
      &&
      `"confidence":"UNKNOWN",`
      &&
      `"evidence":"Evidence",`
      &&
      `"manualReview":true`
      &&
      `}`
      &&
      `],`
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


    DATA(ls_result) =
      mo_cut->parse(
        iv_analysis_id =
          lv_analysis_id

        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_response =
          lv_json
      ).

    "Unknown confidence must degrade safely to LOW.
    cl_abap_unit_assert=>assert_equals(
      exp = 'LOW'
      act = ls_result-business_purpose-confidence
    ).


    READ TABLE ls_result-risks
      INDEX 1
      INTO DATA(ls_risk).


    cl_abap_unit_assert=>assert_equals(
      exp = 'LOW'
      act = ls_risk-confidence
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'MEDIUM'
      act = ls_risk-severity
    ).

  ENDMETHOD.



  METHOD rejects_empty_response.

      DATA lv_analysis_id
        TYPE zif_mig_types=>ty_analysis_id.

      DATA lv_exception_raised
        TYPE abap_bool.


      TRY.

          DATA(ls_result) =
            mo_cut->parse(
              iv_analysis_id =
                lv_analysis_id

              iv_program_name =
                'ZRMIG_SAMPLE_FULL'

              iv_response =
                ``
            ).

          CLEAR ls_result.


        CATCH zcx_mig_analysis.

          lv_exception_raised =
            abap_true.

      ENDTRY.


      cl_abap_unit_assert=>assert_equals(
        exp = abap_true
        act = lv_exception_raised
        msg = 'Empty AI response must be rejected'
      ).

    ENDMETHOD.


  METHOD rejects_missing_summary.

    DATA lv_analysis_id
  TYPE zif_mig_types=>ty_analysis_id.
    DATA(lv_json) =
      `{`
      &&
      `"applicationSummary":"",`
      &&
      `"businessPurposeInference":{`
      &&
      `"text":"Purpose",`
      &&
      `"confidence":"MEDIUM",`
      &&
      `"reasoning":"Reason"`
      &&
      `},`
      &&
      `"legacyFlowExplanation":"Flow",`
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


    DATA lv_exception_raised
      TYPE abap_bool.


    TRY.

        DATA(ls_result) =
          mo_cut->parse(
            iv_analysis_id =
              lv_analysis_id

            iv_program_name =
              'ZRMIG_SAMPLE_FULL'

            iv_response =
              lv_json
          ).


        CLEAR ls_result.


      CATCH zcx_mig_analysis.

        lv_exception_raised =
          abap_true.

    ENDTRY.


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lv_exception_raised
      msg = 'Response without applicationSummary must fail'
    ).

  ENDMETHOD.



  METHOD accepts_markdown_fence.
    DATA lv_analysis_id
        TYPE zif_mig_types=>ty_analysis_id.
    DATA(lv_json) =
      '```json'
      &&
      cl_abap_char_utilities=>newline
      &&
      `{`
      &&
      `"applicationSummary":"Fenced JSON",`
      &&
      `"businessPurposeInference":{`
      &&
      `"text":"Purpose",`
      &&
      `"confidence":"MEDIUM",`
      &&
      `"reasoning":"Evidence based"`
      &&
      `},`
      &&
      `"legacyFlowExplanation":"Flow",`
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
      `}`
      &&
      cl_abap_char_utilities=>newline
      &&
      '```'.


    DATA(ls_result) =
      mo_cut->parse(
        iv_analysis_id =
          lv_analysis_id

        iv_program_name =
          'ZRMIG_SAMPLE_FULL'

        iv_response =
          lv_json
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'Fenced JSON'
      act = ls_result-application_summary
    ).

  ENDMETHOD.


ENDCLASS.
