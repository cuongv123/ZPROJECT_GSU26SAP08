CLASS ltc_tech_doc_builder DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS get_document
      RETURNING
        VALUE(rs_document)
          TYPE zif_mig_tech_doc_builder=>ty_tech_document
      RAISING
        zcx_mig_analysis.


    METHODS build_document_header
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS build_all_sections
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS preserve_legacy_flow
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS preserve_domain_facts
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS preserve_recommendations
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS preserve_evidence
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_tech_doc_builder IMPLEMENTATION.


  METHOD get_document.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).


    DATA(ls_result) =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name =
          'ZRMIG_SAMPLE_FULL'
      ).


    DATA(lo_flow) =
      NEW zcl_mig_flow_summarizer( ).


    DATA(ls_flow) =
      lo_flow->zif_mig_flow_summarizer~summarize(
        is_result = ls_result
      ).


    DATA(lo_builder) =
      NEW zcl_mig_tech_doc_builder( ).


    rs_document =
      lo_builder->zif_mig_tech_doc_builder~build(
        is_result = ls_result
        is_flow   = ls_flow
      ).


  ENDMETHOD.

    METHOD build_document_header.

    DATA(ls_document) =
      get_document( ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_FULL'
      act = ls_document-program_name
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_document-analysis_id
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_document-document_title
    ).


    cl_abap_unit_assert=>assert_not_initial(
      act = ls_document-analysis_status
    ).


  ENDMETHOD.

    METHOD build_all_sections.

    DATA(ls_document) =
      get_document( ).


    cl_abap_unit_assert=>assert_equals(
      exp = 12
      act = lines( ls_document-sections )
      msg = 'Technical Document phải có 12 sections'
    ).


    READ TABLE ls_document-sections
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_flow
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu Legacy Application Flow'
    ).


    READ TABLE ls_document-sections
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_review
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Thiếu Manual Review section'
    ).


  ENDMETHOD.

    METHOD preserve_legacy_flow.

    DATA(ls_document) =
      get_document( ).


    READ TABLE ls_document-items
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_flow

        item_kind =
          zif_mig_tech_doc_builder=>gc_kind_flow

        label =
          'START-OF-SELECTION'
      TRANSPORTING NO FIELDS.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Document thiếu START-OF-SELECTION'
    ).


    READ TABLE ls_document-items
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_flow

        item_kind =
          zif_mig_tech_doc_builder=>gc_kind_flow

        label =
          'LOAD_DATA'
      TRANSPORTING NO FIELDS.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Document thiếu LOAD_DATA'
    ).


    READ TABLE ls_document-items
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_flow

        item_kind =
          zif_mig_tech_doc_builder=>gc_kind_flow

        label =
          'DISPLAY_DATA'
      TRANSPORTING NO FIELDS.


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Document thiếu DISPLAY_DATA'
    ).


  ENDMETHOD.

    METHOD preserve_recommendations.

    DATA(ls_document) =
      get_document( ).


    READ TABLE ls_document-sections
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_recommend
      INTO DATA(ls_section).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).


    cl_abap_unit_assert=>assert_true(
      act = xsdbool(
        ls_section-item_count > 0
      )
      msg = 'Recommendation section không được rỗng'
    ).


  ENDMETHOD.

    METHOD preserve_evidence.

    DATA(ls_document) =
      get_document( ).


    READ TABLE ls_document-sections
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_evidence
      INTO DATA(ls_section).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).


    cl_abap_unit_assert=>assert_true(
      act = xsdbool(
        ls_section-item_count > 0
      )
    ).


    LOOP AT ls_document-items
      ASSIGNING FIELD-SYMBOL(<item>)
      WHERE section_id =
        zif_mig_tech_doc_builder=>gc_sec_evidence.


      cl_abap_unit_assert=>assert_not_initial(
        act = <item>-evidence_id
      ).


      cl_abap_unit_assert=>assert_not_initial(
        act = <item>-source_object
      ).


      cl_abap_unit_assert=>assert_true(
        act = xsdbool(
          <item>-source_line > 0
        )
      ).


    ENDLOOP.


  ENDMETHOD.

    METHOD preserve_domain_facts.

    DATA(ls_document) =
      get_document( ).


    "Selection
    READ TABLE ls_document-items
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_selection
        label = 'P_BUKRS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).


    "Database
    READ TABLE ls_document-items
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_database
        label = 'T001'
      INTO DATA(ls_db).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_char_cp(
      act = ls_db-detail
      exp = '*GT_RESULT*'
    ).


    "Logic
    READ TABLE ls_document-items
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_logic
        label = 'BAPI_USER_GET_DETAIL'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).


    "ALV
    READ TABLE ls_document-items
      WITH KEY
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_alv
      INTO DATA(ls_alv).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_char_cp(
      act = ls_alv-detail
      exp = '*DISPLAY_DATA*'
    ).

    cl_abap_unit_assert=>assert_char_cp(
      act = ls_alv-detail
      exp = '*GT_RESULT*'
    ).


  ENDMETHOD.

ENDCLASS.
