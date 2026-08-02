CLASS lcl_mig_analysis_buffer DEFINITION
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES tt_analysis_result
      TYPE STANDARD TABLE OF
        zif_mig_types=>ty_analysis_result
      WITH EMPTY KEY.

    CLASS-METHODS add
      IMPORTING
        is_result TYPE zif_mig_types=>ty_analysis_result.

    CLASS-METHODS get_all
      RETURNING
        VALUE(rt_results) TYPE tt_analysis_result.

    CLASS-METHODS clear.

  PRIVATE SECTION.

    CLASS-DATA gt_results TYPE tt_analysis_result.

ENDCLASS.


CLASS lcl_mig_analysis_buffer IMPLEMENTATION.

  METHOD add.

    IF is_result-analysis_id IS INITIAL.
      RETURN.
    ENDIF.

    DELETE gt_results
      WHERE analysis_id = is_result-analysis_id.

    APPEND is_result TO gt_results.

  ENDMETHOD.


  METHOD get_all.

    rt_results = gt_results.

  ENDMETHOD.


  METHOD clear.

    CLEAR gt_results.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Analysis DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Analysis RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ Analysis RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Analysis.

    METHODS rba_Alvoutputs FOR READ
      IMPORTING keys_rba FOR READ Analysis\_Alvoutputs FULL result_requested RESULT result LINK association_links.

    METHODS rba_Businesslogic FOR READ
      IMPORTING keys_rba FOR READ Analysis\_Businesslogic FULL result_requested RESULT result LINK association_links.

    METHODS rba_Databaseobjects FOR READ
      IMPORTING keys_rba FOR READ Analysis\_Databaseobjects FULL result_requested RESULT result LINK association_links.

    METHODS rba_Evidences FOR READ
      IMPORTING keys_rba FOR READ Analysis\_Evidences FULL result_requested RESULT result LINK association_links.

    METHODS rba_Messages FOR READ
      IMPORTING keys_rba FOR READ Analysis\_Messages FULL result_requested RESULT result LINK association_links.

    METHODS rba_Recommendations FOR READ
      IMPORTING keys_rba FOR READ Analysis\_Recommendations FULL result_requested RESULT result LINK association_links.

    METHODS rba_Uifilters FOR READ
      IMPORTING keys_rba FOR READ Analysis\_Uifilters FULL result_requested RESULT result LINK association_links.
    METHODS rba_Sourceobjects FOR READ
      IMPORTING keys_rba FOR READ Analysis\_SourceObjects FULL result_requested RESULT result LINK association_links.

    METHODS Analyze FOR MODIFY
      IMPORTING keys FOR ACTION Analysis~Analyze RESULT result.

ENDCLASS.

CLASS lhc_Analysis IMPLEMENTATION.

  METHOD get_global_authorizations.

      result-%action-Analyze =
        if_abap_behv=>auth-allowed.

  ENDMETHOD.

