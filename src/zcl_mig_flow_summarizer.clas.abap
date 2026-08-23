CLASS zcl_mig_flow_summarizer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_flow_summarizer.


  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_candidate,

        step_kind
          TYPE zif_mig_flow_summarizer=>ty_step_kind,

        context_name
          TYPE zif_mig_flow_summarizer=>ty_name,

        object_name
          TYPE zif_mig_flow_summarizer=>ty_name,

        object_type
          TYPE zif_mig_flow_summarizer=>ty_object_type,

        relation
          TYPE zif_mig_flow_summarizer=>ty_relation,

        detail
          TYPE string,

        source_object
          TYPE progname,

        source_line
          TYPE i,

        evidence_id
          TYPE zif_mig_types=>ty_evidence_id,

        confidence
          TYPE zif_mig_types=>ty_confidence,

        manual_review
          TYPE abap_bool,

      END OF ty_candidate,

      tt_candidate
        TYPE STANDARD TABLE OF ty_candidate
        WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_binding_summary,

        call_item_id
          TYPE zif_mig_types=>ty_item_id,

        detail
          TYPE string,

      END OF ty_binding_summary,

      tt_binding_summary
        TYPE HASHED TABLE OF ty_binding_summary
        WITH UNIQUE KEY call_item_id.

    METHODS collect_context_candidates
      IMPORTING

        iv_context
          TYPE zif_mig_flow_summarizer=>ty_name

        iv_form_as_routine
          TYPE abap_bool

        is_result
          TYPE zif_mig_types=>ty_analysis_result

        it_binding_summaries
          TYPE tt_binding_summary

      RETURNING
        VALUE(rt_candidates)
          TYPE tt_candidate.


    METHODS append_candidate
      IMPORTING

        is_candidate
          TYPE ty_candidate

        iv_level
          TYPE i

      CHANGING

        cv_sequence
          TYPE i

        ct_steps
          TYPE zif_mig_flow_summarizer=>tt_flow_step.


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


    METHODS build_db_detail
      IMPORTING
        is_database
          TYPE zif_mig_types=>ty_database_object

      RETURNING
        VALUE(rv_detail)
          TYPE string.


    METHODS build_logic_detail
      IMPORTING
        is_logic
          TYPE zif_mig_types=>ty_business_logic

      RETURNING
        VALUE(rv_detail)
          TYPE string.


    METHODS build_alv_detail
      IMPORTING
        is_alv
          TYPE zif_mig_types=>ty_alv_output

      RETURNING
        VALUE(rv_detail)
          TYPE string.
    METHODS build_binding_summaries
      IMPORTING
        it_bindings
          TYPE zif_mig_types=>tt_call_binding

      RETURNING
        VALUE(rt_summaries)
          TYPE tt_binding_summary.

ENDCLASS.

