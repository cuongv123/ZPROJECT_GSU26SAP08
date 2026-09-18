CLASS zcl_mig_md_renderer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_md_renderer.


  PRIVATE SECTION.

    TYPES tt_string
      TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.


    METHODS append_line
      IMPORTING
        iv_line TYPE string OPTIONAL
      CHANGING
        cv_markdown TYPE string.


    METHODS render_item
      IMPORTING
        is_item
          TYPE zif_mig_tech_doc_builder=>ty_doc_item
      RETURNING
        VALUE(rv_line)
          TYPE string.


    METHODS build_indent
      IMPORTING
        iv_level TYPE i
      RETURNING
        VALUE(rv_indent) TYPE string.


    METHODS normalize_text
      IMPORTING
        iv_text TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.


    METHODS append_metadata
      IMPORTING
        is_item
          TYPE zif_mig_tech_doc_builder=>ty_doc_item
      CHANGING
        cv_line TYPE string.


    METHODS render_default_section
      IMPORTING
        iv_section_id
          TYPE zif_mig_tech_doc_builder=>ty_section_id

        it_items
          TYPE zif_mig_tech_doc_builder=>tt_doc_item

      CHANGING
        cv_markdown TYPE string.


    METHODS render_business_logic
      IMPORTING
        it_items
          TYPE zif_mig_tech_doc_builder=>tt_doc_item

      CHANGING
        cv_markdown TYPE string.


    METHODS render_recommendations
      IMPORTING
        it_items
          TYPE zif_mig_tech_doc_builder=>tt_doc_item

      CHANGING
        cv_markdown TYPE string.


    METHODS render_evidence
      IMPORTING
        it_items
          TYPE zif_mig_tech_doc_builder=>tt_doc_item

      CHANGING
        cv_markdown TYPE string.


    METHODS append_group
      IMPORTING
        iv_title TYPE string
        it_lines TYPE tt_string

      CHANGING
        cv_markdown TYPE string.

    METHODS render_executive_summary
      IMPORTING
        is_document
          TYPE zif_mig_tech_doc_builder=>ty_tech_document

      CHANGING
        cv_markdown TYPE string.

ENDCLASS.