METHOD read.

  IF keys IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys.

  lt_keys = keys.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zmig_anl_h AS header
    INNER JOIN @lt_keys AS requested
      ON header~analysis_id = requested~AnalysisId

    FIELDS
      header~analysis_id             AS AnalysisId,
      header~program_name            AS ProgramName,
      header~program_description     AS ProgramDescription,
      header~status                  AS Status,

      header~total_source_objects    AS TotalSourceObjects,
      header~total_ui_filters        AS TotalUiFilters,
      header~total_database_objects  AS TotalDatabaseObjects,
      header~total_business_logic    AS TotalBusinessLogic,
      header~total_alv_outputs       AS TotalAlvOutputs,
      header~total_alv_columns       AS TotalAlvColumns,
      header~total_recommendations   AS TotalRecommendations,

      header~complexity_score        AS ComplexityScore,
      header~readiness_score         AS ReadinessScore,

      header~parser_version          AS ParserVersion,
      header~rule_version            AS RuleVersion,
      header~source_hash             AS SourceHash,

      header~created_by              AS CreatedBy,
      header~created_at              AS CreatedAt,
      header~last_changed_by         AS LastChangedBy,
      header~last_changed_at         AS LocalLastChangedAt

    INTO CORRESPONDING FIELDS OF TABLE @result.

ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Alvoutputs.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_alv AS alv_output
    INNER JOIN @lt_keys AS requested
      ON alv_output~AnalysisId =
         requested~AnalysisId
    FIELDS alv_output~*
    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<alv_output>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <alv_output>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <alv_output>-AnalysisId

        OutputId =
          <alv_output>-OutputId
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

  METHOD rba_Businesslogic.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_logic AS business_logic
    INNER JOIN @lt_keys AS requested
      ON business_logic~AnalysisId =
         requested~AnalysisId
    FIELDS business_logic~*
    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<business_logic>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <business_logic>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <business_logic>-AnalysisId

        ItemId =
          <business_logic>-ItemId
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

  METHOD rba_Databaseobjects.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_db AS database_object
    INNER JOIN @lt_keys AS requested
      ON database_object~AnalysisId =
         requested~AnalysisId
    FIELDS database_object~*
    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<database_object>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <database_object>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <database_object>-AnalysisId

        ItemId =
          <database_object>-ItemId
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

  METHOD rba_Evidences.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_evd AS evidence
    INNER JOIN @lt_keys AS requested
      ON evidence~AnalysisId =
         requested~AnalysisId
    FIELDS evidence~*
    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<evidence>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <evidence>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <evidence>-AnalysisId

        EvidenceId =
          <evidence>-EvidenceId
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

  METHOD rba_Messages.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_msg AS message
    INNER JOIN @lt_keys AS requested
      ON message~AnalysisId =
         requested~AnalysisId
    FIELDS message~*
    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<message>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <message>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <message>-AnalysisId

        MessageNo =
          <message>-MessageNo
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

  METHOD rba_Recommendations.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_rec AS recommendation
    INNER JOIN @lt_keys AS requested
      ON recommendation~AnalysisId =
         requested~AnalysisId
    FIELDS recommendation~*
    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<recommendation>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <recommendation>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <recommendation>-AnalysisId

        RecommendationId =
          <recommendation>-RecommendationId
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

  METHOD rba_Uifilters.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_ui AS ui
    INNER JOIN @lt_keys AS requested
      ON ui~AnalysisId = requested~AnalysisId
    FIELDS ui~*
    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<ui_filter>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId = <ui_filter>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId = <ui_filter>-AnalysisId
        ItemId     = <ui_filter>-ItemId
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

METHOD rba_Sourceobjects.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.

  lt_keys = keys_rba.

  SORT lt_keys BY AnalysisId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING AnalysisId.


  SELECT FROM zi_mig_anl_src AS source_object
    INNER JOIN @lt_keys AS requested
      ON source_object~AnalysisId =
         requested~AnalysisId

    FIELDS source_object~*

    INTO CORRESPONDING FIELDS OF TABLE @result.


  LOOP AT result
    ASSIGNING FIELD-SYMBOL(<source_object>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <source_object>-AnalysisId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <source_object>-AnalysisId

        ItemId =
          <source_object>-ItemId
      )
    ) TO association_links.

  ENDLOOP.

ENDMETHOD.

  METHOD Analyze.

      DATA(lo_service) =
        NEW zcl_mig_analysis_service( ).

      LOOP AT keys
        ASSIGNING FIELD-SYMBOL(<key>).

        DATA(lv_program_name) =
            <key>-%param-ProgramName.

        TRY.

            "====================================================
            " Chỉ chạy analysis, chưa ghi database
            "====================================================
            DATA(ls_analysis_result) =
              lo_service->zif_mig_analysis_service~analyze_program(
                iv_program_name = lv_program_name
              ).

            "====================================================
            " Đưa vào RAP transactional buffer
            "====================================================
            lcl_mig_analysis_buffer=>add(
              is_result = ls_analysis_result
            ).

            "====================================================
            " Trả kết quả root cho action caller
            "====================================================
            APPEND VALUE #(
              %cid = <key>-%cid

              %param = VALUE #(
                AnalysisId =
                  ls_analysis_result-analysis_id

                ProgramName =
                  ls_analysis_result-overview-program_name

                ProgramDescription =
                  ls_analysis_result-overview-program_description

                Status =
                  ls_analysis_result-overview-status

                TotalSourceObjects =
                  ls_analysis_result-overview-total_source_objects

                TotalUiFilters =
                  ls_analysis_result-overview-total_ui_filters

                TotalDatabaseObjects =
                  ls_analysis_result-overview-total_database_objects

                TotalBusinessLogic =
                  ls_analysis_result-overview-total_business_logic

                TotalAlvOutputs =
                  ls_analysis_result-overview-total_alv_outputs

                TotalAlvColumns =
                  ls_analysis_result-overview-total_alv_columns

                TotalRecommendations =
                  ls_analysis_result-overview-total_recommendations

                ComplexityScore =
                  ls_analysis_result-overview-complexity_score

                ReadinessScore =
                  ls_analysis_result-overview-readiness_score

                ParserVersion =
                  ls_analysis_result-overview-parser_version

                RuleVersion =
                  ls_analysis_result-overview-rule_version

                SourceHash =
                  ls_analysis_result-overview-source_hash
              )
            ) TO result.

          CATCH zcx_mig_analysis INTO DATA(lx_analysis).

            APPEND VALUE #(
              %cid = <key>-%cid
            ) TO failed-Analysis.

            APPEND VALUE #(
              %cid = <key>-%cid

              %msg = new_message_with_text(
                severity =
                  if_abap_behv_message=>severity-error

                text =
                  lx_analysis->get_text( )
              )
            ) TO reported-Analysis.

        ENDTRY.

      ENDLOOP.

    ENDMETHOD.

