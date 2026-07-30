CLASS zcl_mig_complexity_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_complexity_engine.

  PRIVATE SECTION.

    CONSTANTS:
      gc_score_min TYPE i VALUE 0,
      gc_score_max TYPE i VALUE 100.

    METHODS add_ui_complexity
      IMPORTING
        it_ui_filters TYPE zif_mig_types=>tt_ui_filter
      CHANGING
        cv_complexity TYPE i.

    METHODS add_database_complexity
      IMPORTING
        it_database_objects
          TYPE zif_mig_types=>tt_database_object
      CHANGING
        cv_complexity        TYPE i
        cv_readiness_penalty TYPE i.

    METHODS add_logic_complexity
      IMPORTING
        it_business_logic
          TYPE zif_mig_types=>tt_business_logic
      CHANGING
        cv_complexity        TYPE i
        cv_readiness_penalty TYPE i.

    METHODS add_alv_complexity
      IMPORTING
        it_alv_outputs TYPE zif_mig_types=>tt_alv_output
        it_alv_columns TYPE zif_mig_types=>tt_alv_column
        it_alv_sorts   TYPE zif_mig_types=>tt_alv_sort
        it_alv_filters TYPE zif_mig_types=>tt_alv_filter
        it_alv_events  TYPE zif_mig_types=>tt_alv_event
      CHANGING
        cv_complexity        TYPE i
        cv_readiness_penalty TYPE i.

    METHODS cap_score
      IMPORTING
        iv_score TYPE i
      RETURNING
        VALUE(rv_score) TYPE i.

ENDCLASS.

