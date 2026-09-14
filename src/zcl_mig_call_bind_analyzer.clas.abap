CLASS zcl_mig_call_bind_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_call_bind_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_call_kind      TYPE c LENGTH 30,
      ty_parameter_name TYPE c LENGTH 60.

    TYPES:
      BEGIN OF ty_state,

        analysis_id  TYPE zif_mig_types=>ty_analysis_id,

        source_object TYPE progname,
        statement_id  TYPE i,

        call_item_id TYPE zif_mig_types=>ty_item_id,
        evidence_id  TYPE zif_mig_types=>ty_evidence_id,

        call_kind   TYPE ty_call_kind,
        object_name TYPE c LENGTH 120,

        current_direction TYPE c LENGTH 20,

        "Overall position within one call
        position TYPE i,

        "Position inside USING / CHANGING for PERFORM
        section_position TYPE i,

        call_target_seen TYPE abap_bool,

        previous_token TYPE string,

        parameter_name TYPE ty_parameter_name,
        actual_expression TYPE string,

        "One-token delay while collecting actual expression.
        "Allows detection of:
        "
        " P1 = V1
        " P2 = V2
        "
        "without nested token scanning.
        pending_actual_token TYPE string,

        collecting_actual TYPE abap_bool,

        bindings TYPE zif_mig_types=>tt_call_binding,

      END OF ty_state,

      tt_state TYPE HASHED TABLE OF ty_state
        WITH UNIQUE KEY source_object statement_id.

    TYPES:
      tt_evidence_index
        TYPE HASHED TABLE OF zif_mig_types=>ty_evidence
        WITH UNIQUE KEY evidence_id.


    METHODS build_states
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_logic       TYPE zif_mig_types=>tt_business_logic
        it_evidences   TYPE zif_mig_types=>tt_evidence
      RETURNING
        VALUE(rt_states) TYPE tt_state.


    METHODS process_tokens
      IMPORTING
        it_tokens TYPE zif_mig_types=>tt_token
      CHANGING
        ct_states TYPE tt_state
      RAISING
        zcx_mig_analysis.


    METHODS process_token
      IMPORTING
        iv_token       TYPE string
        iv_upper_token TYPE string
      CHANGING
        cs_state TYPE ty_state
      RAISING
        zcx_mig_analysis.


    METHODS finalize_state
      CHANGING
        cs_state TYPE ty_state
      RAISING
        zcx_mig_analysis.


    METHODS flush_named_binding
      IMPORTING
        iv_include_pending TYPE abap_bool DEFAULT abap_true
      CHANGING
        cs_state TYPE ty_state
      RAISING
        zcx_mig_analysis.


    METHODS append_positional_binding
      IMPORTING
        iv_actual TYPE string
      CHANGING
        cs_state TYPE ty_state
      RAISING
        zcx_mig_analysis.


    METHODS append_actual_token
      IMPORTING
        iv_token TYPE string
      CHANGING
        cv_actual TYPE string.


    METHODS is_supported_logic
      IMPORTING
        iv_object_type TYPE string
      RETURNING
        VALUE(rv_supported) TYPE abap_bool.


    METHODS is_direction
      IMPORTING
        iv_token TYPE string
      RETURNING
        VALUE(rv_direction) TYPE abap_bool.


    METHODS token_matches_target
      IMPORTING
        iv_token       TYPE string
        iv_object_name TYPE string
      RETURNING
        VALUE(rv_match) TYPE abap_bool.


    METHODS clean_identifier
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE ty_parameter_name.


    METHODS is_ignored_positional_token
      IMPORTING
        iv_token TYPE string
      RETURNING
        VALUE(rv_ignore) TYPE abap_bool.


    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

ENDCLASS.