ENDCLASS.

CLASS lhc_UiFilter DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ UiFilter RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ UiFilter\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_UiFilter IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      DATA lt_keys LIKE keys.

      lt_keys = keys.

      SORT lt_keys
        BY AnalysisId
           ItemId.

      DELETE ADJACENT DUPLICATES FROM lt_keys
        COMPARING
          AnalysisId
          ItemId.


      SELECT FROM zi_mig_anl_ui AS ui
        INNER JOIN @lt_keys AS requested
          ON  ui~AnalysisId = requested~AnalysisId
          AND ui~ItemId     = requested~ItemId
        FIELDS ui~*
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_DatabaseObject DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ DatabaseObject RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ DatabaseObject\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_DatabaseObject IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_db
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND ItemId     = @keys-ItemId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_BusinessLogic DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ BusinessLogic RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ BusinessLogic\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_BusinessLogic IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_logic
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND ItemId     = @keys-ItemId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_AlvOutput DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ AlvOutput RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ AlvOutput\_Analysis FULL result_requested RESULT result LINK association_links.

    METHODS rba_Columns FOR READ
      IMPORTING keys_rba FOR READ AlvOutput\_Columns FULL result_requested RESULT result LINK association_links.

    METHODS rba_Events FOR READ
      IMPORTING keys_rba FOR READ AlvOutput\_Events FULL result_requested RESULT result LINK association_links.

    METHODS rba_Filters FOR READ
      IMPORTING keys_rba FOR READ AlvOutput\_Filters FULL result_requested RESULT result LINK association_links.

    METHODS rba_Sorts FOR READ
      IMPORTING keys_rba FOR READ AlvOutput\_Sorts FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_AlvOutput IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_alv
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND OutputId   = @keys-OutputId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

  METHOD rba_Columns.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  TYPES:
    BEGIN OF ty_requested_key,
      analysis_id TYPE zmig_anl_col-analysis_id,
      output_id   TYPE zmig_anl_col-output_id,
    END OF ty_requested_key,

    tt_requested_key TYPE SORTED TABLE OF ty_requested_key
      WITH UNIQUE KEY analysis_id output_id.

  DATA lt_source_keys   LIKE keys_rba.
  DATA lt_requested_keys TYPE tt_requested_key.
  DATA lt_rows           LIKE result.

  lt_source_keys = keys_rba.

  SORT lt_source_keys BY
    AnalysisId
    OutputId.

  DELETE ADJACENT DUPLICATES FROM lt_source_keys
    COMPARING
      AnalysisId
      OutputId.

  lt_requested_keys = VALUE #(
    FOR ls_key IN lt_source_keys
    (
      analysis_id = ls_key-AnalysisId
      output_id   = ls_key-OutputId
    )
  ).

  SELECT FROM zi_mig_anl_col AS alv_column
    INNER JOIN @lt_requested_keys AS requested
      ON  alv_column~AnalysisId = requested~analysis_id
      AND alv_column~OutputId   = requested~output_id
    FIELDS alv_column~*
    INTO CORRESPONDING FIELDS OF TABLE @lt_rows.

  LOOP AT lt_rows
    ASSIGNING FIELD-SYMBOL(<column>).

    READ TABLE lt_source_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId = <column>-AnalysisId
        OutputId   = <column>-OutputId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky = <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId = <column>-AnalysisId
        OutputId   = <column>-OutputId
        ItemId     = <column>-ItemId
      )
    ) TO association_links.

  ENDLOOP.

  IF result_requested = abap_true.
    result = lt_rows.
  ENDIF.