CLASS zcl_mig_complexity_engine IMPLEMENTATION.

  METHOD zif_mig_complexity_engine~enrich.

    DATA:
      lv_complexity_points  TYPE i,
      lv_readiness_penalty  TYPE i,
      lv_readiness_score    TYPE i.

    CLEAR:
      lv_complexity_points,
      lv_readiness_penalty,
      lv_readiness_score.


    "========================================================
    " Selection screen complexity
    "========================================================
    add_ui_complexity(
      EXPORTING
        it_ui_filters = cs_result-ui_filters
      CHANGING
        cv_complexity = lv_complexity_points
    ).


    "========================================================
    " Database complexity and readiness penalties
    "========================================================
    add_database_complexity(
      EXPORTING
        it_database_objects =
          cs_result-database_objects
      CHANGING
        cv_complexity =
          lv_complexity_points
        cv_readiness_penalty =
          lv_readiness_penalty
    ).


    "========================================================
    " Business logic complexity
    "========================================================
    add_logic_complexity(
      EXPORTING
        it_business_logic =
          cs_result-business_logic
      CHANGING
        cv_complexity =
          lv_complexity_points
        cv_readiness_penalty =
          lv_readiness_penalty
    ).


    "========================================================
    " ALV complexity
    "========================================================
    add_alv_complexity(
      EXPORTING
        it_alv_outputs =
          cs_result-alv_outputs
        it_alv_columns =
          cs_result-alv_columns
        it_alv_sorts =
          cs_result-alv_sorts
        it_alv_filters =
          cs_result-alv_filters
        it_alv_events =
          cs_result-alv_events
      CHANGING
        cv_complexity =
          lv_complexity_points
        cv_readiness_penalty =
          lv_readiness_penalty
    ).


    "========================================================
    " Normalize scores to 0..100
    "========================================================
    lv_complexity_points =
      cap_score(
        iv_score = lv_complexity_points
      ).

    lv_readiness_penalty =
      cap_score(
        iv_score = lv_readiness_penalty
      ).

    lv_readiness_score =
      gc_score_max - lv_readiness_penalty.

    lv_readiness_score =
      cap_score(
        iv_score = lv_readiness_score
      ).


    "Implicit numeric conversion: I → DECFLOAT16
    cs_result-overview-complexity_score =
      lv_complexity_points.

    cs_result-overview-readiness_score =
      lv_readiness_score.

  ENDMETHOD.

    METHOD add_ui_complexity.

    DATA(lv_ui_points) =
      lines( it_ui_filters ).

    IF lv_ui_points > 10.
      lv_ui_points = 10.
    ENDIF.

    cv_complexity +=
      lv_ui_points.

  ENDMETHOD.

    METHOD add_database_complexity.

    LOOP AT it_database_objects
      ASSIGNING FIELD-SYMBOL(<database_object>).

      "Mỗi database interaction có độ phức tạp cơ bản
      cv_complexity += 2.


      "======================================================
      " Write operations
      "======================================================
      CASE <database_object>-operation.

        WHEN 'INSERT'
          OR 'UPDATE'
          OR 'MODIFY'
          OR 'DELETE'.

          cv_complexity += 4.

          cv_readiness_penalty += 5.

      ENDCASE.


      "======================================================
      " Dynamic table/view access
      "======================================================
      IF <database_object>-dynamic_access = abap_true.

        cv_complexity += 5.

        cv_readiness_penalty += 10.

      ENDIF.


      "======================================================
      " JOIN
      "======================================================
      IF <database_object>-joined_objects
           IS NOT INITIAL.

        cv_complexity += 3.

        cv_readiness_penalty += 2.

      ENDIF.


      "======================================================
      " Aggregation: COUNT, SUM, MIN, MAX, AVG
      "======================================================
      IF <database_object>-aggregation
           IS NOT INITIAL.

        cv_complexity += 2.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD add_logic_complexity.

    LOOP AT it_business_logic
      ASSIGNING FIELD-SYMBOL(<business_logic>).

      cv_complexity += 2.


      "======================================================
      " GUI dependency
      "======================================================
      IF <business_logic>-gui_dependency = abap_true.

        cv_complexity += 8.

        cv_readiness_penalty += 12.

      ENDIF.


      "======================================================
      " Transaction dependency
      "======================================================
      IF <business_logic>-transaction_dependency
           = abap_true.

        cv_complexity += 5.

        cv_readiness_penalty += 8.

      ENDIF.


      "======================================================
      " Object-specific rules
      "======================================================
      CASE <business_logic>-object_type.

        WHEN 'FORM_DEFINITION'
          OR 'FORM_CALL'.

          cv_complexity += 4.

          cv_readiness_penalty += 4.


        WHEN 'REPORT_SUBMIT'.

          cv_complexity += 5.

          cv_readiness_penalty += 6.


        WHEN 'BAPI'
          OR 'FUNCTION_MODULE'
          OR 'FUNCTION_DEFINITION'.

          cv_complexity += 2.

          cv_readiness_penalty += 2.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

    METHOD add_alv_complexity.

    "========================================================
    " Output framework and behavior
    "========================================================
    LOOP AT it_alv_outputs
      ASSIGNING FIELD-SYMBOL(<alv_output>).

      cv_complexity += 3.

      IF <alv_output>-editable = abap_true.

        cv_complexity += 4.

        cv_readiness_penalty += 5.

      ENDIF.

      IF <alv_output>-hierarchical = abap_true.

        cv_complexity += 5.

        cv_readiness_penalty += 5.

      ENDIF.

    ENDLOOP.


    "========================================================
    " Columns: one point for each group of five columns
    "========================================================
    DATA(lv_column_count) =
      lines( it_alv_columns ).

    DATA(lv_column_points) =
      ( lv_column_count + 4 ) DIV 5.

    IF lv_column_points > 10.
      lv_column_points = 10.
    ENDIF.

    cv_complexity +=
      lv_column_points.


    "========================================================
    " Sort definitions
    "========================================================
    DATA(lv_sort_points) =
      lines( it_alv_sorts ).

    IF lv_sort_points > 5.
      lv_sort_points = 5.
    ENDIF.

    cv_complexity +=
      lv_sort_points.


    "========================================================
    " Filter definitions
    "========================================================
    DATA(lv_filter_points) =
      lines( it_alv_filters ).

    IF lv_filter_points > 5.
      lv_filter_points = 5.
    ENDIF.

    cv_complexity +=
      lv_filter_points.


    "========================================================
    " Event handlers
    "========================================================
    DATA(lv_event_points) =
      lines( it_alv_events ) * 2.

    IF lv_event_points > 10.
      lv_event_points = 10.
    ENDIF.

    cv_complexity +=
      lv_event_points.

    cv_readiness_penalty +=
      lv_event_points.

  ENDMETHOD.

    METHOD cap_score.

    rv_score = iv_score.

    IF rv_score < gc_score_min.

      rv_score =
        gc_score_min.

    ELSEIF rv_score > gc_score_max.

      rv_score =
        gc_score_max.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