CLASS zcl_mig_call_bind_analyzer IMPLEMENTATION.


  METHOD zif_mig_call_bind_analyzer~analyze.

    CLEAR rs_result.


    DATA(lv_analysis_id) =
      iv_analysis_id.


    "Fallback khi caller không truyền AnalysisId
    IF lv_analysis_id IS INITIAL.

      READ TABLE it_logic
        INDEX 1
        INTO DATA(ls_first_logic).

      IF sy-subrc = 0.

        lv_analysis_id =
          ls_first_logic-analysis_id.

      ENDIF.

    ENDIF.


    DATA(lt_states) =
      build_states(
        iv_analysis_id = lv_analysis_id
        it_logic       = it_logic
        it_evidences   = it_evidences
      ).


    IF lt_states IS INITIAL.
      RETURN.
    ENDIF.


    "==========================================================
    " Flatten token stream.
    "
    " Không LOOP source-unit rồi LOOP token bên trong.
    " Mỗi source unit chỉ APPEND LINES OF, sau đó token được
    " scan đúng một lần.
    "==========================================================
    DATA lt_tokens
      TYPE zif_mig_types=>tt_token.


    LOOP AT it_source_units
      ASSIGNING FIELD-SYMBOL(<source_unit>).

      APPEND LINES OF
        <source_unit>-scan_result-tokens
        TO lt_tokens.

    ENDLOOP.


    SORT lt_tokens
      BY source_object
         statement_id
         token_index.


    process_tokens(
      EXPORTING
        it_tokens = lt_tokens
      CHANGING
        ct_states = lt_states
    ).


    "==========================================================
    " Flush state cuối và flatten bindings
    "==========================================================
    LOOP AT lt_states
      INTO DATA(ls_state).

      finalize_state(
        CHANGING
          cs_state = ls_state
      ).

      APPEND LINES OF
        ls_state-bindings
        TO rs_result-call_bindings.

    ENDLOOP.


    SORT rs_result-call_bindings
      BY call_item_id
         position.

  ENDMETHOD.



  METHOD build_states.

    DATA lt_evidence_index
      TYPE tt_evidence_index.


    "==========================================================
    " Evidence index
    "==========================================================
    LOOP AT it_evidences
      INTO DATA(ls_evidence).

      INSERT ls_evidence
        INTO TABLE lt_evidence_index.

    ENDLOOP.


    "==========================================================
    " Business Logic call -> source statement
    "==========================================================
    LOOP AT it_logic
      INTO DATA(ls_logic).


      IF is_supported_logic(
           iv_object_type =
             CONV string(
               ls_logic-object_type
             )
         ) = abap_false.

        CONTINUE.

      ENDIF.


      IF ls_logic-evidence_id IS INITIAL.
        CONTINUE.
      ENDIF.


      READ TABLE lt_evidence_index
        WITH TABLE KEY
          evidence_id = ls_logic-evidence_id
        INTO DATA(ls_call_evidence).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.


      DATA(lv_state_analysis_id) =
        iv_analysis_id.

      IF lv_state_analysis_id IS INITIAL.

        lv_state_analysis_id =
          ls_logic-analysis_id.

      ENDIF.


      "Logic Analyzer hiện tạo một call fact / statement.
      "Nếu statement đã có state thì không tạo duplicate parser.
      READ TABLE rt_states
        WITH TABLE KEY
          source_object = ls_call_evidence-source_object
          statement_id  = ls_call_evidence-statement_id
        TRANSPORTING NO FIELDS.

      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.


      INSERT VALUE #(

        analysis_id =
          lv_state_analysis_id

        source_object =
          ls_call_evidence-source_object

        statement_id =
          ls_call_evidence-statement_id

        call_item_id =
          ls_logic-item_id

        evidence_id =
          ls_logic-evidence_id

        call_kind =
          ls_logic-object_type

        object_name =
          ls_logic-object_name

      ) INTO TABLE rt_states.

    ENDLOOP.

  ENDMETHOD.



  METHOD process_tokens.

    LOOP AT it_tokens
      ASSIGNING FIELD-SYMBOL(<token>).


      READ TABLE ct_states
        WITH TABLE KEY
          source_object = <token>-source_object
          statement_id  = <token>-statement_id
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
          textid       =
            zcx_mig_analysis=>analysis_failed

          program_name =
            ls_state-source_object
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.



  METHOD process_token.

    "==========================================================
    " 1. Parameter direction
    "==========================================================
    IF is_direction(
         iv_token = iv_upper_token
       ) = abap_true.


      IF cs_state-collecting_actual = abap_true.

        flush_named_binding(
          CHANGING
            cs_state = cs_state
        ).

      ENDIF.


      cs_state-current_direction =
        iv_upper_token.

      cs_state-section_position =
        0.

      cs_state-call_target_seen =
        abap_true.

      CLEAR cs_state-previous_token.

      RETURN.

    ENDIF.


    "==========================================================
    " EXCEPTIONS không phải parameter binding business data.
    " Dừng parsing section hiện tại.
    "==========================================================
    IF iv_upper_token = 'EXCEPTIONS'.

      IF cs_state-collecting_actual = abap_true.

        flush_named_binding(
          CHANGING
            cs_state = cs_state
        ).

      ENDIF.


      CLEAR:
        cs_state-current_direction,
        cs_state-section_position,
        cs_state-previous_token.

      RETURN.

    ENDIF.


    "==========================================================
    " 2. Xác định vị trí call target
    "==========================================================
    IF cs_state-call_target_seen = abap_false.

      IF token_matches_target(
         iv_token       = iv_upper_token
         iv_object_name = CONV string( cs_state-object_name )
       ) = abap_true.

        cs_state-call_target_seen =
          abap_true.

        cs_state-previous_token =
          iv_upper_token.

        RETURN.

      ENDIF.

    ENDIF.


    "==========================================================
    " 3. PERFORM ... USING / CHANGING
    "
    " PERFORM call site không chứa formal parameter name.
    " Vì vậy lưu positional binding:
    "
    " USING #1 = P_BUKRS
    " USING #2 = GT_ITEMS
    "==========================================================
    IF cs_state-call_kind = 'FORM_CALL'
       AND cs_state-current_direction IS NOT INITIAL.


      IF is_ignored_positional_token(
           iv_token = iv_upper_token
         ) = abap_true.

        RETURN.

      ENDIF.


      append_positional_binding(
        EXPORTING
          iv_actual = iv_token
        CHANGING
          cs_state  = cs_state
      ).

      RETURN.

    ENDIF.


    "==========================================================
    " 4. Đang thu actual expression của named parameter
    "
    " One-token delay:
    "
    " USERNAME = SY-UNAME
    " ADDRESS  = LS_ADDRESS
    "
    " Khi gặp '=' lần tiếp theo, token ngay trước '=' được
    " xem là formal parameter tiếp theo.
    "==========================================================
    IF cs_state-collecting_actual = abap_true.


      IF iv_upper_token = '='
         AND cs_state-pending_actual_token
               IS NOT INITIAL.


        DATA(lv_next_parameter) =
          cs_state-pending_actual_token.


        flush_named_binding(
          EXPORTING
            iv_include_pending = abap_false
          CHANGING
            cs_state           = cs_state
        ).


        cs_state-parameter_name =
          clean_identifier(
            iv_value =
              lv_next_parameter
          ).

        cs_state-collecting_actual =
          abap_true.

        CLEAR:
          cs_state-actual_expression,
          cs_state-pending_actual_token.

        RETURN.

      ENDIF.


      "Statement / method-call end
      IF iv_upper_token = ')'
         OR iv_upper_token = '.'

         OR iv_upper_token = '].'.


        flush_named_binding(
          CHANGING
            cs_state = cs_state
        ).

        RETURN.

      ENDIF.


      "Delay current token by one token.
      IF cs_state-pending_actual_token
           IS NOT INITIAL.

        append_actual_token(
          EXPORTING
            iv_token =
              cs_state-pending_actual_token

          CHANGING
            cv_actual =
              cs_state-actual_expression
        ).

      ENDIF.


      cs_state-pending_actual_token =
        iv_token.

      RETURN.

    ENDIF.


    "==========================================================
    " 5. Start named parameter:
    "
    " FORMAL = ACTUAL
    "==========================================================
    IF iv_upper_token = '='
       AND cs_state-call_target_seen = abap_true
       AND cs_state-previous_token IS NOT INITIAL.


      "Method short form:
      "
      " lo_obj->method(
      "   iv_value = lv_value
      " ).
      "
      " Nếu chưa có explicit section thì ABAP call-site này
      " tương ứng input/exporting binding.
      IF cs_state-current_direction IS INITIAL.

        IF cs_state-call_kind = 'STATIC_METHOD'
           OR
           cs_state-call_kind = 'INSTANCE_METHOD'.

          cs_state-current_direction =
            'EXPORTING'.

        ELSE.

          "FM/BAPI phải có section rõ ràng.
          cs_state-previous_token =
            iv_upper_token.

          RETURN.

        ENDIF.

      ENDIF.


      cs_state-parameter_name =
        clean_identifier(
          iv_value =
            cs_state-previous_token
        ).


      IF cs_state-parameter_name IS INITIAL.

        cs_state-previous_token =
          iv_upper_token.

        RETURN.

      ENDIF.


      CLEAR:
        cs_state-actual_expression,
        cs_state-pending_actual_token.


      cs_state-collecting_actual =
        abap_true.

      RETURN.

    ENDIF.


    cs_state-previous_token =
      iv_token.

  ENDMETHOD.



  METHOD finalize_state.

    IF cs_state-collecting_actual =
         abap_true.

      flush_named_binding(
        CHANGING
          cs_state = cs_state
      ).

    ENDIF.

  ENDMETHOD.



  METHOD flush_named_binding.

    IF cs_state-collecting_actual =
         abap_false.

      RETURN.

    ENDIF.


    IF iv_include_pending = abap_true
       AND
       cs_state-pending_actual_token
         IS NOT INITIAL.

      append_actual_token(
        EXPORTING
          iv_token =
            cs_state-pending_actual_token

        CHANGING
          cv_actual =
            cs_state-actual_expression
      ).

    ENDIF.


    CONDENSE cs_state-actual_expression.


    IF cs_state-parameter_name IS NOT INITIAL
       AND
       cs_state-actual_expression IS NOT INITIAL.


      cs_state-position += 1.


      DATA(lv_item_id) =
        create_uuid(
          iv_source_object =
            cs_state-source_object
        ).


      APPEND VALUE #(

        item_id =
          lv_item_id

        analysis_id =
          cs_state-analysis_id

        call_item_id =
          cs_state-call_item_id

        evidence_id =
          cs_state-evidence_id

        parameter_name =
          cs_state-parameter_name

        direction =
          cs_state-current_direction

        actual_expression =
          cs_state-actual_expression

        position =
          cs_state-position

        confidence =
          zif_mig_types=>gc_conf_high

      ) TO cs_state-bindings.

    ENDIF.


    CLEAR:
      cs_state-parameter_name,
      cs_state-actual_expression,
      cs_state-pending_actual_token,
      cs_state-collecting_actual.

  ENDMETHOD.



  METHOD append_positional_binding.

    DATA(lv_actual) =
      iv_actual.

    CONDENSE lv_actual.


    IF lv_actual IS INITIAL.
      RETURN.
    ENDIF.


    cs_state-position += 1.

    cs_state-section_position += 1.


    DATA(lv_parameter_name) =
      |#{ cs_state-section_position }|.


    DATA(lv_item_id) =
      create_uuid(
        iv_source_object =
          cs_state-source_object
      ).


    APPEND VALUE #(

      item_id =
        lv_item_id

      analysis_id =
        cs_state-analysis_id

      call_item_id =
        cs_state-call_item_id

      evidence_id =
        cs_state-evidence_id

      parameter_name =
        lv_parameter_name

      direction =
        cs_state-current_direction

      actual_expression =
        lv_actual

      position =
        cs_state-position

      confidence =
        zif_mig_types=>gc_conf_high

    ) TO cs_state-bindings.

  ENDMETHOD.



  METHOD append_actual_token.

    IF iv_token IS INITIAL.
      RETURN.
    ENDIF.


    IF cv_actual IS INITIAL.

      cv_actual =
        iv_token.

    ELSE.

      cv_actual =
        |{ cv_actual } { iv_token }|.

    ENDIF.

  ENDMETHOD.



  METHOD is_supported_logic.

    CASE to_upper( iv_object_type ).

      WHEN 'FORM_CALL'
        OR 'FUNCTION_MODULE'
        OR 'BAPI'
        OR 'DYNAMIC_FUNCTION_MODULE'
        OR 'STATIC_METHOD'
        OR 'INSTANCE_METHOD'.

        rv_supported =
          abap_true.

      WHEN OTHERS.

        rv_supported =
          abap_false.

    ENDCASE.

  ENDMETHOD.



  METHOD is_direction.

    CASE to_upper( iv_token ).

      WHEN 'EXPORTING'
        OR 'IMPORTING'
        OR 'CHANGING'
        OR 'TABLES'
        OR 'RECEIVING'
        OR 'USING'.

        rv_direction =
          abap_true.

      WHEN OTHERS.

        rv_direction =
          abap_false.

    ENDCASE.

  ENDMETHOD.



  METHOD token_matches_target.

    DATA(lv_token) =
      to_upper(
        iv_token
      ).

    DATA(lv_object) =
      to_upper(
        iv_object_name
      ).


    REPLACE ALL OCCURRENCES OF `'`
      IN lv_token
      WITH ''.

    REPLACE ALL OCCURRENCES OF `"`
      IN lv_token
      WITH ''.

    REPLACE ALL OCCURRENCES OF '('
      IN lv_token
      WITH ''.

    REPLACE ALL OCCURRENCES OF ')'
      IN lv_token
      WITH ''.


    CONDENSE:
      lv_token,
      lv_object.


    IF lv_token = lv_object.

      rv_match =
        abap_true.

      RETURN.

    ENDIF.


    DATA(lv_static_pattern) =
      |=>{ lv_object }|.

    DATA(lv_instance_pattern) =
      |->{ lv_object }|.


    rv_match =
      xsdbool(
        lv_token CS lv_static_pattern
        OR
        lv_token CS lv_instance_pattern
      ).

  ENDMETHOD.



  METHOD clean_identifier.

  DATA(lv_value) =
    to_upper(
      iv_value
    ).

  REPLACE ALL OCCURRENCES OF '('
    IN lv_value
    WITH ''.

  REPLACE ALL OCCURRENCES OF ')'
    IN lv_value
    WITH ''.

  REPLACE ALL OCCURRENCES OF ','
    IN lv_value
    WITH ''.

  REPLACE ALL OCCURRENCES OF '.'
    IN lv_value
    WITH ''.

  CONDENSE lv_value.

  rv_value =
    CONV ty_parameter_name( lv_value ).

ENDMETHOD.



  METHOD is_ignored_positional_token.

    CASE iv_token.

      WHEN ''
        OR '.'
        OR ','
        OR '('
        OR ')'.

        rv_ignore =
          abap_true.

      WHEN OTHERS.

        rv_ignore =
          abap_false.

    ENDCASE.

  ENDMETHOD.



  METHOD create_uuid.

    TRY.

        rv_uuid =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid       =
            zcx_mig_analysis=>analysis_failed

          previous     =
            lx_uuid

          program_name =
            iv_source_object
        ).

    ENDTRY.

  ENDMETHOD.


ENDCLASS.