ENDMETHOD.

  METHOD rba_Events.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.
  DATA lt_rows LIKE result.

  lt_keys = keys_rba.

  SORT lt_keys BY
    AnalysisId
    OutputId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING
      AnalysisId
      OutputId.


  SELECT FROM zi_mig_anl_evt AS alv_event
    INNER JOIN @lt_keys AS requested
      ON  alv_event~AnalysisId = requested~AnalysisId
      AND alv_event~OutputId   = requested~OutputId
    FIELDS alv_event~*
    INTO CORRESPONDING FIELDS OF TABLE @lt_rows.


  LOOP AT lt_rows
    ASSIGNING FIELD-SYMBOL(<event>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId = <event>-AnalysisId
        OutputId   = <event>-OutputId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId = <event>-AnalysisId
        OutputId   = <event>-OutputId
        ItemId     = <event>-ItemId
      )
    ) TO association_links.

  ENDLOOP.


  IF result_requested = abap_true.
    result = lt_rows.
  ENDIF.

ENDMETHOD.

  METHOD rba_Filters.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.
  DATA lt_rows LIKE result.

  lt_keys = keys_rba.

  SORT lt_keys BY
    AnalysisId
    OutputId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING
      AnalysisId
      OutputId.


  SELECT FROM zi_mig_anl_flt AS alv_filter
    INNER JOIN @lt_keys AS requested
      ON  alv_filter~AnalysisId = requested~AnalysisId
      AND alv_filter~OutputId   = requested~OutputId
    FIELDS alv_filter~*
    INTO CORRESPONDING FIELDS OF TABLE @lt_rows.


  LOOP AT lt_rows
    ASSIGNING FIELD-SYMBOL(<filter>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId = <filter>-AnalysisId
        OutputId   = <filter>-OutputId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId = <filter>-AnalysisId
        OutputId   = <filter>-OutputId
        ItemId     = <filter>-ItemId
      )
    ) TO association_links.

  ENDLOOP.


  IF result_requested = abap_true.
    result = lt_rows.
  ENDIF.

ENDMETHOD.

  METHOD rba_Sorts.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  TYPES:
    BEGIN OF ty_requested_key,
      analysis_id TYPE zmig_anl_srt-analysis_id,
      output_id   TYPE zmig_anl_srt-output_id,
    END OF ty_requested_key,

    tt_requested_key TYPE SORTED TABLE OF ty_requested_key
      WITH UNIQUE KEY analysis_id output_id.

  DATA lt_source_keys    LIKE keys_rba.
  DATA lt_requested_keys TYPE tt_requested_key.
  DATA lt_rows            LIKE result.

  lt_source_keys = keys_rba.

  SORT lt_source_keys BY
    AnalysisId
    OutputId.

  DELETE ADJACENT DUPLICATES FROM lt_source_keys
    COMPARING
      AnalysisId
      OutputId.

  lt_requested_keys = VALUE #(
    FOR ls_key IN lt_source_keys
    (
      analysis_id = ls_key-AnalysisId
      output_id   = ls_key-OutputId
    )
  ).

  SELECT FROM zi_mig_anl_srt AS alv_sort
    INNER JOIN @lt_requested_keys AS requested
      ON  alv_sort~AnalysisId = requested~analysis_id
      AND alv_sort~OutputId   = requested~output_id
    FIELDS alv_sort~*
    INTO CORRESPONDING FIELDS OF TABLE @lt_rows.

  LOOP AT lt_rows
    ASSIGNING FIELD-SYMBOL(<sort>).

    READ TABLE lt_source_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId = <sort>-AnalysisId
        OutputId   = <sort>-OutputId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky = <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId = <sort>-AnalysisId
        OutputId   = <sort>-OutputId
        ItemId     = <sort>-ItemId
      )
    ) TO association_links.

  ENDLOOP.

  IF result_requested = abap_true.
    result = lt_rows.
  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_AlvColumn DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ AlvColumn RESULT result.

    METHODS rba_Alvoutput FOR READ
      IMPORTING keys_rba FOR READ AlvColumn\_Alvoutput FULL result_requested RESULT result LINK association_links.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ AlvColumn\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_AlvColumn IMPLEMENTATION.

