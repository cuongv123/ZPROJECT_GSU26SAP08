CLASS zcl_mig_alv_fcat_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_alv_fcat_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_identifier TYPE c LENGTH 80,
      ty_component  TYPE c LENGTH 40.

    TYPES:
      BEGIN OF ty_output_map,
        field_catalog TYPE ty_identifier,
        output_id     TYPE zif_mig_types=>ty_item_id,
      END OF ty_output_map,

      tt_output_map TYPE SORTED TABLE OF ty_output_map
        WITH NON-UNIQUE KEY field_catalog.

    TYPES:
      BEGIN OF ty_column_builder,
        work_area       TYPE ty_identifier,

        field_name      TYPE c LENGTH 40,
        label           TYPE c LENGTH 120,
        position        TYPE i,
        data_type       TYPE c LENGTH 30,
        data_element    TYPE c LENGTH 30,
        reference_table TYPE c LENGTH 30,
        reference_field TYPE c LENGTH 30,
        length          TYPE i,
        decimals        TYPE i,

        visible         TYPE abap_bool,
        key_field       TYPE abap_bool,
        technical       TYPE abap_bool,
        editable        TYPE abap_bool,
        hotspot         TYPE abap_bool,
        checkbox        TYPE abap_bool,
        icon            TYPE abap_bool,

        currency_field  TYPE c LENGTH 40,
        unit_field      TYPE c LENGTH 40,
        aggregation     TYPE c LENGTH 20,

        source_object   TYPE progname,
        start_line      TYPE i,
        end_line        TYPE i,
        statement_id    TYPE i,
        statement_text  TYPE string,

        confidence      TYPE zif_mig_types=>ty_confidence,
      END OF ty_column_builder,

      tt_column_builder TYPE HASHED TABLE OF ty_column_builder
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
        ct_columns     TYPE zif_mig_types=>tt_alv_column
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS process_clear
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        ct_builders  TYPE tt_column_builder.

    METHODS process_assignment
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        ct_builders  TYPE tt_column_builder.

    METHODS process_append
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_statement   TYPE zif_mig_types=>ty_statement
        it_output_map  TYPE tt_output_map
        it_builders    TYPE tt_column_builder
      CHANGING
        ct_columns     TYPE zif_mig_types=>tt_alv_column
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

    METHODS apply_component
      IMPORTING
        iv_component TYPE ty_component
        iv_value     TYPE string
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        cs_builder   TYPE ty_column_builder.

    METHODS parse_append
      IMPORTING
        iv_statement_text TYPE string
      EXPORTING
        ev_work_area      TYPE ty_identifier
        ev_catalog_table  TYPE ty_identifier
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

CLASS zcl_mig_alv_fcat_analyzer IMPLEMENTATION.

  METHOD zif_mig_alv_fcat_analyzer~analyze.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    lv_analysis_id = iv_analysis_id.

    "Nếu không truyền Analysis ID, dùng ID của ALV Output đã có
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
          ct_columns     = rs_result-alv_columns
          ct_evidences   = rs_result-evidences
      ).

    ENDLOOP.

    SORT rs_result-alv_columns
      BY output_id
         position
         field_name.

  ENDMETHOD.

     METHOD build_output_map.

      LOOP AT it_alv_outputs
        ASSIGNING FIELD-SYMBOL(<output>)
        WHERE field_catalog IS NOT INITIAL.

        DATA(lv_field_catalog) =
          CONV string( <output>-field_catalog ).

        INSERT VALUE #(
          field_catalog =
            normalize_identifier(
              iv_value = lv_field_catalog
            )
          output_id =
            <output>-output_id
        ) INTO TABLE rt_output_map.

      ENDLOOP.

    ENDMETHOD.

