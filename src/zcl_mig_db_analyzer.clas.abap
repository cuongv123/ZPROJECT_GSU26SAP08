CLASS zcl_mig_db_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_db_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_parse_phase TYPE c LENGTH 20,
      ty_object_name TYPE c LENGTH 40,
      ty_statement_type TYPE c LENGTH 30.

    TYPES:
      BEGIN OF ty_parse_state,
        statement_id       TYPE i,
        source_object      TYPE progname,
        start_line         TYPE i,
        end_line           TYPE i,
        statement_text     TYPE string,
        containing_routine TYPE c LENGTH 120,

        operation          TYPE c LENGTH 20,
        object_name        TYPE ty_object_name,
        object_type        TYPE c LENGTH 20,

        selected_fields    TYPE string,
        where_fields       TYPE string,
        joined_objects     TYPE string,
        join_condition     TYPE string,
        aggregation        TYPE string,

        parse_phase        TYPE ty_parse_phase,
        expect_object      TYPE abap_bool,
        expect_join_object TYPE abap_bool,

        dynamic_access     TYPE abap_bool,
        read_only          TYPE abap_bool,
        paging_capability  TYPE c LENGTH 20,
        confidence         TYPE zif_mig_types=>ty_confidence,
      END OF ty_parse_state,

      tt_parse_state TYPE HASHED TABLE OF ty_parse_state
        WITH UNIQUE KEY statement_id.

    METHODS analyze_source_unit
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_source_unit TYPE zif_mig_types=>ty_source_unit
      CHANGING
        ct_objects     TYPE zif_mig_types=>tt_database_object
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS initialize_states
      IMPORTING
        it_statements TYPE zif_mig_types=>tt_statement
      RETURNING
        VALUE(rt_states) TYPE tt_parse_state.

    METHODS process_tokens
      IMPORTING
        it_tokens TYPE zif_mig_types=>tt_token
      CHANGING
        ct_states TYPE tt_parse_state
      RAISING
        zcx_mig_analysis.

    METHODS process_token
      IMPORTING
        iv_token       TYPE string
        iv_upper_token TYPE string
      CHANGING
        cs_state       TYPE ty_parse_state.

    METHODS finalize_state
      CHANGING
        cs_state TYPE ty_parse_state.

    METHODS append_text
      IMPORTING
        iv_value TYPE string
        iv_separator TYPE string DEFAULT ` `
      CHANGING
        cv_target TYPE string.

    METHODS append_unique
      IMPORTING
        iv_value TYPE string
      CHANGING
        cv_target TYPE string.

    METHODS is_db_statement
      IMPORTING
        iv_statement_type TYPE ty_statement_type
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    METHODS is_clause_keyword
      IMPORTING
        iv_token TYPE string
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

    TYPES tt_statement_word
      TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.

    METHODS is_internal_table_operation
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    METHODS split_statement_words
      IMPORTING
        iv_statement_text TYPE string
      RETURNING
        VALUE(rt_words) TYPE tt_statement_word.

    METHODS contains_word
      IMPORTING
        it_words TYPE tt_statement_word
        iv_word  TYPE string
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

ENDCLASS.

