CLASS zcl_mig_chat_context_builder DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_chat_context_builder.

  PRIVATE SECTION.
    METHODS build_source_section
      IMPORTING iv_analysis_id TYPE sysuuid_x16
                iv_question TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    METHODS get_latest_header
      IMPORTING iv_program_name  TYPE progname
      RETURNING VALUE(rs_header) TYPE zmig_anl_h
      RAISING   zcx_mig_analysis.

    METHODS check_outdated
      IMPORTING is_header          TYPE zmig_anl_h
      RETURNING VALUE(rv_outdated) TYPE abap_bool.

    METHODS build_db_section
      IMPORTING iv_analysis_id TYPE sysuuid_x16
      RETURNING VALUE(rv_text) TYPE string.

    METHODS build_logic_section
      IMPORTING iv_analysis_id TYPE sysuuid_x16
      CHANGING  cv_unresolved  TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    METHODS build_alv_section
      IMPORTING iv_analysis_id TYPE sysuuid_x16
      RETURNING VALUE(rv_text) TYPE string.

    METHODS build_ui_section
      IMPORTING iv_analysis_id TYPE sysuuid_x16
      RETURNING VALUE(rv_text) TYPE string.

    METHODS build_recommend_section
      IMPORTING iv_analysis_id TYPE sysuuid_x16
      RETURNING VALUE(rv_text) TYPE string.

ENDCLASS.


CLASS zcl_mig_chat_context_builder IMPLEMENTATION.

  METHOD zif_mig_chat_context_builder~classify_intent.

  DATA(lv_q) = to_lower( iv_question ).

  IF lv_q CS 'selection-screen' OR lv_q CS 'selection screen'
     OR lv_q CS 'selection' OR lv_q CS 'màn hình'
     OR lv_q CS 'tham số nhập'.
    rv_intent = zif_mig_chat_ai=>intent-ui.

  ELSEIF lv_q CS 'flow' OR lv_q CS 'luồng' OR lv_q CS 'trình tự'
          OR lv_q CS 'tác dụng' OR lv_q CS 'làm gì'
          OR lv_q CS 'mục đích' OR lv_q CS 'overview'.
    rv_intent = zif_mig_chat_ai=>intent-overview.

  ELSEIF lv_q CS 'table' OR lv_q CS 'bảng' OR lv_q CS 'select'.
    rv_intent = zif_mig_chat_ai=>intent-db.

  ELSEIF lv_q CS 'bapi' OR lv_q CS 'function' OR lv_q CS 'fm' OR lv_q CS 'gọi'.
    rv_intent = zif_mig_chat_ai=>intent-bapi.

  ELSEIF lv_q CS 'logic' OR lv_q CS 'nghiệp vụ' OR lv_q CS 'xử lý' OR lv_q CS 'tính'.
    rv_intent = zif_mig_chat_ai=>intent-logic.

  ELSEIF lv_q CS 'alv' OR lv_q CS 'cột' OR lv_q CS 'output'.
    rv_intent = zif_mig_chat_ai=>intent-alv.

  ELSEIF lv_q CS 'filter' OR lv_q CS 'lọc'.
    rv_intent = zif_mig_chat_ai=>intent-ui.

  ELSEIF lv_q CS 'migrate' OR lv_q CS 'nên làm' OR lv_q CS 'hướng' OR lv_q CS 'recommend'.
    rv_intent = zif_mig_chat_ai=>intent-recommend.

  ELSE.
    rv_intent = zif_mig_chat_ai=>intent-overview.

  ENDIF.

ENDMETHOD.


 METHOD zif_mig_chat_context_builder~build.

  DATA lv_program TYPE progname.
  lv_program = to_upper( condense( iv_program_name ) ).

  DATA ls_header TYPE zmig_anl_h.

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

  rs_context-program_name = lv_program.
  rs_context-analysis_id  = ls_header-analysis_id.

ENDMETHOD.


 METHOD get_latest_header.

  SELECT *
    FROM zmig_anl_h
    WHERE program_name = @iv_program_name
      AND ( status = 'COMPLETED' OR status = 'WARNING' )
    ORDER BY created_at DESCENDING, analysis_id DESCENDING
    INTO TABLE @DATA(lt_header)
    UP TO 1 ROWS.

  IF lt_header IS INITIAL.
    RAISE EXCEPTION TYPE zcx_mig_analysis
      EXPORTING
        program_name = iv_program_name.
  ENDIF.

  rs_header = lt_header[ 1 ].

