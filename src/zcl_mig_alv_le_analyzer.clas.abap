CLASS zcl_mig_alv_le_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_alv_le_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_identifier   TYPE c LENGTH 80,
      ty_component    TYPE c LENGTH 40,
      ty_handler_name TYPE c LENGTH 120,
      ty_event_name   TYPE c LENGTH 40,
      ty_handler_kind TYPE c LENGTH 20.

    TYPES:
      BEGIN OF ty_control_map,
        control_object TYPE ty_identifier,
        output_id      TYPE zif_mig_types=>ty_item_id,
      END OF ty_control_map,

      tt_control_map TYPE HASHED TABLE OF ty_control_map
        WITH UNIQUE KEY control_object.

    TYPES:
      BEGIN OF ty_event_source_map,
        event_source TYPE ty_identifier,
        output_id    TYPE zif_mig_types=>ty_item_id,
      END OF ty_event_source_map,

      tt_event_source_map TYPE HASHED TABLE OF ty_event_source_map
        WITH UNIQUE KEY event_source.

    TYPES:
      BEGIN OF ty_layout_builder,
        work_area      TYPE ty_identifier,

        zebra          TYPE abap_bool,
        auto_width     TYPE abap_bool,
        editable       TYPE abap_bool,
        selection_mode TYPE c LENGTH 10,

        source_object  TYPE progname,
        start_line     TYPE i,
        end_line       TYPE i,
        statement_id   TYPE i,
        statement_text TYPE string,

        confidence     TYPE zif_mig_types=>ty_confidence,
      END OF ty_layout_builder,

      tt_layout_builder TYPE HASHED TABLE OF ty_layout_builder
        WITH UNIQUE KEY work_area.

    METHODS build_control_map
      IMPORTING
        it_alv_outputs TYPE zif_mig_types=>tt_alv_output
      RETURNING
        VALUE(rt_control_map) TYPE tt_control_map.

    METHODS analyze_source_unit
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_source_unit TYPE zif_mig_types=>ty_source_unit
        it_control_map TYPE tt_control_map
      CHANGING
        ct_layout_builders TYPE tt_layout_builder
        ct_event_sources   TYPE tt_event_source_map
        ct_events          TYPE zif_mig_types=>tt_alv_event
        ct_evidences       TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS process_layout_assignment
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        ct_builders  TYPE tt_layout_builder.

    METHODS process_event_source
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
        it_control_map TYPE tt_control_map
      CHANGING
        ct_event_sources TYPE tt_event_source_map.

    METHODS process_set_handler
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_statement   TYPE zif_mig_types=>ty_statement
        it_control_map TYPE tt_control_map
        it_event_sources TYPE tt_event_source_map
      CHANGING
        ct_events      TYPE zif_mig_types=>tt_alv_event
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS apply_layouts
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_builders    TYPE tt_layout_builder
      CHANGING
        ct_outputs     TYPE zif_mig_types=>tt_alv_output
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS parse_assignment
      IMPORTING
        iv_statement_text TYPE string
      EXPORTING
        ev_work_area      TYPE ty_identifier
        ev_component      TYPE ty_component
        ev_value          TYPE string
        ev_success        TYPE abap_bool.

    METHODS apply_layout_component
      IMPORTING
        iv_component TYPE ty_component
        iv_value     TYPE string
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        cs_builder   TYPE ty_layout_builder.

    METHODS parse_set_handler
      IMPORTING
        iv_statement_text TYPE string
      EXPORTING
        ev_handler_name   TYPE ty_handler_name
        ev_control_object TYPE ty_identifier
        ev_success        TYPE abap_bool.

    METHODS determine_event_name
      IMPORTING
        iv_handler_name TYPE ty_handler_name
      RETURNING
        VALUE(rv_event_name) TYPE ty_event_name.

    METHODS determine_handler_kind
      IMPORTING
        iv_handler_name TYPE ty_handler_name
      RETURNING
        VALUE(rv_handler_kind) TYPE ty_handler_kind.

    METHODS normalize_identifier
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE ty_identifier.

    METHODS normalize_handler
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE ty_handler_name.

    METHODS normalize_value
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS is_true_value
      IMPORTING
        iv_value TYPE string
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

