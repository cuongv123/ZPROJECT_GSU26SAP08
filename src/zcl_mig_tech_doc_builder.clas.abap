CLASS zcl_mig_tech_doc_builder DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_tech_doc_builder.


  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_binding_summary,
        call_item_id TYPE zif_mig_types=>ty_item_id,
        detail       TYPE string,
      END OF ty_binding_summary,

      tt_binding_summary TYPE HASHED TABLE OF ty_binding_summary
        WITH UNIQUE KEY call_item_id.

    METHODS append_item
      IMPORTING

        iv_section
          TYPE zif_mig_tech_doc_builder=>ty_section_id

        iv_kind
          TYPE zif_mig_tech_doc_builder=>ty_item_kind

        iv_level
          TYPE i DEFAULT 0

        iv_label
          TYPE zif_mig_tech_doc_builder=>ty_label OPTIONAL

        iv_value
          TYPE string OPTIONAL

        iv_detail
          TYPE string OPTIONAL

        iv_evidence_id
          TYPE zif_mig_types=>ty_evidence_id OPTIONAL

        iv_source_object
          TYPE progname OPTIONAL

        iv_source_line
          TYPE i OPTIONAL

        iv_confidence
          TYPE zif_mig_types=>ty_confidence OPTIONAL

        iv_manual_review
          TYPE abap_bool DEFAULT abap_false

      CHANGING

        cv_sequence
          TYPE i

        ct_items
          TYPE zif_mig_tech_doc_builder=>tt_doc_item.


    METHODS build_sections
      IMPORTING

        it_items
          TYPE zif_mig_tech_doc_builder=>tt_doc_item

      RETURNING

        VALUE(rt_sections)
          TYPE zif_mig_tech_doc_builder=>tt_section.


    METHODS get_evidence_location
      IMPORTING

        iv_evidence_id
          TYPE zif_mig_types=>ty_evidence_id

        it_evidences
          TYPE zif_mig_types=>tt_evidence

      EXPORTING

        ev_source_object
          TYPE progname

        ev_source_line
          TYPE i.

    METHODS build_binding_summaries
      IMPORTING
        it_bindings TYPE zif_mig_types=>tt_call_binding
      RETURNING
        VALUE(rt_summaries) TYPE tt_binding_summary.

ENDCLASS.