METHOD read.

  IF keys IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys.

  lt_keys = keys.

  SORT lt_keys
    BY AnalysisId
       OutputId
       ItemId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING
      AnalysisId
      OutputId
      ItemId.


  SELECT FROM zmig_anl_col AS alv_column
    INNER JOIN @lt_keys AS requested
      ON  alv_column~analysis_id = requested~AnalysisId
      AND alv_column~output_id   = requested~OutputId
      AND alv_column~item_id     = requested~ItemId

    FIELDS
      alv_column~analysis_id       AS AnalysisId,
      alv_column~output_id         AS OutputId,
      alv_column~item_id           AS ItemId,
      alv_column~evidence_id       AS EvidenceId,

      alv_column~field_name        AS FieldName,
      alv_column~column_label      AS ColumnLabel,
      alv_column~column_position   AS ColumnPosition,

      alv_column~data_type         AS DataType,
      alv_column~data_element      AS DataElement,
      alv_column~reference_table   AS ReferenceTable,
      alv_column~reference_field   AS ReferenceField,

      alv_column~field_length      AS FieldLength,
      alv_column~decimals          AS Decimals,

      alv_column~visible           AS Visible,
      alv_column~key_field         AS KeyField,
      alv_column~technical         AS Technical,
      alv_column~editable          AS Editable,
      alv_column~hotspot           AS Hotspot,
      alv_column~checkbox          AS Checkbox,
      alv_column~icon              AS Icon,

      alv_column~currency_field    AS CurrencyField,
      alv_column~unit_field        AS UnitField,
      alv_column~aggregation       AS Aggregation,

      alv_column~source_mapping    AS SourceMapping,
      alv_column~confidence        AS Confidence

    INTO CORRESPONDING FIELDS OF TABLE @result.