CLASS zcl_mig_alv_le_analyzer IMPLEMENTATION.

  METHOD zif_mig_alv_le_analyzer~analyze.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    lv_analysis_id = iv_analysis_id.

    IF lv_analysis_id IS INITIAL.

      READ TABLE it_alv_outputs
        INDEX 1
        INTO DATA(ls_first_output).

      IF sy-subrc = 0.
        lv_analysis_id =
          ls_first_output-analysis_id.
      ENDIF.

    ENDIF.

    IF lv_analysis_id IS INITIAL.

      lv_analysis_id =
        create_uuid(
          iv_source_object = ''
        ).

    ENDIF.

    rs_result-alv_outputs =
      it_alv_outputs.

    DATA(lt_control_map) =
      build_control_map(
        it_alv_outputs = it_alv_outputs
      ).

    DATA:
      lt_layout_builders TYPE tt_layout_builder,
      lt_event_sources   TYPE tt_event_source_map.

    LOOP AT it_source_units
      ASSIGNING FIELD-SYMBOL(<source_unit>).

      analyze_source_unit(
        EXPORTING
          iv_analysis_id    = lv_analysis_id
          is_source_unit    = <source_unit>
          it_control_map    = lt_control_map
        CHANGING
          ct_layout_builders = lt_layout_builders
          ct_event_sources   = lt_event_sources
          ct_events          = rs_result-alv_events
          ct_evidences       = rs_result-evidences
      ).

    ENDLOOP.

    apply_layouts(
      EXPORTING
        iv_analysis_id = lv_analysis_id
        it_builders    = lt_layout_builders
      CHANGING
        ct_outputs     = rs_result-alv_outputs
        ct_evidences   = rs_result-evidences
    ).

    SORT rs_result-alv_events
      BY output_id
         event_name
         handler_name.

  ENDMETHOD.

    METHOD build_control_map.

    LOOP AT it_alv_outputs
      ASSIGNING FIELD-SYMBOL(<output>)
      WHERE control_object IS NOT INITIAL.

      DATA(lv_control_object) =
        CONV string(
          <output>-control_object
        ).

      INSERT VALUE #(
        control_object =
          normalize_identifier(
            iv_value = lv_control_object
          )
        output_id =
          <output>-output_id
      ) INTO TABLE rt_control_map.

    ENDLOOP.

  ENDMETHOD.

    METHOD analyze_source_unit.

    LOOP AT is_source_unit-scan_result-statements
      ASSIGNING FIELD-SYMBOL(<statement>).

      DATA(lv_text) =
        to_upper(
            <statement>-statement_text
        ).

      CONDENSE lv_text.

      "GS_LAYOUT-ZEBRA = ABAP_TRUE
      IF lv_text CS '='
         AND lv_text CS '-'.

        process_layout_assignment(
          EXPORTING
            is_statement = <statement>
          CHANGING
            ct_builders  = ct_layout_builders
        ).

      ENDIF.

      "GO_EVENTS = GO_SALV->GET_EVENT( )
      IF lv_text CS 'GET_EVENT'
         AND lv_text CS '='
         AND lv_text CS '->'.

        process_event_source(
          EXPORTING
            is_statement = <statement>
            it_control_map = it_control_map
          CHANGING
            ct_event_sources = ct_event_sources
        ).

      ENDIF.

      "SET HANDLER ... FOR ...
      IF lv_text CP 'SET HANDLER * FOR *'.

        process_set_handler(
          EXPORTING
            iv_analysis_id  = iv_analysis_id
            is_statement    = <statement>
            it_control_map  = it_control_map
            it_event_sources = ct_event_sources
          CHANGING
            ct_events       = ct_events
            ct_evidences    = ct_evidences
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD parse_assignment.

    CLEAR:
      ev_work_area,
      ev_component,
      ev_value,
      ev_success.

    IF iv_statement_text NS '='
       OR iv_statement_text NS '-'.

      RETURN.

    ENDIF.

    DATA:
      lv_left  TYPE string,
      lv_right TYPE string.

    SPLIT iv_statement_text
      AT '='
      INTO lv_left lv_right.

    CONDENSE lv_left NO-GAPS.

    DATA:
      lv_work_area_text TYPE string,
      lv_component_text TYPE string.

    SPLIT lv_left
      AT '-'
      INTO lv_work_area_text
           lv_component_text.

    ev_work_area =
      normalize_identifier(
        iv_value = lv_work_area_text
      ).

    ev_component =
      normalize_identifier(
        iv_value = lv_component_text
      ).

    ev_value =
      normalize_value(
        iv_value = lv_right
      ).

    ev_success =
      xsdbool(
        ev_work_area IS NOT INITIAL
        AND ev_component IS NOT INITIAL
      ).

  ENDMETHOD.

    METHOD process_layout_assignment.

    DATA:
      lv_work_area TYPE ty_identifier,
      lv_component TYPE ty_component,
      lv_value     TYPE string,
      lv_success   TYPE abap_bool.

    parse_assignment(
      EXPORTING
        iv_statement_text =
          is_statement-statement_text
      IMPORTING
        ev_work_area =
          lv_work_area
        ev_component =
          lv_component
        ev_value =
          lv_value
        ev_success =
          lv_success
    ).

    IF lv_success = abap_false.
      RETURN.
    ENDIF.

    CASE lv_component.

      WHEN 'ZEBRA'
        OR 'CWIDTH_OPT'
        OR 'EDIT'
        OR 'SEL_MODE'.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

    READ TABLE ct_builders
      WITH TABLE KEY
        work_area = lv_work_area
      INTO DATA(ls_builder).

    IF sy-subrc <> 0.

      ls_builder-work_area =
        lv_work_area.

      ls_builder-confidence =
        zif_mig_types=>gc_conf_high.

    ENDIF.

    apply_layout_component(
      EXPORTING
        iv_component = lv_component
        iv_value     = lv_value
        is_statement = is_statement
      CHANGING
        cs_builder   = ls_builder
    ).

    DELETE TABLE ct_builders
      WITH TABLE KEY
        work_area = lv_work_area.

    INSERT ls_builder
      INTO TABLE ct_builders.

  ENDMETHOD.

    METHOD apply_layout_component.

    IF cs_builder-source_object IS INITIAL.

      cs_builder-source_object =
        is_statement-source_object.

      cs_builder-start_line =
        is_statement-start_line.

      cs_builder-end_line =
        is_statement-end_line.

      cs_builder-statement_id =
        is_statement-statement_id.

      cs_builder-statement_text =
        is_statement-statement_text.

    ENDIF.

    CASE iv_component.

      WHEN 'ZEBRA'.

        cs_builder-zebra =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'CWIDTH_OPT'.

        cs_builder-auto_width =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'EDIT'.

        cs_builder-editable =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'SEL_MODE'.

        cs_builder-selection_mode =
          to_upper( iv_value ).

    ENDCASE.

  ENDMETHOD.

    METHOD process_event_source.

    DATA:
      lv_left  TYPE string,
      lv_right TYPE string.

    SPLIT is_statement-statement_text
      AT '='
      INTO lv_left lv_right.

    IF lv_left IS INITIAL
       OR lv_right IS INITIAL.

      RETURN.

    ENDIF.

    DATA(lv_event_source) =
      normalize_identifier(
        iv_value = lv_left
      ).

    DATA(lv_upper_right) =
      to_upper( lv_right ).

    CONDENSE lv_upper_right NO-GAPS.

    IF lv_upper_right NS '->GET_EVENT'.
      RETURN.
    ENDIF.

    DATA:
      lv_control_text TYPE string,
      lv_rest_text    TYPE string.

    SPLIT lv_upper_right
      AT '->GET_EVENT'
      INTO lv_control_text
           lv_rest_text.

    DATA(lv_control_object) =
      normalize_identifier(
        iv_value = lv_control_text
      ).

    READ TABLE it_control_map
      WITH TABLE KEY
        control_object = lv_control_object
      INTO DATA(ls_control_map).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DELETE TABLE ct_event_sources
      WITH TABLE KEY
        event_source = lv_event_source.

    INSERT VALUE #(
      event_source = lv_event_source
      output_id    = ls_control_map-output_id
    ) INTO TABLE ct_event_sources.

  ENDMETHOD.

    METHOD parse_set_handler.

    CLEAR:
      ev_handler_name,
      ev_control_object,
      ev_success.

    DATA(lv_text) =
      to_upper( iv_statement_text ).

    CONDENSE lv_text.

    IF lv_text NP 'SET HANDLER * FOR *'.
      RETURN.
    ENDIF.

    REPLACE FIRST OCCURRENCE OF
      'SET HANDLER '
      IN lv_text
      WITH ''.

    DATA:
      lv_handler_text TYPE string,
      lv_control_text TYPE string.

    SPLIT lv_text
      AT ' FOR '
      INTO lv_handler_text
           lv_control_text.

    ev_handler_name =
      normalize_handler(
        iv_value = lv_handler_text
      ).

    ev_control_object =
      normalize_identifier(
        iv_value = lv_control_text
      ).

    ev_success =
      xsdbool(
        ev_handler_name IS NOT INITIAL
        AND ev_control_object IS NOT INITIAL
      ).

  ENDMETHOD.

    METHOD process_set_handler.

    DATA:
      lv_handler_name   TYPE ty_handler_name,
      lv_control_object TYPE ty_identifier,
      lv_success        TYPE abap_bool.

    parse_set_handler(
      EXPORTING
        iv_statement_text =
          is_statement-statement_text
      IMPORTING
        ev_handler_name =
          lv_handler_name
        ev_control_object =
          lv_control_object
        ev_success =
          lv_success
    ).

    IF lv_success = abap_false.
      RETURN.
    ENDIF.

    DATA lv_output_id
      TYPE zif_mig_types=>ty_item_id.

    READ TABLE it_control_map
      WITH TABLE KEY
        control_object = lv_control_object
      INTO DATA(ls_control_map).

    IF sy-subrc = 0.

      lv_output_id =
        ls_control_map-output_id.

    ELSE.

      READ TABLE it_event_sources
        WITH TABLE KEY
          event_source = lv_control_object
        INTO DATA(ls_event_source).

      IF sy-subrc <> 0.
        RETURN.
      ENDIF.

      lv_output_id =
        ls_event_source-output_id.

    ENDIF.

    DATA(lv_event_name) =
      determine_event_name(
        iv_handler_name = lv_handler_name
      ).

    IF lv_event_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_event_id) =
      create_uuid(
        iv_source_object =
          is_statement-source_object
      ).

    DATA(lv_evidence_id) =
      create_uuid(
        iv_source_object =
          is_statement-source_object
      ).

    APPEND VALUE #(
      item_id        = lv_event_id
      analysis_id    = iv_analysis_id
      output_id      = lv_output_id
      evidence_id    = lv_evidence_id

      event_name     = lv_event_name
      handler_name   = lv_handler_name
      handler_kind   =
        determine_handler_kind(
          iv_handler_name = lv_handler_name
        )
      control_object = lv_control_object
      gui_dependency = abap_true
      confidence     = zif_mig_types=>gc_conf_high
    ) TO ct_events.

    APPEND VALUE #(
      evidence_id    = lv_evidence_id
      analysis_id    = iv_analysis_id
      source_object  = is_statement-source_object
      start_line     = is_statement-start_line
      end_line       = is_statement-end_line
      statement_id   = is_statement-statement_id
      statement_text = is_statement-statement_text
      confidence     = zif_mig_types=>gc_conf_high
    ) TO ct_evidences.

  ENDMETHOD.

    METHOD determine_event_name.

    DATA(lv_handler) =
      to_upper(
        CONV string(
          iv_handler_name
        )
      ).

    IF lv_handler CS 'DOUBLE_CLICK'.

      rv_event_name = 'DOUBLE_CLICK'.

    ELSEIF lv_handler CS 'HOTSPOT_CLICK'.

      rv_event_name = 'HOTSPOT_CLICK'.

    ELSEIF lv_handler CS 'DATA_CHANGED'.

      rv_event_name = 'DATA_CHANGED'.

    ELSEIF lv_handler CS 'USER_COMMAND'.

      rv_event_name = 'USER_COMMAND'.

    ELSEIF lv_handler CS 'TOOLBAR'.

      rv_event_name = 'TOOLBAR'.

    ENDIF.

  ENDMETHOD.


  METHOD determine_handler_kind.

    IF iv_handler_name CS '=>'.

      rv_handler_kind = 'STATIC_METHOD'.

    ELSEIF iv_handler_name CS '->'.

      rv_handler_kind = 'INSTANCE_METHOD'.

    ELSE.

      rv_handler_kind = 'UNKNOWN'.

    ENDIF.

  ENDMETHOD.

    METHOD apply_layouts.

    LOOP AT ct_outputs
      ASSIGNING FIELD-SYMBOL(<output>)
      WHERE layout_object IS NOT INITIAL.

      DATA(lv_layout_object) =
        CONV string(
          <output>-layout_object
        ).

      DATA(lv_normalized_layout) =
        normalize_identifier(
          iv_value = lv_layout_object
        ).

      READ TABLE it_builders
        WITH TABLE KEY
          work_area = lv_normalized_layout
        INTO DATA(ls_builder).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      <output>-zebra =
        ls_builder-zebra.

      <output>-auto_width =
        ls_builder-auto_width.

      <output>-editable =
        ls_builder-editable.

      <output>-selection_mode =
        ls_builder-selection_mode.

      DATA(lv_evidence_id) =
        create_uuid(
          iv_source_object =
            ls_builder-source_object
        ).

      <output>-layout_evidence_id =
        lv_evidence_id.

      APPEND VALUE #(
        evidence_id    = lv_evidence_id
        analysis_id    = iv_analysis_id
        source_object  = ls_builder-source_object
        start_line     = ls_builder-start_line
        end_line       = ls_builder-end_line
        statement_id   = ls_builder-statement_id
        statement_text = ls_builder-statement_text
        confidence     = ls_builder-confidence
      ) TO ct_evidences.

    ENDLOOP.

  ENDMETHOD.

    METHOD normalize_identifier.

    DATA lv_value TYPE string.

    lv_value = iv_value.

    CONDENSE lv_value NO-GAPS.

    IF lv_value IS NOT INITIAL
       AND lv_value+0(1) = '@'.

      lv_value =
        substring(
          val = lv_value
          off = 1
        ).

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


  METHOD normalize_handler.

    DATA lv_value TYPE string.

    lv_value = iv_value.

    CONDENSE lv_value NO-GAPS.

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


  METHOD normalize_value.

    DATA lv_value TYPE string.

    lv_value = iv_value.

    CONDENSE lv_value.

    WHILE lv_value IS NOT INITIAL.

      DATA(lv_length) =
        strlen( lv_value ).

      DATA(lv_offset) =
        lv_length - 1.

      IF lv_value+lv_offset(1) = '.'
         OR lv_value+lv_offset(1) = ','.

        lv_value =
          substring(
            val = lv_value
            len = lv_offset
          ).

        CONDENSE lv_value.

      ELSE.

        EXIT.

      ENDIF.

    ENDWHILE.

    IF strlen( lv_value ) >= 2
       AND lv_value+0(1) = ''''.

      DATA(lv_quote_length) =
        strlen( lv_value ).

      DATA(lv_quote_offset) =
        lv_quote_length - 1.

      IF lv_value+lv_quote_offset(1) = ''''.

        lv_value =
          substring(
            val = lv_value
            off = 1
            len = lv_quote_length - 2
          ).

      ENDIF.

    ENDIF.

    rv_value = lv_value.

  ENDMETHOD.


  METHOD is_true_value.

    DATA(lv_value) =
      to_upper(
        normalize_value(
          iv_value = iv_value
        )
      ).

    CASE lv_value.

      WHEN 'X'
        OR 'ABAP_TRUE'
        OR 'TRUE'
        OR '1'.

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

ENDCLASS.
