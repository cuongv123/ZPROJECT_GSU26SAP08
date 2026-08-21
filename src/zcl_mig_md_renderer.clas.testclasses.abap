CLASS ltc_md_renderer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS get_markdown
      RETURNING
        VALUE(rv_markdown) TYPE string
      RAISING
        zcx_mig_analysis.


    METHODS render_header
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS render_sections
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS render_legacy_flow
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS render_domain_facts
      FOR TESTING
      RAISING zcx_mig_analysis.


    METHODS render_evidence
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_md_renderer IMPLEMENTATION.


  METHOD get_markdown.

    DATA(lo_service) =
      NEW zcl_mig_analysis_service( ).


    DATA(ls_result) =
      lo_service->zif_mig_analysis_service~analyze_program(
        iv_program_name = 'ZRMIG_SAMPLE_FULL'
      ).


    DATA(lo_flow) =
      NEW zcl_mig_flow_summarizer( ).


    DATA(ls_flow) =
      lo_flow->zif_mig_flow_summarizer~summarize(
        is_result = ls_result
      ).


    DATA(lo_builder) =
      NEW zcl_mig_tech_doc_builder( ).


    DATA(ls_document) =
      lo_builder->zif_mig_tech_doc_builder~build(
        is_result = ls_result
        is_flow   = ls_flow
      ).


    DATA(lo_renderer) =
      NEW zcl_mig_md_renderer( ).


    rv_markdown =
      lo_renderer->zif_mig_md_renderer~render(
        is_document = ls_document
      ).


  ENDMETHOD.

    METHOD render_header.

    DATA(lv_markdown) =
      get_markdown( ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*# Technical Analysis - ZRMIG_SAMPLE_FULL*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*Program:*ZRMIG_SAMPLE_FULL*'
    ).


  ENDMETHOD.

    METHOD render_sections.

    DATA(lv_markdown) =
      get_markdown( ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*## 1. Executive Summary*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*## 4. Legacy Application Flow*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*## 6. Database Access*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*## 10. Modernization Recommendations*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*## 12. Evidence Appendix*'
    ).


  ENDMETHOD.

    METHOD render_legacy_flow.

    DATA(lv_markdown) =
      get_markdown( ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*START-OF-SELECTION*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*LOAD_DATA*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*T001*GT_RESULT*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*PROCESS_DATA*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*BAPI_USER_GET_DETAIL*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*DISPLAY_DATA*CL_GUI_ALV_GRID*GT_RESULT*'
    ).


  ENDMETHOD.

    METHOD render_domain_facts.

    DATA(lv_markdown) =
      get_markdown( ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*P_BUKRS*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*S_WERKS*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*T001K*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*DDIF_FIELDINFO_GET*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*CL_GUI_ALV_GRID*'
    ).


  ENDMETHOD.

    METHOD render_evidence.

    DATA(lv_markdown) =
      get_markdown( ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*## 12. Evidence Appendix*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*ZRMIG_SAMPLE_FULL*'
    ).


    cl_abap_unit_assert=>assert_char_cp(
      act = lv_markdown
      exp = '*SELECT*'
    ).


  ENDMETHOD.


ENDCLASS.
