CLASS zcl_mig_ai_client_gemini DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.


  PUBLIC SECTION.

    INTERFACES
      zif_mig_ai_client.


    METHODS constructor
      IMPORTING
        iv_destination
          TYPE rfcdest
          DEFAULT 'ZGEMINI_API'

        iv_api_key
          TYPE string

        iv_model
          TYPE string
          DEFAULT 'gemini-3.5-flash-lite'

        iv_timeout
          TYPE i
          DEFAULT 120

        iv_max_output_tokens
          TYPE i
          DEFAULT 8192.


  PRIVATE SECTION.

    "==========================================================
    " Minimal Gemini response wire types
    "==========================================================
    TYPES:
      BEGIN OF ty_content,

        type
          TYPE string,

        text
          TYPE string,

      END OF ty_content.


    TYPES:
      tt_content
        TYPE STANDARD TABLE OF ty_content
        WITH EMPTY KEY.


    TYPES:
      BEGIN OF ty_step,

        type
          TYPE string,

        content
          TYPE tt_content,

      END OF ty_step.


    TYPES:
      tt_step
        TYPE STANDARD TABLE OF ty_step
        WITH EMPTY KEY.


    TYPES:
      BEGIN OF ty_error,

        code
          TYPE string,

        message
          TYPE string,

      END OF ty_error.


    TYPES:
      BEGIN OF ty_response,

        status
          TYPE string,

        error
          TYPE ty_error,

        steps
          TYPE tt_step,

      END OF ty_response.


    DATA mv_destination
      TYPE rfcdest.


    DATA mv_api_key
      TYPE string.


    DATA mv_model
      TYPE string.


    DATA mv_timeout
      TYPE i.


    DATA mv_max_output_tokens
      TYPE i.


    METHODS build_response_schema
      RETURNING
        VALUE(rv_schema)
          TYPE string.


    METHODS build_request
      IMPORTING
        is_prompt
          TYPE zif_mig_ai_types=>ty_prompt

      RETURNING
        VALUE(rv_json)
          TYPE string.


    METHODS extract_response
      IMPORTING
        iv_body
          TYPE string

      RETURNING
        VALUE(rv_response)
          TYPE string

      RAISING
        zcx_mig_analysis.


ENDCLASS.



