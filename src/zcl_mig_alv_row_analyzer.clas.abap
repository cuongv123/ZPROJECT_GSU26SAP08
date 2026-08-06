CLASS zcl_mig_alv_row_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_alv_fcat_analyzer.

  PRIVATE SECTION.

    TYPES:
      ty_identifier TYPE c LENGTH 80.

    TYPES:
      BEGIN OF ty_table_type,
        type_name TYPE ty_identifier,
        row_type  TYPE ty_identifier,
      END OF ty_table_type,

      tt_table_type TYPE HASHED TABLE OF ty_table_type
        WITH UNIQUE KEY type_name.

    TYPES:
      BEGIN OF ty_data_decl,
        variable_name TYPE ty_identifier,
        type_name     TYPE ty_identifier,
        row_type      TYPE ty_identifier,
      END OF ty_data_decl,

      tt_data_decl TYPE HASHED TABLE OF ty_data_decl
        WITH UNIQUE KEY variable_name.

    TYPES:
      BEGIN OF ty_component,
        struct_name    TYPE ty_identifier,
        field_name     TYPE c LENGTH 40,
        type_ref       TYPE ty_identifier,
        position       TYPE i,

        label           TYPE c LENGTH 120,
        data_type       TYPE c LENGTH 30,
        data_element    TYPE c LENGTH 30,
        reference_table TYPE c LENGTH 30,
        reference_field TYPE c LENGTH 30,
        field_length    TYPE i,
        decimals        TYPE i,

        source_object   TYPE progname,
        start_line      TYPE i,
        end_line        TYPE i,
        statement_id    TYPE i,
        statement_text  TYPE string,
      END OF ty_component,

      tt_component TYPE SORTED TABLE OF ty_component
        WITH NON-UNIQUE KEY struct_name position field_name.

    METHODS collect_declarations
      IMPORTING
        it_source_units TYPE zif_mig_types=>tt_source_unit
      EXPORTING
        et_table_types  TYPE tt_table_type
        et_data_decls   TYPE tt_data_decl
        et_components   TYPE tt_component.

    METHODS parse_types_statement
      IMPORTING
        is_statement   TYPE zif_mig_types=>ty_statement
      CHANGING
        ct_table_types TYPE tt_table_type
        ct_components  TYPE tt_component.

    METHODS parse_data_statement
      IMPORTING
        is_statement TYPE zif_mig_types=>ty_statement
      CHANGING
        ct_data_decls TYPE tt_data_decl.

    METHODS resolve_output_row_type
      IMPORTING
        iv_output_table TYPE ty_identifier
        it_table_types  TYPE tt_table_type
        it_data_decls   TYPE tt_data_decl
      RETURNING
        VALUE(rv_row_type) TYPE ty_identifier.

    METHODS append_local_columns
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_output      TYPE zif_mig_types=>ty_alv_output
        iv_row_type    TYPE ty_identifier
        it_components  TYPE tt_component
      CHANGING
        ct_columns     TYPE zif_mig_types=>tt_alv_column
        ct_evidences   TYPE zif_mig_types=>tt_evidence
      RAISING
        zcx_mig_analysis.

    METHODS normalize_statement
      IMPORTING
        iv_text TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS normalize_identifier
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE ty_identifier.

    METHODS get_first_word
      IMPORTING
        iv_text TYPE string
      RETURNING
        VALUE(rv_word) TYPE string.

    METHODS extract_row_type
      IMPORTING
        iv_type_expression TYPE string
      RETURNING
        VALUE(rv_row_type) TYPE ty_identifier.

    METHODS fill_component_metadata
      IMPORTING
        iv_type_expression TYPE string
      CHANGING
        cs_component TYPE ty_component.

    METHODS fill_ddic_field_metadata
      IMPORTING
        iv_table TYPE tabname
        iv_field TYPE fieldname
      CHANGING
        cs_component TYPE ty_component.

    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

ENDCLASS.