CLASS zcl_mig_db_analyzer IMPLEMENTATION.

  METHOD zif_mig_db_analyzer~analyze.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    lv_analysis_id = iv_analysis_id.

    IF lv_analysis_id IS INITIAL.

      lv_analysis_id =
        create_uuid(
          iv_source_object = ''
        ).

    ENDIF.

    LOOP AT it_source_units
      ASSIGNING FIELD-SYMBOL(<source_unit>).

      analyze_source_unit(
        EXPORTING
          iv_analysis_id = lv_analysis_id
          is_source_unit = <source_unit>
        CHANGING
          ct_objects     = rs_result-database_objects
          ct_evidences   = rs_result-evidences
      ).

    ENDLOOP.

    SORT rs_result-database_objects
      BY object_name
         operation.

  ENDMETHOD.

    METHOD analyze_source_unit.

    DATA(lt_states) =
      initialize_states(
        it_statements =
          is_source_unit-scan_result-statements
      ).

    IF lt_states IS INITIAL.
      RETURN.
    ENDIF.

    process_tokens(
      EXPORTING
        it_tokens = is_source_unit-scan_result-tokens
      CHANGING
        ct_states = lt_states
    ).

    LOOP AT lt_states
      INTO DATA(ls_state).

      finalize_state(
        CHANGING
          cs_state = ls_state
      ).

      IF ls_state-object_name IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_item_id) =
        create_uuid(
          iv_source_object =
            ls_state-source_object
        ).

      DATA(lv_evidence_id) =
        create_uuid(
          iv_source_object =
            ls_state-source_object
        ).

      APPEND VALUE #(
        item_id            = lv_item_id
        analysis_id        = iv_analysis_id
        evidence_id        = lv_evidence_id
        object_name        = ls_state-object_name
        object_type        = ls_state-object_type
        operation          = ls_state-operation
        selected_fields    = ls_state-selected_fields
        where_fields       = ls_state-where_fields
        joined_objects     = ls_state-joined_objects
        join_condition     = ls_state-join_condition
        aggregation        = ls_state-aggregation
        containing_routine = ls_state-containing_routine
        dynamic_access     = ls_state-dynamic_access
        read_only          = ls_state-read_only
        paging_capability  = ls_state-paging_capability
        confidence         = ls_state-confidence
      ) TO ct_objects.

      APPEND VALUE #(
        evidence_id    = lv_evidence_id
        analysis_id    = iv_analysis_id
        source_object  = ls_state-source_object
        start_line     = ls_state-start_line
        end_line       = ls_state-end_line
        statement_id   = ls_state-statement_id
        statement_text = ls_state-statement_text
        confidence     = ls_state-confidence
      ) TO ct_evidences.

    ENDLOOP.

  ENDMETHOD.

    METHOD initialize_states.

    LOOP AT it_statements
      ASSIGNING FIELD-SYMBOL(<statement>).

      IF is_db_statement(
           iv_statement_type =
             <statement>-statement_type
         ) = abap_false.

        CONTINUE.

      ENDIF.

      IF is_internal_table_operation(
             is_statement = <statement>
           ) = abap_true.

          CONTINUE.

      ENDIF.

      DATA(lv_operation) =
        to_upper(
          CONV string(
            <statement>-statement_type
          )
        ).

      DATA:
        lv_phase         TYPE ty_parse_phase,
        lv_expect_object TYPE abap_bool,
        lv_read_only     TYPE abap_bool.

      CLEAR:
        lv_phase,
        lv_expect_object,
        lv_read_only.

      CASE lv_operation.

        WHEN 'SELECT'.

          lv_phase         = 'SELECT_FIELDS'.
          lv_read_only     = abap_true.
          lv_expect_object = abap_false.

        WHEN 'INSERT'.

          lv_phase         = 'OBJECT'.
          lv_expect_object = abap_true.

        WHEN 'UPDATE'.

          lv_phase         = 'OBJECT'.
          lv_expect_object = abap_true.

        WHEN 'MODIFY'.

          lv_phase         = 'OBJECT'.
          lv_expect_object = abap_true.

        WHEN 'DELETE'.

          lv_phase         = 'OBJECT'.
          lv_expect_object = abap_true.

      ENDCASE.

      INSERT VALUE #(
        statement_id       = <statement>-statement_id
        source_object      = <statement>-source_object
        start_line         = <statement>-start_line
        end_line           = <statement>-end_line
        statement_text     = <statement>-statement_text
        containing_routine = <statement>-parent_routine

        operation          = lv_operation
        object_type        = 'TABLE_OR_VIEW'
        parse_phase        = lv_phase
        expect_object      = lv_expect_object
        read_only          = lv_read_only
        confidence         = zif_mig_types=>gc_conf_high
      ) INTO TABLE rt_states.

    ENDLOOP.

  ENDMETHOD.

  METHOD process_tokens.

  LOOP AT it_tokens
    ASSIGNING FIELD-SYMBOL(<token>).

    "Không truyền trực tiếp dòng HASHED TABLE vào CHANGING.
    "Đọc ra work area trước.
    READ TABLE ct_states
      WITH TABLE KEY
        statement_id = <token>-statement_id
      INTO DATA(ls_state).

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    DATA(lv_upper_token) =
      to_upper( <token>-token_text ).

    process_token(
      EXPORTING
        iv_token       = <token>-token_text
        iv_upper_token = lv_upper_token
      CHANGING
        cs_state       = ls_state
    ).

    "Ghi work area trở lại HASHED TABLE.
    "STATEMENT_ID không bị thay đổi.
    MODIFY TABLE ct_states
      FROM ls_state.

    IF sy-subrc <> 0.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        program_name = ls_state-source_object
      ).

    ENDIF.

  ENDLOOP.

