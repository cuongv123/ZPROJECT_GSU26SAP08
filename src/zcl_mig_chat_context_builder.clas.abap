CLASS zcl_mig_chat_context_builder DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_chat_context_builder.

  PRIVATE SECTION.

    METHODS get_latest_header
      IMPORTING
        iv_program_name TYPE progname
      RETURNING
        VALUE(rs_header) TYPE zmig_anl_h
      RAISING
        zcx_mig_analysis.

    METHODS check_outdated
      IMPORTING
        is_header TYPE zmig_anl_h
      RETURNING
        VALUE(rv_outdated) TYPE abap_bool.

    METHODS build_source_section
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
        iv_question    TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS build_db_section
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS build_logic_section
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
      CHANGING
        cv_unresolved TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS build_alv_section
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS build_ui_section
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS build_recommend_section
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
      RETURNING
        VALUE(rv_text) TYPE string.

ENDCLASS.


CLASS zcl_mig_chat_context_builder IMPLEMENTATION.

  METHOD zif_mig_chat_context_builder~classify_intent.

    DATA(lv_q) = to_lower( iv_question ).

    IF lv_q CS 'selection-screen'
       OR lv_q CS 'selection screen'
       OR lv_q CS 'selection'
       OR lv_q CS 'màn hình'
       OR lv_q CS 'tham số nhập'.

      rv_intent = zif_mig_chat_ai=>intent-ui.

    ELSEIF lv_q CS 'flow'
        OR lv_q CS 'luồng'
        OR lv_q CS 'trình tự'
        OR lv_q CS 'tác dụng'
        OR lv_q CS 'làm gì'
        OR lv_q CS 'mục đích'
        OR lv_q CS 'overview'.

      rv_intent = zif_mig_chat_ai=>intent-overview.

    ELSEIF lv_q CS 'bapi'
        OR lv_q CS 'function'
        OR lv_q CS 'fm'
        OR lv_q CS 'gọi'.

      rv_intent = zif_mig_chat_ai=>intent-bapi.

    ELSEIF lv_q CS 'alv'
        OR lv_q CS 'cột'
        OR lv_q CS 'output'.

      rv_intent = zif_mig_chat_ai=>intent-alv.

    ELSEIF lv_q CS 'table'
        OR lv_q CS 'bảng'
        OR lv_q CS 'select'.

      rv_intent = zif_mig_chat_ai=>intent-db.

    ELSEIF lv_q CS 'logic'
        OR lv_q CS 'nghiệp vụ'
        OR lv_q CS 'xử lý'
        OR lv_q CS 'tính'.

      rv_intent = zif_mig_chat_ai=>intent-logic.

    ELSEIF lv_q CS 'filter'
        OR lv_q CS 'lọc'.

      rv_intent = zif_mig_chat_ai=>intent-ui.

    ELSEIF lv_q CS 'migrate'
        OR lv_q CS 'nên làm'
        OR lv_q CS 'hướng'
        OR lv_q CS 'recommend'.

      rv_intent = zif_mig_chat_ai=>intent-recommend.

    ELSE.

      rv_intent = zif_mig_chat_ai=>intent-overview.

    ENDIF.

  ENDMETHOD.


  METHOD zif_mig_chat_context_builder~build.

    CLEAR rs_context.

    DATA lv_program TYPE progname.
    DATA ls_header TYPE zmig_anl_h.
    DATA lv_focused TYPE string.

    lv_program = to_upper( condense( iv_program_name ) ).

    IF lv_program IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_analysis(
        program_name = lv_program ).
    ENDIF.

    " Resolve the snapshot once and use it for every section.
    IF iv_analysis_id IS INITIAL.

      ls_header = get_latest_header( lv_program ).

    ELSE.

      SELECT SINGLE analysis_id,
                    program_name,
                    program_description,
                    status,
                    total_source_objects,
                    total_ui_filters,
                    total_database_objects,
                    total_business_logic,
                    total_alv_outputs,
                    total_alv_columns,
                    total_recommendations,
                    complexity_score,
                    readiness_score,
                    parser_version,
                    rule_version,
                    source_hash,
                    created_at
        FROM zmig_anl_h
        WHERE analysis_id = @iv_analysis_id
          AND program_name = @lv_program
        INTO CORRESPONDING FIELDS OF @ls_header.

      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW zcx_mig_analysis(
          program_name = lv_program ).
      ENDIF.

    ENDIF.

    IF ls_header-status <> 'COMPLETED'
       AND ls_header-status <> 'WARNING'.
      RAISE EXCEPTION NEW zcx_mig_analysis(
        program_name = lv_program ).
    ENDIF.

    rs_context-program_name = lv_program.
    rs_context-analysis_id  = ls_header-analysis_id.
    rs_context-is_outdated  = check_outdated( ls_header ).

    " Supply a basic overview for every question.
    rs_context-anchor_summary =
      |Report: { ls_header-program_name }\n| &&
      |Description: { ls_header-program_description }\n| &&
      |Analysis status: { ls_header-status }\n| &&
      |Source objects: { ls_header-total_source_objects }\n| &&
      |Database objects: { ls_header-total_database_objects }\n| &&
      |Business logic items: { ls_header-total_business_logic }\n| &&
      |UI filters: { ls_header-total_ui_filters }\n| &&
      |ALV outputs: { ls_header-total_alv_outputs }\n|.

    DATA(lv_intent) =
      zif_mig_chat_context_builder~classify_intent( iv_question ).

    " Add focused metadata based on the current question.
    CASE lv_intent.

      WHEN zif_mig_chat_ai=>intent-db.

        lv_focused = build_db_section(
          ls_header-analysis_id ).

      WHEN zif_mig_chat_ai=>intent-bapi
        OR zif_mig_chat_ai=>intent-logic.

        lv_focused = build_logic_section(
          EXPORTING
            iv_analysis_id = ls_header-analysis_id
          CHANGING
            cv_unresolved = rs_context-unresolved_note ).

      WHEN zif_mig_chat_ai=>intent-alv.

        lv_focused = build_alv_section(
          ls_header-analysis_id ).

      WHEN zif_mig_chat_ai=>intent-ui.

        lv_focused = build_ui_section(
          ls_header-analysis_id ).

      WHEN zif_mig_chat_ai=>intent-recommend.

        lv_focused = build_recommend_section(
          ls_header-analysis_id ).

      WHEN OTHERS.

        " General questions use the technical document and source.
        CLEAR lv_focused.

    ENDCASE.

    " Generate the technical document from the same snapshot.
    DATA(lo_doc_service) = NEW zcl_mig_tech_doc_service( ).

    DATA(ls_doc) =
      lo_doc_service->zif_mig_tech_doc_service~generate(
        iv_analysis_id = ls_header-analysis_id ).

    IF strlen( ls_doc-markdown )
         > zif_mig_chat_ai=>max_doc_chars.

      ls_doc-markdown = substring(
        val = ls_doc-markdown
        len = zif_mig_chat_ai=>max_doc_chars ) &&
        |\n[Technical document truncated.]|.

    ENDIF.

    IF strlen( lv_focused )
         > zif_mig_chat_ai=>max_focused_chars.

      lv_focused = substring(
        val = lv_focused
        len = zif_mig_chat_ai=>max_focused_chars ) &&
        |\n[Focused metadata truncated.]|.

    ENDIF.

    IF strlen( rs_context-unresolved_note )
         > zif_mig_chat_ai=>max_unresolved_chars.

      rs_context-unresolved_note = substring(
        val = rs_context-unresolved_note
        len = zif_mig_chat_ai=>max_unresolved_chars ) &&
        |\n[Further unresolved calls omitted.]|.

    ENDIF.

    DATA(lv_source) = build_source_section(
      iv_analysis_id = ls_header-analysis_id
      iv_question    = iv_question ).

    " Preserve source evidence before applying the final limit.
    rs_context-focused_section =
      |SAVED SOURCE EVIDENCE\n| &&
      lv_source &&
      |\n\nFOCUSED ANALYSIS\n| &&
      lv_focused &&
      |\n\nTECHNICAL DOCUMENT (static analysis, not a runtime trace)\n| &&
      ls_doc-markdown.

    IF strlen( rs_context-focused_section )
         > zif_mig_chat_ai=>max_context_chars.

      rs_context-focused_section = substring(
        val = rs_context-focused_section
        len = zif_mig_chat_ai=>max_context_chars ) &&
        |\n[Context truncated; omitted content is unknown.]|.

    ENDIF.

  ENDMETHOD.


  METHOD get_latest_header.

    DATA lt_header TYPE STANDARD TABLE OF zmig_anl_h
      WITH EMPTY KEY.

    SELECT analysis_id,
           program_name,
           program_description,
           status,
           total_source_objects,
           total_ui_filters,
           total_database_objects,
           total_business_logic,
           total_alv_outputs,
           total_alv_columns,
           total_recommendations,
           complexity_score,
           readiness_score,
           parser_version,
           rule_version,
           source_hash,
           created_at
      FROM zmig_anl_h
      WHERE program_name = @iv_program_name
        AND ( status = 'COMPLETED' OR status = 'WARNING' )
      ORDER BY created_at DESCENDING, analysis_id DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @lt_header
      UP TO 1 ROWS.

    IF lt_header IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_analysis(
        program_name = iv_program_name ).
    ENDIF.

    rs_header = lt_header[ 1 ].

  ENDMETHOD.


  METHOD check_outdated.

    rv_outdated = abap_false.

    SELECT item_id, object_name
      FROM zmig_anl_src
      WHERE analysis_id = @is_header-analysis_id
      INTO TABLE @DATA(lt_objects).

    SELECT source_item_id, line_number, source_text
      FROM zmig_anl_code
      WHERE analysis_id = @is_header-analysis_id
      ORDER BY source_item_id, line_number
      INTO TABLE @DATA(lt_saved).

    IF lt_objects IS INITIAL OR lt_saved IS INITIAL.
      rv_outdated = abap_true.
      RETURN.
    ENDIF.

    " Index source lines for direct lookup during comparison.
    TYPES:
      BEGIN OF ty_saved_line,
        source_item_id TYPE sysuuid_x16,
        line_number   TYPE i,
        source_text   TYPE string,
      END OF ty_saved_line.

    DATA lt_saved_index TYPE HASHED TABLE OF ty_saved_line
      WITH UNIQUE KEY source_item_id line_number.

    lt_saved_index = CORRESPONDING #( lt_saved ).

    DATA lt_active TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.

    DATA lv_total_active TYPE i.
    DATA lv_line_number TYPE i.

    LOOP AT lt_objects INTO DATA(ls_object).

      CLEAR lt_active.

      TEST-SEAM read_active_source.
        READ REPORT ls_object-object_name
          INTO lt_active STATE 'A'.
      END-TEST-SEAM.

      IF sy-subrc <> 0.
        rv_outdated = abap_true.
        RETURN.
      ENDIF.

      lv_total_active = lv_total_active + lines( lt_active ).

      " Each active line is compared using a hashed key lookup.
      LOOP AT lt_active INTO DATA(lv_active_line).

        lv_line_number = sy-tabix.

        READ TABLE lt_saved_index
          WITH TABLE KEY
            source_item_id = ls_object-item_id
            line_number    = lv_line_number
          INTO DATA(ls_saved_line).

        IF sy-subrc <> 0.
          rv_outdated = abap_true.
          RETURN.
        ENDIF.

        IF lv_active_line <> ls_saved_line-source_text.
          rv_outdated = abap_true.
          RETURN.
        ENDIF.

      ENDLOOP.

    ENDLOOP.

    " Detect extra saved lines or source lines without an object.
    IF lv_total_active <> lines( lt_saved_index ).
      rv_outdated = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD build_source_section.

    CONSTANTS lc_context_radius TYPE i VALUE 12.

    TYPES:
      BEGIN OF ty_line,
        object_name TYPE progname,
        line_number TYPE i,
        source_text TYPE string,
        priority    TYPE i,
      END OF ty_line,

      BEGIN OF ty_priority_line,
        object_name TYPE progname,
        line_number TYPE i,
      END OF ty_priority_line.

    DATA lt_lines TYPE STANDARD TABLE OF ty_line
      WITH EMPTY KEY.

    DATA lt_priority_lines TYPE HASHED TABLE OF ty_priority_line
      WITH UNIQUE KEY object_name line_number.

    SELECT s~object_name,
           c~line_number,
           c~source_text
      FROM zmig_anl_code AS c
      INNER JOIN zmig_anl_src AS s
        ON s~analysis_id = c~analysis_id
       AND s~item_id = c~source_item_id
      WHERE c~analysis_id = @iv_analysis_id
      INTO CORRESPONDING FIELDS OF TABLE @lt_lines.

    IF lt_lines IS INITIAL.
      rv_text =
        'No saved source lines. Do not invent source citations.'.
      RETURN.
    ENDIF.

    DATA(lv_question) = to_upper( iv_question ).

    REPLACE ALL OCCURRENCES OF PCRE
      '[^A-Z0-9_/]+'
      IN lv_question
      WITH ' '.

    SPLIT lv_question AT ' ' INTO TABLE DATA(lt_words).

    SORT lt_words.
    DELETE ADJACENT DUPLICATES FROM lt_words.
    DELETE lt_words WHERE table_line = ''.

    DATA lv_match TYPE abap_bool.
    DATA lv_first_line TYPE i.
    DATA lv_last_line TYPE i.
    DATA lv_current_line TYPE i.

    " Mark matching symbols and a bounded window around each match.
    LOOP AT lt_lines INTO DATA(ls_line).

      lv_match = abap_false.

      LOOP AT lt_words INTO DATA(lv_word).

        IF strlen( lv_word ) < 4.
          CONTINUE.
        ENDIF.

        IF to_upper( ls_line-source_text ) CS lv_word.
          lv_match = abap_true.
          EXIT.
        ENDIF.

      ENDLOOP.

      IF lv_match = abap_false.
        CONTINUE.
      ENDIF.

      lv_first_line = ls_line-line_number - lc_context_radius.
      lv_last_line  = ls_line-line_number + lc_context_radius.

      IF lv_first_line < 1.
        lv_first_line = 1.
      ENDIF.

      lv_current_line = lv_first_line.

      WHILE lv_current_line <= lv_last_line.

        INSERT VALUE #(
          object_name = ls_line-object_name
          line_number = lv_current_line
        ) INTO TABLE lt_priority_lines.

        lv_current_line = lv_current_line + 1.

      ENDWHILE.

    ENDLOOP.

    LOOP AT lt_lines ASSIGNING FIELD-SYMBOL(<line>).

      <line>-priority = 1.

      IF line_exists(
        lt_priority_lines[
          object_name = <line>-object_name
          line_number = <line>-line_number ] ).

        <line>-priority = 0.

      ENDIF.

    ENDLOOP.

    SORT lt_lines BY priority object_name line_number.

    LOOP AT lt_lines INTO ls_line.

      DATA(lv_piece) =
        |[{ ls_line-object_name }:{ ls_line-line_number }] | &&
        |{ ls_line-source_text }\n|.

      IF strlen( rv_text ) + strlen( lv_piece )
           > zif_mig_chat_ai=>max_source_chars.

        rv_text = rv_text &&
          |\n[Source selection truncated. Other lines may exist.]|.

        EXIT.

      ENDIF.

      rv_text = rv_text && lv_piece.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_db_section.

    SELECT object_name,
           object_type,
           operation,
           selected_fields,
           where_fields,
           joined_objects,
           join_condition,
           result_target,
           containing_routine,
           execution_context,
           dynamic_access,
           description
      FROM zmig_anl_db
      WHERE analysis_id = @iv_analysis_id
      ORDER BY object_name, containing_routine, operation
      INTO TABLE @DATA(lt_db).

    LOOP AT lt_db INTO DATA(ls_db).

      rv_text = rv_text &&
        |- { ls_db-object_name } | &&
        |({ ls_db-object_type }, { ls_db-operation }): | &&
        |{ ls_db-description }| &&
        COND string(
          WHEN ls_db-containing_routine IS NOT INITIAL
          THEN |; routine={ ls_db-containing_routine }|
          ELSE '' ) &&
        COND string(
          WHEN ls_db-selected_fields IS NOT INITIAL
          THEN |; fields={ ls_db-selected_fields }|
          ELSE '' ) &&
        COND string(
          WHEN ls_db-where_fields IS NOT INITIAL
          THEN |; where={ ls_db-where_fields }|
          ELSE '' ) &&
        COND string(
          WHEN ls_db-joined_objects IS NOT INITIAL
          THEN |; joins={ ls_db-joined_objects }|
          ELSE '' ) &&
        COND string(
          WHEN ls_db-join_condition IS NOT INITIAL
          THEN |; on={ ls_db-join_condition }|
          ELSE '' ) &&
        COND string(
          WHEN ls_db-result_target IS NOT INITIAL
          THEN |; result={ ls_db-result_target }|
          ELSE '' ) &&
        COND string(
          WHEN ls_db-execution_context IS NOT INITIAL
          THEN |; context={ ls_db-execution_context }|
          ELSE '' ) &&
        COND string(
          WHEN ls_db-dynamic_access = abap_true
          THEN |; dynamic-access|
          ELSE '' ) &&
        |\n|.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_logic_section.

    TYPES:
      BEGIN OF ty_binding_text,
        call_item_id TYPE sysuuid_x16,
        text         TYPE string,
      END OF ty_binding_text.

    DATA lt_binding_text TYPE HASHED TABLE OF ty_binding_text
      WITH UNIQUE KEY call_item_id.

    SELECT item_id,
           object_name,
           object_type,
           container_name,
           calling_routine,
           execution_kind,
           execution_context,
           description,
           side_effect
      FROM zmig_anl_log
      WHERE analysis_id = @iv_analysis_id
      ORDER BY item_id
      INTO TABLE @DATA(lt_log).

    IF lt_log IS INITIAL.
      RETURN.
    ENDIF.

    " Fetch bindings in bulk; never query the database per call.
    SELECT call_item_id,
           parameter_name,
           direction,
           actual_expression,
           binding_position
      FROM zmig_anl_bind
      FOR ALL ENTRIES IN @lt_log
      WHERE analysis_id = @iv_analysis_id
        AND call_item_id = @lt_log-item_id
      INTO TABLE @DATA(lt_bind).

    SORT lt_bind BY call_item_id binding_position parameter_name.

    " Build an index to avoid scanning all bindings for every call.
    LOOP AT lt_bind INTO DATA(ls_bind).

      READ TABLE lt_binding_text
        ASSIGNING FIELD-SYMBOL(<binding_text>)
        WITH TABLE KEY call_item_id = ls_bind-call_item_id.

      IF sy-subrc <> 0.

        INSERT VALUE #(
          call_item_id = ls_bind-call_item_id
          text =
            |  { ls_bind-direction } { ls_bind-parameter_name }| &&
            | = { ls_bind-actual_expression }\n|
        ) INTO TABLE lt_binding_text.

      ELSE.

        <binding_text>-text = <binding_text>-text &&
          |  { ls_bind-direction } { ls_bind-parameter_name }| &&
          | = { ls_bind-actual_expression }\n|.

      ENDIF.

    ENDLOOP.

    LOOP AT lt_log INTO DATA(ls_log).

      " Preserve the uncertainty of dynamically resolved calls.
      IF ls_log-object_type CS 'DYNAMIC'.

        cv_unresolved = cv_unresolved &&
          |- { ls_log-object_name } at { ls_log-calling_routine }: | &&
          |dynamic call, exact target could not be resolved.\n|.

        CONTINUE.

      ENDIF.

      rv_text = rv_text &&
        |- { ls_log-object_name } ({ ls_log-object_type }| &&
        COND string(
          WHEN ls_log-container_name IS NOT INITIAL
          THEN | on { ls_log-container_name }|
          ELSE '' ) &&
        |), called in { ls_log-calling_routine }| &&
        COND string(
          WHEN ls_log-execution_kind = 'CONDITIONAL'
          THEN | (condition: { ls_log-execution_context })|
          ELSE '' ) &&
        |: { ls_log-description }| &&
        COND string(
          WHEN ls_log-side_effect IS NOT INITIAL
          THEN |. Side effect: { ls_log-side_effect }|
          ELSE '' ) &&
        |\n|.

      READ TABLE lt_binding_text
        ASSIGNING <binding_text>
        WITH TABLE KEY call_item_id = ls_log-item_id.

      IF sy-subrc = 0.
        rv_text = rv_text && <binding_text>-text.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_alv_section.

    TYPES:
      BEGIN OF ty_column_text,
        output_id TYPE zmig_anl_col-output_id,
        text      TYPE string,
      END OF ty_column_text.

    DATA lt_column_text TYPE HASHED TABLE OF ty_column_text
      WITH UNIQUE KEY output_id.

    SELECT output_id,
           output_name,
           framework,
           output_table,
           field_catalog,
           sort_table,
           hierarchical
      FROM zmig_anl_alv
      WHERE analysis_id = @iv_analysis_id
      ORDER BY output_id
      INTO TABLE @DATA(lt_alv).

    SELECT output_id,
           field_name,
           column_label,
           column_position,
           data_type,
           data_element,
           reference_table,
           reference_field
      FROM zmig_anl_col
      WHERE analysis_id = @iv_analysis_id
      ORDER BY output_id, column_position, field_name
      INTO TABLE @DATA(lt_columns).

    " Group column descriptions once before processing outputs.
    LOOP AT lt_columns INTO DATA(ls_column).

      DATA(lv_column_text) =
        |  column { ls_column-column_position }: | &&
        |{ ls_column-field_name }| &&
        COND string(
          WHEN ls_column-column_label IS NOT INITIAL
          THEN | ({ ls_column-column_label })|
          ELSE '' ) &&
        COND string(
          WHEN ls_column-data_type IS NOT INITIAL
          THEN | type={ ls_column-data_type }|
          ELSE '' ) &&
        COND string(
          WHEN ls_column-data_element IS NOT INITIAL
          THEN | data_element={ ls_column-data_element }|
          ELSE '' ) &&
        COND string(
          WHEN ls_column-reference_table IS NOT INITIAL
          THEN | reference={ ls_column-reference_table }-{ ls_column-reference_field }|
          ELSE '' ) &&
        |\n|.

      READ TABLE lt_column_text
        ASSIGNING FIELD-SYMBOL(<column_text>)
        WITH TABLE KEY output_id = ls_column-output_id.

      IF sy-subrc <> 0.

        INSERT VALUE #(
          output_id = ls_column-output_id
          text      = lv_column_text
        ) INTO TABLE lt_column_text.

      ELSE.

        <column_text>-text =
          <column_text>-text && lv_column_text.

      ENDIF.

    ENDLOOP.

    LOOP AT lt_alv INTO DATA(ls_alv).

      rv_text = rv_text &&
        |- Output "{ ls_alv-output_name }" | &&
        |({ ls_alv-framework }), | &&
        |internal table { ls_alv-output_table }| &&
        COND string(
          WHEN ls_alv-field_catalog IS NOT INITIAL
          THEN |; field catalog={ ls_alv-field_catalog }|
          ELSE '' ) &&
        COND string(
          WHEN ls_alv-sort_table IS NOT INITIAL
          THEN |; sort table={ ls_alv-sort_table }|
          ELSE '' ) &&
        COND string(
          WHEN ls_alv-hierarchical = abap_true
          THEN |; hierarchical|
          ELSE '' ) &&
        |\n|.

      READ TABLE lt_column_text
        ASSIGNING <column_text>
        WITH TABLE KEY output_id = ls_alv-output_id.

      IF sy-subrc = 0.
        rv_text = rv_text && <column_text>-text.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_ui_section.

    SELECT field_name,
           field_kind,
           reference_table,
           reference_field,
           data_element,
           data_type,
           description,
           selection_block,
           mandatory,
           hidden,
           multiple_selection,
           range_supported,
           default_value,
           validation_routine
      FROM zmig_anl_ui
      WHERE analysis_id = @iv_analysis_id
      ORDER BY selection_block, field_name
      INTO TABLE @DATA(lt_ui).

    LOOP AT lt_ui INTO DATA(ls_ui).

      rv_text = rv_text &&
        |- { ls_ui-field_name } ({ ls_ui-field_kind }): | &&
        |{ ls_ui-description }| &&
        COND string(
          WHEN ls_ui-data_type IS NOT INITIAL
          THEN | [type={ ls_ui-data_type }]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-data_element IS NOT INITIAL
          THEN | [data_element={ ls_ui-data_element }]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-reference_table IS NOT INITIAL
          THEN | [reference={ ls_ui-reference_table }-{ ls_ui-reference_field }]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-selection_block IS NOT INITIAL
          THEN | [block={ ls_ui-selection_block }]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-mandatory = abap_true
          THEN | [mandatory]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-hidden = abap_true
          THEN | [hidden]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-multiple_selection = abap_true
          THEN | [multiple-selection]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-range_supported = abap_true
          THEN | [range]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-default_value IS NOT INITIAL
          THEN | [default={ ls_ui-default_value }]|
          ELSE '' ) &&
        COND string(
          WHEN ls_ui-validation_routine IS NOT INITIAL
          THEN | [validation={ ls_ui-validation_routine }]|
          ELSE '' ) &&
        |\n|.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_recommend_section.

    SELECT title,
           display_text,
           explanation,
           severity
      FROM zmig_anl_rec
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_rec).

    LOOP AT lt_rec INTO DATA(ls_rec).

      rv_text = rv_text &&
        |- [{ ls_rec-severity }] { ls_rec-title }\n| &&
        |  { ls_rec-display_text }\n| &&
        |  { ls_rec-explanation }\n|.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
