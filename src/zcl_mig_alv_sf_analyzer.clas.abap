CLASS zcl_mig_alv_sf_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_alv_sf_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_identifier  TYPE c LENGTH 80,
      ty_component   TYPE c LENGTH 40,
      ty_config_kind TYPE c LENGTH 10.

    TYPES:
      BEGIN OF ty_output_map,
        target_table TYPE ty_identifier,
        config_kind  TYPE ty_config_kind,
        output_id    TYPE zif_mig_types=>ty_item_id,
      END OF ty_output_map,

      tt_output_map TYPE SORTED TABLE OF ty_output_map
        WITH UNIQUE KEY target_table config_kind.

    TYPES:
      BEGIN OF ty_sort_builder,
        work_area     TYPE ty_identifier,
        field_name    TYPE c LENGTH 40,
        position      TYPE i,
        ascending     TYPE abap_bool,
        descending    TYPE abap_bool,
        subtotal      TYPE abap_bool,

        source_object TYPE progname,
        start_line    TYPE i,
        end_line      TYPE i,
        statement_id  TYPE i,
        statement_text TYPE string,

        confidence    TYPE zif_mig_types=>ty_confidence,
      END OF ty_sort_builder,

      tt_sort_builder TYPE HASHED TABLE OF ty_sort_builder
        WITH UNIQUE KEY work_area.

    TYPES:
      BEGIN OF ty_filter_builder,
        work_area      TYPE ty_identifier,
        field_name     TYPE c LENGTH 40,
        sign           TYPE c LENGTH 1,
        option         TYPE c LENGTH 2,
        low_value      TYPE string,
        high_value     TYPE string,

        source_object  TYPE progname,
        start_line     TYPE i,
        end_line       TYPE i,
        statement_id   TYPE i,
        statement_text TYPE string,

        confidence     TYPE zif_mig_types=>ty_confidence,
      END OF ty_filter_builder,

      tt_filter_builder TYPE HASHED TABLE OF ty_filter_builder
        WITH UNIQUE KEY work_area.

    METHODS build_output_map
      IMPORTING
        it_alv_outputs TYPE zif_mig_types=>tt_alv_output
      RETURNING
        VALUE(rt_output_map) TYPE tt_output_map.

    METHODS analyze_source_unit
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_source_unit TYPE zif_mig_types=>ty_source_unit
        it_output_map  TYPE tt_output_map
      CHANGING
        ct_sorts       TYPE zif_mig_types=>tt_alv_sort
        ct_filters     TYPE zif_mig_types=>tt_alv_filter
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS process_clear
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        ct_sort_builders   TYPE tt_sort_builder
        ct_filter_builders TYPE tt_filter_builder.

    METHODS process_assignment
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        ct_sort_builders   TYPE tt_sort_builder
        ct_filter_builders TYPE tt_filter_builder.

    METHODS process_append
      IMPORTING
        iv_analysis_id    TYPE zif_mig_types=>ty_analysis_id
        is_statement      TYPE zif_mig_types=>ty_statement
        it_output_map     TYPE tt_output_map
        it_sort_builders  TYPE tt_sort_builder
        it_filter_builders TYPE tt_filter_builder
      CHANGING
        ct_sorts          TYPE zif_mig_types=>tt_alv_sort
        ct_filters        TYPE zif_mig_types=>tt_alv_filter
        ct_evidences      TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS apply_sort_component
      IMPORTING
        iv_component TYPE ty_component
        iv_value     TYPE string
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        cs_builder   TYPE ty_sort_builder.

    METHODS apply_filter_component
      IMPORTING
        iv_component TYPE ty_component
        iv_value     TYPE string
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        cs_builder   TYPE ty_filter_builder.

    METHODS parse_assignment
      IMPORTING
        iv_statement_text TYPE string
      EXPORTING
        ev_work_area      TYPE ty_identifier
        ev_component      TYPE ty_component
        ev_value          TYPE string
        ev_success        TYPE abap_bool.

    METHODS parse_append
      IMPORTING
        iv_statement_text TYPE string
      EXPORTING
        ev_work_area      TYPE ty_identifier
        ev_target_table   TYPE ty_identifier
        ev_success        TYPE abap_bool.

    METHODS normalize_identifier
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE ty_identifier.

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

