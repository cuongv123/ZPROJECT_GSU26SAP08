INTERFACE zif_mig_tech_doc_builder
  PUBLIC.

  TYPES:
    ty_section_id TYPE c LENGTH 30,
    ty_item_kind  TYPE c LENGTH 20,
    ty_label      TYPE c LENGTH 120.


  CONSTANTS:
    gc_sec_summary
      TYPE ty_section_id VALUE 'EXECUTIVE_SUMMARY',

    gc_sec_inventory
      TYPE ty_section_id VALUE 'APPLICATION_INVENTORY',

    gc_sec_source
      TYPE ty_section_id VALUE 'SOURCE_STRUCTURE',

    gc_sec_flow
      TYPE ty_section_id VALUE 'LEGACY_FLOW',

    gc_sec_selection
      TYPE ty_section_id VALUE 'SELECTION_SCREEN',

    gc_sec_database
      TYPE ty_section_id VALUE 'DATABASE_ACCESS',

    gc_sec_logic
      TYPE ty_section_id VALUE 'BUSINESS_LOGIC',

    gc_sec_alv
      TYPE ty_section_id VALUE 'ALV_OUTPUT',

    gc_sec_score
      TYPE ty_section_id VALUE 'COMPLEXITY_READINESS',

    gc_sec_recommend
      TYPE ty_section_id VALUE 'RECOMMENDATIONS',

    gc_sec_review
      TYPE ty_section_id VALUE 'MANUAL_REVIEW',

    gc_sec_evidence
      TYPE ty_section_id VALUE 'EVIDENCE_APPENDIX'.


  CONSTANTS:
    gc_kind_text
      TYPE ty_item_kind VALUE 'TEXT',

    gc_kind_metric
      TYPE ty_item_kind VALUE 'METRIC',

    gc_kind_source
      TYPE ty_item_kind VALUE 'SOURCE',

    gc_kind_flow
      TYPE ty_item_kind VALUE 'FLOW',

    gc_kind_filter
      TYPE ty_item_kind VALUE 'FILTER',

    gc_kind_database
      TYPE ty_item_kind VALUE 'DATABASE',

    gc_kind_logic
      TYPE ty_item_kind VALUE 'LOGIC',

    gc_kind_alv
      TYPE ty_item_kind VALUE 'ALV',

    gc_kind_recommendation
      TYPE ty_item_kind VALUE 'RECOMMENDATION',

    gc_kind_warning
      TYPE ty_item_kind VALUE 'WARNING',

    gc_kind_evidence
      TYPE ty_item_kind VALUE 'EVIDENCE'.


  TYPES:
    BEGIN OF ty_doc_item,

      sequence       TYPE i,

      section_id     TYPE ty_section_id,
      item_kind      TYPE ty_item_kind,

      level          TYPE i,

      label          TYPE ty_label,
      value          TYPE string,
      detail         TYPE string,

      evidence_id
        TYPE zif_mig_types=>ty_evidence_id,

      source_object
        TYPE progname,

      source_line
        TYPE i,

      confidence
        TYPE zif_mig_types=>ty_confidence,

      manual_review
        TYPE abap_bool,

    END OF ty_doc_item,

    tt_doc_item
      TYPE STANDARD TABLE OF ty_doc_item
      WITH EMPTY KEY.


  TYPES:
    BEGIN OF ty_section,

      section_id
        TYPE ty_section_id,

      position
        TYPE i,

      title
        TYPE c LENGTH 80,

      item_count
        TYPE i,

    END OF ty_section,

    tt_section
      TYPE STANDARD TABLE OF ty_section
      WITH EMPTY KEY.


  TYPES:
    BEGIN OF ty_tech_document,

      analysis_id
        TYPE zif_mig_types=>ty_analysis_id,

      program_name
        TYPE progname,

      document_title
        TYPE c LENGTH 160,

      analysis_status
        TYPE zif_mig_types=>ty_status,

      complexity_score
        TYPE decfloat16,

      readiness_score
        TYPE decfloat16,

      sections
        TYPE tt_section,

      items
        TYPE tt_doc_item,

    END OF ty_tech_document.


  METHODS build
    IMPORTING

      is_result
        TYPE zif_mig_types=>ty_analysis_result

      is_flow
        TYPE zif_mig_flow_summarizer=>ty_flow_summary

    RETURNING

      VALUE(rs_document)
        TYPE ty_tech_document.

ENDINTERFACE.