CLASS zcl_mig_md_renderer IMPLEMENTATION.


  METHOD zif_mig_md_renderer~render.

    CLEAR rv_markdown.


    "==========================================================
    " Document Header
    "==========================================================
    append_line(
      EXPORTING
        iv_line =
          |# {
             normalize_text(
               iv_text = CONV string(
                 is_document-document_title
               )
             )
           }|
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      EXPORTING
        iv_line =
          |**Program:** `{ is_document-program_name }`|
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      EXPORTING
        iv_line =
          |**Analysis Status:** {
             is_document-analysis_status }|
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      EXPORTING
        iv_line =
          |**Complexity Score:** {
             is_document-complexity_score }|
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      EXPORTING
        iv_line =
          |**Readiness Score:** {
             is_document-readiness_score }|
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      EXPORTING
        iv_line = '---'
      CHANGING
        cv_markdown = rv_markdown
    ).


    append_line(
      CHANGING
        cv_markdown = rv_markdown
    ).


    "==========================================================
    " Sections
    "==========================================================
    DATA lv_section_number TYPE i.

    CLEAR lv_section_number.


    LOOP AT is_document-sections
      INTO DATA(ls_section).


      lv_section_number += 1.


      append_line(
        EXPORTING
          iv_line =
            |## { lv_section_number }. {
               normalize_text(
                 iv_text = CONV string(
                   ls_section-title
                 )
               )
             }|
        CHANGING
          cv_markdown = rv_markdown
      ).


      append_line(
        CHANGING
          cv_markdown = rv_markdown
      ).


      "========================================================
      " Developer-readable presentation
      "
      " Structured document remains untouched.
      " Only Markdown rendering changes.
      "========================================================
      CASE ls_section-section_id.


      WHEN 'EXECUTIVE_SUMMARY'.

        render_executive_summary(
          EXPORTING
            is_document =
              is_document

          CHANGING
            cv_markdown =
              rv_markdown
        ).


      WHEN 'BUSINESS_LOGIC'.

        render_business_logic(
          EXPORTING
            it_items =
              is_document-items

          CHANGING
            cv_markdown =
              rv_markdown
        ).


      WHEN 'RECOMMENDATIONS'.

        render_recommendations(
          EXPORTING
            it_items =
              is_document-items

          CHANGING
            cv_markdown =
              rv_markdown
        ).


      WHEN 'EVIDENCE_APPENDIX'.

        render_evidence(
          EXPORTING
            it_items =
              is_document-items

          CHANGING
            cv_markdown =
              rv_markdown
        ).


      WHEN OTHERS.

        render_default_section(
          EXPORTING
            iv_section_id =
              ls_section-section_id

            it_items =
              is_document-items

          CHANGING
            cv_markdown =
              rv_markdown
        ).


    ENDCASE.


      append_line(
        CHANGING
          cv_markdown = rv_markdown
      ).


    ENDLOOP.


  ENDMETHOD.



  METHOD append_line.

    IF cv_markdown IS INITIAL.

      cv_markdown =
        iv_line.

    ELSE.

      cv_markdown =
        |{ cv_markdown }{
           cl_abap_char_utilities=>newline }{
           iv_line }|.

    ENDIF.

  ENDMETHOD.



  METHOD build_indent.

    CLEAR rv_indent.


    IF iv_level <= 0.
      RETURN.
    ENDIF.


    DO iv_level TIMES.

      rv_indent =
        |{ rv_indent }  |.

    ENDDO.

  ENDMETHOD.



  METHOD normalize_text.

    rv_text =
      iv_text.


    REPLACE ALL OCCURRENCES OF
      cl_abap_char_utilities=>cr_lf
      IN rv_text
      WITH ` `.


    REPLACE ALL OCCURRENCES OF
      cl_abap_char_utilities=>newline
      IN rv_text
      WITH ` `.


    REPLACE ALL OCCURRENCES OF
      cl_abap_char_utilities=>horizontal_tab
      IN rv_text
      WITH ` `.


    CONDENSE rv_text.

  ENDMETHOD.



  METHOD render_default_section.

    DATA(lv_found) =
      abap_false.


    LOOP AT it_items
      INTO DATA(ls_item)
      WHERE section_id = iv_section_id.


      lv_found =
        abap_true.


      DATA(lv_line) =
        render_item(
          is_item = ls_item
        ).


      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.


      append_line(
        EXPORTING
          iv_line = lv_line

        CHANGING
          cv_markdown = cv_markdown
      ).


    ENDLOOP.


   IF lv_found = abap_false.

  IF iv_section_id =
       zif_mig_tech_doc_builder=>gc_sec_database.

    append_line(
      EXPORTING
        iv_line =
          '_No direct database access was detected in the analyzed source._'

      CHANGING
        cv_markdown = cv_markdown
    ).

    append_line(
      EXPORTING
        iv_line =
          '_Database operations may exist inside called function modules or other unresolved dependencies._'

      CHANGING
        cv_markdown = cv_markdown
    ).

  ELSE.

    append_line(
      EXPORTING
        iv_line =
          '_No findings detected._'

      CHANGING
        cv_markdown = cv_markdown
    ).

  ENDIF.