ENDMETHOD.

  METHOD rba_Alvoutput.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source ALV detail → target ALV Output
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId

        OutputId =
          <key>-OutputId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Đọc ALV Output parent khi caller yêu cầu
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY AlvOutput
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId

          OutputId =
            ls_key-OutputId
        )
      )

      RESULT DATA(lt_alv_outputs).

    result =
      lt_alv_outputs.

  ENDIF.

ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_AlvSort DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ AlvSort RESULT result.

    METHODS rba_Alvoutput FOR READ
      IMPORTING keys_rba FOR READ AlvSort\_Alvoutput FULL result_requested RESULT result LINK association_links.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ AlvSort\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_AlvSort IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_srt
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND OutputId   = @keys-OutputId
          AND ItemId     = @keys-ItemId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Alvoutput.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source ALV detail → target ALV Output
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId

        OutputId =
          <key>-OutputId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Đọc ALV Output parent khi caller yêu cầu
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY AlvOutput
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId

          OutputId =
            ls_key-OutputId
        )
      )

      RESULT DATA(lt_alv_outputs).

    result =
      lt_alv_outputs.

  ENDIF.

ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_AlvFilter DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ AlvFilter RESULT result.

    METHODS rba_Alvoutput FOR READ
      IMPORTING keys_rba FOR READ AlvFilter\_Alvoutput FULL result_requested RESULT result LINK association_links.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ AlvFilter\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_AlvFilter IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_flt
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND OutputId   = @keys-OutputId
          AND ItemId     = @keys-ItemId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Alvoutput.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source ALV detail → target ALV Output
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId

        OutputId =
          <key>-OutputId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Đọc ALV Output parent khi caller yêu cầu
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY AlvOutput
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId

          OutputId =
            ls_key-OutputId
        )
      )

      RESULT DATA(lt_alv_outputs).

    result =
      lt_alv_outputs.

  ENDIF.

ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_AlvEvent DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ AlvEvent RESULT result.

    METHODS rba_Alvoutput FOR READ
      IMPORTING keys_rba FOR READ AlvEvent\_Alvoutput FULL result_requested RESULT result LINK association_links.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ AlvEvent\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_AlvEvent IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_evt
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND OutputId   = @keys-OutputId
          AND ItemId     = @keys-ItemId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Alvoutput.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source ALV detail → target ALV Output
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId

        OutputId =
          <key>-OutputId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Đọc ALV Output parent khi caller yêu cầu
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY AlvOutput
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId

          OutputId =
            ls_key-OutputId
        )
      )

      RESULT DATA(lt_alv_outputs).

    result =
      lt_alv_outputs.

  ENDIF.

ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_Evidence DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ Evidence RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ Evidence\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_Evidence IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_evd
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND EvidenceId = @keys-EvidenceId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_Recommendation DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ Recommendation RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ Recommendation\_Analysis FULL result_requested RESULT result LINK association_links.

    METHODS rba_Annotations FOR READ
      IMPORTING keys_rba FOR READ Recommendation\_Annotations FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_Recommendation IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_rec
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId       = @keys-AnalysisId
          AND RecommendationId = @keys-RecommendationId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

  METHOD rba_Annotations.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.

  DATA lt_keys LIKE keys_rba.
  DATA lt_rows LIKE result.

  lt_keys = keys_rba.

  SORT lt_keys BY
    AnalysisId
    RecommendationId.

  DELETE ADJACENT DUPLICATES FROM lt_keys
    COMPARING
      AnalysisId
      RecommendationId.


  SELECT FROM zi_mig_anl_ann AS annotation
    INNER JOIN @lt_keys AS requested
      ON  annotation~AnalysisId =
            requested~AnalysisId

      AND annotation~RecommendationId =
            requested~RecommendationId
    FIELDS annotation~*
    INTO CORRESPONDING FIELDS OF TABLE @lt_rows.


  LOOP AT lt_rows
    ASSIGNING FIELD-SYMBOL(<annotation>).

    READ TABLE lt_keys
      ASSIGNING FIELD-SYMBOL(<source_key>)
      WITH KEY
        AnalysisId =
          <annotation>-AnalysisId

        RecommendationId =
          <annotation>-RecommendationId
      BINARY SEARCH.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      source-%tky =
        <source_key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <annotation>-AnalysisId

        RecommendationId =
          <annotation>-RecommendationId

        ItemId =
          <annotation>-ItemId
      )
    ) TO association_links.

  ENDLOOP.


  IF result_requested = abap_true.
    result = lt_rows.
  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_Annotation DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ Annotation RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ Annotation\_Analysis FULL result_requested RESULT result LINK association_links.

    METHODS rba_Recommendation FOR READ
      IMPORTING keys_rba FOR READ Annotation\_Recommendation FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_Annotation IMPLEMENTATION.

     METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_ann
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId       = @keys-AnalysisId
          AND RecommendationId = @keys-RecommendationId
          AND ItemId           = @keys-ItemId
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

  METHOD rba_Recommendation.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " Annotation → Recommendation
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId

        RecommendationId =
          <key>-RecommendationId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Đọc Recommendation parent khi caller yêu cầu
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Recommendation
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId

          RecommendationId =
            ls_key-RecommendationId
        )
      )

      RESULT DATA(lt_recommendations).

    result =
      lt_recommendations.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_AnalysisMessage DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ AnalysisMessage RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING keys_rba FOR READ AnalysisMessage\_Analysis FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_AnalysisMessage IMPLEMENTATION.

    METHOD read.

      IF keys IS INITIAL.
        RETURN.
      ENDIF.

      SELECT FROM zi_mig_anl_msg
        FIELDS *
        FOR ALL ENTRIES IN @keys
        WHERE AnalysisId = @keys-AnalysisId
          AND MessageNo  = @keys-MessageNo
        INTO CORRESPONDING FIELDS OF TABLE @result.

    ENDMETHOD.

  METHOD rba_Analysis.

  IF keys_rba IS INITIAL.
    RETURN.
  ENDIF.


  "==========================================================
  " Association links:
  " source child → target Analysis
  "==========================================================
  LOOP AT keys_rba
    ASSIGNING FIELD-SYMBOL(<key>).

    APPEND VALUE #(
      source-%tky =
        <key>-%tky

      target-%tky = VALUE #(
        AnalysisId =
          <key>-AnalysisId
      )
    ) TO association_links.

  ENDLOOP.


  "==========================================================
  " Chỉ đọc parent data khi caller yêu cầu RESULT
  "==========================================================
  IF result_requested = abap_true.

    READ ENTITIES OF zi_mig_analysis
      IN LOCAL MODE

      ENTITY Analysis
      ALL FIELDS

      WITH VALUE #(
        FOR ls_key IN keys_rba
        (
          AnalysisId =
            ls_key-AnalysisId
        )
      )

      RESULT DATA(lt_analysis).

    result =
      lt_analysis.

  ENDIF.

