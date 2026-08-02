CLASS zcl_mig_ui_filter_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_ui_filter_analyzer.

  PRIVATE SECTION.
    TYPES:
        ty_selection_block TYPE c LENGTH 40,
        ty_ddic_name       TYPE c LENGTH 30.

    TYPES:
      BEGIN OF ty_word,
        word_index TYPE i,
        raw_text   TYPE string,
        upper_text TYPE string,
      END OF ty_word,

      tt_word TYPE STANDARD TABLE OF ty_word
        WITH EMPTY KEY.

    TYPES:
      tt_filter_map TYPE HASHED TABLE OF
        zif_mig_types=>ty_ui_filter
        WITH UNIQUE KEY field_name.

    TYPES:
      BEGIN OF ty_validation,
        target_name    TYPE c LENGTH 40,
        validation_type TYPE c LENGTH 10,
        routine_name   TYPE c LENGTH 120,
      END OF ty_validation,

      tt_validation TYPE HASHED TABLE OF ty_validation
        WITH UNIQUE KEY target_name validation_type.

    METHODS analyze_source_unit
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        is_source_unit TYPE zif_mig_types=>ty_source_unit
      CHANGING
        ct_filters     TYPE tt_filter_map
        ct_evidences   TYPE zif_mig_types=>tt_evidence
        ct_validations TYPE tt_validation
      RAISING
        zcx_mig_analysis.

    METHODS build_filter
      IMPORTING
        iv_analysis_id     TYPE zif_mig_types=>ty_analysis_id
        iv_selection_block TYPE ty_selection_block
        is_statement       TYPE zif_mig_types=>ty_statement
      EXPORTING
        es_filter          TYPE zif_mig_types=>ty_ui_filter
        es_evidence        TYPE zif_mig_types=>ty_evidence
      RAISING
        zcx_mig_analysis.

    METHODS split_words
      IMPORTING
        iv_statement_text TYPE string
      RETURNING
        VALUE(rt_words) TYPE tt_word.

    METHODS normalize_word
      IMPORTING
        iv_word TYPE string
      RETURNING
        VALUE(rv_word) TYPE string.

    METHODS split_reference
      IMPORTING
        iv_reference TYPE string
      EXPORTING
        ev_table     TYPE ty_ddic_name
        ev_field     TYPE ty_ddic_name.

    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

ENDCLASS.