CLASS zcl_mig_ai_client_gemini IMPLEMENTATION.


  METHOD constructor.

    mv_destination =
      iv_destination.

    mv_api_key =
      iv_api_key.

    mv_model =
      iv_model.

    mv_timeout =
      iv_timeout.

    mv_max_output_tokens =
      iv_max_output_tokens.

  ENDMETHOD.



  METHOD build_response_schema.

    "==========================================================
    " JSON schema expected by ZCL_MIG_AI_RESPONSE_PARSER
    "==========================================================

    rv_schema =
      `{`
      &&
      `"type":"object",`
      &&
      `"properties":{`

      &&
      `"applicationSummary":{`
      &&
      `"type":"string"`
      &&
      `},`

      &&
      `"businessPurposeInference":{`
      &&
      `"type":"object",`
      &&
      `"properties":{`
      &&
      `"text":{"type":"string"},`
      &&
      `"confidence":{"type":"string"},`
      &&
      `"reasoning":{"type":"string"}`
      &&
      `},`
      &&
      `"required":[`
      &&
      `"text",`
      &&
      `"confidence",`
      &&
      `"reasoning"`
      &&
      `]`
      &&
      `},`

      &&
      `"legacyFlowExplanation":{`
      &&
      `"type":"string"`
      &&
      `},`

      &&
      `"risks":{`
      &&
      `"type":"array",`
      &&
      `"items":{`
      &&
      `"type":"object",`
      &&
      `"properties":{`
      &&
      `"title":{"type":"string"},`
      &&
      `"description":{"type":"string"},`
      &&
      `"severity":{"type":"string"},`
      &&
      `"confidence":{"type":"string"},`
      &&
      `"evidence":{"type":"string"},`
      &&
      `"manualReview":{"type":"boolean"}`
      &&
      `},`
      &&
      `"required":[`
      &&
      `"title",`
      &&
      `"description",`
      &&
      `"severity",`
      &&
      `"confidence",`
      &&
      `"evidence",`
      &&
      `"manualReview"`
      &&
      `]`
      &&
      `}`
      &&
      `},`

      &&
      `"modernizationPlan":{`
      &&
      `"type":"array",`
      &&
      `"items":{`
      &&
      `"type":"object",`
      &&
      `"properties":{`
      &&
      `"sequence":{"type":"integer"},`
      &&
      `"title":{"type":"string"},`
      &&
      `"description":{"type":"string"},`
      &&
      `"targetLayer":{"type":"string"},`
      &&
      `"confidence":{"type":"string"},`
      &&
      `"manualReview":{"type":"boolean"}`
      &&
      `},`
      &&
      `"required":[`
      &&
      `"sequence",`
      &&
      `"title",`
      &&
      `"description",`
      &&
      `"targetLayer",`
      &&
      `"confidence",`
      &&
      `"manualReview"`
      &&
      `]`
      &&
      `}`
      &&
      `},`

      &&
      `"targetArchitecture":{`
      &&
      `"type":"array",`
      &&
      `"items":{`
      &&
      `"type":"object",`
      &&
      `"properties":{`
      &&
      `"legacyComponent":{"type":"string"},`
      &&
      `"targetComponent":{"type":"string"},`
      &&
      `"rationale":{"type":"string"},`
      &&
      `"confidence":{"type":"string"}`
      &&
      `},`
      &&
      `"required":[`
      &&
      `"legacyComponent",`
      &&
      `"targetComponent",`
      &&
      `"rationale",`
      &&
      `"confidence"`
      &&
      `]`
      &&
      `}`
      &&
      `},`

      &&
      `"codeSuggestions":{`
      &&
      `"type":"array",`
      &&
      `"items":{`
      &&
      `"type":"object",`
      &&
      `"properties":{`
      &&
      `"title":{"type":"string"},`
      &&
      `"targetObject":{"type":"string"},`
      &&
      `"suggestion":{"type":"string"},`
      &&
      `"code":{"type":"string"},`
      &&
      `"language":{"type":"string"},`
      &&
      `"confidence":{"type":"string"},`
      &&
      `"manualReview":{"type":"boolean"}`
      &&
      `},`
      &&
      `"required":[`
      &&
      `"title",`
      &&
      `"targetObject",`
      &&
      `"suggestion",`
      &&
      `"code",`
      &&
      `"language",`
      &&
      `"confidence",`
      &&
      `"manualReview"`
      &&
      `]`
      &&
      `}`
      &&
      `},`

      &&
      `"manualReview":{`
      &&
      `"type":"array",`
      &&
      `"items":{`
      &&
      `"type":"object",`
      &&
      `"properties":{`
      &&
      `"title":{"type":"string"},`
      &&
      `"description":{"type":"string"},`
      &&
      `"severity":{"type":"string"},`
      &&
      `"confidence":{"type":"string"},`
      &&
      `"evidence":{"type":"string"},`
      &&
      `"manualReview":{"type":"boolean"}`
      &&
      `},`
      &&
      `"required":[`
      &&
      `"title",`
      &&
      `"description",`
      &&
      `"severity",`
      &&
      `"confidence",`
      &&
      `"evidence",`
      &&
      `"manualReview"`
      &&
      `]`
      &&
      `}`
      &&
      `}`

      &&
      `},`

      &&
      `"required":[`
      &&
      `"applicationSummary",`
      &&
      `"businessPurposeInference",`
      &&
      `"legacyFlowExplanation",`
      &&
      `"risks",`
      &&
      `"modernizationPlan",`
      &&
      `"targetArchitecture",`
      &&
      `"codeSuggestions",`
      &&
      `"manualReview"`
      &&
      `]`

      &&
      `}`.

  ENDMETHOD.



  METHOD build_request.

    "==========================================================
    " Serialize dynamic strings independently.
    "
    " Technical Document contains quotes, newlines, ABAP source,
    " Markdown, backslashes, etc. Never concatenate it directly
    " into JSON without escaping.
    "==========================================================

    DATA(lv_model_json) =
      /ui2/cl_json=>serialize(
        data =
          mv_model

        compress =
          abap_true
      ).


    DATA(lv_system_json) =
      /ui2/cl_json=>serialize(
        data =
          is_prompt-system_prompt

        compress =
          abap_true
      ).


    DATA(lv_user_json) =
      /ui2/cl_json=>serialize(
        data =
          is_prompt-user_prompt

        compress =
          abap_true
      ).


    DATA(lv_schema) =
      build_response_schema( ).


    DATA(lv_max_tokens) =
      |{ mv_max_output_tokens }|.


    "==========================================================
    " Gemini Interactions API request
    "==========================================================

    rv_json =
      `{"model":`
      &&
      lv_model_json

      &&
      `,"system_instruction":`
      &&
      lv_system_json

      &&
      `,"input":`
      &&
      lv_user_json

      &&
      `,"store":false`

      &&
      `,"response_format":{`
      &&
      `"type":"text",`
      &&
      `"mime_type":"application/json",`
      &&
      `"schema":`
      &&
      lv_schema
      &&
      `}`

      &&
      `,"generation_config":{`
      &&
      `"max_output_tokens":`
      &&
      lv_max_tokens
      &&
      `}`

      &&
      `}`.

  ENDMETHOD.



  METHOD extract_response.

    DATA ls_response
      TYPE ty_response.


    "==========================================================
    " Parse Gemini envelope
    "==========================================================

    TRY.

        /ui2/cl_json=>deserialize(
          EXPORTING
            json =
              iv_body

          CHANGING
            data =
              ls_response
        ).

      CATCH cx_root INTO DATA(lx_json).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed

          previous =
            lx_json
        ).

    ENDTRY.


    "==========================================================
    " Provider-level failure
    "==========================================================

    IF ls_response-error-message IS NOT INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    IF ls_response-status <> 'completed'.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " Actual response observed from Gemini:
    "
    " steps[]
    "   thought
    "   model_output
    "
    " Do NOT assume a fixed array index.
    "==========================================================

    READ TABLE ls_response-steps
      WITH KEY
        type = 'model_output'
      INTO DATA(ls_model_output).


    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " We requested a TEXT response format containing JSON.
    "==========================================================

    READ TABLE ls_model_output-content
      WITH KEY
        type = 'text'
      INTO DATA(ls_text).


    IF sy-subrc <> 0
       OR ls_text-text IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " Return ONLY assessment JSON.
    "
    " ZCL_MIG_AI_RESPONSE_PARSER remains responsible for
    " interpreting the business assessment.
    "==========================================================

    rv_response =
      ls_text-text.

  ENDMETHOD.



  METHOD zif_mig_ai_client~execute.

    CLEAR rv_response.


    "==========================================================
    " Configuration validation
    "==========================================================

    IF mv_destination IS INITIAL
       OR mv_api_key IS INITIAL
       OR mv_model IS INITIAL
       OR mv_timeout <= 0
       OR mv_max_output_tokens <= 0.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " Prompt validation
    "==========================================================

    IF is_prompt-system_prompt IS INITIAL
       OR is_prompt-user_prompt IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " Create HTTP client from SM59 destination ZGEMINI_API
    "==========================================================

    DATA lo_http_client
      TYPE REF TO if_http_client.


    cl_http_client=>create_by_destination(
      EXPORTING
        destination =
          mv_destination

      IMPORTING
        client =
          lo_http_client

      EXCEPTIONS
        OTHERS =
          1
    ).


    IF sy-subrc <> 0
       OR lo_http_client IS NOT BOUND.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    DATA(lv_request_body) =
      build_request(
        is_prompt =
          is_prompt
      ).


    "==========================================================
    " HTTP request
    "==========================================================

    lo_http_client->request->set_method(
      'POST'
    ).


    lo_http_client->request->set_header_field(
      name =
        '~request_uri'

      value =
        '/v1/interactions'
    ).


    lo_http_client->request->set_header_field(
      name =
        'Content-Type'

      value =
        'application/json; charset=utf-8'
    ).


    lo_http_client->request->set_header_field(
      name =
        'Accept'

      value =
        'application/json'
    ).


    lo_http_client->request->set_header_field(
      name =
        'x-goog-api-key'

      value =
        mv_api_key
    ).


    lo_http_client->request->set_cdata(
      lv_request_body
    ).


    "==========================================================
    " Send
    "==========================================================

    lo_http_client->send(
      EXPORTING
        timeout =
          mv_timeout

      EXCEPTIONS
        OTHERS =
          1
    ).


    IF sy-subrc <> 0.

      lo_http_client->close( ).

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " Receive
    "==========================================================

    lo_http_client->receive(
      EXCEPTIONS
        OTHERS =
          1
    ).


    IF sy-subrc <> 0.

      lo_http_client->close( ).

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " HTTP status + response body
    "==========================================================

    DATA lv_status_code
      TYPE i.


    DATA lv_reason
      TYPE string.


    lo_http_client->response->get_status(
      IMPORTING
        code =
          lv_status_code

        reason =
          lv_reason
    ).


    DATA(lv_response_body) =
      lo_http_client->response->get_cdata( ).


    lo_http_client->close( ).


    "==========================================================
    " 2xx required
    "==========================================================

    IF lv_status_code < 200
       OR lv_status_code >= 300.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    IF lv_response_body IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    rv_response =
      extract_response(
        iv_body =
          lv_response_body
      ).

  ENDMETHOD.


ENDCLASS.