METHOD analyze_source_unit.

  DATA lt_builders TYPE tt_column_builder.

  LOOP AT is_source_unit-scan_result-statements
    ASSIGNING FIELD-SYMBOL(<statement>).

    DATA(lv_statement_text) =
      to_upper(
          <statement>-statement_text
      ).

    CONDENSE lv_statement_text.

    "========================================================
    " CLEAR GS_FIELDCAT
    "========================================================
    IF lv_statement_text CP 'CLEAR *'.

      process_clear(
        EXPORTING
          is_statement = <statement>
        CHANGING
          ct_builders  = lt_builders
      ).

      CONTINUE.

    ENDIF.

    "========================================================
    " APPEND GS_FIELDCAT TO GT_FIELDCAT
    "========================================================
    IF lv_statement_text CP 'APPEND * TO *'.

      process_append(
        EXPORTING
          iv_analysis_id = iv_analysis_id
          is_statement   = <statement>
          it_output_map  = it_output_map
          it_builders    = lt_builders
        CHANGING
          ct_columns     = ct_columns
          ct_evidences   = ct_evidences
      ).

      CONTINUE.

    ENDIF.

    "========================================================
    " GS_FIELDCAT-FIELDNAME = 'ITEM_ID'
    "========================================================
    IF lv_statement_text CS '='
       AND lv_statement_text CS '-'.

      process_assignment(
        EXPORTING
          is_statement = <statement>
        CHANGING
          ct_builders  = lt_builders
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

    DATA(lv_normalized_work_area) =
      normalize_identifier(
        iv_value = lv_work_area
      ).

    IF lv_normalized_work_area IS INITIAL.
      RETURN.
    ENDIF.

    DELETE TABLE ct_builders
      WITH TABLE KEY
        work_area = lv_normalized_work_area.

    INSERT VALUE #(
      work_area  = lv_normalized_work_area
      visible    = abap_true
      confidence = zif_mig_types=>gc_conf_high
    ) INTO TABLE ct_builders.

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

    READ TABLE ct_builders
      WITH TABLE KEY
        work_area = lv_work_area
      INTO DATA(ls_builder).

    IF sy-subrc <> 0.

      ls_builder-work_area =
        lv_work_area.

      ls_builder-visible =
        abap_true.

      ls_builder-confidence =
        zif_mig_types=>gc_conf_high.

    ENDIF.

    apply_component(
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

    IF lv_left NS '-'.
      RETURN.
    ENDIF.

    DATA:
      lv_work_area_text TYPE string,
      lv_component_text TYPE string.

    SPLIT lv_left
      AT '-'
      INTO lv_work_area_text lv_component_text.

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

    METHOD apply_component.

    CASE iv_component.

      WHEN 'FIELDNAME'.

        cs_builder-field_name =
          to_upper( iv_value ).

        "FIELDNAME assignment là evidence chính của column
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

      WHEN 'COLTEXT'
        OR 'SELTEXT_L'
        OR 'SCRTEXT_L'.

        cs_builder-label =
          iv_value.

      WHEN 'COL_POS'.

        TRY.

            cs_builder-position =
              CONV i( iv_value ).

          CATCH cx_sy_conversion_no_number.
            cs_builder-confidence =
              zif_mig_types=>gc_conf_medium.

        ENDTRY.

      WHEN 'DATATYPE'.

        cs_builder-data_type =
          to_upper( iv_value ).

      WHEN 'ROLLNAME'.

        cs_builder-data_element =
          to_upper( iv_value ).

      WHEN 'REF_TABLE'
        OR 'REF_TABLE_LVC'.

        cs_builder-reference_table =
          to_upper( iv_value ).

      WHEN 'REF_FIELD'
        OR 'REF_FIELD_LVC'.

        cs_builder-reference_field =
          to_upper( iv_value ).

      WHEN 'INTLEN'
        OR 'OUTPUTLEN'.

        TRY.

            cs_builder-length =
              CONV i( iv_value ).

          CATCH cx_sy_conversion_no_number.
            cs_builder-confidence =
              zif_mig_types=>gc_conf_medium.

        ENDTRY.

      WHEN 'DECIMALS'
        OR 'DECIMALS_O'.

        TRY.

            cs_builder-decimals =
              CONV i( iv_value ).

          CATCH cx_sy_conversion_no_number.
            cs_builder-confidence =
              zif_mig_types=>gc_conf_medium.

        ENDTRY.

      WHEN 'KEY'.

        cs_builder-key_field =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'NO_OUT'.

        IF is_true_value(
             iv_value = iv_value
           ) = abap_true.

          cs_builder-visible =
            abap_false.

        ENDIF.

      WHEN 'TECH'.

        cs_builder-technical =
          is_true_value(
            iv_value = iv_value
          ).

        IF cs_builder-technical = abap_true.
          cs_builder-visible = abap_false.
        ENDIF.

      WHEN 'EDIT'.

        cs_builder-editable =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'HOTSPOT'.

        cs_builder-hotspot =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'CHECKBOX'.

        cs_builder-checkbox =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'ICON'.

        cs_builder-icon =
          is_true_value(
            iv_value = iv_value
          ).

      WHEN 'DO_SUM'.

        IF is_true_value(
             iv_value = iv_value
           ) = abap_true.

          cs_builder-aggregation =
            'SUM'.

        ENDIF.

      WHEN 'CFIELDNAME'.

        cs_builder-currency_field =
          to_upper( iv_value ).

      WHEN 'QFIELDNAME'.

        cs_builder-unit_field =
          to_upper( iv_value ).

    ENDCASE.

  ENDMETHOD.

    METHOD process_append.

    DATA:
      lv_work_area     TYPE ty_identifier,
      lv_catalog_table TYPE ty_identifier,
      lv_success       TYPE abap_bool.

    parse_append(
      EXPORTING
        iv_statement_text =
          is_statement-statement_text
      IMPORTING
        ev_work_area =
          lv_work_area
        ev_catalog_table =
          lv_catalog_table
        ev_success =
          lv_success
    ).

    IF lv_success = abap_false.
      RETURN.
    ENDIF.

    READ TABLE it_builders
      WITH TABLE KEY
        work_area = lv_work_area
      INTO DATA(ls_builder).

    IF sy-subrc <> 0
       OR ls_builder-field_name IS INITIAL.

      RETURN.

    ENDIF.

    READ TABLE it_output_map
      WITH KEY
        field_catalog = lv_catalog_table
      INTO DATA(ls_output_map).

    IF sy-subrc <> 0.

      "Đây không phải field catalog của ALV đã phát hiện
      RETURN.

    ENDIF.

    DATA(lv_item_id) =
      create_uuid(
        iv_source_object =
          ls_builder-source_object
      ).

    DATA(lv_evidence_id) =
      create_uuid(
        iv_source_object =
          ls_builder-source_object
      ).

    APPEND VALUE #(
      item_id         = lv_item_id
      analysis_id     = iv_analysis_id
      output_id       = ls_output_map-output_id
      evidence_id     = lv_evidence_id

      field_name      = ls_builder-field_name
      label           = ls_builder-label
      position        = ls_builder-position
      data_type       = ls_builder-data_type
      data_element    = ls_builder-data_element
      reference_table = ls_builder-reference_table
      reference_field = ls_builder-reference_field
      length          = ls_builder-length
      decimals        = ls_builder-decimals

      visible         = ls_builder-visible
      key_field       = ls_builder-key_field
      technical       = ls_builder-technical
      editable        = ls_builder-editable
      hotspot         = ls_builder-hotspot
      checkbox        = ls_builder-checkbox
      icon            = ls_builder-icon

      currency_field  = ls_builder-currency_field
      unit_field      = ls_builder-unit_field
      aggregation     = ls_builder-aggregation
      source_mapping  = ''
      confidence      = ls_builder-confidence
    ) TO ct_columns.

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

  ENDMETHOD.