CLASS zcl_mig_flow_summarizer IMPLEMENTATION.


  METHOD zif_mig_flow_summarizer~summarize.

    CLEAR rs_summary.

    rs_summary-program_name =
      is_result-overview-program_name.

    DATA(lt_binding_summaries) =
      build_binding_summaries(
        it_bindings =
          is_result-call_bindings
      ).


    "==========================================================
    " Processing events mà Normalizer V1 hỗ trợ
    "
    " Thứ tự ở đây là logical ABAP processing order mức cao.
    " Không phải statement-level CFG.
    "==========================================================
    DATA lt_events
      TYPE STANDARD TABLE OF
        zif_mig_flow_summarizer=>ty_name
      WITH EMPTY KEY.


    lt_events = VALUE #(

      ( 'LOAD-OF-PROGRAM' )

      ( 'INITIALIZATION' )

      ( 'AT SELECTION-SCREEN' )

      ( 'START-OF-SELECTION' )

      ( 'END-OF-SELECTION' )

      ( 'TOP-OF-PAGE' )

      ( 'END-OF-PAGE' )

      ( 'AT LINE-SELECTION' )

      ( 'AT USER-COMMAND' )

    ).


    DATA lv_sequence TYPE i.

    CLEAR lv_sequence.


    LOOP AT lt_events
      INTO DATA(lv_event).


      "========================================================
      " Lấy toàn bộ activity thuộc event:
      "
      " - PERFORM → ROUTINE
      " - direct DB
      " - direct FM/BAPI/method
      " - direct ALV
      "========================================================
      DATA(lt_event_candidates) =
      collect_context_candidates(
        iv_context =
          lv_event

        iv_form_as_routine =
          abap_true

        is_result =
          is_result

        it_binding_summaries =
          lt_binding_summaries
      ).


      IF lt_event_candidates IS INITIAL.

        CONTINUE.

      ENDIF.


      "========================================================
      " Synthetic EVENT node
      "========================================================
      lv_sequence += 1.


      APPEND VALUE #(

        sequence      = lv_sequence
        level         = 0

        step_kind     = 'EVENT'

        object_name   = lv_event
        object_type   = 'PROCESSING_EVENT'

        relation      = 'ROOT'

        confidence    =
          zif_mig_types=>gc_conf_high

        manual_review = abap_false

      ) TO rs_summary-steps.


      "========================================================
      " Activity trực tiếp dưới EVENT
      "========================================================
      LOOP AT lt_event_candidates
        INTO DATA(ls_event_candidate).


        append_candidate(
          EXPORTING
            is_candidate = ls_event_candidate
            iv_level     = 1

          CHANGING
            cv_sequence  = lv_sequence
            ct_steps     = rs_summary-steps
        ).


        "======================================================
        " Nếu EVENT → FORM
        "
        " tiếp tục summarize facts thuộc FORM đó.
        "
        " Không recursive vô hạn.
        " Nested PERFORM chỉ được mô tả là CALL ở level 2.
        "======================================================
        IF ls_event_candidate-step_kind <> 'ROUTINE'.

          CONTINUE.

        ENDIF.


        DATA(lt_routine_candidates) =
          collect_context_candidates(
            iv_context =
              ls_event_candidate-object_name

            iv_form_as_routine =
              abap_false

            is_result =
              is_result

            it_binding_summaries =
              lt_binding_summaries
          ).

        LOOP AT lt_routine_candidates
          INTO DATA(ls_routine_candidate).


          append_candidate(
            EXPORTING
              is_candidate =
                ls_routine_candidate

              iv_level =
                2

            CHANGING
              cv_sequence =
                lv_sequence

              ct_steps =
                rs_summary-steps
          ).


        ENDLOOP.


      ENDLOOP.


    ENDLOOP.


  ENDMETHOD.

    METHOD collect_context_candidates.

    CLEAR rt_candidates.


    "==========================================================
    " DATABASE
    "==========================================================
    LOOP AT is_result-database_objects
      ASSIGNING FIELD-SYMBOL(<database>)
      WHERE containing_routine = iv_context.


      DATA:
        lv_db_source TYPE progname,
        lv_db_line   TYPE i.


      get_evidence_location(
        EXPORTING
          iv_evidence_id =
            <database>-evidence_id

          it_evidences =
            is_result-evidences

        IMPORTING
          ev_source_object =
            lv_db_source

          ev_source_line =
            lv_db_line
      ).


      DATA(lv_db_detail) =
        build_db_detail(
          is_database = <database>
        ).


      DATA(lv_db_review) =
        xsdbool(
          <database>-dynamic_access = abap_true
          OR
          <database>-paging_capability = 'REVIEW'
          OR
          <database>-confidence =
            zif_mig_types=>gc_conf_low
        ).


      APPEND VALUE #(

        step_kind     = 'DATABASE'

        context_name  = iv_context

        object_name   =
          <database>-object_name

        object_type   =
          <database>-object_type

        relation      = 'ACCESSES_DB'

        detail        = lv_db_detail

        source_object = lv_db_source
        source_line   = lv_db_line

        evidence_id   =
          <database>-evidence_id

        confidence    =
          <database>-confidence

        manual_review =
          lv_db_review

      ) TO rt_candidates.


    ENDLOOP.



    "==========================================================
    " BUSINESS LOGIC
    "==========================================================
    LOOP AT is_result-business_logic
      ASSIGNING FIELD-SYMBOL(<logic>)
      WHERE calling_routine = iv_context.


      "Definitions không phải runtime flow.
      IF <logic>-object_type = 'FORM_DEFINITION'
         OR <logic>-object_type = 'METHOD_DEFINITION'
         OR <logic>-object_type = 'FUNCTION_DEFINITION'.

        CONTINUE.

      ENDIF.


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


      DATA lv_step_kind
        TYPE zif_mig_flow_summarizer=>ty_step_kind.

      DATA lv_relation
        TYPE zif_mig_flow_summarizer=>ty_relation.


      IF <logic>-object_type = 'FORM_CALL'
         AND iv_form_as_routine = abap_true.

        lv_step_kind =
          'ROUTINE'.

        lv_relation =
          'ENTERS_ROUTINE'.

      ELSE.

        lv_step_kind =
          'CALL'.

        lv_relation =
          'CALLS'.

      ENDIF.


      DATA(lv_logic_detail) =
        build_logic_detail(
          is_logic = <logic>
        ).

      READ TABLE it_binding_summaries
          WITH TABLE KEY
            call_item_id = <logic>-item_id
          ASSIGNING FIELD-SYMBOL(<binding_summary>).


        IF sy-subrc = 0.

          lv_logic_detail =
            |{ lv_logic_detail }; ObservedBindings=[{
               <binding_summary>-detail }] |.

          CONDENSE lv_logic_detail.

        ENDIF.


      DATA(lv_logic_review) =
        xsdbool(
          <logic>-object_type =
            'DYNAMIC_FUNCTION_MODULE'

          OR

          <logic>-confidence =
            zif_mig_types=>gc_conf_low
        ).


      APPEND VALUE #(

        step_kind     =
          lv_step_kind

        context_name  =
          iv_context

        object_name   =
          <logic>-object_name

        object_type   =
          <logic>-object_type

        relation      =
          lv_relation

        detail        =
          lv_logic_detail

        source_object =
          lv_logic_source

        source_line   =
          lv_logic_line

        evidence_id   =
          <logic>-evidence_id

        confidence    =
          <logic>-confidence

        manual_review =
          lv_logic_review

      ) TO rt_candidates.


    ENDLOOP.



    "==========================================================
    " ALV
    "==========================================================
    LOOP AT is_result-alv_outputs
      ASSIGNING FIELD-SYMBOL(<alv>)
      WHERE containing_routine = iv_context.


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
        build_alv_detail(
          is_alv = <alv>
        ).


      DATA lv_alv_name
        TYPE zif_mig_flow_summarizer=>ty_name.


      IF <alv>-output_name IS NOT INITIAL.

        lv_alv_name =
          <alv>-output_name.

      ELSE.

        lv_alv_name =
          <alv>-framework.

      ENDIF.


      DATA(lv_alv_review) =
        xsdbool(
          <alv>-output_table IS INITIAL
          OR
          <alv>-confidence =
            zif_mig_types=>gc_conf_low
        ).


      APPEND VALUE #(

        step_kind     = 'ALV'

        context_name  = iv_context

        object_name   = lv_alv_name

        object_type   =
          <alv>-framework

        relation      = 'DISPLAYS'

        detail        =
          lv_alv_detail

        source_object =
          lv_alv_source

        source_line   =
          lv_alv_line

        evidence_id   =
          <alv>-evidence_id

        confidence    =
          <alv>-confidence

        manual_review =
          lv_alv_review

      ) TO rt_candidates.


    ENDLOOP.


    "==========================================================
    " Trong cùng một routine/event:
    "
    " dùng Evidence location để giữ source order gần nhất.
    "
    " Không tuyên bố đây là runtime CFG.
    "==========================================================
    SORT rt_candidates
      BY source_object
         source_line
         step_kind
         object_name.


  ENDMETHOD.

    METHOD append_candidate.

    cv_sequence += 1.


    APPEND VALUE #(

      sequence      =
        cv_sequence

      level         =
        iv_level

      step_kind     =
        is_candidate-step_kind

      context_name  =
        is_candidate-context_name

      object_name   =
        is_candidate-object_name

      object_type   =
        is_candidate-object_type

      relation      =
        is_candidate-relation

      detail        =
        is_candidate-detail

      source_object =
        is_candidate-source_object

      source_line   =
        is_candidate-source_line

      evidence_id   =
        is_candidate-evidence_id

      confidence    =
        is_candidate-confidence

      manual_review =
        is_candidate-manual_review

    ) TO ct_steps.


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

    METHOD build_db_detail.

    CLEAR rv_detail.


    rv_detail =
      |{ is_database-operation } {
         is_database-object_name }|.


    IF is_database-joined_objects
         IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; JOINS={
           is_database-joined_objects }|.

    ENDIF.


    IF is_database-result_target
         IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; RESULT={
           is_database-result_target }|.

    ENDIF.


    IF is_database-dynamic_access =
         abap_true.

      rv_detail =
        |{ rv_detail }; DYNAMIC|.

    ENDIF.

    IF is_database-execution_kind IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; EXECUTION={
           is_database-execution_kind }|.

    ENDIF.


    IF is_database-execution_context IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; CONTEXT={
           is_database-execution_context }|.

    ENDIF.

  ENDMETHOD.

    METHOD build_logic_detail.

    CLEAR rv_detail.


    CASE is_logic-object_type.


      WHEN 'STATIC_METHOD'.

        rv_detail =
          |{ is_logic-container_name }=>{
             is_logic-object_name }|.


      WHEN 'INSTANCE_METHOD'.

        rv_detail =
          |{ is_logic-container_name }->{
             is_logic-object_name }|.


      WHEN 'FORM_CALL'.

        rv_detail =
          |PERFORM { is_logic-object_name }|.


      WHEN 'DYNAMIC_FUNCTION_MODULE'.

        rv_detail =
          |CALL FUNCTION ({ is_logic-object_name })|.


      WHEN 'FUNCTION_MODULE'
        OR 'BAPI'.

        rv_detail =
          |CALL FUNCTION { is_logic-object_name }|.


      WHEN OTHERS.

        rv_detail =
          is_logic-object_name.


    ENDCASE.


    IF is_logic-side_effect
         IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; SIDE_EFFECT={
           is_logic-side_effect }|.

    ENDIF.

    IF is_logic-execution_kind IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; EXECUTION={
           is_logic-execution_kind }|.

    ENDIF.


    IF is_logic-execution_context IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; CONTEXT={
           is_logic-execution_context }|.

    ENDIF.


  ENDMETHOD.

    METHOD build_alv_detail.

    CLEAR rv_detail.


    rv_detail =
      is_alv-framework.


    IF is_alv-control_object
         IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; CONTROL={
           is_alv-control_object }|.

    ENDIF.


    IF is_alv-output_table
         IS NOT INITIAL.

      rv_detail =
        |{ rv_detail }; OUTPUT={
           is_alv-output_table }|.

    ELSE.

      rv_detail =
        |{ rv_detail }; OUTPUT=UNRESOLVED|.

    ENDIF.


  ENDMETHOD.

  METHOD build_binding_summaries.

  DATA lt_bindings
    TYPE zif_mig_types=>tt_call_binding.


  lt_bindings =
    it_bindings.


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
