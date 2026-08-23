CLASS zcl_mig_ai_support_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.


  PUBLIC SECTION.

    INTERFACES
      zif_mig_ai_support_service.


    METHODS constructor
      IMPORTING

        io_ai_service
          TYPE REF TO zif_mig_ai_service

        io_tech_doc_service
          TYPE REF TO zif_mig_tech_doc_service OPTIONAL.


  PRIVATE SECTION.

    DATA mo_ai_service
      TYPE REF TO zif_mig_ai_service.


    DATA mo_tech_doc_service
      TYPE REF TO zif_mig_tech_doc_service.


ENDCLASS.



CLASS zcl_mig_ai_support_service IMPLEMENTATION.


  METHOD constructor.

    "==========================================================
    " AI service
    "==========================================================
    mo_ai_service =
      io_ai_service.


    "==========================================================
    " Technical document service
    "==========================================================
    IF io_tech_doc_service IS BOUND.

      mo_tech_doc_service =
        io_tech_doc_service.

    ELSE.

      mo_tech_doc_service =
        NEW zcl_mig_tech_doc_service( ).

    ENDIF.

  ENDMETHOD.



  METHOD zif_mig_ai_support_service~analyze.

    CLEAR rs_assessment.


    "==========================================================
    " 1. Validate Analysis ID
    "==========================================================
    IF iv_analysis_id IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " 2. Ensure AI service dependency exists
    "==========================================================
    IF mo_ai_service IS NOT BOUND.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed.

    ENDIF.


    "==========================================================
    " 3. Generate deterministic Technical Document
    "==========================================================
    DATA(ls_document) =
      mo_tech_doc_service->generate(
        iv_analysis_id =
          iv_analysis_id
      ).


    "==========================================================
    " 4. Validate Technical Document
    "==========================================================
    IF ls_document-analysis_id IS INITIAL
       OR ls_document-markdown IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            ls_document-program_name.

    ENDIF.


    "==========================================================
    " 5. Pass deterministic document to AI pipeline
    "==========================================================
    rs_assessment =
      mo_ai_service->analyze(
        iv_analysis_id =
          ls_document-analysis_id

        iv_program_name =
          ls_document-program_name

        iv_markdown =
          ls_document-markdown
      ).


    "==========================================================
    " 6. Defensive identity validation
    "==========================================================
    IF rs_assessment-analysis_id
         <> ls_document-analysis_id

       OR rs_assessment-program_name
         <> ls_document-program_name.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            ls_document-program_name.

    ENDIF.


  ENDMETHOD.


ENDCLASS.
