CLASS zcl_mig_alv_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_alv_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_framework      TYPE c LENGTH 40,
      ty_parameter_name TYPE c LENGTH 40,
      ty_identifier     TYPE c LENGTH 80.

    TYPES:
      BEGIN OF ty_alv_state,
        statement_id   TYPE i,
        source_object  TYPE progname,
        start_line     TYPE i,
        end_line       TYPE i,
        statement_text TYPE string,

        framework      TYPE ty_framework,
        output_table   TYPE ty_identifier,
        field_catalog  TYPE ty_identifier,
        sort_table     TYPE ty_identifier,
        filter_table   TYPE ty_identifier,
        layout_object  TYPE ty_identifier,
        variant_object TYPE ty_identifier,
        control_object TYPE ty_identifier,

        current_parameter TYPE ty_parameter_name,
        expect_value      TYPE abap_bool,

        recognized     TYPE abap_bool,
        confidence     TYPE zif_mig_types=>ty_confidence,
      END OF ty_alv_state,

      tt_alv_state TYPE HASHED TABLE OF ty_alv_state
        WITH UNIQUE KEY statement_id.

    METHODS analyze_source_unit
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_source_unit TYPE zif_mig_types=>ty_source_unit
      CHANGING
        ct_outputs     TYPE zif_mig_types=>tt_alv_output
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS initialize_states
      IMPORTING
        it_statements TYPE zif_mig_types=>tt_statement
      RETURNING
        VALUE(rt_states) TYPE tt_alv_state.

    METHODS process_tokens
      IMPORTING
        it_tokens TYPE zif_mig_types=>tt_token
      CHANGING
        ct_states TYPE tt_alv_state
      RAISING
        zcx_mig_analysis.

    METHODS process_token
      IMPORTING
        iv_token       TYPE string
        iv_upper_token TYPE string
      CHANGING
        cs_state       TYPE ty_alv_state.

    METHODS map_parameter_value
      IMPORTING
        iv_parameter TYPE ty_parameter_name
        iv_value     TYPE string
      CHANGING
        cs_state     TYPE ty_alv_state.

    METHODS is_candidate_statement
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    METHODS is_alv_parameter
      IMPORTING
        iv_token TYPE string
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    METHODS normalize_identifier
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE ty_identifier.

    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

ENDCLASS.

CLASS zcl_mig_alv_analyzer IMPLEMENTATION.

  METHOD zif_mig_alv_analyzer~analyze.

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
          ct_outputs     = rs_result-alv_outputs
          ct_evidences   = rs_result-evidences
      ).

    ENDLOOP.

    SORT rs_result-alv_outputs
      BY framework
         output_table.

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

      IF ls_state-recognized = abap_false.
        CONTINUE.
      ENDIF.

      IF ls_state-output_table IS INITIAL.

        ls_state-confidence =
          zif_mig_types=>gc_conf_medium.

      ENDIF.

      DATA(lv_output_id) =
        create_uuid(
          iv_source_object =
            ls_state-source_object
        ).

      DATA(lv_evidence_id) =
        create_uuid(
          iv_source_object =
            ls_state-source_object
        ).

      DATA(lv_output_name) =
        COND string(
          WHEN ls_state-output_table IS NOT INITIAL
          THEN ls_state-output_table
          ELSE ls_state-framework
        ).

      APPEND VALUE #(
        output_id       = lv_output_id
        analysis_id     = iv_analysis_id
        evidence_id     = lv_evidence_id
        output_name     = lv_output_name
        output_kind     = 'MAIN_ALV'
        framework       = ls_state-framework
        control_object  = ls_state-control_object
        output_table    = ls_state-output_table
        row_type        = ''
        field_catalog   = ls_state-field_catalog
        sort_table      = ls_state-sort_table
        filter_table    = ls_state-filter_table
        layout_object   = ls_state-layout_object
        variant_object  = ls_state-variant_object
        editable        = abap_false
        hierarchical    = abap_false
        confidence      = ls_state-confidence
      ) TO ct_outputs.

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

    IF is_candidate_statement(
         is_statement = <statement>
       ) = abap_false.

      CONTINUE.

    ENDIF.

    DATA(lv_text) =
      to_upper(
        <statement>-statement_text
      ).

    DATA:
      lv_framework      TYPE ty_framework,
      lv_recognized     TYPE abap_bool,
      lv_control_object TYPE ty_identifier.

    CLEAR:
      lv_framework,
      lv_recognized,
      lv_control_object.

    IF lv_text CS 'REUSE_ALV_GRID_DISPLAY_LVC'.

      lv_framework  = 'REUSE_ALV_GRID_DISPLAY_LVC'.
      lv_recognized = abap_true.

    ELSEIF lv_text CS 'REUSE_ALV_GRID_DISPLAY'.

      lv_framework  = 'REUSE_ALV_GRID_DISPLAY'.
      lv_recognized = abap_true.

    ELSEIF lv_text CS 'REUSE_ALV_LIST_DISPLAY'.

      lv_framework  = 'REUSE_ALV_LIST_DISPLAY'.
      lv_recognized = abap_true.

    ELSEIF lv_text CS 'SET_TABLE_FOR_FIRST_DISPLAY'.

      lv_framework  = 'CL_GUI_ALV_GRID'.
      lv_recognized = abap_true.

    ELSEIF lv_text CS 'CL_SALV_TABLE'
       AND lv_text CS 'FACTORY'.

      lv_framework  = 'CL_SALV_TABLE'.
      lv_recognized = abap_true.

    ENDIF.

    IF lv_recognized = abap_false.
      CONTINUE.
    ENDIF.

    "========================================================
    " Lấy ALV control object:
    "
    " GO_GRID->SET_TABLE_FOR_FIRST_DISPLAY( ... )
    "           ↓
    " CONTROL_OBJECT = GO_GRID
    "========================================================
    IF lv_framework = 'CL_GUI_ALV_GRID'.

      DATA(lv_compact_text) =
        lv_text.

      "Hỗ trợ cả:
      "GO_GRID->SET_TABLE...
      "GO_GRID -> SET_TABLE...
      CONDENSE lv_compact_text NO-GAPS.

      IF lv_compact_text
           CS '->SET_TABLE_FOR_FIRST_DISPLAY'.

        DATA:
          lv_control_text TYPE string,
          lv_rest_text    TYPE string.

        SPLIT lv_compact_text
          AT '->SET_TABLE_FOR_FIRST_DISPLAY'
          INTO lv_control_text
               lv_rest_text.

        lv_control_object =
          normalize_identifier(
            iv_value = lv_control_text
          ).

      ENDIF.

    ENDIF.

    INSERT VALUE #(
      statement_id   = <statement>-statement_id
      source_object  = <statement>-source_object
      start_line     = <statement>-start_line
      end_line       = <statement>-end_line
      statement_text = <statement>-statement_text
      framework      = lv_framework
      control_object = lv_control_object
      recognized     = abap_true
      confidence     = zif_mig_types=>gc_conf_high
    ) INTO TABLE rt_states.

  ENDLOOP.

