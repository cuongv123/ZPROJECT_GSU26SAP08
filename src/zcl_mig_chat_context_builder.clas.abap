CLASS zcl_mig_chat_context_builder DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_chat_context_builder.

  PRIVATE SECTION.
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

  IF lv_q CS 'table' OR lv_q CS 'bảng' OR lv_q CS 'select'.
    rv_intent = zif_mig_chat_ai=>intent-db.

  ELSEIF lv_q CS 'bapi' OR lv_q CS 'function' OR lv_q CS 'fm' OR lv_q CS 'gọi'.
    rv_intent = zif_mig_chat_ai=>intent-bapi.

  ELSEIF lv_q CS 'logic' OR lv_q CS 'nghiệp vụ' OR lv_q CS 'xử lý' OR lv_q CS 'tính'.
    rv_intent = zif_mig_chat_ai=>intent-logic.

  ELSEIF lv_q CS 'alv' OR lv_q CS 'cột' OR lv_q CS 'output'.
    rv_intent = zif_mig_chat_ai=>intent-alv.

  ELSEIF lv_q CS 'filter' OR lv_q CS 'selection' OR lv_q CS 'màn hình'.
    rv_intent = zif_mig_chat_ai=>intent-ui.

  ELSEIF lv_q CS 'migrate' OR lv_q CS 'nên làm' OR lv_q CS 'hướng' OR lv_q CS 'recommend'.
    rv_intent = zif_mig_chat_ai=>intent-recommend.

  ELSE.
    rv_intent = zif_mig_chat_ai=>intent-overview.

  ENDIF.

ENDMETHOD.


  METHOD zif_mig_chat_context_builder~build.

    " 1. Always fetch the LATEST analysis by program - never take analysis_id from user input
    DATA(ls_header) = get_latest_header( iv_program_name ).

    rs_context-program_name = iv_program_name.
    rs_context-analysis_id  = ls_header-analysis_id.
    rs_context-is_outdated  = check_outdated( ls_header ).

    " 2. Small anchor - always included, built from header fields already in memory
    rs_context-anchor_summary =
      |Report: { ls_header-program_name }. { ls_header-program_description }.\n| &&
      |Complexity score: { ls_header-complexity_score } / 100. | &&
      |Readiness score: { ls_header-readiness_score } / 100.\n| &&
      |Overview: { ls_header-total_database_objects } DB object(s), | &&
      |{ ls_header-total_business_logic } business logic item(s), | &&
      |{ ls_header-total_alv_outputs } ALV output(s), | &&
      |{ ls_header-total_ui_filters } UI filter(s).|.

    " 3. Slice by intent - only SELECT the table needed for this question
    DATA(lv_intent) = zif_mig_chat_context_builder~classify_intent( iv_question ).
    CASE lv_intent.

      WHEN zif_mig_chat_ai=>intent-db.
        rs_context-focused_section = build_db_section( ls_header-analysis_id ).

      WHEN zif_mig_chat_ai=>intent-bapi OR zif_mig_chat_ai=>intent-logic.
        rs_context-focused_section = build_logic_section(
          EXPORTING iv_analysis_id = ls_header-analysis_id
          CHANGING  cv_unresolved  = rs_context-unresolved_note ).

      WHEN zif_mig_chat_ai=>intent-alv.
        rs_context-focused_section = build_alv_section( ls_header-analysis_id ).

      WHEN zif_mig_chat_ai=>intent-ui.
        rs_context-focused_section = build_ui_section( ls_header-analysis_id ).

      WHEN zif_mig_chat_ai=>intent-recommend.
        rs_context-focused_section = build_recommend_section( ls_header-analysis_id ).

      WHEN OTHERS. " OVERVIEW - anchor only, nothing else fetched
        rs_context-focused_section = ''.

    ENDCASE.

  ENDMETHOD.


 METHOD get_latest_header.

  SELECT *
    FROM zmig_anl_h
    WHERE program_name = @iv_program_name
    ORDER BY created_at DESCENDING
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

  DATA lv_analysis_date TYPE d.
  DATA lv_analysis_time TYPE t.

  CONVERT TIME STAMP is_header-created_at
    TIME ZONE sy-zonlo
    INTO DATE lv_analysis_date
         TIME lv_analysis_time.

  SELECT SINGLE udat, utime
    FROM reposrc
    WHERE progname = @is_header-program_name
      AND r3state  = 'A'
    INTO ( @DATA(lv_prog_udat), @DATA(lv_prog_utime) ).

  IF sy-subrc <> 0.
    " Program no longer found in the system -> treat as outdated
    " so the UI warns instead of silently using stale data
    rv_outdated = abap_true.
    RETURN.
  ENDIF.

  rv_outdated = xsdbool(
    lv_prog_udat > lv_analysis_date OR
    ( lv_prog_udat = lv_analysis_date AND lv_prog_utime > lv_analysis_time ) ).

ENDMETHOD.


  METHOD build_db_section.

    SELECT object_name, object_type, operation, description
      FROM zmig_anl_db
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_db).

    " Loop only over the internal table already fetched - no SELECT in loop
    LOOP AT lt_db INTO DATA(ls_db).
      rv_text = rv_text &&
        |- { ls_db-object_name } ({ ls_db-object_type }, { ls_db-operation }): | &&
        |{ ls_db-description }\n|.
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
    SELECT call_item_id, parameter_name, direction, actual_expression
      FROM zmig_anl_bind
      FOR ALL ENTRIES IN @lt_log
      WHERE analysis_id  = @iv_analysis_id
        AND call_item_id = @lt_log-item_id
      INTO TABLE @DATA(lt_bind).

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

    ENDLOOP.

  ENDMETHOD.


  METHOD build_alv_section.

    SELECT output_name, framework, output_table, field_catalog,
           sort_table, hierarchical
      FROM zmig_anl_alv
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_alv).

    LOOP AT lt_alv INTO DATA(ls_alv).
      rv_text = rv_text &&
        |- Output "{ ls_alv-output_name }" ({ ls_alv-framework }), | &&
        |internal table { ls_alv-output_table }.\n|.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_ui_section.

    SELECT field_name, field_kind, description, mandatory, hidden
      FROM zmig_anl_ui
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_ui).

    LOOP AT lt_ui INTO DATA(ls_ui).
      rv_text = rv_text &&
        |- { ls_ui-field_name } ({ ls_ui-field_kind }): { ls_ui-description }|
        && COND #( WHEN ls_ui-mandatory = abap_true THEN | [mandatory]| ELSE '' )
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