ENDMETHOD.


  METHOD check_outdated.
    " Compare saved root AND includes to active source; no timezone inference.
    SELECT item_id, object_name FROM zmig_anl_src
      WHERE analysis_id = @is_header-analysis_id INTO TABLE @DATA(lt_objects).
    SELECT source_item_id, line_number, source_text FROM zmig_anl_code
      WHERE analysis_id = @is_header-analysis_id
      ORDER BY source_item_id, line_number INTO TABLE @DATA(lt_saved).
    IF lt_objects IS INITIAL OR lt_saved IS INITIAL.
      rv_outdated = abap_true.
      RETURN.
    ENDIF.
    LOOP AT lt_objects INTO DATA(ls_object).
      DATA lt_active TYPE STANDARD TABLE OF string WITH EMPTY KEY.
      CLEAR lt_active.
      TEST-SEAM read_active_source.
        READ REPORT ls_object-object_name INTO lt_active STATE 'A'.
      END-TEST-SEAM.
      IF sy-subrc <> 0.
        rv_outdated = abap_true.
        RETURN.
      ENDIF.
      DATA(lv_count) = 0.
      LOOP AT lt_saved INTO DATA(ls_saved) WHERE source_item_id = ls_object-item_id.
        lv_count += 1.
        READ TABLE lt_active INDEX ls_saved-line_number INTO DATA(lv_line).
        IF sy-subrc <> 0 OR lv_line <> ls_saved-source_text.
          rv_outdated = abap_true.
          RETURN.
        ENDIF.
      ENDLOOP.
      IF lv_count <> lines( lt_active ).
        rv_outdated = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD build_source_section.
    TYPES: BEGIN OF ty_line,
             object_name TYPE progname,
             line_number TYPE i,
             source_text TYPE string,
             priority TYPE i,
           END OF ty_line.
    DATA lt_lines TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.
    SELECT s~object_name, c~line_number, c~source_text
      FROM zmig_anl_code AS c INNER JOIN zmig_anl_src AS s
        ON s~analysis_id = c~analysis_id AND s~item_id = c~source_item_id
      WHERE c~analysis_id = @iv_analysis_id
      INTO CORRESPONDING FIELDS OF TABLE @lt_lines.
    IF lt_lines IS INITIAL.
      rv_text = 'No saved source lines. Do not invent source citations.'.
      RETURN.
    ENDIF.
    DATA(lv_question) = to_upper( iv_question ).
    REPLACE ALL OCCURRENCES OF REGEX '[^A-Z0-9_/]+' IN lv_question WITH ' '.
    SPLIT lv_question AT ' ' INTO TABLE DATA(lt_words).
    LOOP AT lt_lines ASSIGNING FIELD-SYMBOL(<line>).
      <line>-priority = 1.
    ENDLOOP.
    " Prioritize the named symbol and nearby parameter/condition handling.
    LOOP AT lt_lines INTO DATA(ls_line).
      DATA(lv_match) = abap_false.
      LOOP AT lt_words INTO DATA(lv_word) WHERE table_line <> ''.
        IF strlen( lv_word ) >= 4 AND to_upper( ls_line-source_text ) CS lv_word.
          lv_match = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_match = abap_true.
        LOOP AT lt_lines ASSIGNING <line> WHERE object_name = ls_line-object_name
          AND line_number >= ls_line-line_number - 12
          AND line_number <= ls_line-line_number + 12.
          <line>-priority = 0.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
    SORT lt_lines BY priority object_name line_number.
    LOOP AT lt_lines INTO ls_line.
      DATA(lv_piece) = |[{ ls_line-object_name }:{ ls_line-line_number }] { ls_line-source_text }\n|.
      IF strlen( rv_text ) + strlen( lv_piece ) > 32000.
        rv_text = rv_text && |\n[Source selection truncated. Other lines may exist; ask a narrower question.]|.
        EXIT.
      ENDIF.
      rv_text = rv_text && lv_piece.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_db_section.

    SELECT object_name, object_type, operation, selected_fields,
           where_fields, joined_objects, join_condition, aggregation,
           result_target, containing_routine, execution_kind,
           execution_context, dynamic_access, read_only,
           paging_capability, description, confidence
      FROM zmig_anl_db
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_db).

    " Loop only over the internal table already fetched - no SELECT in loop
    LOOP AT lt_db INTO DATA(ls_db).
      rv_text = rv_text &&
        |- { ls_db-object_name } ({ ls_db-object_type }, { ls_db-operation }): | &&
        |{ ls_db-description }| &&
        COND #( WHEN ls_db-containing_routine IS NOT INITIAL
                THEN |; routine={ ls_db-containing_routine }| ELSE '' ) &&
        COND #( WHEN ls_db-selected_fields IS NOT INITIAL
                THEN |; fields={ ls_db-selected_fields }| ELSE '' ) &&
        COND #( WHEN ls_db-where_fields IS NOT INITIAL
                THEN |; where={ ls_db-where_fields }| ELSE '' ) &&
        COND #( WHEN ls_db-joined_objects IS NOT INITIAL
                THEN |; joins={ ls_db-joined_objects }| ELSE '' ) &&
        COND #( WHEN ls_db-join_condition IS NOT INITIAL
                THEN |; on={ ls_db-join_condition }| ELSE '' ) &&
        COND #( WHEN ls_db-result_target IS NOT INITIAL
                THEN |; result={ ls_db-result_target }| ELSE '' ) &&
        COND #( WHEN ls_db-execution_context IS NOT INITIAL
                THEN |; context={ ls_db-execution_context }| ELSE '' ) &&
        COND #( WHEN ls_db-dynamic_access = abap_true
                THEN |; dynamic-access| ELSE '' ) &&
        |\n|.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_logic_section.

    " 1. Fetch all business logic items at once - no SELECT inside LOOP
    SELECT item_id, object_name, object_type, container_name,
           calling_routine, execution_kind, execution_context,
           description, side_effect
      FROM zmig_anl_log
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_log).

    IF lt_log IS INITIAL.
      RETURN.
    ENDIF.

    " 2. Fetch all related bindings via a single FOR ALL ENTRIES -
    "    do NOT SELECT per item_id inside the loop
    SELECT call_item_id, parameter_name, direction, actual_expression,
           binding_position
      FROM zmig_anl_bind
      FOR ALL ENTRIES IN @lt_log
      WHERE analysis_id  = @iv_analysis_id
        AND call_item_id = @lt_log-item_id
      INTO TABLE @DATA(lt_bind).

    SORT lt_bind BY call_item_id binding_position parameter_name.

    " 3. Loop only over the internal table already in memory
    LOOP AT lt_log INTO DATA(ls_log).

      " The dynamic-call flag lives in OBJECT_TYPE (e.g. 'DYNAMIC_FUNCTION_MODULE'),
      " NOT in execution_kind (execution_kind is only CONDITIONAL / DIRECT)
      IF ls_log-object_type CS 'DYNAMIC'.
        cv_unresolved = cv_unresolved &&
          |- { ls_log-object_name } at { ls_log-calling_routine }: | &&
          |dynamic call, exact target could not be resolved.\n|.
        CONTINUE.
      ENDIF.

      rv_text = rv_text &&
        |- { ls_log-object_name } ({ ls_log-object_type }| &&
        COND #( WHEN ls_log-container_name IS NOT INITIAL
                THEN | on { ls_log-container_name }|
                ELSE '' ) &&
        |), called in { ls_log-calling_routine }| &&
        COND #( WHEN ls_log-execution_kind = 'CONDITIONAL'
                THEN | (condition: { ls_log-execution_context })|
                ELSE '' ) &&
        |: { ls_log-description }| &&
        COND #( WHEN ls_log-side_effect IS NOT INITIAL
                THEN |. Side effect: { ls_log-side_effect }|
                ELSE '' ) &&
        |\n|.
      LOOP AT lt_bind INTO DATA(ls_bind) WHERE call_item_id = ls_log-item_id.
        rv_text = rv_text && |  { ls_bind-direction } { ls_bind-parameter_name } = { ls_bind-actual_expression }\n|.
      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_alv_section.
    SELECT output_id, output_name, framework, output_table, field_catalog,
           sort_table, hierarchical
      FROM zmig_anl_alv
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_alv).

    SELECT output_id, field_name, column_label, column_position,
           data_type, data_element, reference_table, reference_field
      FROM zmig_anl_col
      WHERE analysis_id = @iv_analysis_id
      ORDER BY output_id, column_position
      INTO TABLE @DATA(lt_columns).

    LOOP AT lt_alv INTO DATA(ls_alv).
      rv_text = rv_text &&
        |- Output "{ ls_alv-output_name }" ({ ls_alv-framework }), | &&
        |internal table { ls_alv-output_table }.\n|.
      LOOP AT lt_columns INTO DATA(ls_column).
        CHECK ls_column-output_id = ls_alv-output_id.
        rv_text = rv_text &&
          |  column { ls_column-column_position }: { ls_column-field_name }| &&
          COND #( WHEN ls_column-column_label IS NOT INITIAL
                  THEN | ({ ls_column-column_label })| ELSE '' ) &&
          COND #( WHEN ls_column-data_type IS NOT INITIAL
                  THEN | type={ ls_column-data_type }| ELSE '' ) &&
          |\n|.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_ui_section.

    SELECT field_name, field_kind, reference_table, reference_field,
           data_element, data_type, description, selection_block,
           mandatory, hidden, multiple_selection, range_supported,
           default_value, validation_routine
      FROM zmig_anl_ui
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_ui).

    LOOP AT lt_ui INTO DATA(ls_ui).
      rv_text = rv_text &&
        |- { ls_ui-field_name } ({ ls_ui-field_kind }): { ls_ui-description }|
        && COND #( WHEN ls_ui-mandatory = abap_true THEN | [mandatory]| ELSE '' )
        && COND #( WHEN ls_ui-hidden = abap_true THEN | [hidden]| ELSE '' )
        && COND #( WHEN ls_ui-range_supported = abap_true THEN | [range]| ELSE '' )
        && COND #( WHEN ls_ui-default_value IS NOT INITIAL
                   THEN | [default={ ls_ui-default_value }]| ELSE '' )
        && COND #( WHEN ls_ui-validation_routine IS NOT INITIAL
                   THEN | [validation={ ls_ui-validation_routine }]| ELSE '' )
        && |\n|.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_recommend_section.

    SELECT title, display_text, explanation, severity
      FROM zmig_anl_rec
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_rec).

    LOOP AT lt_rec INTO DATA(ls_rec).
      rv_text = rv_text &&
        |- [{ ls_rec-severity }] { ls_rec-title }: { ls_rec-explanation }\n|.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

