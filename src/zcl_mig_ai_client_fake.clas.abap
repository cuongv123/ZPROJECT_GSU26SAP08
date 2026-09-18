CLASS zcl_mig_ai_client_fake DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES
      zif_mig_ai_client.


    METHODS constructor
      IMPORTING
        iv_response
          TYPE string OPTIONAL

        iv_raise_error
          TYPE abap_bool DEFAULT abap_false.


    METHODS get_last_prompt
      RETURNING
        VALUE(rs_prompt)
          TYPE zif_mig_ai_types=>ty_prompt.


  PRIVATE SECTION.

    DATA mv_response
      TYPE string.


    DATA mv_raise_error
      TYPE abap_bool.


    DATA ms_last_prompt
      TYPE zif_mig_ai_types=>ty_prompt.


ENDCLASS.



CLASS zcl_mig_ai_client_fake IMPLEMENTATION.


  METHOD constructor.

    mv_raise_error =
      iv_raise_error.


    "==========================================================
    " Custom response for tests
    "==========================================================
    IF iv_response IS NOT INITIAL.

      mv_response =
        iv_response.

      RETURN.

    ENDIF.


    "==========================================================
    " Default deterministic fake AI response
    "==========================================================
    mv_response =
      `{`
      &&
      `"applicationSummary":"Fake application summary",`
      &&
      `"businessPurposeInference":{`
      &&
      `"text":"Fake inferred business purpose",`
      &&
      `"confidence":"MEDIUM",`
      &&
      `"reasoning":"Fake reasoning based on supplied technical document"`
      &&
      `},`
      &&
      `"legacyFlowExplanation":"Fake legacy flow explanation",`
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

  ENDMETHOD.



  METHOD zif_mig_ai_client~execute.

    "==========================================================
    " Remember exactly what was sent to the AI provider
    "==========================================================
    ms_last_prompt =
      is_prompt.


    "==========================================================
    " Simulated provider failure
    "==========================================================
    IF mv_raise_error = abap_true.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " A client must never silently return an empty response
    "==========================================================
    IF mv_response IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    rv_response =
      mv_response.

  ENDMETHOD.



  METHOD get_last_prompt.

    rs_prompt =
      ms_last_prompt.

  ENDMETHOD.


ENDCLASS.