ENDIF.

  ENDMETHOD.



  METHOD append_group.

    IF it_lines IS INITIAL.
      RETURN.
    ENDIF.


    append_line(
      EXPORTING
        iv_line =
          |### { iv_title }|

      CHANGING
        cv_markdown = cv_markdown
    ).


    append_line(
      CHANGING
        cv_markdown = cv_markdown
    ).


    LOOP AT it_lines
      INTO DATA(lv_line).

      append_line(
        EXPORTING
          iv_line = lv_line

        CHANGING
          cv_markdown = cv_markdown
      ).

    ENDLOOP.


    append_line(
      CHANGING
        cv_markdown = cv_markdown
    ).

  ENDMETHOD.

  METHOD render_executive_summary.

  "============================================================
  " Developer-readable Executive Summary
  "
  " IMPORTANT:
  " - Deterministic only
  " - Uses structured document facts
  " - No AI inference
  " - No source re-analysis
  "============================================================


  DATA:
    lv_purpose          TYPE string,
    lv_source_objects   TYPE string,
    lv_selection_fields TYPE string,
    lv_database_objects TYPE string,
    lv_alv_outputs      TYPE string,
    lv_alv_columns      TYPE string.


  "============================================================
  " 1. Preserve existing purpose
  "============================================================
  LOOP AT is_document-items
    INTO DATA(ls_exec_item)
    WHERE section_id = 'EXECUTIVE_SUMMARY'.


    IF ls_exec_item-label = 'Purpose'.

      lv_purpose =
        normalize_text(
          iv_text =
            ls_exec_item-value
        ).

      EXIT.

    ENDIF.


  ENDLOOP.


  "============================================================
  " 2. Collect inventory metrics
  "============================================================
  LOOP AT is_document-items
    INTO DATA(ls_inventory)
    WHERE section_id = 'APPLICATION_INVENTORY'.


    DATA(lv_inventory_label) =
      normalize_text(
        iv_text =
          CONV string(
            ls_inventory-label
          )
      ).


    CASE lv_inventory_label.


      WHEN 'Source Objects'.

        lv_source_objects =
          normalize_text(
            iv_text =
              ls_inventory-value
          ).


      WHEN 'Selection Fields'.

        lv_selection_fields =
          normalize_text(
            iv_text =
              ls_inventory-value
          ).


      WHEN 'Database Objects'.

        lv_database_objects =
          normalize_text(
            iv_text =
              ls_inventory-value
          ).


      WHEN 'ALV Outputs'.

        lv_alv_outputs =
          normalize_text(
            iv_text =
              ls_inventory-value
          ).


      WHEN 'ALV Columns'.

        lv_alv_columns =
          normalize_text(
            iv_text =
              ls_inventory-value
          ).


    ENDCASE.


  ENDLOOP.


  "============================================================
  " 3. Application at a Glance
  "============================================================
  append_line(
    EXPORTING
      iv_line =
        '### Application at a Glance'

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  append_line(
    CHANGING
      cv_markdown =
        cv_markdown
  ).


  IF lv_purpose IS NOT INITIAL.

    append_line(
      EXPORTING
        iv_line =
          |**Purpose:** { lv_purpose }|

      CHANGING
        cv_markdown =
          cv_markdown
    ).

  ENDIF.


  DATA(lv_profile) =
    |**Profile:** {
       is_document-program_name }|.


  IF lv_source_objects IS NOT INITIAL.

    lv_profile =
      |{ lv_profile } — {
         lv_source_objects } source object(s)|.

  ENDIF.


  IF lv_selection_fields IS NOT INITIAL.

    lv_profile =
      |{ lv_profile }, {
         lv_selection_fields } selection field(s)|.

  ENDIF.


  IF lv_database_objects IS NOT INITIAL.

    lv_profile =
      |{ lv_profile }, {
         lv_database_objects } database access object(s)|.

  ENDIF.


  IF lv_alv_outputs IS NOT INITIAL.

    lv_profile =
      |{ lv_profile }, {
         lv_alv_outputs } ALV output(s)|.

  ENDIF.


  IF lv_alv_columns IS NOT INITIAL.

    lv_profile =
      |{ lv_profile }, {
         lv_alv_columns } ALV column(s)|.

  ENDIF.


  lv_profile =
    |{ lv_profile }.|.


  append_line(
    EXPORTING
      iv_line =
        lv_profile

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  append_line(
    EXPORTING
      iv_line =
        |**Analysis Status:** {
           is_document-analysis_status }|

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  append_line(
    EXPORTING
      iv_line =
        |**Complexity Score:** {
           is_document-complexity_score }|

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  append_line(
    EXPORTING
      iv_line =
        |**Readiness Score:** {
           is_document-readiness_score }|

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  append_line(
    CHANGING
      cv_markdown =
        cv_markdown
  ).


  "============================================================
  " 4. High-level processing flow
  "
  " We only show:
  " EVENT -> direct routine
  "
  " Detailed flow remains in section 4.
  "============================================================
  DATA lt_flow_lines
    TYPE tt_string.


  DATA lv_current_event
    TYPE string.


  LOOP AT is_document-items
    INTO DATA(ls_flow)
    WHERE section_id = 'LEGACY_FLOW'.


    IF ls_flow-item_kind <>
         zif_mig_tech_doc_builder=>gc_kind_flow.

      CONTINUE.

    ENDIF.


    DATA(lv_flow_label) =
      normalize_text(
        iv_text =
          CONV string(
            ls_flow-label
          )
      ).


    IF lv_flow_label IS INITIAL.
      CONTINUE.
    ENDIF.


    "----------------------------------------------------------
    " Level 0 = processing event
    "----------------------------------------------------------
    IF ls_flow-level = 0.

      lv_current_event =
        lv_flow_label.

      CONTINUE.

    ENDIF.


    "----------------------------------------------------------
    " Level 1 = routine directly invoked by event
    "----------------------------------------------------------
    IF ls_flow-level = 1
       AND lv_current_event IS NOT INITIAL.


      DATA(lv_flow_line) =
        |- `{ lv_current_event }` → `{ lv_flow_label }`|.


      READ TABLE lt_flow_lines
        WITH KEY
          table_line =
            lv_flow_line
        TRANSPORTING NO FIELDS.


      IF sy-subrc <> 0.

        APPEND lv_flow_line
          TO lt_flow_lines.

      ENDIF.


    ENDIF.


  ENDLOOP.


  append_group(
    EXPORTING
      iv_title =
        'Main Processing Flow'

      it_lines =
        lt_flow_lines

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  IF lt_flow_lines IS INITIAL.

    append_line(
      EXPORTING
        iv_line =
          '_No high-level event-to-routine flow was resolved._'

      CHANGING
        cv_markdown =
          cv_markdown
    ).


    append_line(
      CHANGING
        cv_markdown =
          cv_markdown
    ).

  ENDIF.


  "============================================================
  " 5. Key Dependencies & Output
  "============================================================
  DATA lt_dependency_lines
    TYPE tt_string.


  "------------------------------------------------------------
  " Database access
  "------------------------------------------------------------
  LOOP AT is_document-items
    INTO DATA(ls_database)
    WHERE section_id = 'DATABASE_ACCESS'.


    IF ls_database-item_kind <>
         zif_mig_tech_doc_builder=>gc_kind_database.

      CONTINUE.

    ENDIF.


    DATA(lv_db_name) =
      normalize_text(
        iv_text =
          CONV string(
            ls_database-label
          )
      ).


    DATA(lv_db_operation) =
      normalize_text(
        iv_text =
          ls_database-value
      ).


    DATA(lv_dependency_line) =
      |- **Database:** `{ lv_db_name }`|.


    IF lv_db_operation IS NOT INITIAL.

      lv_dependency_line =
        |{ lv_dependency_line } ({
           lv_db_operation })|.

    ENDIF.


    READ TABLE lt_dependency_lines
      WITH KEY
        table_line =
          lv_dependency_line
      TRANSPORTING NO FIELDS.


    IF sy-subrc <> 0.

      APPEND lv_dependency_line
        TO lt_dependency_lines.

    ENDIF.


  ENDLOOP.


  "------------------------------------------------------------
  " External FM / BAPI dependencies
  "------------------------------------------------------------
  LOOP AT is_document-items
    INTO DATA(ls_logic)
    WHERE section_id = 'BUSINESS_LOGIC'.


    IF ls_logic-item_kind <>
         zif_mig_tech_doc_builder=>gc_kind_logic.

      CONTINUE.

    ENDIF.


    DATA(lv_logic_type) =
      to_upper(
        normalize_text(
          iv_text =
            ls_logic-value
        )
      ).


    IF lv_logic_type <> 'BAPI'
       AND lv_logic_type <> 'FUNCTION_MODULE'
       AND lv_logic_type <> 'DYNAMIC_FUNCTION_MODULE'.

      CONTINUE.

    ENDIF.


    DATA(lv_logic_name) =
      normalize_text(
        iv_text =
          CONV string(
            ls_logic-label
          )
      ).


    lv_dependency_line =
      |- **External Dependency:** `{
         lv_logic_name }` ({
         lv_logic_type })|.


    IF ls_logic-manual_review = abap_true.

      lv_dependency_line =
        |{ lv_dependency_line } **[MANUAL REVIEW]**|.

    ENDIF.


    READ TABLE lt_dependency_lines
      WITH KEY
        table_line =
          lv_dependency_line
      TRANSPORTING NO FIELDS.


    IF sy-subrc <> 0.

      APPEND lv_dependency_line
        TO lt_dependency_lines.

    ENDIF.


  ENDLOOP.


  "------------------------------------------------------------
  " ALV output
  "------------------------------------------------------------
  LOOP AT is_document-items
    INTO DATA(ls_alv)
    WHERE section_id = 'ALV_OUTPUT'.


    IF ls_alv-item_kind <>
         zif_mig_tech_doc_builder=>gc_kind_alv.

      CONTINUE.

    ENDIF.


    DATA(lv_alv_table) =
      normalize_text(
        iv_text =
          CONV string(
            ls_alv-label
          )
      ).


    DATA(lv_alv_framework) =
      normalize_text(
        iv_text =
          ls_alv-value
      ).


    lv_dependency_line =
      |- **Output:** `{
         lv_alv_table }`|.


    IF lv_alv_framework IS NOT INITIAL.

      lv_dependency_line =
        |{ lv_dependency_line } via `{
           lv_alv_framework }`|.

    ENDIF.


    READ TABLE lt_dependency_lines
      WITH KEY
        table_line =
          lv_dependency_line
      TRANSPORTING NO FIELDS.


    IF sy-subrc <> 0.

      APPEND lv_dependency_line
        TO lt_dependency_lines.

    ENDIF.


  ENDLOOP.


  append_group(
    EXPORTING
      iv_title =
        'Key Dependencies & Output'

      it_lines =
        lt_dependency_lines

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  "============================================================
  " 6. Priority Modernization Actions
  "
  " Priority:
  " 1. Recommendations requiring manual review
  " 2. Remaining recommendation categories
  "
  " Only unique recommendation titles are shown.
  " Full recommendation details remain in section 10.
  "============================================================
  DATA:
    lt_priority_lines TYPE tt_string,
    lt_priority_titles TYPE tt_string.


  DATA lv_priority_count TYPE i.

  CLEAR lv_priority_count.


  "------------------------------------------------------------
  " Pass 1 - manual review recommendations
  "------------------------------------------------------------
  LOOP AT is_document-items
    INTO DATA(ls_priority_manual)
    WHERE section_id = 'RECOMMENDATIONS'
      AND manual_review = abap_true.


    IF lv_priority_count >= 6.
      EXIT.
    ENDIF.


    DATA(lv_priority_title) =
      normalize_text(
        iv_text =
          CONV string(
            ls_priority_manual-label
          )
      ).


    IF lv_priority_title IS INITIAL.
      CONTINUE.
    ENDIF.


    READ TABLE lt_priority_titles
      WITH KEY
        table_line =
          lv_priority_title
      TRANSPORTING NO FIELDS.


    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.


    APPEND lv_priority_title
      TO lt_priority_titles.


    APPEND
      |- **{ lv_priority_title }** — Manual review required|
      TO lt_priority_lines.


    lv_priority_count += 1.


  ENDLOOP.


  "------------------------------------------------------------
  " Pass 2 - other recommendation categories
  "------------------------------------------------------------
  LOOP AT is_document-items
    INTO DATA(ls_priority)
    WHERE section_id = 'RECOMMENDATIONS'.


    IF lv_priority_count >= 6.
      EXIT.
    ENDIF.


    lv_priority_title =
      normalize_text(
        iv_text =
          CONV string(
            ls_priority-label
          )
      ).


    IF lv_priority_title IS INITIAL.
      CONTINUE.
    ENDIF.


    READ TABLE lt_priority_titles
      WITH KEY
        table_line =
          lv_priority_title
      TRANSPORTING NO FIELDS.


    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.


    APPEND lv_priority_title
      TO lt_priority_titles.


    APPEND
      |- **{ lv_priority_title }**|
      TO lt_priority_lines.


    lv_priority_count += 1.


  ENDLOOP.


  append_group(
    EXPORTING
      iv_title =
        'Priority Modernization Actions'

      it_lines =
        lt_priority_lines

    CHANGING
      cv_markdown =
        cv_markdown
  ).


  IF lt_priority_lines IS INITIAL.

    append_line(
      EXPORTING
        iv_line =
          '_No modernization recommendations were generated._'

      CHANGING
        cv_markdown =
          cv_markdown
    ).


    append_line(
      CHANGING
        cv_markdown =
          cv_markdown
    ).

  ENDIF.


  "============================================================
  " 7. Analysis Boundary
  "
  " Reuse section 11 content rather than inventing new limits.
  "============================================================
  DATA lv_boundary_found
    TYPE abap_bool.

  CLEAR lv_boundary_found.


  LOOP AT is_document-items
    INTO DATA(ls_boundary)
    WHERE section_id = 'MANUAL_REVIEW'.


    DATA(lv_boundary_label) =
      normalize_text(
        iv_text =
          CONV string(
            ls_boundary-label
          )
      ).


    DATA(lv_boundary_value) =
      normalize_text(
        iv_text =
          ls_boundary-value
      ).


    DATA(lv_boundary_detail) =
      normalize_text(
        iv_text =
          ls_boundary-detail
      ).


    IF lv_boundary_label IS INITIAL
       AND lv_boundary_value IS INITIAL
       AND lv_boundary_detail IS INITIAL.

      CONTINUE.

    ENDIF.


    IF lv_boundary_found = abap_false.

      append_line(
        EXPORTING
          iv_line =
            '### Analysis Boundary'

        CHANGING
          cv_markdown =
            cv_markdown
      ).


      append_line(
        CHANGING
          cv_markdown =
            cv_markdown
      ).


      lv_boundary_found =
        abap_true.

    ENDIF.


    DATA(lv_boundary_line) =
      |- **{ lv_boundary_label }**|.


    IF lv_boundary_value IS NOT INITIAL.

      lv_boundary_line =
        |{ lv_boundary_line }: {
           lv_boundary_value }|.

    ENDIF.


    IF lv_boundary_detail IS NOT INITIAL.

      lv_boundary_line =
        |{ lv_boundary_line } — {
           lv_boundary_detail }|.

    ENDIF.


    append_line(
      EXPORTING
        iv_line =
          lv_boundary_line

      CHANGING
        cv_markdown =
          cv_markdown
    ).


  ENDLOOP.


ENDMETHOD.

  METHOD render_business_logic.

    DATA:
      lt_routines TYPE tt_string,
      lt_external TYPE tt_string,
      lt_methods  TYPE tt_string,
      lt_other    TYPE tt_string.


    DATA lv_definition_count TYPE i.

    CLEAR lv_definition_count.


    LOOP AT it_items
      INTO DATA(ls_item)
      WHERE section_id = 'BUSINESS_LOGIC'.


      DATA(lv_type) =
        to_upper(
          normalize_text(
            iv_text =
                ls_item-value
          )
        ).


      "========================================================
      " Definitions remain in structured document/evidence,
      " but are intentionally omitted from developer summary.
      "========================================================
      IF lv_type = 'FORM_DEFINITION'
         OR lv_type = 'METHOD_DEFINITION'
         OR lv_type = 'FUNCTION_DEFINITION'.

        lv_definition_count += 1.

        CONTINUE.

      ENDIF.


      DATA(lv_line) =
        render_item(
          is_item = ls_item
        ).


      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.


      CASE lv_type.


        "======================================================
        " Procedural internal routine calls
        "======================================================
        WHEN 'FORM_CALL'.

          READ TABLE lt_routines
            WITH KEY
              table_line = lv_line
            TRANSPORTING NO FIELDS.

          IF sy-subrc <> 0.

            APPEND lv_line
              TO lt_routines.

          ENDIF.


        "======================================================
        " External functions / BAPIs
        "======================================================
        WHEN 'BAPI'
          OR 'FUNCTION_MODULE'
          OR 'DYNAMIC_FUNCTION_MODULE'.

          READ TABLE lt_external
            WITH KEY
              table_line = lv_line
            TRANSPORTING NO FIELDS.

          IF sy-subrc <> 0.

            APPEND lv_line
              TO lt_external.

          ENDIF.


        "======================================================
        " OO dependencies
        "======================================================
        WHEN 'STATIC_METHOD'
          OR 'INSTANCE_METHOD'.

          READ TABLE lt_methods
            WITH KEY
              table_line = lv_line
            TRANSPORTING NO FIELDS.

          IF sy-subrc <> 0.

            APPEND lv_line
              TO lt_methods.

          ENDIF.


        "======================================================
        " Other dependencies:
        " transaction, module, submit, dypro, etc.
        "======================================================
        WHEN OTHERS.

          READ TABLE lt_other
            WITH KEY
              table_line = lv_line
            TRANSPORTING NO FIELDS.

          IF sy-subrc <> 0.

            APPEND lv_line
              TO lt_other.

          ENDIF.


      ENDCASE.


    ENDLOOP.


    "==========================================================
    " Render grouped developer view
    "==========================================================
    append_group(
      EXPORTING
        iv_title =
          'Internal Routine Calls'

        it_lines =
          lt_routines

      CHANGING
        cv_markdown =
          cv_markdown
    ).


    append_group(
      EXPORTING
        iv_title =
          'External Function Dependencies'

        it_lines =
          lt_external

      CHANGING
        cv_markdown =
          cv_markdown
    ).


    append_group(
      EXPORTING
        iv_title =
          'Class / Method Dependencies'

        it_lines =
          lt_methods

      CHANGING
        cv_markdown =
          cv_markdown
    ).


    append_group(
      EXPORTING
        iv_title =
          'Other Dependencies'

        it_lines =
          lt_other

      CHANGING
        cv_markdown =
          cv_markdown
    ).


    "==========================================================
    " Definitions are deliberately hidden from main summary
    "==========================================================
    IF lv_definition_count > 0.

      append_line(
        EXPORTING
          iv_line =
            |_Internal definitions omitted from this summary: {
               lv_definition_count
             }. See Evidence Appendix for source-level traceability._|

        CHANGING
          cv_markdown =
            cv_markdown
      ).

    ENDIF.


    IF lt_routines IS INITIAL
       AND lt_external IS INITIAL
       AND lt_methods IS INITIAL
       AND lt_other IS INITIAL
       AND lv_definition_count = 0.

      append_line(
        EXPORTING
          iv_line =
            '_No business logic dependencies detected._'

        CHANGING
          cv_markdown =
            cv_markdown
      ).

    ENDIF.

  ENDMETHOD.



  METHOD render_recommendations.

    DATA lt_rendered_titles
      TYPE tt_string.


    DATA(lv_found) =
      abap_false.


    LOOP AT it_items
      ASSIGNING FIELD-SYMBOL(<recommendation>)
      WHERE section_id = 'RECOMMENDATIONS'.


      DATA(lv_title) =
        normalize_text(
          iv_text =
            CONV string(
              <recommendation>-label
            )
        ).


      IF lv_title IS INITIAL.
        CONTINUE.
      ENDIF.


      lv_found =
        abap_true.


      "========================================================
      " Recommendation title has already been rendered
      "========================================================
      READ TABLE lt_rendered_titles
        WITH KEY
          table_line = lv_title
        TRANSPORTING NO FIELDS.


      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.


      APPEND lv_title
        TO lt_rendered_titles.


      append_line(
        EXPORTING
          iv_line =
            |### { lv_title }|

        CHANGING
          cv_markdown =
            cv_markdown
      ).


      append_line(
        CHANGING
          cv_markdown =
            cv_markdown
      ).


      DATA:
          lt_actions TYPE tt_string,
          lt_reasons TYPE tt_string.


        CLEAR:
          lt_actions,
          lt_reasons.


        DATA(lv_group_label) =
          <recommendation>-label.


      "========================================================
      " Collect recommendations with the same title
      "========================================================
      LOOP AT it_items
        ASSIGNING FIELD-SYMBOL(<group_item>)
        WHERE section_id = 'RECOMMENDATIONS'
          AND label      = lv_group_label.


        "======================================================
        " Recommendation action
        "======================================================
        DATA(lv_action) =
          normalize_text(
            iv_text =
              <group_item>-value
          ).


        IF lv_action IS NOT INITIAL.

          READ TABLE lt_actions
            WITH KEY
              table_line = lv_action
            TRANSPORTING NO FIELDS.


          "Duplicate semantic recommendation:
          "do not render again.
          IF sy-subrc <> 0.

            APPEND lv_action
              TO lt_actions.


            DATA(lv_action_line) =
              |- { lv_action }|.


            "Preserve confidence, manual review and source.
            append_metadata(
              EXPORTING
                is_item =
                  <group_item>

              CHANGING
                cv_line =
                  lv_action_line
            ).


            append_line(
              EXPORTING
                iv_line =
                  lv_action_line

              CHANGING
                cv_markdown =
                  cv_markdown
            ).

          ENDIF.

        ENDIF.


        "======================================================
        " Recommendation rationale
        "======================================================
        DATA(lv_reason) =
          normalize_text(
            iv_text =
              <group_item>-detail
          ).


        IF lv_reason IS NOT INITIAL.

          READ TABLE lt_reasons
            WITH KEY
              table_line = lv_reason
            TRANSPORTING NO FIELDS.


          IF sy-subrc <> 0.

            APPEND lv_reason
              TO lt_reasons.

          ENDIF.

        ENDIF.


      ENDLOOP.


      "========================================================
      " Render unique rationale(s)
      "========================================================
      LOOP AT lt_reasons
        INTO DATA(lv_group_reason).

        append_line(
          EXPORTING
            iv_line =
              |_Rationale:_ {
                 lv_group_reason }|

          CHANGING
            cv_markdown =
              cv_markdown
        ).

      ENDLOOP.


      append_line(
        CHANGING
          cv_markdown =
            cv_markdown
      ).


    ENDLOOP.


    IF lv_found = abap_false.

      append_line(
        EXPORTING
          iv_line =
            '_No recommendations generated._'

        CHANGING
          cv_markdown =
            cv_markdown
      ).

    ENDIF.

  ENDMETHOD.



  METHOD render_evidence.

    DATA lt_rendered_lines
      TYPE tt_string.


    DATA(lv_found) =
      abap_false.


    LOOP AT it_items
      INTO DATA(ls_item)
      WHERE section_id = 'EVIDENCE_APPENDIX'.


      DATA(lv_line) =
        render_item(
          is_item = ls_item
        ).


      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.


      "========================================================
      " Deduplicate rendering only.
      "
      " Evidence objects in TY_ANALYSIS_RESULT / persistence
      " remain untouched.
      "========================================================
      READ TABLE lt_rendered_lines
        WITH KEY
          table_line = lv_line
        TRANSPORTING NO FIELDS.


      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.


      APPEND lv_line
        TO lt_rendered_lines.


      lv_found =
        abap_true.


      append_line(
        EXPORTING
          iv_line =
            lv_line

        CHANGING
          cv_markdown =
            cv_markdown
      ).


    ENDLOOP.


    IF lv_found = abap_false.

      append_line(
        EXPORTING
          iv_line =
            '_No evidence available._'

        CHANGING
          cv_markdown =
            cv_markdown
      ).

    ENDIF.

  ENDMETHOD.



  METHOD render_item.

    DATA(lv_indent) =
      build_indent(
        iv_level = is_item-level
      ).


    DATA(lv_label) =
      normalize_text(
        iv_text =
          CONV string(
            is_item-label
          )
      ).


    DATA(lv_value) =
      normalize_text(
        iv_text =
          is_item-value
      ).


    DATA(lv_detail) =
      normalize_text(
        iv_text =
          is_item-detail
      ).


    CASE is_item-item_kind.


      "========================================================
      " Plain text / metric
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_text

        OR
        zif_mig_tech_doc_builder=>gc_kind_metric.


        rv_line =
          |{ lv_indent }- **{ lv_label }:** {
             lv_value }|.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Source structure
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_source.


        rv_line =
          |{ lv_indent }- `{ lv_label }`|.


        IF lv_value IS NOT INITIAL.

          rv_line =
            |{ rv_line } ({ lv_value })|.

        ENDIF.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Application flow
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_flow.


        rv_line =
          |{ lv_indent }- `{ lv_label }`|.


        IF lv_value IS NOT INITIAL.

          rv_line =
            |{ rv_line } **[{ lv_value }]**|.

        ENDIF.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Selection field
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_filter.


        rv_line =
          |{ lv_indent }- **{ lv_label }**|.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Database
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_database.


        rv_line =
          |{ lv_indent }- `{ lv_label }` **{ lv_value }**|.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Business Logic
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_logic.


        rv_line =
          |{ lv_indent }- `{ lv_label }` ({ lv_value })|.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " ALV
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_alv.


        rv_line =
          |{ lv_indent }- **{ lv_label }** ({ lv_value })|.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Recommendation
      "
      " Normally recommendations are now rendered through
      " RENDER_RECOMMENDATIONS. This branch is kept so
      " RENDER_ITEM remains backwards-compatible.
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_recommendation.


        rv_line =
          |{ lv_indent }- **{ lv_label }**|.


        IF lv_value IS NOT INITIAL.

          rv_line =
            |{ rv_line }: { lv_value }|.

        ENDIF.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Warning / Manual review
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_warning.


        rv_line =
          |{ lv_indent }- **Review: { lv_label }**|.


        IF lv_value IS NOT INITIAL.

          rv_line =
            |{ rv_line }: { lv_value }|.

        ENDIF.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.



      "========================================================
      " Evidence appendix
      "========================================================
      WHEN
        zif_mig_tech_doc_builder=>gc_kind_evidence.


        "Presentation cleanup for ranges such as:
        "Line 9-$12 -> Line 9-12
        REPLACE ALL OCCURRENCES OF
          '-$'
          IN lv_value
          WITH '-'.


        rv_line =
          |{ lv_indent }- `{ lv_label }` — { lv_value }|.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — `{ lv_detail }`|.

        ENDIF.



      WHEN OTHERS.


        rv_line =
          |{ lv_indent }- { lv_label }|.


        IF lv_value IS NOT INITIAL.

          rv_line =
            |{ rv_line }: { lv_value }|.

        ENDIF.


        IF lv_detail IS NOT INITIAL.

          rv_line =
            |{ rv_line } — { lv_detail }|.

        ENDIF.


    ENDCASE.


    append_metadata(
      EXPORTING
        is_item = is_item

      CHANGING
        cv_line = rv_line
    ).


  ENDMETHOD.



  METHOD append_metadata.

    IF is_item-confidence IS NOT INITIAL
       AND is_item-confidence <>
         zif_mig_types=>gc_conf_high.

      cv_line =
        |{ cv_line } _(confidence: {
           is_item-confidence })_|.

    ENDIF.


    IF is_item-manual_review =
         abap_true.

      cv_line =
        |{ cv_line } **[MANUAL REVIEW]**|.

    ENDIF.


    IF is_item-source_object IS NOT INITIAL
       AND is_item-source_line > 0
       AND is_item-item_kind <>
         zif_mig_tech_doc_builder=>gc_kind_evidence.

      cv_line =
        |{ cv_line } _(source: {
           is_item-source_object }:{
           is_item-source_line })_|.

    ENDIF.


  ENDMETHOD.


ENDCLASS.