CLASS zcl_mig_alv_row_analyzer IMPLEMENTATION.

  METHOD zif_mig_alv_fcat_analyzer~analyze.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    lv_analysis_id =
      iv_analysis_id.


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


    DATA:
      lt_table_types TYPE tt_table_type,
      lt_data_decls  TYPE tt_data_decl,
      lt_components  TYPE tt_component.


    collect_declarations(
      EXPORTING
        it_source_units = it_source_units
      IMPORTING
        et_table_types  = lt_table_types
        et_data_decls   = lt_data_decls
        et_components   = lt_components
    ).


    LOOP AT it_alv_outputs
      INTO DATA(ls_output)
      WHERE field_catalog IS INITIAL
        AND output_table IS NOT INITIAL.


      DATA(lv_output_table) =
        normalize_identifier(
          iv_value =
            CONV string(
              ls_output-output_table
            )
        ).


      DATA(lv_row_type) =
        resolve_output_row_type(
          iv_output_table = lv_output_table
          it_table_types  = lt_table_types
          it_data_decls   = lt_data_decls
        ).


      IF lv_row_type IS INITIAL.

        CONTINUE.

      ENDIF.


      append_local_columns(
        EXPORTING
          iv_analysis_id = lv_analysis_id
          is_output      = ls_output
          iv_row_type    = lv_row_type
          it_components  = lt_components
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


  METHOD collect_declarations.

    CLEAR:
      et_table_types,
      et_data_decls,
      et_components.


    LOOP AT it_source_units
      ASSIGNING FIELD-SYMBOL(<source_unit>).


      LOOP AT <source_unit>-scan_result-statements
        ASSIGNING FIELD-SYMBOL(<statement>).


        DATA(lv_statement_text) =
          normalize_statement(
            iv_text =
              <statement>-statement_text
          ).


        IF lv_statement_text CP 'TYPES*'.

          parse_types_statement(
            EXPORTING
              is_statement   = <statement>
            CHANGING
              ct_table_types = et_table_types
              ct_components  = et_components
          ).

        ELSEIF lv_statement_text CP 'DATA*'.

          parse_data_statement(
            EXPORTING
              is_statement = <statement>
            CHANGING
              ct_data_decls = et_data_decls
          ).

        ENDIF.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD parse_types_statement.

    DATA(lv_text) =
      normalize_statement(
        iv_text =
          is_statement-statement_text
      ).


    REPLACE FIRST OCCURRENCE OF 'TYPES'
      IN lv_text
      WITH ''.

    CONDENSE lv_text.


    IF lv_text IS NOT INITIAL
       AND lv_text+0(1) = ':'.

      lv_text =
        substring(
          val = lv_text
          off = 1
        ).

      CONDENSE lv_text.

    ENDIF.


    DATA lt_segments
      TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.


    SPLIT lv_text
      AT ','
      INTO TABLE lt_segments.


    DATA:
      lv_current_structure TYPE ty_identifier,
      lv_position          TYPE i.


    LOOP AT lt_segments
      INTO DATA(lv_segment).


      CONDENSE lv_segment.


      IF lv_segment IS INITIAL.

        CONTINUE.

      ENDIF.


      IF lv_segment CP 'BEGIN OF *'.

        DATA(lv_begin_text) =
          lv_segment.

        REPLACE FIRST OCCURRENCE OF 'BEGIN OF'
          IN lv_begin_text
          WITH ''.

        CONDENSE lv_begin_text.


        lv_current_structure =
          normalize_identifier(
            iv_value =
              get_first_word(
                iv_text = lv_begin_text
              )
          ).


        CLEAR lv_position.

        CONTINUE.

      ENDIF.


      IF lv_segment CP 'END OF *'.

        CLEAR:
          lv_current_structure,
          lv_position.

        CONTINUE.

      ENDIF.


      IF lv_current_structure IS NOT INITIAL.

        IF lv_segment NS ' TYPE '.

          CONTINUE.

        ENDIF.


        DATA:
          lv_field_left       TYPE string,
          lv_type_expression  TYPE string.


        SPLIT lv_segment
          AT ' TYPE '
          INTO lv_field_left
               lv_type_expression.


        DATA(lv_field_name) =
          normalize_identifier(
            iv_value =
              get_first_word(
                iv_text = lv_field_left
              )
          ).


        IF lv_field_name IS INITIAL.

          CONTINUE.

        ENDIF.


        lv_position += 10.


        DATA ls_component
          TYPE ty_component.


        CLEAR ls_component.


        ls_component-struct_name =
          lv_current_structure.

        ls_component-field_name =
          lv_field_name.

        ls_component-position =
          lv_position.

        ls_component-label =
          lv_field_name.

        ls_component-source_object =
          is_statement-source_object.

        ls_component-start_line =
          is_statement-start_line.

        ls_component-end_line =
          is_statement-end_line.

        ls_component-statement_id =
          is_statement-statement_id.

        ls_component-statement_text =
          is_statement-statement_text.


        fill_component_metadata(
          EXPORTING
            iv_type_expression =
              lv_type_expression
          CHANGING
            cs_component =
              ls_component
        ).


        INSERT ls_component
          INTO TABLE ct_components.

        CONTINUE.

      ENDIF.


      IF lv_segment NS ' TYPE '
         OR lv_segment NS 'TABLE OF'.

        CONTINUE.

      ENDIF.


      DATA:
        lv_alias_left       TYPE string,
        lv_alias_expression TYPE string.


      SPLIT lv_segment
        AT ' TYPE '
        INTO lv_alias_left
             lv_alias_expression.


      DATA(lv_alias_name) =
        normalize_identifier(
          iv_value =
            get_first_word(
              iv_text = lv_alias_left
            )
        ).


      DATA(lv_alias_row_type) =
        extract_row_type(
          iv_type_expression =
            lv_alias_expression
        ).


      IF lv_alias_name IS INITIAL
         OR lv_alias_row_type IS INITIAL.

        CONTINUE.

      ENDIF.


      DELETE TABLE ct_table_types
        WITH TABLE KEY
          type_name = lv_alias_name.


      INSERT VALUE #(
        type_name = lv_alias_name
        row_type  = lv_alias_row_type
      ) INTO TABLE ct_table_types.

    ENDLOOP.

  ENDMETHOD.


  METHOD parse_data_statement.

    DATA(lv_text) =
      normalize_statement(
        iv_text =
          is_statement-statement_text
      ).


    REPLACE FIRST OCCURRENCE OF 'DATA'
      IN lv_text
      WITH ''.

    CONDENSE lv_text.


    IF lv_text IS NOT INITIAL
       AND lv_text+0(1) = ':'.

      lv_text =
        substring(
          val = lv_text
          off = 1
        ).

      CONDENSE lv_text.

    ENDIF.


    DATA lt_segments
      TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.


    SPLIT lv_text
      AT ','
      INTO TABLE lt_segments.


    LOOP AT lt_segments
      INTO DATA(lv_segment).


      CONDENSE lv_segment.


      IF lv_segment IS INITIAL
         OR lv_segment NS ' TYPE '.

        CONTINUE.

      ENDIF.


      DATA:
        lv_variable_left  TYPE string,
        lv_type_expression TYPE string.


      SPLIT lv_segment
        AT ' TYPE '
        INTO lv_variable_left
             lv_type_expression.


      DATA(lv_variable_name) =
        normalize_identifier(
          iv_value =
            get_first_word(
              iv_text = lv_variable_left
            )
        ).


      IF lv_variable_name IS INITIAL.

        CONTINUE.

      ENDIF.


      DATA ls_data_decl
        TYPE ty_data_decl.


      CLEAR ls_data_decl.


      ls_data_decl-variable_name =
        lv_variable_name.


      IF lv_type_expression CS 'TABLE OF'.

        ls_data_decl-row_type =
          extract_row_type(
            iv_type_expression =
              lv_type_expression
          ).

      ELSE.

        ls_data_decl-type_name =
          normalize_identifier(
            iv_value =
              get_first_word(
                iv_text =
                  lv_type_expression
              )
          ).

      ENDIF.


      IF ls_data_decl-type_name IS INITIAL
         AND ls_data_decl-row_type IS INITIAL.

        CONTINUE.

      ENDIF.


      DELETE TABLE ct_data_decls
        WITH TABLE KEY
          variable_name = lv_variable_name.


      INSERT ls_data_decl
        INTO TABLE ct_data_decls.

    ENDLOOP.

  ENDMETHOD.


  METHOD resolve_output_row_type.

    CLEAR rv_row_type.


    READ TABLE it_data_decls
      WITH TABLE KEY
        variable_name = iv_output_table
      INTO DATA(ls_data_decl).


    IF sy-subrc <> 0.

      RETURN.

    ENDIF.


    IF ls_data_decl-row_type IS NOT INITIAL.

      rv_row_type =
        ls_data_decl-row_type.

      RETURN.

    ENDIF.


    IF ls_data_decl-type_name IS INITIAL.

      RETURN.

    ENDIF.


    READ TABLE it_table_types
      WITH TABLE KEY
        type_name = ls_data_decl-type_name
      INTO DATA(ls_table_type).


    IF sy-subrc = 0.

      rv_row_type =
        ls_table_type-row_type.

    ENDIF.

  ENDMETHOD.


  METHOD append_local_columns.

    LOOP AT it_components
      INTO DATA(ls_component)
      WHERE struct_name = iv_row_type.


      READ TABLE ct_columns
        WITH KEY
          output_id  = is_output-output_id
          field_name = ls_component-field_name
        TRANSPORTING NO FIELDS.


      IF sy-subrc = 0.

        CONTINUE.

      ENDIF.


      DATA(lv_item_id) =
        create_uuid(
          iv_source_object =
            ls_component-source_object
        ).


      DATA(lv_evidence_id) =
        create_uuid(
          iv_source_object =
            ls_component-source_object
        ).


      APPEND VALUE #(
        item_id         = lv_item_id
        analysis_id     = iv_analysis_id
        output_id       = is_output-output_id
        evidence_id     = lv_evidence_id

        field_name      = ls_component-field_name
        label           = ls_component-label
        position        = ls_component-position
        data_type       = ls_component-data_type
        data_element    = ls_component-data_element
        reference_table = ls_component-reference_table
        reference_field = ls_component-reference_field
        length          = ls_component-field_length
        decimals        = ls_component-decimals

        visible         = abap_true
        key_field       = abap_false
        technical       = abap_false
        editable        = abap_false
        hotspot         = abap_false
        checkbox        = abap_false
        icon            = abap_false

        currency_field  = ''
        unit_field      = ''
        aggregation     = ''
        source_mapping  = ls_component-type_ref
        confidence      = zif_mig_types=>gc_conf_medium
      ) TO ct_columns.


      APPEND VALUE #(
        evidence_id    = lv_evidence_id
        analysis_id    = iv_analysis_id
        source_object  = ls_component-source_object
        start_line     = ls_component-start_line
        end_line       = ls_component-end_line
        statement_id   = ls_component-statement_id
        statement_text = ls_component-statement_text
        confidence     = zif_mig_types=>gc_conf_medium
      ) TO ct_evidences.

    ENDLOOP.

  ENDMETHOD.


  METHOD normalize_statement.

    rv_text =
      to_upper(
        iv_text
      ).


    REPLACE ALL OCCURRENCES OF
      cl_abap_char_utilities=>newline
      IN rv_text
      WITH space.


    REPLACE ALL OCCURRENCES OF
      cl_abap_char_utilities=>horizontal_tab
      IN rv_text
      WITH space.


    CONDENSE rv_text.


    WHILE rv_text IS NOT INITIAL.

      DATA(lv_length) =
        strlen( rv_text ).


      DATA(lv_offset) =
        lv_length - 1.


      DATA(lv_last_character) =
        substring(
          val = rv_text
          off = lv_offset
          len = 1
        ).


      IF lv_last_character = '.'.

        rv_text =
          substring(
            val = rv_text
            len = lv_offset
          ).

        CONDENSE rv_text.

      ELSE.

        EXIT.

      ENDIF.

    ENDWHILE.

  ENDMETHOD.


  METHOD normalize_identifier.

    DATA(lv_value) =
      iv_value.


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


      DATA(lv_last_character) =
        substring(
          val = lv_value
          off = lv_offset
          len = 1
        ).


      IF lv_last_character = '.'
         OR lv_last_character = ','
         OR lv_last_character = ')'
         OR lv_last_character = '('
         OR lv_last_character = ']'.

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
      to_upper(
        lv_value
      ).

  ENDMETHOD.


  METHOD get_first_word.

    DATA:
      lv_text TYPE string,
      lv_rest TYPE string.


    lv_text =
      iv_text.


    CONDENSE lv_text.


    SPLIT lv_text
      AT space
      INTO rv_word
           lv_rest.

  ENDMETHOD.


  METHOD extract_row_type.

    DATA(lv_expression) =
      normalize_statement(
        iv_text =
          iv_type_expression
      ).


    IF lv_expression NS 'TABLE OF'.

      RETURN.

    ENDIF.


    DATA:
      lv_before TYPE string,
      lv_after  TYPE string.


    SPLIT lv_expression
      AT 'TABLE OF'
      INTO lv_before
           lv_after.


    CONDENSE lv_after.


    rv_row_type =
      normalize_identifier(
        iv_value =
          get_first_word(
            iv_text = lv_after
          )
      ).

  ENDMETHOD.


  METHOD fill_component_metadata.

    DATA(lv_expression) =
      normalize_statement(
        iv_text =
          iv_type_expression
      ).


    DATA(lv_type_ref) =
      normalize_identifier(
        iv_value =
          get_first_word(
            iv_text =
              lv_expression
          )
      ).


    cs_component-type_ref =
      lv_type_ref.


    IF lv_type_ref CS '-'.

      DATA:
        lv_reference_table TYPE string,
        lv_reference_field TYPE string.


      SPLIT lv_type_ref
        AT '-'
        INTO lv_reference_table
             lv_reference_field.


      cs_component-reference_table =
        normalize_identifier(
          iv_value =
            lv_reference_table
        ).


      cs_component-reference_field =
        normalize_identifier(
          iv_value =
            lv_reference_field
        ).


      fill_ddic_field_metadata(
        EXPORTING
          iv_table =
            CONV tabname(
              cs_component-reference_table
            )

          iv_field =
            CONV fieldname(
              cs_component-reference_field
            )

        CHANGING
          cs_component =
            cs_component
      ).


      RETURN.

    ENDIF.


    IF lv_type_ref CP 'CHAR*'.

      cs_component-data_type =
        'CHAR'.

      cs_component-data_element =
        lv_type_ref.


      DATA(lv_char_length) =
        substring(
          val = CONV string( lv_type_ref )
          off = 4
        ).


      TRY.

          cs_component-field_length =
            CONV i(
              lv_char_length
            ).

        CATCH cx_sy_conversion_no_number.

          CLEAR cs_component-field_length.

      ENDTRY.


      RETURN.

    ENDIF.


    IF lv_type_ref CP 'NUMC*'.

      cs_component-data_type =
        'NUMC'.

      cs_component-data_element =
        lv_type_ref.


      DATA(lv_numc_length) =
        substring(
          val = CONV string( lv_type_ref )
          off = 4
        ).


      TRY.

          cs_component-field_length =
            CONV i(
              lv_numc_length
            ).

        CATCH cx_sy_conversion_no_number.

          CLEAR cs_component-field_length.

      ENDTRY.


      RETURN.

    ENDIF.


    CASE lv_type_ref.

      WHEN 'C'.

        cs_component-data_type =
          'CHAR'.


        IF lv_expression CS ' LENGTH '.

          DATA:
            lv_before_length TYPE string,
            lv_after_length  TYPE string.


          SPLIT lv_expression
            AT ' LENGTH '
            INTO lv_before_length
                 lv_after_length.


          TRY.

              cs_component-field_length =
                CONV i(
                  get_first_word(
                    iv_text =
                      lv_after_length
                  )
                ).

            CATCH cx_sy_conversion_no_number.

              CLEAR cs_component-field_length.

          ENDTRY.

        ENDIF.


      WHEN 'I'.

        cs_component-data_type =
          'INT4'.

        cs_component-field_length =
          4.


      WHEN 'INT8'.

        cs_component-data_type =
          'INT8'.

        cs_component-field_length =
          8.


      WHEN 'D'.

        cs_component-data_type =
          'DATS'.

        cs_component-field_length =
          8.


      WHEN 'T'.

        cs_component-data_type =
          'TIMS'.

        cs_component-field_length =
          6.


      WHEN 'STRING'.

        cs_component-data_type =
          'STRING'.


      WHEN OTHERS.

        cs_component-data_element =
          lv_type_ref.

    ENDCASE.

  ENDMETHOD.


  METHOD fill_ddic_field_metadata.

    DATA lt_dfies
      TYPE STANDARD TABLE OF dfies
      WITH EMPTY KEY.


    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = iv_table
        langu          = sy-langu
      TABLES
        dfies_tab      = lt_dfies
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.


    IF sy-subrc <> 0.

      RETURN.

    ENDIF.


    READ TABLE lt_dfies
      WITH KEY
        fieldname = iv_field
      INTO DATA(ls_dfies).


    IF sy-subrc <> 0.

      RETURN.

    ENDIF.


    cs_component-data_type =
      ls_dfies-datatype.

    cs_component-data_element =
      ls_dfies-rollname.

    cs_component-field_length =
      ls_dfies-leng.

    cs_component-decimals =
      ls_dfies-decimals.


    IF ls_dfies-scrtext_l IS NOT INITIAL.

      cs_component-label =
        ls_dfies-scrtext_l.

    ELSEIF ls_dfies-fieldtext IS NOT INITIAL.

      cs_component-label =
        ls_dfies-fieldtext.

    ENDIF.

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