ENDMETHOD.

    METHOD process_token.

    "Bỏ keyword đầu của statement
    IF iv_upper_token = cs_state-operation.
      RETURN.
    ENDIF.

    "==========================================================
    " Các clause chính
    "==========================================================
    CASE iv_upper_token.

      WHEN 'FROM'.

        IF cs_state-operation = 'SELECT'.

          cs_state-parse_phase   = 'FROM_OBJECT'.
          cs_state-expect_object = abap_true.

        ELSEIF cs_state-operation = 'DELETE'.

          cs_state-parse_phase   = 'OBJECT'.
          cs_state-expect_object = abap_true.

        ENDIF.

        RETURN.

      WHEN 'INTO'.

        IF cs_state-operation = 'INSERT'.

          cs_state-parse_phase   = 'OBJECT'.
          cs_state-expect_object = abap_true.

        ELSEIF cs_state-operation = 'SELECT'.

          cs_state-parse_phase = 'OTHER'.

        ENDIF.

        RETURN.

      WHEN 'JOIN'
        OR 'INNER'
        OR 'LEFT'
        OR 'RIGHT'
        OR 'FULL'.

        IF iv_upper_token = 'JOIN'.

          cs_state-parse_phase        = 'JOIN_OBJECT'.
          cs_state-expect_join_object = abap_true.

        ENDIF.

        RETURN.

      WHEN 'ON'.

        cs_state-parse_phase = 'JOIN_CONDITION'.
        RETURN.

      WHEN 'WHERE'.

        cs_state-parse_phase = 'WHERE'.
        RETURN.

      WHEN 'GROUP'
        OR 'HAVING'
        OR 'ORDER'
        OR 'UP'
        OR 'OFFSET'
        OR 'CONNECTION'
        OR 'CLIENT'.

        cs_state-parse_phase = 'OTHER'.
        RETURN.

      WHEN 'SET'.

        IF cs_state-operation = 'UPDATE'.

          cs_state-parse_phase = 'OTHER'.

        ENDIF.

        RETURN.

    ENDCASE.

    "==========================================================
    " Aggregate functions
    "
    " Tùy SAP release, SCAN có thể trả:
    " COUNT
    " COUNT(
    " COUNT(*)
    " SUM(
    "==========================================================
    DATA lv_aggregation TYPE c LENGTH 10.

    CLEAR lv_aggregation.

    IF iv_upper_token CP 'COUNT*'.

      lv_aggregation = 'COUNT'.

    ELSEIF iv_upper_token CP 'SUM*'.

      lv_aggregation = 'SUM'.

    ELSEIF iv_upper_token CP 'MIN*'.

      lv_aggregation = 'MIN'.

    ELSEIF iv_upper_token CP 'MAX*'.

      lv_aggregation = 'MAX'.

    ELSEIF iv_upper_token CP 'AVG*'.

      lv_aggregation = 'AVG'.

    ENDIF.

    IF lv_aggregation IS NOT INITIAL.

      append_unique(
        EXPORTING
          iv_value  = CONV string( lv_aggregation )
        CHANGING
          cv_target = cs_state-aggregation
      ).

    ENDIF.


    "==========================================================
    " Object chính
    "==========================================================
    IF cs_state-expect_object = abap_true.

      "Các từ bổ trợ không phải tên bảng
      IF iv_upper_token = 'TABLE'
         OR iv_upper_token = 'CORRESPONDING'
         OR iv_upper_token = 'FIELDS'
         OR iv_upper_token = 'VALUE'.

        RETURN.

      ENDIF.

      cs_state-expect_object = abap_false.

      IF iv_upper_token = '('
         OR iv_upper_token CS '('.

        cs_state-dynamic_access = abap_true.
        cs_state-confidence     = zif_mig_types=>gc_conf_medium.

      ENDIF.

      cs_state-object_name =
        CONV ty_object_name( iv_upper_token ).

      cs_state-parse_phase = 'OTHER'.

      RETURN.

    ENDIF.

    "==========================================================
    " JOIN object
    "==========================================================
    IF cs_state-expect_join_object = abap_true.

      cs_state-expect_join_object = abap_false.

      IF iv_upper_token = '('
         OR iv_upper_token CS '('.

        cs_state-dynamic_access = abap_true.
        cs_state-confidence     = zif_mig_types=>gc_conf_medium.

      ENDIF.

      append_unique(
        EXPORTING
          iv_value = iv_upper_token
        CHANGING
          cv_target = cs_state-joined_objects
      ).

      cs_state-parse_phase = 'OTHER'.

      RETURN.

    ENDIF.

    "==========================================================
    " Nội dung theo phase
    "==========================================================
    CASE cs_state-parse_phase.

      WHEN 'SELECT_FIELDS'.

        "Bỏ các modifiers của SELECT
        IF iv_upper_token <> 'SINGLE'
           AND iv_upper_token <> 'DISTINCT'
           AND iv_upper_token <> 'BYPASSING'
           AND iv_upper_token <> 'BUFFER'
           AND iv_upper_token <> 'CLIENT'
           AND iv_upper_token <> 'SPECIFIED'.

          append_text(
            EXPORTING
              iv_value     = iv_token
              iv_separator = ` `
            CHANGING
              cv_target    = cs_state-selected_fields
          ).

        ENDIF.

      WHEN 'WHERE'.

        append_text(
          EXPORTING
            iv_value     = iv_token
            iv_separator = ` `
          CHANGING
            cv_target    = cs_state-where_fields
        ).

      WHEN 'JOIN_CONDITION'.

        append_text(
          EXPORTING
            iv_value     = iv_token
            iv_separator = ` `
          CHANGING
            cv_target    = cs_state-join_condition
        ).

    ENDCASE.

  ENDMETHOD.

    METHOD finalize_state.

    CASE cs_state-operation.

      WHEN 'SELECT'.

        cs_state-read_only = abap_true.

        IF cs_state-dynamic_access = abap_true.

          cs_state-paging_capability =
            'REVIEW'.

        ELSE.

          cs_state-paging_capability =
            'DB_PUSHDOWN'.

        ENDIF.

      WHEN 'INSERT'
        OR 'UPDATE'
        OR 'MODIFY'
        OR 'DELETE'.

        cs_state-read_only = abap_false.

        cs_state-paging_capability =
          'NOT_APPLICABLE'.

    ENDCASE.

    IF cs_state-object_name IS INITIAL.

      cs_state-confidence =
        zif_mig_types=>gc_conf_low.

    ENDIF.

  ENDMETHOD.

    METHOD append_text.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    IF cv_target IS INITIAL.

      cv_target = iv_value.

    ELSE.

      cv_target =
        |{ cv_target }{ iv_separator }{ iv_value }|.

    ENDIF.

  ENDMETHOD.


  METHOD append_unique.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    IF cv_target IS INITIAL.

      cv_target = iv_value.
      RETURN.

    ENDIF.

    IF cv_target CS iv_value.
      RETURN.
    ENDIF.

    cv_target =
      |{ cv_target }, { iv_value }|.

  ENDMETHOD.


  METHOD is_db_statement.

    CASE to_upper( iv_statement_type ).

      WHEN 'SELECT'
        OR 'INSERT'
        OR 'UPDATE'
        OR 'MODIFY'
        OR 'DELETE'.

        rv_result = abap_true.

      WHEN OTHERS.

        rv_result = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD is_clause_keyword.

    CASE to_upper( iv_token ).

      WHEN 'FROM'
        OR 'INTO'
        OR 'JOIN'
        OR 'ON'
        OR 'WHERE'
        OR 'GROUP'
        OR 'HAVING'
        OR 'ORDER'.

        rv_result = abap_true.

      WHEN OTHERS.

        rv_result = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD create_uuid.

    TRY.

        rv_uuid =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid       = zcx_mig_analysis=>analysis_failed
          previous     = lx_uuid
          program_name = iv_source_object
        ).

    ENDTRY.

  ENDMETHOD.

  METHOD split_statement_words.

  DATA(lv_text) =
    to_upper( iv_statement_text ).

  REPLACE ALL OCCURRENCES OF `.`
    IN lv_text WITH ` `.

  REPLACE ALL OCCURRENCES OF `,`
    IN lv_text WITH ` `.

  REPLACE ALL OCCURRENCES OF `:`
    IN lv_text WITH ` `.

  REPLACE ALL OCCURRENCES OF `(`
    IN lv_text WITH ` `.

  REPLACE ALL OCCURRENCES OF `)`
    IN lv_text WITH ` `.

  DATA lt_raw_words
    TYPE STANDARD TABLE OF string
    WITH EMPTY KEY.

  SPLIT lv_text
    AT space
    INTO TABLE lt_raw_words.

  LOOP AT lt_raw_words
    INTO DATA(lv_word).

    IF lv_word IS INITIAL.
      CONTINUE.
    ENDIF.

    APPEND lv_word
      TO rt_words.

  ENDLOOP.