ENDMETHOD.

ENDCLASS.

CLASS lhc_SourceObject DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING
        keys FOR READ SourceObject
      RESULT result.

    METHODS rba_Analysis FOR READ
      IMPORTING
        keys_rba FOR READ SourceObject\_Analysis
        FULL result_requested
      RESULT result
      LINK association_links.

ENDCLASS.

CLASS lhc_SourceObject IMPLEMENTATION.

  METHOD read.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_keys LIKE keys.

    lt_keys = keys.

    SORT lt_keys
      BY AnalysisId
         ItemId.

    DELETE ADJACENT DUPLICATES FROM lt_keys
      COMPARING
        AnalysisId
        ItemId.


    SELECT FROM zmig_anl_src AS source_object
      INNER JOIN @lt_keys AS requested
        ON  source_object~analysis_id =
              requested~AnalysisId
        AND source_object~item_id =
              requested~ItemId

      FIELDS
        source_object~analysis_id   AS AnalysisId,
        source_object~item_id       AS ItemId,
        source_object~object_name   AS ObjectName,
        source_object~object_type   AS ObjectType,
        source_object~parent_object AS ParentObject,
        source_object~include_depth AS IncludeDepth,
        source_object~line_count    AS LineCount,
        source_object~source_hash   AS SourceHash

      INTO CORRESPONDING FIELDS OF TABLE @result.

  ENDMETHOD.

    METHOD rba_Analysis.

    IF keys_rba IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_parent_keys LIKE keys_rba.

    lt_parent_keys = keys_rba.

    SORT lt_parent_keys BY AnalysisId.

    DELETE ADJACENT DUPLICATES FROM lt_parent_keys
      COMPARING AnalysisId.


    SELECT FROM zi_mig_analysis AS analysis
      INNER JOIN @lt_parent_keys AS requested
        ON analysis~AnalysisId =
           requested~AnalysisId

      FIELDS analysis~*

      INTO CORRESPONDING FIELDS OF TABLE @result.


    LOOP AT keys_rba
      ASSIGNING FIELD-SYMBOL(<source_key>).

      APPEND VALUE #(
        source-%tky =
          <source_key>-%tky

        target-%tky = VALUE #(
          AnalysisId =
            <source_key>-AnalysisId
        )
      ) TO association_links.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_MIG_ANALYSIS DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_MIG_ANALYSIS IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.

      DATA(lt_results) =
        lcl_mig_analysis_buffer=>get_all( ).

      IF lt_results IS INITIAL.
        RETURN.
      ENDIF.

      DATA(lo_store) =
        NEW zcl_mig_analysis_store( ).

      LOOP AT lt_results
        ASSIGNING FIELD-SYMBOL(<analysis_result>).

        TRY.

            lo_store->zif_mig_analysis_store~save(
              is_result = <analysis_result>
            ).

          CATCH zcx_mig_analysis INTO DATA(lx_save).

            "Lỗi trong SAVE là lỗi kỹ thuật vì interaction phase
            "đã hoàn thành và CHECK_BEFORE_SAVE đã được chạy.
            RAISE SHORTDUMP NEW zcx_mig_analysis(
              textid =
                zcx_mig_analysis=>analysis_failed

              previous =
                lx_save

              program_name =
                <analysis_result>-overview-program_name
            ).

        ENDTRY.

      ENDLOOP.

    ENDMETHOD.

    METHOD cleanup.

      lcl_mig_analysis_buffer=>clear( ).

    ENDMETHOD.


    METHOD cleanup_finalize.

      lcl_mig_analysis_buffer=>clear( ).

    ENDMETHOD.

ENDCLASS.