ENDMETHOD.

    METHOD is_candidate_statement.

    DATA(lv_text) =
      to_upper(
        is_statement-statement_text
      ).

    IF lv_text CS 'REUSE_ALV_GRID_DISPLAY'
       OR lv_text CS 'REUSE_ALV_LIST_DISPLAY'
       OR lv_text CS 'SET_TABLE_FOR_FIRST_DISPLAY'
       OR ( lv_text CS 'CL_SALV_TABLE'
            AND lv_text CS 'FACTORY' ).

      rv_result = abap_true.

    ELSE.

      rv_result = abap_false.

    ENDIF.

  ENDMETHOD.

    METHOD process_tokens.

    LOOP AT it_tokens
      ASSIGNING FIELD-SYMBOL(<token>).

      READ TABLE ct_states
        WITH TABLE KEY
          statement_id = <token>-statement_id
        INTO DATA(ls_state).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_upper_token) =
        to_upper(
          <token>-token_text
        ).

      process_token(
        EXPORTING
          iv_token       = <token>-token_text
          iv_upper_token = lv_upper_token
        CHANGING
          cs_state       = ls_state
      ).

      MODIFY TABLE ct_states
        FROM ls_state.

      IF sy-subrc <> 0.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
          program_name =
            ls_state-source_object
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD process_token.

    "==========================================================
    " Trường hợp token có dạng:
    " IT_OUTTAB=GT_RESULT
    "==========================================================
    IF iv_upper_token CS '='
       AND iv_upper_token <> '='.

      DATA:
        lv_left  TYPE string,
        lv_right TYPE string.

      SPLIT iv_upper_token
        AT '='
        INTO lv_left lv_right.

      IF is_alv_parameter(
           iv_token = lv_left
         ) = abap_true.

        map_parameter_value(
          EXPORTING
            iv_parameter =
              CONV ty_parameter_name(
                to_upper( lv_left )
              )
            iv_value =
              lv_right
          CHANGING
            cs_state =
              cs_state
        ).

        CLEAR:
          cs_state-current_parameter,
          cs_state-expect_value.

        RETURN.

      ENDIF.

    ENDIF.

    "==========================================================
    " Gặp tên parameter
    "==========================================================
    IF is_alv_parameter(
         iv_token = iv_upper_token
       ) = abap_true.

      cs_state-current_parameter =
        CONV ty_parameter_name(
          iv_upper_token
        ).

      cs_state-expect_value =
        abap_false.

      RETURN.

    ENDIF.

    "==========================================================
    " Gặp dấu =
    "==========================================================
    IF iv_upper_token = '='
       AND cs_state-current_parameter
             IS NOT INITIAL.

      cs_state-expect_value =
        abap_true.

      RETURN.

    ENDIF.

    "==========================================================
    " Token sau dấu = là variable/object được truyền vào
    "==========================================================
    IF cs_state-expect_value = abap_true.

      map_parameter_value(
        EXPORTING
          iv_parameter =
            cs_state-current_parameter
          iv_value =
            iv_token
        CHANGING
          cs_state =
            cs_state
      ).

      CLEAR:
        cs_state-current_parameter,
        cs_state-expect_value.

    ENDIF.

  ENDMETHOD.

    METHOD is_alv_parameter.

    CASE to_upper( iv_token ).

      WHEN 'R_SALV_TABLE'.

        rv_result = abap_true.
      "Output data
      WHEN 'T_OUTTAB'
        OR 'IT_OUTTAB'
        OR 'T_TABLE'.

        rv_result = abap_true.

      "Field catalog
      WHEN 'IT_FIELDCAT'
        OR 'IT_FIELDCAT_LVC'
        OR 'IT_FIELDCATALOG'.

        rv_result = abap_true.

      "Sort
      WHEN 'IT_SORT'
        OR 'IT_SORT_LVC'.

        rv_result = abap_true.

      "Filter
      WHEN 'IT_FILTER'
        OR 'IT_FILTER_LVC'.

        rv_result = abap_true.

      "Layout
      WHEN 'IS_LAYOUT'
        OR 'IS_LAYOUT_LVC'.

        rv_result = abap_true.

      "Variant
      WHEN 'IS_VARIANT'.

        rv_result = abap_true.

      WHEN OTHERS.

        rv_result = abap_false.

    ENDCASE.

  ENDMETHOD.

    METHOD map_parameter_value.

    DATA(lv_value) =
      normalize_identifier(
        iv_value = iv_value
      ).

    IF lv_value IS INITIAL.
      RETURN.
    ENDIF.

    CASE iv_parameter.
      WHEN 'R_SALV_TABLE'.

       cs_state-control_object =
          lv_value.

      WHEN 'T_OUTTAB'
        OR 'IT_OUTTAB'
        OR 'T_TABLE'.

        cs_state-output_table =
          lv_value.

      WHEN 'IT_FIELDCAT'
        OR 'IT_FIELDCAT_LVC'
        OR 'IT_FIELDCATALOG'.

        cs_state-field_catalog =
          lv_value.

      WHEN 'IT_SORT'
        OR 'IT_SORT_LVC'.

        cs_state-sort_table =
          lv_value.

      WHEN 'IT_FILTER'
        OR 'IT_FILTER_LVC'.

        cs_state-filter_table =
          lv_value.

      WHEN 'IS_LAYOUT'
        OR 'IS_LAYOUT_LVC'.

        cs_state-layout_object =
          lv_value.

      WHEN 'IS_VARIANT'.

        cs_state-variant_object =
          lv_value.

    ENDCASE.

  ENDMETHOD.

    METHOD normalize_identifier.

    DATA lv_value TYPE string.

    lv_value = iv_value.

    CONDENSE lv_value NO-GAPS.

    "Loại bỏ escape character @
    IF lv_value IS NOT INITIAL
       AND lv_value+0(1) = '@'.

      lv_value =
        substring(
          val = lv_value
          off = 1
        ).

    ENDIF.

    "Loại bỏ quote
    IF strlen( lv_value ) >= 2
       AND lv_value+0(1) = ''''.

      DATA(lv_initial_length) =
        strlen( lv_value ).

      DATA(lv_initial_last) =
        lv_initial_length - 1.

      IF lv_value+lv_initial_last(1) = ''''.

        lv_value =
          substring(
            val = lv_value
            off = 1
            len = lv_initial_length - 2
          ).

      ENDIF.

    ENDIF.

    WHILE lv_value IS NOT INITIAL.

      DATA(lv_length) =
        strlen( lv_value ).

      DATA(lv_offset) =
        lv_length - 1.

      DATA(lv_last_char) =
        substring(
          val = lv_value
          off = lv_offset
          len = 1
        ).

      IF lv_last_char = '.'
         OR lv_last_char = ','
         OR lv_last_char = ')'
         OR lv_last_char = '('.

        lv_value =
          substring(
            val = lv_value
            len = lv_offset
          ).

      ELSE.

        EXIT.

      ENDIF.

    ENDWHILE.

    rv_value =
      to_upper( lv_value ).

  ENDMETHOD.

    METHOD create_uuid.

    TRY.

        rv_uuid =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
          previous =
            lx_uuid
          program_name =
            iv_source_object
        ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