METHOD parse_append.

  CLEAR:
    ev_work_area,
    ev_catalog_table,
    ev_success.

  DATA lt_words TYPE STANDARD TABLE OF string
    WITH EMPTY KEY.

  DATA(lv_statement_text) =
    iv_statement_text.

  CONDENSE lv_statement_text.

  SPLIT lv_statement_text
    AT space
    INTO TABLE lt_words.

  READ TABLE lt_words
    INDEX 1
    INTO DATA(lv_append).

  READ TABLE lt_words
    INDEX 2
    INTO DATA(lv_work_area).

  READ TABLE lt_words
    INDEX 3
    INTO DATA(lv_to).

  READ TABLE lt_words
    INDEX 4
    INTO DATA(lv_catalog_table).

  IF to_upper( lv_append ) <> 'APPEND'
     OR to_upper( lv_to ) <> 'TO'.

    RETURN.

  ENDIF.

  "Hỗ trợ APPEND ... TO TABLE ...
  IF to_upper( lv_catalog_table ) = 'TABLE'.

    READ TABLE lt_words
      INDEX 5
      INTO lv_catalog_table.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

  ENDIF.

  ev_work_area =
    normalize_identifier(
      iv_value = lv_work_area
    ).

  ev_catalog_table =
    normalize_identifier(
      iv_value = lv_catalog_table
    ).

  ev_success =
    xsdbool(
      ev_work_area IS NOT INITIAL
      AND ev_catalog_table IS NOT INITIAL
    ).

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

      DATA(lv_last_char) =
        substring(
          val = lv_value
          off = lv_offset
          len = 1
        ).

      IF lv_last_char = '.'
         OR lv_last_char = ','.

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