ENDMETHOD.

METHOD contains_word.

  READ TABLE it_words
    WITH KEY table_line = to_upper( iv_word )
    TRANSPORTING NO FIELDS.

  rv_result =
    xsdbool(
      sy-subrc = 0
    ).

ENDMETHOD.

METHOD is_internal_table_operation.

  DATA(lt_words) =
    split_statement_words(
      iv_statement_text =
        is_statement-statement_text
    ).

  IF lt_words IS INITIAL.
    RETURN.
  ENDIF.

  DATA:
    lv_operation TYPE string,
    lv_word_2    TYPE string.

  READ TABLE lt_words
    INDEX 1
    INTO lv_operation.

  READ TABLE lt_words
    INDEX 2
    INTO lv_word_2.

  CASE lv_operation.

    "========================================================
    " SELECT / UPDATE
    "
    "SELECT được xử lý như Open SQL ở scope hiện tại.
    "UPDATE không có biến thể internal-table tương ứng.
    "========================================================
    WHEN 'SELECT'
      OR 'UPDATE'.

      rv_result = abap_false.


    "========================================================
    " INSERT
    "========================================================
    WHEN 'INSERT'.

      "INSERT LINES OF source INTO TABLE target
      "INSERT INITIAL LINE INTO TABLE target
      IF lv_word_2 = 'LINES'
         OR lv_word_2 = 'INITIAL'.

        rv_result = abap_true.
        RETURN.

      ENDIF.

      "Open SQL hợp lệ:
      "INSERT INTO dbtab ...
      IF lv_word_2 = 'INTO'.

        rv_result = abap_false.
        RETURN.

      ENDIF.

      "Nếu INTO xuất hiện sau source object:
      "INSERT ls_row INTO TABLE lt_table
      "INSERT ls_row INTO lt_table INDEX ...
      IF contains_word(
           it_words = lt_words
           iv_word  = 'INTO'
         ) = abap_true.

        rv_result = abap_true.
        RETURN.

      ENDIF.


    "========================================================
    " MODIFY
    "========================================================
    WHEN 'MODIFY'.

      "MODIFY TABLE lt_table FROM ls_row
      IF lv_word_2 = 'TABLE'.

        rv_result = abap_true.
        RETURN.

      ENDIF.

      "Các addition này thuộc internal table
      IF contains_word(
           it_words = lt_words
           iv_word  = 'INDEX'
         ) = abap_true
         OR contains_word(
              it_words = lt_words
              iv_word  = 'TRANSPORTING'
            ) = abap_true
         OR contains_word(
              it_words = lt_words
              iv_word  = 'USING'
            ) = abap_true
         OR contains_word(
              it_words = lt_words
              iv_word  = 'WHERE'
            ) = abap_true.

        rv_result = abap_true.
        RETURN.

      ENDIF.


    "========================================================
    " DELETE
    "========================================================
    WHEN 'DELETE'.

      "DELETE ADJACENT DUPLICATES FROM lt_table
      "DELETE TABLE lt_table FROM ls_row
      IF lv_word_2 = 'ADJACENT'
         OR lv_word_2 = 'TABLE'.

        rv_result = abap_true.
        RETURN.

      ENDIF.

      "Open SQL:
      "DELETE FROM dbtab WHERE ...
      IF lv_word_2 = 'FROM'.

        rv_result = abap_false.
        RETURN.

      ENDIF.

      "Internal table variants:
      "DELETE lt_table.
      "DELETE lt_table INDEX n.
      "DELETE lt_table FROM n TO m.
      "DELETE lt_table WHERE ...
      IF contains_word(
           it_words = lt_words
           iv_word  = 'INDEX'
         ) = abap_true
         OR contains_word(
              it_words = lt_words
              iv_word  = 'TO'
            ) = abap_true
         OR contains_word(
              it_words = lt_words
              iv_word  = 'WHERE'
            ) = abap_true.

        rv_result = abap_true.
        RETURN.

      ENDIF.

      "Không có FROM thì đây là DELETE internal table đơn giản
      IF contains_word(
           it_words = lt_words
           iv_word  = 'FROM'
         ) = abap_false.

        rv_result = abap_true.
        RETURN.

      ENDIF.

  ENDCASE.

ENDMETHOD.

ENDCLASS.