CLASS zcl_mig_ui_filter_analyzer IMPLEMENTATION.

  METHOD zif_mig_ui_filter_analyzer~analyze.

    DATA:
      lv_analysis_id TYPE zif_mig_types=>ty_analysis_id,
      lt_filters     TYPE tt_filter_map,
      lt_validations TYPE tt_validation.

    lv_analysis_id = iv_analysis_id.

    IF lv_analysis_id IS INITIAL.

      lv_analysis_id =
        create_uuid(
          iv_source_object = ''
        ).

    ENDIF.

    "----------------------------------------------------------
    " Mỗi source unit được xử lý đúng một lần.
    "
    "Không có tìm kiếm statement × token.
    "Statement text đã được Normalizer dựng trước đó.
    "----------------------------------------------------------
    LOOP AT it_source_units
      ASSIGNING FIELD-SYMBOL(<source_unit>).

      analyze_source_unit(
        EXPORTING
          iv_analysis_id = lv_analysis_id
          is_source_unit = <source_unit>
        CHANGING
          ct_filters     = lt_filters
          ct_evidences   = rs_result-evidences
          ct_validations = lt_validations
      ).

    ENDLOOP.

    "----------------------------------------------------------
    " Gắn validation vào filter bằng hashed lookup
    "----------------------------------------------------------
    LOOP AT lt_filters
      ASSIGNING FIELD-SYMBOL(<filter>).

      READ TABLE lt_validations
        WITH TABLE KEY
          target_name     = <filter>-field_name
          validation_type = 'FIELD'
        INTO DATA(ls_field_validation).

      IF sy-subrc = 0.

        <filter>-validation_routine =
          ls_field_validation-routine_name.

      ELSEIF <filter>-selection_block IS NOT INITIAL.

        READ TABLE lt_validations
          WITH TABLE KEY
            target_name     = <filter>-selection_block
            validation_type = 'BLOCK'
          INTO DATA(ls_block_validation).

        IF sy-subrc = 0.

          <filter>-validation_routine =
            ls_block_validation-routine_name.

        ENDIF.

      ENDIF.

      APPEND <filter>
        TO rs_result-ui_filters.

    ENDLOOP.

    SORT rs_result-ui_filters
      BY field_name.

  ENDMETHOD.

    METHOD analyze_source_unit.

    DATA lv_current_block TYPE c LENGTH 40.

    LOOP AT is_source_unit-scan_result-statements
      ASSIGNING FIELD-SYMBOL(<statement>).

      DATA(lt_words) =
        split_words(
          iv_statement_text =
            <statement>-statement_text
        ).

      IF lt_words IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA:
        ls_word_1 TYPE ty_word,
        ls_word_2 TYPE ty_word,
        ls_word_3 TYPE ty_word,
        ls_word_4 TYPE ty_word,
        ls_word_5 TYPE ty_word.

      CLEAR:
        ls_word_1,
        ls_word_2,
        ls_word_3,
        ls_word_4,
        ls_word_5.

      READ TABLE lt_words INDEX 1 INTO ls_word_1.
      READ TABLE lt_words INDEX 2 INTO ls_word_2.
      READ TABLE lt_words INDEX 3 INTO ls_word_3.
      READ TABLE lt_words INDEX 4 INTO ls_word_4.
      READ TABLE lt_words INDEX 5 INTO ls_word_5.

      "========================================================
      " Selection-screen block
      "========================================================
      IF ls_word_1-upper_text = 'SELECTION-SCREEN'.

        IF ls_word_2-upper_text = 'BEGIN'
           AND ls_word_3-upper_text = 'OF'
           AND ls_word_4-upper_text = 'BLOCK'.

          lv_current_block =
            ls_word_5-upper_text.

          CONTINUE.

        ENDIF.

        IF ls_word_2-upper_text = 'END'
           AND ls_word_3-upper_text = 'OF'
           AND ls_word_4-upper_text = 'BLOCK'.

          CLEAR lv_current_block.
          CONTINUE.

        ENDIF.

      ENDIF.

      "========================================================
      " Field validation:
      " AT SELECTION-SCREEN ON p_field.
      "========================================================
      IF ls_word_1-upper_text = 'AT'
         AND ls_word_2-upper_text = 'SELECTION-SCREEN'
         AND ls_word_3-upper_text = 'ON'.

        IF ls_word_4-upper_text = 'BLOCK'.

          IF ls_word_5-upper_text IS NOT INITIAL.

            INSERT VALUE #(
              target_name     = ls_word_5-upper_text
              validation_type = 'BLOCK'
              routine_name    =
                |AT SELECTION-SCREEN ON BLOCK {
                   ls_word_5-upper_text }|
            ) INTO TABLE ct_validations.

          ENDIF.

        ELSEIF ls_word_4-upper_text IS NOT INITIAL.

          INSERT VALUE #(
            target_name     = ls_word_4-upper_text
            validation_type = 'FIELD'
            routine_name    =
              |AT SELECTION-SCREEN ON {
                 ls_word_4-upper_text }|
          ) INTO TABLE ct_validations.

        ENDIF.

        CONTINUE.

      ENDIF.

      "========================================================
      " Filter declarations
      "========================================================
      IF <statement>-statement_type <> 'PARAMETERS'
         AND <statement>-statement_type <> 'SELECT-OPTIONS'.

        CONTINUE.

      ENDIF.

      DATA:
      ls_filter   TYPE zif_mig_types=>ty_ui_filter,
      ls_evidence TYPE zif_mig_types=>ty_evidence.

    CLEAR:
      ls_filter,
      ls_evidence.

    build_filter(
      EXPORTING
        iv_analysis_id     = iv_analysis_id
        iv_selection_block = lv_current_block
        is_statement       = <statement>
      IMPORTING
        es_filter          = ls_filter
        es_evidence        = ls_evidence
    ).

      IF ls_filter-field_name IS INITIAL.
        CONTINUE.
      ENDIF.

      INSERT ls_filter
        INTO TABLE ct_filters.

      IF sy-subrc = 0.

        APPEND ls_evidence
          TO ct_evidences.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD build_filter.

      CLEAR:
        es_filter,
        es_evidence.

      DATA(lt_words) =
        split_words(
          iv_statement_text =
            is_statement-statement_text
        ).

      READ TABLE lt_words
        INDEX 2
        INTO DATA(ls_field_word).

      IF sy-subrc <> 0.
        RETURN.
      ENDIF.

    es_filter-analysis_id =
      iv_analysis_id.

    es_filter-item_id =
      create_uuid(
        iv_source_object =
          is_statement-source_object
      ).

    es_evidence-evidence_id =
      create_uuid(
        iv_source_object =
          is_statement-source_object
      ).

    es_filter-evidence_id =
      es_evidence-evidence_id.

    es_filter-field_name =
      ls_field_word-upper_text.

    es_filter-selection_block =
      iv_selection_block.

    es_filter-confidence =
      zif_mig_types=>gc_conf_high.

    CASE is_statement-statement_type.

      WHEN 'PARAMETERS'.

        es_filter-field_kind =
          'PARAMETER'.

        es_filter-multiple_selection =
          abap_false.

        es_filter-range_supported =
          abap_false.

      WHEN 'SELECT-OPTIONS'.

        es_filter-field_kind =
          'SELECT_OPTIONS'.

        es_filter-multiple_selection =
          abap_true.

        es_filter-range_supported =
          abap_true.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

    "----------------------------------------------------------
    " Evidence
    "----------------------------------------------------------
    es_evidence-analysis_id =
      iv_analysis_id.

    es_evidence-source_object =
      is_statement-source_object.

    es_evidence-start_line =
      is_statement-start_line.

    es_evidence-end_line =
      is_statement-end_line.

    es_evidence-statement_id =
      is_statement-statement_id.

    es_evidence-statement_text =
      is_statement-statement_text.

    es_evidence-confidence =
      zif_mig_types=>gc_conf_high.

    "----------------------------------------------------------
    " Duyệt word đúng một lần
    "----------------------------------------------------------
    LOOP AT lt_words
      INTO DATA(ls_word).

      DATA(lv_next_index) =
        ls_word-word_index + 1.

      DATA(lv_next_2_index) =
        ls_word-word_index + 2.

      DATA:
        ls_next_word   TYPE ty_word,
        ls_next_2_word TYPE ty_word.

      CLEAR:
        ls_next_word,
        ls_next_2_word.

      READ TABLE lt_words
        INDEX lv_next_index
        INTO ls_next_word.

      READ TABLE lt_words
        INDEX lv_next_2_index
        INTO ls_next_2_word.

      CASE ls_word-upper_text.

        WHEN 'TYPE' OR 'LIKE'.

          IF ls_next_word-upper_text IS NOT INITIAL.

            es_filter-data_type =
              ls_next_word-upper_text.

            split_reference(
              EXPORTING
                iv_reference =
                  ls_next_word-upper_text
              IMPORTING
                ev_table =
                  es_filter-reference_table
                ev_field =
                  es_filter-reference_field
            ).

          ENDIF.

        WHEN 'FOR'.

          IF ls_next_word-upper_text IS NOT INITIAL.

            es_filter-data_type =
              ls_next_word-upper_text.

            split_reference(
              EXPORTING
                iv_reference =
                  ls_next_word-upper_text
              IMPORTING
                ev_table =
                  es_filter-reference_table
                ev_field =
                  es_filter-reference_field
            ).

          ENDIF.

        WHEN 'OBLIGATORY'.

          es_filter-mandatory =
            abap_true.

        WHEN 'NO-DISPLAY'.

          es_filter-hidden =
            abap_true.

        WHEN 'NO-EXTENSION'.

          es_filter-multiple_selection =
            abap_false.

        WHEN 'NO'.

          CASE ls_next_word-upper_text.

            WHEN 'DISPLAY'.

              es_filter-hidden =
                abap_true.

            WHEN 'EXTENSION'.

              es_filter-multiple_selection =
                abap_false.

            WHEN 'INTERVALS'.

              es_filter-range_supported =
                abap_false.

          ENDCASE.

        WHEN 'NO-INTERVALS'.

          es_filter-range_supported =
            abap_false.

        WHEN 'AS'.

          IF ls_next_word-upper_text = 'CHECKBOX'.

            es_filter-checkbox =
              abap_true.

          ENDIF.

        WHEN 'RADIOBUTTON'.

          IF ls_next_word-upper_text = 'GROUP'
             AND ls_next_2_word-upper_text
                   IS NOT INITIAL.

            es_filter-radio_group =
              ls_next_2_word-upper_text.

          ENDIF.

        WHEN 'DEFAULT'.

          IF ls_next_word-raw_text IS NOT INITIAL.

            es_filter-default_value =
              ls_next_word-raw_text.

          ENDIF.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

    METHOD split_words.

    DATA lt_raw_words TYPE STANDARD TABLE OF string
      WITH EMPTY KEY.

    SPLIT iv_statement_text
      AT space
      INTO TABLE lt_raw_words.

    LOOP AT lt_raw_words
      INTO DATA(lv_raw_word).

      IF lv_raw_word IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        word_index = lines( rt_words ) + 1
        raw_text   = normalize_word( lv_raw_word )
        upper_text = to_upper(
          normalize_word( lv_raw_word )
        )
      ) TO rt_words.

    ENDLOOP.

  ENDMETHOD.


  METHOD normalize_word.

    rv_word = iv_word.

    WHILE rv_word IS NOT INITIAL.

      DATA(lv_length) =
        strlen( rv_word ).

      DATA(lv_offset) =
        lv_length - 1.

      DATA(lv_last_character) =
        substring(
          val = rv_word
          off = lv_offset
          len = 1
        ).

      IF lv_last_character = '.'
         OR lv_last_character = ','
         OR lv_last_character = ':'.

        rv_word =
          substring(
            val = rv_word
            len = lv_offset
          ).

      ELSE.

        EXIT.

      ENDIF.

    ENDWHILE.

  ENDMETHOD.

    METHOD split_reference.

    CLEAR:
      ev_table,
      ev_field.

    DATA lv_reference TYPE string.

    lv_reference =
      to_upper( iv_reference ).

    IF lv_reference CS '-'.

      SPLIT lv_reference
        AT '-'
        INTO ev_table ev_field.

    ELSEIF lv_reference CS '~'.

      SPLIT lv_reference
        AT '~'
        INTO ev_table ev_field.

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
          previous     = lx_uuid
          program_name = iv_source_object
        ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