CLASS zcl_mig_alv_sf_analyzer IMPLEMENTATION.

  METHOD zif_mig_alv_sf_analyzer~analyze.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    lv_analysis_id = iv_analysis_id.

    IF lv_analysis_id IS INITIAL.

      READ TABLE it_alv_outputs
        INDEX 1
        INTO DATA(ls_first_output).

      IF sy-subrc = 0.
        lv_analysis_id = ls_first_output-analysis_id.
      ENDIF.

    ENDIF.

    IF lv_analysis_id IS INITIAL.

      lv_analysis_id =
        create_uuid(
          iv_source_object = ''
        ).

    ENDIF.

    DATA(lt_output_map) =
      build_output_map(
        it_alv_outputs = it_alv_outputs
      ).

    LOOP AT it_source_units
      ASSIGNING FIELD-SYMBOL(<source_unit>).

      analyze_source_unit(
        EXPORTING
          iv_analysis_id = lv_analysis_id
          is_source_unit = <source_unit>
          it_output_map  = lt_output_map
        CHANGING
          ct_sorts       = rs_result-alv_sorts
          ct_filters     = rs_result-alv_filters
          ct_evidences   = rs_result-evidences
      ).

    ENDLOOP.

    SORT rs_result-alv_sorts
      BY output_id
         position
         field_name.

    SORT rs_result-alv_filters
      BY output_id
         field_name
         sign
         option.

  ENDMETHOD.

    METHOD build_output_map.

    LOOP AT it_alv_outputs
      ASSIGNING FIELD-SYMBOL(<output>).

      IF <output>-sort_table IS NOT INITIAL.

        DATA(lv_sort_table) =
          CONV string( <output>-sort_table ).

        INSERT VALUE #(
          target_table =
            normalize_identifier(
              iv_value = lv_sort_table
            )
          config_kind = 'SORT'
          output_id   = <output>-output_id
        ) INTO TABLE rt_output_map.

      ENDIF.

      IF <output>-filter_table IS NOT INITIAL.

        DATA(lv_filter_table) =
          CONV string( <output>-filter_table ).

        INSERT VALUE #(
          target_table =
            normalize_identifier(
              iv_value = lv_filter_table
            )
          config_kind = 'FILTER'
          output_id   = <output>-output_id
        ) INTO TABLE rt_output_map.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD analyze_source_unit.

    DATA:
      lt_sort_builders   TYPE tt_sort_builder,
      lt_filter_builders TYPE tt_filter_builder.

    LOOP AT is_source_unit-scan_result-statements
      ASSIGNING FIELD-SYMBOL(<statement>).

      DATA(lv_text) =
        to_upper(
            <statement>-statement_text
        ).

      CONDENSE lv_text.

      IF lv_text CP 'CLEAR *'.

        process_clear(
          EXPORTING
            is_statement       = <statement>
          CHANGING
            ct_sort_builders   = lt_sort_builders
            ct_filter_builders = lt_filter_builders
        ).

        CONTINUE.

      ENDIF.

      IF lv_text CP 'APPEND * TO *'.

        process_append(
          EXPORTING
            iv_analysis_id     = iv_analysis_id
            is_statement       = <statement>
            it_output_map      = it_output_map
            it_sort_builders   = lt_sort_builders
            it_filter_builders = lt_filter_builders
          CHANGING
            ct_sorts           = ct_sorts
            ct_filters         = ct_filters
            ct_evidences       = ct_evidences
        ).

        CONTINUE.

      ENDIF.

      IF lv_text CS '='
         AND lv_text CS '-'.

        process_assignment(
          EXPORTING
            is_statement       = <statement>
          CHANGING
            ct_sort_builders   = lt_sort_builders
            ct_filter_builders = lt_filter_builders
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD process_clear.

    DATA lt_words TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.

    SPLIT is_statement-statement_text
      AT space
      INTO TABLE lt_words.

    READ TABLE lt_words
      INDEX 2
      INTO DATA(lv_work_area).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(lv_normalized) =
      normalize_identifier(
        iv_value = lv_work_area
      ).

    IF lv_normalized IS INITIAL.
      RETURN.
    ENDIF.

    DELETE TABLE ct_sort_builders
      WITH TABLE KEY
        work_area = lv_normalized.

    DELETE TABLE ct_filter_builders
      WITH TABLE KEY
        work_area = lv_normalized.

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

    METHOD process_assignment.

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

      "LVC_S_SORT / SLIS_SORTINFO_ALV
      WHEN 'SPOS'
        OR 'UP'
        OR 'DOWN'
        OR 'SUBTOT'.

        READ TABLE ct_sort_builders
          WITH TABLE KEY
            work_area = lv_work_area
          INTO DATA(ls_sort_builder).

        IF sy-subrc <> 0.

          ls_sort_builder-work_area =
            lv_work_area.

          ls_sort_builder-confidence =
            zif_mig_types=>gc_conf_high.

        ENDIF.

        apply_sort_component(
          EXPORTING
            iv_component = lv_component
            iv_value     = lv_value
            is_statement = is_statement
          CHANGING
            cs_builder   = ls_sort_builder
        ).

        DELETE TABLE ct_sort_builders
          WITH TABLE KEY
            work_area = lv_work_area.

        INSERT ls_sort_builder
          INTO TABLE ct_sort_builders.

      "LVC_S_FILT
      WHEN 'SIGN'
        OR 'OPTION'
        OR 'LOW'
        OR 'HIGH'.

        READ TABLE ct_filter_builders
          WITH TABLE KEY
            work_area = lv_work_area
          INTO DATA(ls_filter_builder).

        IF sy-subrc <> 0.

          ls_filter_builder-work_area =
            lv_work_area.

          ls_filter_builder-confidence =
            zif_mig_types=>gc_conf_high.

        ENDIF.

        apply_filter_component(
          EXPORTING
            iv_component = lv_component
            iv_value     = lv_value
            is_statement = is_statement
          CHANGING
            cs_builder   = ls_filter_builder
        ).

        DELETE TABLE ct_filter_builders
          WITH TABLE KEY
            work_area = lv_work_area.

        INSERT ls_filter_builder
          INTO TABLE ct_filter_builders.

      WHEN 'FIELDNAME'.

        "FIELDNAME tồn tại trong cả sort và filter.
        "Cập nhật cả hai builder; APPEND target sẽ quyết định loại fact.

        READ TABLE ct_sort_builders
          WITH TABLE KEY
            work_area = lv_work_area
          INTO ls_sort_builder.

        IF sy-subrc <> 0.

          ls_sort_builder-work_area =
            lv_work_area.

          ls_sort_builder-confidence =
            zif_mig_types=>gc_conf_high.

        ENDIF.

        apply_sort_component(
          EXPORTING
            iv_component = lv_component
            iv_value     = lv_value
            is_statement = is_statement
          CHANGING
            cs_builder   = ls_sort_builder
        ).

        DELETE TABLE ct_sort_builders
          WITH TABLE KEY
            work_area = lv_work_area.

        INSERT ls_sort_builder
          INTO TABLE ct_sort_builders.


        READ TABLE ct_filter_builders
          WITH TABLE KEY
            work_area = lv_work_area
          INTO ls_filter_builder.

        IF sy-subrc <> 0.

          ls_filter_builder-work_area =
            lv_work_area.

          ls_filter_builder-confidence =
            zif_mig_types=>gc_conf_high.

        ENDIF.

        apply_filter_component(
          EXPORTING
            iv_component = lv_component
            iv_value     = lv_value
            is_statement = is_statement
          CHANGING
            cs_builder   = ls_filter_builder
        ).

        DELETE TABLE ct_filter_builders
          WITH TABLE KEY
            work_area = lv_work_area.

        INSERT ls_filter_builder
          INTO TABLE ct_filter_builders.

    ENDCASE.

  ENDMETHOD.

    METHOD apply_sort_component.

    CASE iv_component.

      WHEN 'FIELDNAME'.

        cs_builder-field_name =
          to_upper( iv_value ).

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

      WHEN 'SPOS'.

        TRY.

            cs_builder-position =
              CONV i( iv_value ).

          CATCH cx_sy_conversion_no_number.

            cs_builder-confidence =
              zif_mig_types=>gc_conf_medium.

        ENDTRY.

      WHEN 'UP'.

        cs_builder-ascending =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'DOWN'.

        cs_builder-descending =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'SUBTOT'.

        cs_builder-subtotal =
          is_true_value(
            iv_value = iv_value
          ).

    ENDCASE.

  ENDMETHOD.

    METHOD apply_filter_component.

    CASE iv_component.

      WHEN 'FIELDNAME'.

        cs_builder-field_name =
          to_upper( iv_value ).

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

      WHEN 'SIGN'.

        cs_builder-sign =
          to_upper( iv_value ).

      WHEN 'OPTION'.

        cs_builder-option =
          to_upper( iv_value ).

      WHEN 'LOW'.

        cs_builder-low_value =
          iv_value.

      WHEN 'HIGH'.

        cs_builder-high_value =
          iv_value.

    ENDCASE.

  ENDMETHOD.

    METHOD parse_append.

    CLEAR:
      ev_work_area,
      ev_target_table,
      ev_success.

    DATA(lv_text) =
      to_upper( iv_statement_text ).

    CONDENSE lv_text.

    WHILE lv_text IS NOT INITIAL.

      DATA(lv_length) =
        strlen( lv_text ).

      DATA(lv_offset) =
        lv_length - 1.

      IF lv_text+lv_offset(1) = '.'.

        lv_text =
          substring(
            val = lv_text
            len = lv_offset
          ).

        CONDENSE lv_text.

      ELSE.

        EXIT.

      ENDIF.

    ENDWHILE.

    IF lv_text NP 'APPEND * TO *'.
      RETURN.
    ENDIF.

    REPLACE FIRST OCCURRENCE OF 'APPEND '
      IN lv_text
      WITH ''.

    DATA:
      lv_work_area_text TYPE string,
      lv_target_text    TYPE string.

    SPLIT lv_text
      AT ' TO '
      INTO lv_work_area_text
           lv_target_text.

    IF lv_target_text CP 'TABLE *'.

      REPLACE FIRST OCCURRENCE OF 'TABLE '
        IN lv_target_text
        WITH ''.

    ENDIF.

    ev_work_area =
      normalize_identifier(
        iv_value = lv_work_area_text
      ).

    ev_target_table =
      normalize_identifier(
        iv_value = lv_target_text
      ).

    ev_success =
      xsdbool(
        ev_work_area IS NOT INITIAL
        AND ev_target_table IS NOT INITIAL
      ).

  ENDMETHOD.

    METHOD process_append.

    DATA:
      lv_work_area   TYPE ty_identifier,
      lv_target_table TYPE ty_identifier,
      lv_success     TYPE abap_bool.

    parse_append(
      EXPORTING
        iv_statement_text =
          is_statement-statement_text
      IMPORTING
        ev_work_area =
          lv_work_area
        ev_target_table =
          lv_target_table
        ev_success =
          lv_success
    ).

    IF lv_success = abap_false.
      RETURN.
    ENDIF.

    "========================================================
    " SORT
    "========================================================
    READ TABLE it_output_map
      WITH TABLE KEY
        target_table = lv_target_table
        config_kind  = 'SORT'
      INTO DATA(ls_sort_map).

    IF sy-subrc = 0.

      READ TABLE it_sort_builders
        WITH TABLE KEY
          work_area = lv_work_area
        INTO DATA(ls_sort_builder).

      IF sy-subrc <> 0
         OR ls_sort_builder-field_name IS INITIAL.

        RETURN.

      ENDIF.

      "Nếu không chỉ định UP/DOWN, mặc định ALV sort tăng dần
      IF ls_sort_builder-ascending = abap_false
         AND ls_sort_builder-descending = abap_false.

        ls_sort_builder-ascending =
          abap_true.

      ENDIF.

      DATA(lv_sort_id) =
        create_uuid(
          iv_source_object =
            ls_sort_builder-source_object
        ).

      DATA(lv_sort_evidence_id) =
        create_uuid(
          iv_source_object =
            ls_sort_builder-source_object
        ).

      APPEND VALUE #(
        item_id     = lv_sort_id
        analysis_id = iv_analysis_id
        output_id   = ls_sort_map-output_id
        evidence_id = lv_sort_evidence_id

        field_name  = ls_sort_builder-field_name
        position    = ls_sort_builder-position
        ascending   = ls_sort_builder-ascending
        descending  = ls_sort_builder-descending
        subtotal    = ls_sort_builder-subtotal
        confidence  = ls_sort_builder-confidence
      ) TO ct_sorts.

      APPEND VALUE #(
        evidence_id    = lv_sort_evidence_id
        analysis_id    = iv_analysis_id
        source_object  = ls_sort_builder-source_object
        start_line     = ls_sort_builder-start_line
        end_line       = ls_sort_builder-end_line
        statement_id   = ls_sort_builder-statement_id
        statement_text = ls_sort_builder-statement_text
        confidence     = ls_sort_builder-confidence
      ) TO ct_evidences.

      RETURN.

    ENDIF.

    "========================================================
    " FILTER
    "========================================================
    READ TABLE it_output_map
      WITH TABLE KEY
        target_table = lv_target_table
        config_kind  = 'FILTER'
      INTO DATA(ls_filter_map).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    READ TABLE it_filter_builders
      WITH TABLE KEY
        work_area = lv_work_area
      INTO DATA(ls_filter_builder).

    IF sy-subrc <> 0
       OR ls_filter_builder-field_name IS INITIAL.

      RETURN.

    ENDIF.

    IF ls_filter_builder-sign IS INITIAL.
      ls_filter_builder-sign = 'I'.
    ENDIF.

    IF ls_filter_builder-option IS INITIAL.
      ls_filter_builder-option = 'EQ'.
    ENDIF.

    DATA(lv_filter_id) =
      create_uuid(
        iv_source_object =
          ls_filter_builder-source_object
      ).

    DATA(lv_filter_evidence_id) =
      create_uuid(
        iv_source_object =
          ls_filter_builder-source_object
      ).

    APPEND VALUE #(
      item_id     = lv_filter_id
      analysis_id = iv_analysis_id
      output_id   = ls_filter_map-output_id
      evidence_id = lv_filter_evidence_id

      field_name  = ls_filter_builder-field_name
      sign        = ls_filter_builder-sign
      option      = ls_filter_builder-option
      low_value   = ls_filter_builder-low_value
      high_value  = ls_filter_builder-high_value
      confidence  = ls_filter_builder-confidence
    ) TO ct_filters.

    APPEND VALUE #(
      evidence_id    = lv_filter_evidence_id
      analysis_id    = iv_analysis_id
      source_object  = ls_filter_builder-source_object
      start_line     = ls_filter_builder-start_line
      end_line       = ls_filter_builder-end_line
      statement_id   = ls_filter_builder-statement_id
      statement_text = ls_filter_builder-statement_text
      confidence     = ls_filter_builder-confidence
    ) TO ct_evidences.

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

      DATA(lv_last_quote_offset) =
        lv_quote_length - 1.

      IF lv_value+lv_last_quote_offset(1) = ''''.

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
