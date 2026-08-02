CLASS zcl_mig_logic_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_logic_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_object_name    TYPE c LENGTH 120,
      ty_object_type    TYPE c LENGTH 30,
      ty_side_effect    TYPE c LENGTH 20,
      ty_reuse_level    TYPE c LENGTH 20,
      ty_statement_type TYPE c LENGTH 30.

    TYPES:
      BEGIN OF ty_logic_state,
        statement_id       TYPE i,
        statement_type     TYPE ty_statement_type,
        source_object      TYPE progname,
        start_line         TYPE i,
        end_line           TYPE i,
        statement_text     TYPE string,
        calling_routine    TYPE c LENGTH 120,

        object_name        TYPE ty_object_name,
        object_type        TYPE ty_object_type,
        container_name     TYPE ty_object_name,

        side_effect        TYPE ty_side_effect,
        transaction_dependent TYPE abap_bool,
        gui_dependency     TYPE abap_bool,
        reuse_feasibility  TYPE ty_reuse_level,
        confidence         TYPE zif_mig_types=>ty_confidence,

        token_count        TYPE i,
        previous_token     TYPE string,

        call_kind          TYPE c LENGTH 20,
        expect_call_object TYPE abap_bool,
        expect_method_name TYPE abap_bool,

        recognized         TYPE abap_bool,
      END OF ty_logic_state,

      tt_logic_state TYPE HASHED TABLE OF ty_logic_state
        WITH UNIQUE KEY statement_id.

    METHODS analyze_source_unit
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_source_unit TYPE zif_mig_types=>ty_source_unit
      CHANGING
        ct_logic       TYPE zif_mig_types=>tt_business_logic
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS initialize_states
      IMPORTING
        it_statements TYPE zif_mig_types=>tt_statement
      RETURNING
        VALUE(rt_states) TYPE tt_logic_state.

    METHODS process_tokens
      IMPORTING
        it_tokens TYPE zif_mig_types=>tt_token
      CHANGING
        ct_states TYPE tt_logic_state
      RAISING
        zcx_mig_analysis.

    METHODS process_token
      IMPORTING
        iv_token       TYPE string
        iv_upper_token TYPE string
      CHANGING
        cs_state       TYPE ty_logic_state.

    METHODS finalize_state
      CHANGING
        cs_state TYPE ty_logic_state.

    METHODS parse_combined_method
      IMPORTING
        iv_token TYPE string
      CHANGING
        cs_state TYPE ty_logic_state.

    METHODS normalize_object_name
      IMPORTING
        iv_name TYPE string
      RETURNING
        VALUE(rv_name) TYPE ty_object_name.

    METHODS infer_side_effect
      IMPORTING
        iv_object_name TYPE ty_object_name
        iv_object_type TYPE ty_object_type
      EXPORTING
        ev_side_effect TYPE ty_side_effect
        ev_transaction_dependency TYPE abap_bool.

    METHODS is_candidate_statement
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    METHODS has_write_name_hint
      IMPORTING
        iv_object_name TYPE ty_object_name
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.


ENDCLASS.

