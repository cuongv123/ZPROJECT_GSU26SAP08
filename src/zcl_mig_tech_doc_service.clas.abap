CLASS zcl_mig_tech_doc_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_tech_doc_service.


    METHODS constructor
      IMPORTING

        io_reader
          TYPE REF TO zif_mig_analysis_reader OPTIONAL

        io_flow_summarizer
          TYPE REF TO zif_mig_flow_summarizer OPTIONAL

        io_doc_builder
          TYPE REF TO zif_mig_tech_doc_builder OPTIONAL

        io_md_renderer
          TYPE REF TO zif_mig_md_renderer OPTIONAL.


  PRIVATE SECTION.

    DATA:
      mo_reader
        TYPE REF TO zif_mig_analysis_reader,

      mo_flow_summarizer
        TYPE REF TO zif_mig_flow_summarizer,

      mo_doc_builder
        TYPE REF TO zif_mig_tech_doc_builder,

      mo_md_renderer
        TYPE REF TO zif_mig_md_renderer.


    METHODS build_file_name
      IMPORTING
        iv_program_name TYPE progname
      RETURNING
        VALUE(rv_file_name) TYPE string.

ENDCLASS.

CLASS zcl_mig_tech_doc_service IMPLEMENTATION.


  METHOD constructor.

    "==========================================================
    " Analysis Reader
    "==========================================================
    IF io_reader IS BOUND.

      mo_reader =
        io_reader.

    ELSE.

      mo_reader =
        NEW zcl_mig_analysis_reader( ).

    ENDIF.


    "==========================================================
    " Flow Summarizer
    "==========================================================
    IF io_flow_summarizer IS BOUND.

      mo_flow_summarizer =
        io_flow_summarizer.

    ELSE.

      mo_flow_summarizer =
        NEW zcl_mig_flow_summarizer( ).

    ENDIF.


    "==========================================================
    " Technical Document Builder
    "==========================================================
    IF io_doc_builder IS BOUND.

      mo_doc_builder =
        io_doc_builder.

    ELSE.

      mo_doc_builder =
        NEW zcl_mig_tech_doc_builder( ).

    ENDIF.


    "==========================================================
    " Markdown Renderer
    "==========================================================
    IF io_md_renderer IS BOUND.

      mo_md_renderer =
        io_md_renderer.

    ELSE.

      mo_md_renderer =
        NEW zcl_mig_md_renderer( ).

    ENDIF.


  ENDMETHOD.

    METHOD zif_mig_tech_doc_service~generate.

    CLEAR rs_result.


    "==========================================================
    " Validate request
    "==========================================================
    IF iv_analysis_id IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    "==========================================================
    " 1. Read persisted analysis snapshot
    "==========================================================
    DATA(ls_analysis) =
      mo_reader->read(
        iv_analysis_id = iv_analysis_id
      ).


    IF ls_analysis-analysis_id IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          ls_analysis-overview-program_name
      ).

    ENDIF.


    "==========================================================
    " 2. Build high-level application flow
    "==========================================================
    DATA(ls_flow) =
      mo_flow_summarizer->summarize(
        is_result = ls_analysis
      ).


    "==========================================================
    " 3. Build structured technical document
    "==========================================================
    DATA(ls_document) =
      mo_doc_builder->build(
        is_result = ls_analysis
        is_flow   = ls_flow
      ).


    "==========================================================
    " 4. Render Markdown
    "==========================================================
    DATA(lv_markdown) =
      mo_md_renderer->render(
        is_document = ls_document
      ).


    "==========================================================
    " 5. Build delivery result
    "==========================================================
    rs_result-analysis_id =
      iv_analysis_id.

    rs_result-program_name =
      ls_analysis-overview-program_name.

    rs_result-file_name =
      build_file_name(
        iv_program_name =
          ls_analysis-overview-program_name
      ).

    rs_result-mime_type =
      'text/markdown; charset=utf-8'.

    rs_result-markdown =
      lv_markdown.


  ENDMETHOD.

    METHOD build_file_name.

    DATA(lv_program_name) =
      to_lower(
        CONV string( iv_program_name )
      ).


    IF lv_program_name IS INITIAL.

      lv_program_name =
        'legacy_abap_report'.

    ENDIF.


    rv_file_name =
      |{ lv_program_name }_technical_analysis.md|.


  ENDMETHOD.


ENDCLASS.