CLASS zcl_mig_tech_doc_builder IMPLEMENTATION.


  METHOD zif_mig_tech_doc_builder~build.

    CLEAR rs_document.


    rs_document-analysis_id =
      is_result-analysis_id.

    rs_document-program_name =
      is_result-overview-program_name.

    rs_document-document_title =
      |Technical Analysis - {
         is_result-overview-program_name }|.

    rs_document-analysis_status =
      is_result-overview-status.

    rs_document-complexity_score =
      is_result-overview-complexity_score.

    rs_document-readiness_score =
      is_result-overview-readiness_score.


    DATA lv_sequence TYPE i.

    CLEAR lv_sequence.


    "==========================================================
    " 01. EXECUTIVE SUMMARY
    "==========================================================
    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_summary

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_text

        iv_label =
          'Program'

        iv_value =
          CONV string(
            is_result-overview-program_name
          )

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_summary

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_text

        iv_label =
          'Analysis Status'

        iv_value =
          CONV string(
            is_result-overview-status
          )

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_summary

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_text

        iv_label =
          'Purpose'

        iv_value =
          |Static analysis of legacy ABAP report {
             is_result-overview-program_name
           } for modernization assessment.|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).

        "==========================================================
    " 02. APPLICATION INVENTORY
    "==========================================================

    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_inventory

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'Source Objects'

        iv_value =
          |{ lines( is_result-source_objects ) }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_inventory

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'Selection Fields'

        iv_value =
          |{ lines( is_result-ui_filters ) }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_inventory

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'Database Objects'

        iv_value =
          |{ lines( is_result-database_objects ) }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_inventory

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'Business Logic Dependencies'

        iv_value =
          |{ lines( is_result-business_logic ) }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_inventory

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'ALV Outputs'

        iv_value =
          |{ lines( is_result-alv_outputs ) }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_inventory

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'ALV Columns'

        iv_value =
          |{ lines( is_result-alv_columns ) }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).

        "==========================================================
    " 03. SOURCE STRUCTURE
    "==========================================================

    LOOP AT is_result-source_objects
      ASSIGNING FIELD-SYMBOL(<source>).


      append_item(
        EXPORTING
          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_source

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_source

          iv_level =
            <source>-include_depth

          iv_label =
            CONV zif_mig_tech_doc_builder=>ty_label(
              <source>-object_name
            )

          iv_value =
            CONV string(
              <source>-object_type
            )

          iv_detail =
            |Parent={
               <source>-parent_object
             }; Lines={
               <source>-line_count }|

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.

        "==========================================================
    " 04. LEGACY APPLICATION FLOW
    "==========================================================

    LOOP AT is_flow-steps
      ASSIGNING FIELD-SYMBOL(<flow>).


      append_item(
        EXPORTING

          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_flow

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_flow

          iv_level =
            <flow>-level

          iv_label =
              <flow>-object_name

          iv_value =
            CONV string(
              <flow>-step_kind
            )

          iv_detail =
            <flow>-detail

          iv_evidence_id =
            <flow>-evidence_id

          iv_source_object =
            <flow>-source_object

          iv_source_line =
            <flow>-source_line

          iv_confidence =
            <flow>-confidence

          iv_manual_review =
            <flow>-manual_review

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.

        "==========================================================
    " 05. SELECTION SCREEN
    "==========================================================

    LOOP AT is_result-ui_filters
      ASSIGNING FIELD-SYMBOL(<filter>).


      DATA:
        lv_filter_source TYPE progname,
        lv_filter_line   TYPE i.


      get_evidence_location(
        EXPORTING
          iv_evidence_id =
            <filter>-evidence_id

          it_evidences =
            is_result-evidences

        IMPORTING
          ev_source_object =
            lv_filter_source

          ev_source_line =
            lv_filter_line
      ).


      DATA(lv_filter_detail) =
        |Kind={ <filter>-field_kind }|.


      IF <filter>-reference_table IS NOT INITIAL.

        lv_filter_detail =
          |{ lv_filter_detail }; Reference={
             <filter>-reference_table }-{
             <filter>-reference_field }|.

      ENDIF.


      IF <filter>-mandatory = abap_true.

        lv_filter_detail =
          |{ lv_filter_detail }; Mandatory|.

      ENDIF.


      IF <filter>-checkbox = abap_true.

        lv_filter_detail =
          |{ lv_filter_detail }; Checkbox|.

      ENDIF.


      IF <filter>-multiple_selection = abap_true.

        lv_filter_detail =
          |{ lv_filter_detail }; Multiple Selection|.

      ENDIF.


      IF <filter>-range_supported = abap_true.

        lv_filter_detail =
          |{ lv_filter_detail }; Range Supported|.

      ENDIF.


      append_item(
        EXPORTING
          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_selection

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_filter

          iv_label =
            CONV zif_mig_tech_doc_builder=>ty_label(
              <filter>-field_name
            )

          iv_value =
            CONV string(
              <filter>-field_kind
            )

          iv_detail =
            lv_filter_detail

          iv_evidence_id =
            <filter>-evidence_id

          iv_source_object =
            lv_filter_source

          iv_source_line =
            lv_filter_line

          iv_confidence =
            <filter>-confidence

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.

    "==========================================================
    " 06. DATABASE ACCESS
    "==========================================================

    LOOP AT is_result-database_objects
      ASSIGNING FIELD-SYMBOL(<db>).


      DATA:
        lv_db_source TYPE progname,
        lv_db_line   TYPE i.


      get_evidence_location(
        EXPORTING
          iv_evidence_id =
            <db>-evidence_id

          it_evidences =
            is_result-evidences

        IMPORTING
          ev_source_object =
            lv_db_source

          ev_source_line =
            lv_db_line
      ).


      DATA(lv_db_detail) =
        |Operation={ <db>-operation }; Routine={
           <db>-containing_routine }|.

      IF <db>-execution_kind IS NOT INITIAL.

          lv_db_detail =
            |{ lv_db_detail }; Execution={
               <db>-execution_kind }|.

        ENDIF.


        IF <db>-execution_context IS NOT INITIAL.

          lv_db_detail =
            |{ lv_db_detail }; Context={
               <db>-execution_context }|.

        ENDIF.

      IF <db>-joined_objects IS NOT INITIAL.

        lv_db_detail =
          |{ lv_db_detail }; Joins={
             <db>-joined_objects }|.

      ENDIF.


      IF <db>-result_target IS NOT INITIAL.

        lv_db_detail =
          |{ lv_db_detail }; Result={
             <db>-result_target }|.

      ENDIF.


      IF <db>-where_fields IS NOT INITIAL.

        lv_db_detail =
          |{ lv_db_detail }; Where={
             <db>-where_fields }|.

      ENDIF.


      DATA(lv_db_review) =
        xsdbool(
          <db>-dynamic_access = abap_true
          OR
          <db>-paging_capability = 'REVIEW'
        ).


      append_item(
        EXPORTING

          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_database

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_database

          iv_label =
            CONV zif_mig_tech_doc_builder=>ty_label(
              <db>-object_name
            )

          iv_value =
            CONV string(
              <db>-operation
            )

          iv_detail =
            lv_db_detail

          iv_evidence_id =
            <db>-evidence_id

          iv_source_object =
            lv_db_source

          iv_source_line =
            lv_db_line

          iv_confidence =
            <db>-confidence

          iv_manual_review =
            lv_db_review

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.

    DATA(lt_binding_summaries) =
      build_binding_summaries(
        it_bindings =
          is_result-call_bindings
      ).

    "==========================================================
    " 07. BUSINESS LOGIC & DEPENDENCIES
    "==========================================================

    LOOP AT is_result-business_logic
      ASSIGNING FIELD-SYMBOL(<logic>).


      DATA:
        lv_logic_source TYPE progname,
        lv_logic_line   TYPE i.


      get_evidence_location(
        EXPORTING
          iv_evidence_id =
            <logic>-evidence_id

          it_evidences =
            is_result-evidences

        IMPORTING
          ev_source_object =
            lv_logic_source

          ev_source_line =
            lv_logic_line
      ).


      DATA(lv_logic_detail) =
        |Type={ <logic>-object_type }; Caller={
           <logic>-calling_routine }|.

      READ TABLE lt_binding_summaries
          WITH TABLE KEY
            call_item_id = <logic>-item_id
          INTO DATA(ls_binding_summary).


        IF sy-subrc = 0.

          lv_logic_detail =
            |{ lv_logic_detail }; ObservedBindings=[{
               ls_binding_summary-detail }] |.

          CONDENSE lv_logic_detail.

        ENDIF.

      IF <logic>-execution_kind IS NOT INITIAL.

          lv_logic_detail =
            |{ lv_logic_detail }; Execution={
               <logic>-execution_kind }|.

        ENDIF.


        IF <logic>-execution_context IS NOT INITIAL.

          lv_logic_detail =
            |{ lv_logic_detail }; Context={
               <logic>-execution_context }|.

        ENDIF.


      IF <logic>-container_name IS NOT INITIAL.

        lv_logic_detail =
          |{ lv_logic_detail }; Container={
             <logic>-container_name }|.

      ENDIF.


      IF <logic>-side_effect IS NOT INITIAL.

        lv_logic_detail =
          |{ lv_logic_detail }; SideEffect={
             <logic>-side_effect }|.

      ENDIF.


      IF <logic>-reuse_feasibility IS NOT INITIAL.

        lv_logic_detail =
          |{ lv_logic_detail }; Reuse={
             <logic>-reuse_feasibility }|.

      ENDIF.


      DATA(lv_logic_review) =
        xsdbool(
          <logic>-object_type =
            'DYNAMIC_FUNCTION_MODULE'
          OR
          <logic>-confidence =
            zif_mig_types=>gc_conf_low
        ).


      append_item(
        EXPORTING
          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_logic

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_logic

          iv_label =
              <logic>-object_name

          iv_value =
            CONV string(
              <logic>-object_type
            )

          iv_detail =
            lv_logic_detail

          iv_evidence_id =
            <logic>-evidence_id

          iv_source_object =
            lv_logic_source

          iv_source_line =
            lv_logic_line

          iv_confidence =
            <logic>-confidence

          iv_manual_review =
            lv_logic_review

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.

        "==========================================================
    " 08. ALV OUTPUT
    "==========================================================

    LOOP AT is_result-alv_outputs
      ASSIGNING FIELD-SYMBOL(<alv>).


      DATA:
        lv_alv_source TYPE progname,
        lv_alv_line   TYPE i.


      get_evidence_location(
        EXPORTING
          iv_evidence_id =
            <alv>-evidence_id

          it_evidences =
            is_result-evidences

        IMPORTING
          ev_source_object =
            lv_alv_source

          ev_source_line =
            lv_alv_line
      ).


      DATA(lv_alv_detail) =
        |Framework={ <alv>-framework }; Routine={
           <alv>-containing_routine }|.


      IF <alv>-output_table IS NOT INITIAL.

        lv_alv_detail =
          |{ lv_alv_detail }; Output={
             <alv>-output_table }|.

      ELSE.

        lv_alv_detail =
          |{ lv_alv_detail }; Output=UNRESOLVED|.

      ENDIF.


      IF <alv>-field_catalog IS NOT INITIAL.

        lv_alv_detail =
          |{ lv_alv_detail }; FieldCatalog={
             <alv>-field_catalog }|.

      ENDIF.


      IF <alv>-layout_object IS NOT INITIAL.

        lv_alv_detail =
          |{ lv_alv_detail }; Layout={
             <alv>-layout_object }|.

      ENDIF.


      append_item(
        EXPORTING

          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_alv

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_alv

          iv_label =
              <alv>-output_name

          iv_value =
            CONV string(
              <alv>-framework
            )

          iv_detail =
            lv_alv_detail

          iv_evidence_id =
            <alv>-evidence_id

          iv_source_object =
            lv_alv_source

          iv_source_line =
            lv_alv_line

          iv_confidence =
            <alv>-confidence

          iv_manual_review =
            xsdbool(
              <alv>-output_table IS INITIAL
            )

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.


        "==========================================================
    " 09. COMPLEXITY & READINESS
    "==========================================================

    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_score

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'Complexity Score'

        iv_value =
          |{ is_result-overview-complexity_score }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


    append_item(
      EXPORTING
        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_score

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_metric

        iv_label =
          'Readiness Score'

        iv_value =
          |{ is_result-overview-readiness_score }|

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).


        "==========================================================
    " 10. MODERNIZATION RECOMMENDATIONS
    "==========================================================

    LOOP AT is_result-recommendations
      ASSIGNING FIELD-SYMBOL(<recommendation>).


      DATA:
        lv_rec_source TYPE progname,
        lv_rec_line   TYPE i.


      get_evidence_location(
        EXPORTING
          iv_evidence_id =
            <recommendation>-evidence_id

          it_evidences =
            is_result-evidences

        IMPORTING
          ev_source_object =
            lv_rec_source

          ev_source_line =
            lv_rec_line
      ).


      append_item(
        EXPORTING

          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_recommend

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_recommendation

          iv_label =
            <recommendation>-title

          iv_value =
            <recommendation>-display_text

          iv_detail =
            <recommendation>-explanation

          iv_evidence_id =
            <recommendation>-evidence_id

          iv_source_object =
            lv_rec_source

          iv_source_line =
            lv_rec_line

          iv_confidence =
            <recommendation>-confidence

          iv_manual_review =
            <recommendation>-manual_review

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.


        "==========================================================
    " 11. MANUAL REVIEW & LIMITATIONS
    "==========================================================

    LOOP AT is_result-messages
      ASSIGNING FIELD-SYMBOL(<message>).


      IF <message>-message_type <> 'WARNING'
         AND <message>-message_type <> 'ERROR'.

        CONTINUE.

      ENDIF.


      append_item(
        EXPORTING

          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_review

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_warning

          iv_label =
            CONV zif_mig_tech_doc_builder=>ty_label(
              <message>-message_code
            )

          iv_value =
            <message>-message_text

          iv_source_object =
            <message>-source_object

          iv_source_line =
            <message>-source_line

          iv_manual_review =
            abap_true

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.

        append_item(
      EXPORTING

        iv_section =
          zif_mig_tech_doc_builder=>gc_sec_review

        iv_kind =
          zif_mig_tech_doc_builder=>gc_kind_text

        iv_label =
          'Static Analysis Boundary'

        iv_value =
          'Analysis is based on static source inspection.'

        iv_detail =
          'Dynamic runtime values, full inter-procedural data flow, full CFG and complex GUI behavior are outside Parser V1 scope.'

      CHANGING
        cv_sequence = lv_sequence
        ct_items    = rs_document-items
    ).

        "==========================================================
    " 12. EVIDENCE APPENDIX
    "==========================================================

    LOOP AT is_result-evidences
      ASSIGNING FIELD-SYMBOL(<evidence>).


      append_item(
        EXPORTING

          iv_section =
            zif_mig_tech_doc_builder=>gc_sec_evidence

          iv_kind =
            zif_mig_tech_doc_builder=>gc_kind_evidence

          iv_label =
            CONV zif_mig_tech_doc_builder=>ty_label(
              <evidence>-source_object
            )

          iv_value =
            |Line {
               <evidence>-start_line }-${
               <evidence>-end_line }|

          iv_detail =
            <evidence>-statement_text

          iv_evidence_id =
            <evidence>-evidence_id

          iv_source_object =
            <evidence>-source_object

          iv_source_line =
            <evidence>-start_line

          iv_confidence =
            <evidence>-confidence

        CHANGING
          cv_sequence = lv_sequence
          ct_items    = rs_document-items
      ).


    ENDLOOP.


    rs_document-sections =
      build_sections(
        it_items = rs_document-items
      ).


  ENDMETHOD.


    METHOD append_item.

    cv_sequence += 1.


    APPEND VALUE #(

      sequence       = cv_sequence

      section_id     = iv_section
      item_kind      = iv_kind

      level           = iv_level

      label           = iv_label
      value           = iv_value
      detail          = iv_detail

      evidence_id     = iv_evidence_id

      source_object   = iv_source_object
      source_line     = iv_source_line

      confidence      = iv_confidence

      manual_review   = iv_manual_review

    ) TO ct_items.


  ENDMETHOD.


    METHOD build_sections.

    CLEAR rt_sections.


    DATA lt_registry
      TYPE zif_mig_tech_doc_builder=>tt_section.


    lt_registry = VALUE #(

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_summary
        position = 10
        title    = 'Executive Summary'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_inventory
        position = 20
        title    = 'Application Inventory'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_source
        position = 30
        title    = 'Source Structure'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_flow
        position = 40
        title    = 'Legacy Application Flow'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_selection
        position = 50
        title    = 'Selection Screen'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_database
        position = 60
        title    = 'Database Access'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_logic
        position = 70
        title    = 'Business Logic & Dependencies'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_alv
        position = 80
        title    = 'ALV Output'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_score
        position = 90
        title    = 'Complexity & Readiness'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_recommend
        position = 100
        title    = 'Modernization Recommendations'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_review
        position = 110
        title    = 'Manual Review & Limitations'
      )

      (
        section_id =
          zif_mig_tech_doc_builder=>gc_sec_evidence
        position = 120
        title    = 'Evidence Appendix'
      )

    ).


    LOOP AT lt_registry
      INTO DATA(ls_section).


      DATA(lv_count) = 0.


      LOOP AT it_items
        TRANSPORTING NO FIELDS
        WHERE section_id = ls_section-section_id.

        lv_count += 1.

      ENDLOOP.


      ls_section-item_count =
        lv_count.


      "Giữ đủ 12 sections kể cả section chưa có findings.
      APPEND ls_section
        TO rt_sections.


    ENDLOOP.


    SORT rt_sections
      BY position.


  ENDMETHOD.


    METHOD get_evidence_location.

    CLEAR:
      ev_source_object,
      ev_source_line.


    IF iv_evidence_id IS INITIAL.
      RETURN.
    ENDIF.


    READ TABLE it_evidences
      WITH KEY
        evidence_id = iv_evidence_id
      INTO DATA(ls_evidence).


    IF sy-subrc <> 0.
      RETURN.
    ENDIF.


    ev_source_object =
      ls_evidence-source_object.

    ev_source_line =
      ls_evidence-start_line.


  ENDMETHOD.

  METHOD build_binding_summaries.

  DATA lt_bindings
    TYPE zif_mig_types=>tt_call_binding.

  lt_bindings =
    it_bindings.


  "Giữ thứ tự parameter ổn định trong document
  SORT lt_bindings
    BY call_item_id
       position
       parameter_name.


  LOOP AT lt_bindings
    ASSIGNING FIELD-SYMBOL(<binding>).


    DATA(lv_piece) =
      |{ <binding>-direction } {
         <binding>-parameter_name } = {
         <binding>-actual_expression }|.


    READ TABLE rt_summaries
      WITH TABLE KEY
        call_item_id = <binding>-call_item_id
      ASSIGNING FIELD-SYMBOL(<summary>).


    IF sy-subrc = 0.

      <summary>-detail =
        |{ <summary>-detail }; { lv_piece }|.

    ELSE.

      INSERT VALUE #(
        call_item_id =
          <binding>-call_item_id

        detail =
          lv_piece
      ) INTO TABLE rt_summaries.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