CLASS zcl_mig_logic_analyzer IMPLEMENTATION.

  METHOD zif_mig_logic_analyzer~analyze.

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
          ct_logic       = rs_result-business_logic
          ct_evidences   = rs_result-evidences
      ).

    ENDLOOP.

    SORT rs_result-business_logic
      BY object_type
         object_name.

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

      IF ls_state-recognized = abap_false
         OR ls_state-object_name IS INITIAL.

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
        item_id                = lv_item_id
        analysis_id            = iv_analysis_id
        evidence_id            = lv_evidence_id
        object_name            = ls_state-object_name
        object_type            = ls_state-object_type
        container_name         = ls_state-container_name
        calling_routine        = ls_state-calling_routine
        interface_summary      = ''
        description            = ''
        side_effect            = ls_state-side_effect
        transaction_dependency = ls_state-transaction_dependent
        gui_dependency         = ls_state-gui_dependency
        reuse_feasibility      = ls_state-reuse_feasibility
        confidence             = ls_state-confidence
      ) TO ct_logic.

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

      INSERT VALUE #(
        statement_id       = <statement>-statement_id
        statement_type     = <statement>-statement_type
        source_object      = <statement>-source_object
        start_line         = <statement>-start_line
        end_line           = <statement>-end_line
        statement_text     = <statement>-statement_text
        calling_routine    = <statement>-parent_routine
        confidence         = zif_mig_types=>gc_conf_high
      ) INTO TABLE rt_states.

    ENDLOOP.

  ENDMETHOD.

    METHOD is_candidate_statement.

    CASE is_statement-statement_type.

      WHEN 'FORM'
        OR 'METHOD'
        OR 'FUNCTION'
        OR 'MODULE'
        OR 'PERFORM'
        OR 'CALL'
        OR 'SUBMIT'.

        rv_result = abap_true.

      WHEN OTHERS.

        DATA(lv_statement_text) =
          to_upper(
            is_statement-statement_text
          ).

        IF lv_statement_text CS '=>'
           OR lv_statement_text CS '->'.

          rv_result = abap_true.

        ELSE.

          rv_result = abap_false.

        ENDIF.

    ENDCASE.

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
        to_upper( <token>-token_text ).

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
          textid       = zcx_mig_analysis=>analysis_failed
          program_name = ls_state-source_object
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD process_token.

    cs_state-token_count += 1.

    "==========================================================
    " Combined method token:
    " LCL_WORKER=>READ_DATA
    " LO_WORKER->CALCULATE
    "==========================================================
    IF iv_upper_token CS '=>'
       OR iv_upper_token CS '->'.

      parse_combined_method(
        EXPORTING
          iv_token = iv_upper_token
        CHANGING
          cs_state = cs_state
      ).

      cs_state-previous_token = iv_upper_token.
      RETURN.

    ENDIF.

    "==========================================================
    " Method operator được scanner tách riêng
    " LCL_WORKER  =>  READ_DATA
    " LO_WORKER   ->  CALCULATE
    "==========================================================
    IF iv_upper_token = '=>'.

      cs_state-container_name =
        normalize_object_name(
          iv_name = cs_state-previous_token
        ).

      cs_state-object_type =
        'STATIC_METHOD'.

      cs_state-expect_method_name =
        abap_true.

      cs_state-recognized =
        abap_true.

      cs_state-previous_token = iv_upper_token.
      RETURN.

    ELSEIF iv_upper_token = '->'.

      cs_state-container_name =
        normalize_object_name(
          iv_name = cs_state-previous_token
        ).

      cs_state-object_type =
        'INSTANCE_METHOD'.

      cs_state-expect_method_name =
        abap_true.

      cs_state-recognized =
        abap_true.

      cs_state-previous_token = iv_upper_token.
      RETURN.

    ENDIF.

    IF cs_state-expect_method_name = abap_true.

      cs_state-object_name =
        normalize_object_name(
          iv_name = iv_upper_token
        ).

      cs_state-expect_method_name =
        abap_false.

      cs_state-previous_token =
        iv_upper_token.

      RETURN.

    ENDIF.

    "==========================================================
    " Statement-level classification
    "==========================================================
    CASE cs_state-statement_type.

      WHEN 'FORM'.

        IF cs_state-token_count = 2.

          cs_state-object_name =
            normalize_object_name(
              iv_name = iv_upper_token
            ).

          cs_state-object_type =
            'FORM_DEFINITION'.

          cs_state-reuse_feasibility =
            'REFACTOR'.

          cs_state-recognized =
            abap_true.

        ENDIF.

      WHEN 'METHOD'.

        IF cs_state-token_count = 2.

          cs_state-object_name =
            normalize_object_name(
              iv_name = iv_upper_token
            ).

          cs_state-object_type =
            'METHOD_DEFINITION'.

          cs_state-container_name =
            cs_state-source_object.

          cs_state-reuse_feasibility =
            'REUSABLE'.

          cs_state-recognized =
            abap_true.

        ENDIF.

      WHEN 'FUNCTION'.

        IF cs_state-token_count = 2.

          cs_state-object_name =
            normalize_object_name(
              iv_name = iv_upper_token
            ).

          cs_state-object_type =
            'FUNCTION_DEFINITION'.

          cs_state-reuse_feasibility =
            'ADAPTER_REVIEW'.

          cs_state-recognized =
            abap_true.

        ENDIF.

      WHEN 'MODULE'.

        IF cs_state-token_count = 2.

          cs_state-object_name =
            normalize_object_name(
              iv_name = iv_upper_token
            ).

          cs_state-object_type =
            'MODULE'.

          cs_state-gui_dependency =
            abap_true.

          cs_state-reuse_feasibility =
            'REDESIGN'.

          cs_state-recognized =
            abap_true.

        ENDIF.

      WHEN 'PERFORM'.

        IF cs_state-token_count = 2.

          cs_state-object_name =
            normalize_object_name(
              iv_name = iv_upper_token
            ).

          cs_state-object_type =
            'FORM_CALL'.

          cs_state-reuse_feasibility =
            'REFACTOR'.

          cs_state-recognized =
            abap_true.

        ENDIF.

      WHEN 'SUBMIT'.

        IF cs_state-token_count = 2.

          cs_state-object_name =
            normalize_object_name(
              iv_name = iv_upper_token
            ).

          cs_state-object_type =
            'REPORT_SUBMIT'.

          cs_state-reuse_feasibility =
            'ADAPTER_REVIEW'.

          cs_state-recognized =
            abap_true.

        ENDIF.

      WHEN 'CALL'.

        "CALL FUNCTION / SCREEN / TRANSACTION / METHOD
        IF cs_state-token_count = 2.

          cs_state-call_kind =
            iv_upper_token.

          cs_state-expect_call_object =
            abap_true.

          cs_state-previous_token =
            iv_upper_token.

          RETURN.

        ENDIF.

        IF cs_state-expect_call_object = abap_true.

          cs_state-expect_call_object =
            abap_false.

          CASE cs_state-call_kind.

            WHEN 'FUNCTION'.

              cs_state-object_name =
                normalize_object_name(
                  iv_name = iv_upper_token
                ).

              IF cs_state-object_name CP 'BAPI_*'.

                cs_state-object_type =
                  'BAPI'.

              ELSE.

                cs_state-object_type =
                  'FUNCTION_MODULE'.

              ENDIF.

              cs_state-reuse_feasibility =
                'ADAPTER_REVIEW'.

              cs_state-recognized =
                abap_true.

            WHEN 'SCREEN'.

              cs_state-object_name =
                normalize_object_name(
                  iv_name = iv_upper_token
                ).

              cs_state-object_type =
                'DYPRO'.

              cs_state-gui_dependency =
                abap_true.

              cs_state-reuse_feasibility =
                'REDESIGN'.

              cs_state-recognized =
                abap_true.

            WHEN 'TRANSACTION'.

              cs_state-object_name =
                normalize_object_name(
                  iv_name = iv_upper_token
                ).

              cs_state-object_type =
                'TRANSACTION'.

              cs_state-gui_dependency =
                abap_true.

              cs_state-reuse_feasibility =
                'REDESIGN'.

              cs_state-recognized =
                abap_true.

            WHEN 'METHOD'.

              "CALL METHOD lo_service->execute
              "Method reference sẽ tiếp tục được xử lý bởi
              "operator -> hoặc combined token.

            WHEN OTHERS.

          ENDCASE.

        ENDIF.

    ENDCASE.

    cs_state-previous_token =
      iv_upper_token.

  ENDMETHOD.

    METHOD parse_combined_method.

    DATA:
      lv_container TYPE string,
      lv_method    TYPE string.

    IF iv_token CS '=>'.

      SPLIT iv_token
        AT '=>'
        INTO lv_container lv_method.

      cs_state-object_type =
        'STATIC_METHOD'.

    ELSEIF iv_token CS '->'.

      SPLIT iv_token
        AT '->'
        INTO lv_container lv_method.

      cs_state-object_type =
        'INSTANCE_METHOD'.

    ELSE.

      RETURN.

    ENDIF.

    cs_state-container_name =
      normalize_object_name(
        iv_name = lv_container
      ).

    cs_state-object_name =
      normalize_object_name(
        iv_name = lv_method
      ).

    cs_state-reuse_feasibility =
      'REUSABLE'.

    cs_state-recognized =
      abap_true.

  ENDMETHOD.

    METHOD normalize_object_name.

    DATA lv_name TYPE string.

    lv_name = iv_name.

    CONDENSE lv_name NO-GAPS.

    "Xóa literal quote
    IF strlen( lv_name ) >= 2
       AND lv_name+0(1) = ''''.

      DATA(lv_length) =
        strlen( lv_name ).

      DATA(lv_last_offset) =
        lv_length - 1.

      IF lv_name+lv_last_offset(1) = ''''.

        lv_name =
          substring(
            val = lv_name
            off = 1
            len = lv_length - 2
          ).

      ENDIF.

    ENDIF.

    "Xóa dấu ngoặc/câu kết thúc
    WHILE lv_name IS NOT INITIAL.

      DATA(lv_current_length) =
        strlen( lv_name ).

      DATA(lv_offset) =
        lv_current_length - 1.

      DATA(lv_last_char) =
        substring(
          val = lv_name
          off = lv_offset
          len = 1
        ).

      IF lv_last_char = '('
         OR lv_last_char = ')'
         OR lv_last_char = '.'
         OR lv_last_char = ','.

        lv_name =
          substring(
            val = lv_name
            len = lv_offset
          ).

      ELSE.

        EXIT.

      ENDIF.

    ENDWHILE.

    rv_name =
      to_upper( lv_name ).

  ENDMETHOD.

    METHOD finalize_state.

    IF cs_state-recognized = abap_false.
      RETURN.
    ENDIF.

    infer_side_effect(
      EXPORTING
        iv_object_name =
          cs_state-object_name
        iv_object_type =
          cs_state-object_type
      IMPORTING
        ev_side_effect =
          cs_state-side_effect
        ev_transaction_dependency =
          cs_state-transaction_dependent
    ).

    IF cs_state-side_effect = 'REVIEW'
       AND cs_state-confidence =
             zif_mig_types=>gc_conf_high.

      cs_state-confidence =
        zif_mig_types=>gc_conf_medium.

    ENDIF.

    IF cs_state-reuse_feasibility IS INITIAL.

      CASE cs_state-object_type.

        WHEN 'STATIC_METHOD'
          OR 'INSTANCE_METHOD'
          OR 'METHOD_DEFINITION'.

          cs_state-reuse_feasibility =
            'REUSABLE'.

        WHEN 'BAPI'
          OR 'FUNCTION_MODULE'
          OR 'FUNCTION_DEFINITION'
          OR 'REPORT_SUBMIT'.

          cs_state-reuse_feasibility =
            'ADAPTER_REVIEW'.

        WHEN 'FORM_CALL'
          OR 'FORM_DEFINITION'.

          cs_state-reuse_feasibility =
            'REFACTOR'.

        WHEN 'DYPRO'
          OR 'TRANSACTION'
          OR 'MODULE'.

          cs_state-reuse_feasibility =
            'REDESIGN'.

      ENDCASE.

    ENDIF.

  ENDMETHOD.

