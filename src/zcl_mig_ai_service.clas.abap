CLASS zcl_mig_ai_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        io_prompt_builder
          TYPE REF TO zif_mig_ai_prompt_builder

        io_ai_client
          TYPE REF TO zif_mig_ai_client

        io_response_parser
          TYPE REF TO zif_mig_ai_response_parser.


    INTERFACES
      zif_mig_ai_service.


  PRIVATE SECTION.

    DATA mo_prompt_builder
      TYPE REF TO zif_mig_ai_prompt_builder.

    DATA mo_ai_client
      TYPE REF TO zif_mig_ai_client.

    DATA mo_response_parser
      TYPE REF TO zif_mig_ai_response_parser.

ENDCLASS.



CLASS zcl_mig_ai_service IMPLEMENTATION.


  METHOD constructor.

    mo_prompt_builder =
      io_prompt_builder.

    mo_ai_client =
      io_ai_client.

    mo_response_parser =
      io_response_parser.

  ENDMETHOD.



  METHOD zif_mig_ai_service~analyze.

    "==========================================================
    " 1. Validate Markdown
    "==========================================================
    IF iv_markdown IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            iv_program_name.

    ENDIF.


    "==========================================================
    " 2. Build AI prompt
    "==========================================================
    DATA(ls_prompt) =
      mo_prompt_builder->build(
        iv_program_name =
          iv_program_name

        iv_markdown =
          iv_markdown
      ).


    "==========================================================
    " 3. Call AI client
    "==========================================================
    DATA(lv_response) =
      mo_ai_client->execute(
        is_prompt =
          ls_prompt
      ).


    "==========================================================
    " 4. Parse AI response
    "==========================================================
    rs_assessment =
      mo_response_parser->parse(
        iv_analysis_id =
          iv_analysis_id

        iv_program_name =
          iv_program_name

        iv_response =
          lv_response
      ).


  ENDMETHOD.


ENDCLASS.