METHOD infer_side_effect.

  CLEAR:
    ev_side_effect,
    ev_transaction_dependency.

  "==========================================================
  " Definitions chỉ mô tả cấu trúc source.
  "
  "Không thể suy ra side effect từ tên của definition.
  "==========================================================
  CASE iv_object_type.

    WHEN 'METHOD_DEFINITION'
      OR 'FORM_DEFINITION'
      OR 'FUNCTION_DEFINITION'.

      ev_side_effect =
        'NONE'.

      RETURN.

  ENDCASE.


  "==========================================================
  " GUI dependencies
  "==========================================================
  CASE iv_object_type.

    WHEN 'DYPRO'
      OR 'MODULE'.

      ev_side_effect =
        'GUI_DEPENDENT'.

      RETURN.


    WHEN 'TRANSACTION'.

      ev_side_effect =
        'GUI_DEPENDENT'.

      ev_transaction_dependency =
        abap_true.

      RETURN.

  ENDCASE.


  DATA(lv_name) =
    to_upper(
      CONV string( iv_object_name )
    ).


  "==========================================================
  " Explicit transaction APIs
  "==========================================================
  IF lv_name = 'BAPI_TRANSACTION_COMMIT'
     OR lv_name = 'BAPI_TRANSACTION_ROLLBACK'.

    ev_side_effect =
      'TRANSACTION'.

    ev_transaction_dependency =
      abap_true.

    RETURN.

  ENDIF.


  "==========================================================
  " BAPI
  "
  "Chỉ dựa vào tên BAPI chưa đủ để kết luận READ/WRITE.
  "==========================================================
  IF iv_object_type = 'BAPI'.

    ev_side_effect =
      'REVIEW'.

    RETURN.

  ENDIF.


  "==========================================================
  " Write-name hint
  "
  "Đây chỉ là hint, không phải bằng chứng về side effect.
  "Không đặt transaction_dependency.
  "==========================================================
  IF has_write_name_hint(
       iv_object_name = iv_object_name
     ) = abap_true.

    CASE iv_object_type.

      WHEN 'STATIC_METHOD'
        OR 'INSTANCE_METHOD'
        OR 'FUNCTION_MODULE'
        OR 'FORM_CALL'
        OR 'REPORT_SUBMIT'.

        ev_side_effect =
          'REVIEW'.

        RETURN.

    ENDCASE.

  ENDIF.


  "==========================================================
  " Không có đủ evidence để kết luận
  "==========================================================
  ev_side_effect =
    'READ_OR_UNKNOWN'.

ENDMETHOD.
  METHOD has_write_name_hint.

  DATA(lv_name) =
    to_upper(
      CONV string( iv_object_name )
    ).

  "Không dùng substring vì:
  "HANDLE_DATA_CHANGED chứa CHANGE nhưng không có nghĩa
  "method thực hiện database write.
  REPLACE ALL OCCURRENCES OF `-`
    IN lv_name
    WITH `_`.

  DATA lt_name_parts
    TYPE STANDARD TABLE OF string
    WITH EMPTY KEY.

  SPLIT lv_name
    AT `_`
    INTO TABLE lt_name_parts.

  LOOP AT lt_name_parts
    INTO DATA(lv_name_part).

    CASE lv_name_part.

      WHEN 'CREATE'
        OR 'CHANGE'
        OR 'UPDATE'
        OR 'DELETE'
        OR 'POST'
        OR 'SAVE'
        OR 'CANCEL'
        OR 'RELEASE'
        OR 'APPROVE'.

        rv_result = abap_true.
        RETURN.

    ENDCASE.

  ENDLOOP.

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

ENDCLASS.
