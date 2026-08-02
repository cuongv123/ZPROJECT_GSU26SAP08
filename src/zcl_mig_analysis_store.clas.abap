CLASS zcl_mig_analysis_store DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_analysis_store.

  PRIVATE SECTION.

    METHODS cleanup_analysis
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id.

    METHODS raise_store_error
      IMPORTING
        iv_program_name TYPE progname OPTIONAL
        ix_previous     TYPE REF TO cx_root OPTIONAL
      RAISING
        zcx_mig_analysis.

ENDCLASS.

CLASS zcl_mig_analysis_store IMPLEMENTATION.

  METHOD raise_store_error.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid       = zcx_mig_analysis=>analysis_failed
      previous     = ix_previous
      program_name = iv_program_name
    ).

  ENDMETHOD.

    METHOD zif_mig_analysis_store~exists.

    CLEAR rv_exists.

    IF iv_analysis_id IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE analysis_id
      FROM zmig_anl_h
      WHERE analysis_id = @iv_analysis_id
      INTO @DATA(lv_existing_id).

    rv_exists =
      xsdbool(
        sy-subrc = 0
        AND lv_existing_id IS NOT INITIAL
      ).

  ENDMETHOD.

    METHOD cleanup_analysis.

    IF iv_analysis_id IS INITIAL.
      RETURN.
    ENDIF.

    "Child sâu nhất trước
    DELETE FROM zmig_anl_msg
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_ann
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_rec
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_evd
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_evt
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_flt
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_srt
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_col
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_alv
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_log
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_db
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_ui
      WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_src
     WHERE analysis_id = @iv_analysis_id.

    DELETE FROM zmig_anl_h
      WHERE analysis_id = @iv_analysis_id.

  ENDMETHOD.

    METHOD zif_mig_analysis_store~delete.

    IF iv_analysis_id IS INITIAL.

      raise_store_error( ).

    ENDIF.

    IF zif_mig_analysis_store~exists(
         iv_analysis_id = iv_analysis_id
       ) = abap_false.

      raise_store_error( ).

    ENDIF.

    TRY.

        cleanup_analysis(
          iv_analysis_id = iv_analysis_id
        ).

      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

        raise_store_error(
          ix_previous = lx_sql
        ).

    ENDTRY.

  ENDMETHOD.

    METHOD zif_mig_analysis_store~save.

    DATA(lv_analysis_id) =
      is_result-analysis_id.

    IF lv_analysis_id IS INITIAL.

      raise_store_error(
        iv_program_name =
          is_result-overview-program_name
      ).

    ENDIF.

    IF zif_mig_analysis_store~exists(
         iv_analysis_id = lv_analysis_id
       ) = abap_true.

      "Không cho ghi đè analysis đã tồn tại
      raise_store_error(
        iv_program_name =
          is_result-overview-program_name
      ).

    ENDIF.


    DATA lv_timestamp TYPE timestampl.

    GET TIME STAMP FIELD lv_timestamp.


    "========================================================
    " Header
    "========================================================
    DATA ls_header TYPE zmig_anl_h.

    MOVE-CORRESPONDING
      is_result-overview
      TO ls_header.

    ls_header-analysis_id =
      lv_analysis_id.

    ls_header-created_by =
      sy-uname.

    ls_header-created_at =
      lv_timestamp.

    ls_header-last_changed_by =
      sy-uname.

    ls_header-last_changed_at =
      lv_timestamp.

    "========================================================
    " Source Objects
    "
    "Không persist SOURCE_LINES vì đây là runtime data.
    "========================================================
    DATA lt_source_object
      TYPE STANDARD TABLE OF zmig_anl_src
      WITH EMPTY KEY.

    LOOP AT is_result-source_objects
      ASSIGNING FIELD-SYMBOL(<source_object>).

      APPEND VALUE #(
        analysis_id   = lv_analysis_id
        item_id       = <source_object>-item_id
        object_name   = <source_object>-object_name
        object_type   = <source_object>-object_type
        parent_object = <source_object>-parent_object
        include_depth = <source_object>-include_depth
        line_count    = <source_object>-line_count
        source_hash   = <source_object>-source_hash
      ) TO lt_source_object.

    ENDLOOP.

    "====================================================
    " Source Objects
    "====================================================
    IF lt_source_object IS NOT INITIAL.

      INSERT zmig_anl_src
        FROM TABLE @lt_source_object.

      IF sy-subrc <> 0.

        raise_store_error(
          iv_program_name =
            is_result-overview-program_name
        ).

      ENDIF.

    ENDIF.

    "========================================================
    " UI Filters
    "========================================================
    DATA lt_ui TYPE STANDARD TABLE OF zmig_anl_ui
      WITH EMPTY KEY.

    LOOP AT is_result-ui_filters
      ASSIGNING FIELD-SYMBOL(<ui_filter>).

      DATA ls_ui TYPE zmig_anl_ui.

      CLEAR ls_ui.

      MOVE-CORRESPONDING
        <ui_filter>
        TO ls_ui.

      ls_ui-analysis_id =
        lv_analysis_id.

      APPEND ls_ui TO lt_ui.

    ENDLOOP.


    "========================================================
    " Database Objects
    "========================================================
    DATA lt_db TYPE STANDARD TABLE OF zmig_anl_db
      WITH EMPTY KEY.

    LOOP AT is_result-database_objects
      ASSIGNING FIELD-SYMBOL(<database_object>).

      DATA ls_db TYPE zmig_anl_db.

      CLEAR ls_db.

      MOVE-CORRESPONDING
        <database_object>
        TO ls_db.

      ls_db-analysis_id =
        lv_analysis_id.

      APPEND ls_db TO lt_db.

    ENDLOOP.


    "========================================================
    " Business Logic
    "========================================================
    DATA lt_logic TYPE STANDARD TABLE OF zmig_anl_log
      WITH EMPTY KEY.

    LOOP AT is_result-business_logic
      ASSIGNING FIELD-SYMBOL(<business_logic>).

      DATA ls_logic TYPE zmig_anl_log.

      CLEAR ls_logic.

      MOVE-CORRESPONDING
        <business_logic>
        TO ls_logic.

      ls_logic-analysis_id =
        lv_analysis_id.

      APPEND ls_logic TO lt_logic.

    ENDLOOP.



    "========================================================
    " ALV Outputs
    "========================================================
    DATA lt_alv TYPE STANDARD TABLE OF zmig_anl_alv
      WITH EMPTY KEY.

    LOOP AT is_result-alv_outputs
      ASSIGNING FIELD-SYMBOL(<alv_output>).

      DATA ls_alv TYPE zmig_anl_alv.

      CLEAR ls_alv.

      MOVE-CORRESPONDING
        <alv_output>
        TO ls_alv.

      ls_alv-analysis_id =
        lv_analysis_id.

      APPEND ls_alv TO lt_alv.

    ENDLOOP.


    "========================================================
    " ALV Columns
    "
    " Renamed persistence fields:
    " LABEL    → COLUMN_LABEL
    " POSITION → COLUMN_POSITION
    " LENGTH   → FIELD_LENGTH
    "========================================================
    DATA lt_column TYPE STANDARD TABLE OF zmig_anl_col
      WITH EMPTY KEY.

    LOOP AT is_result-alv_columns
      ASSIGNING FIELD-SYMBOL(<alv_column>).

      DATA ls_column TYPE zmig_anl_col.

      CLEAR ls_column.

      MOVE-CORRESPONDING
        <alv_column>
        TO ls_column.

      ls_column-analysis_id =
        lv_analysis_id.

      ls_column-column_label =
        <alv_column>-label.

      ls_column-column_position =
        <alv_column>-position.

      ls_column-field_length =
        <alv_column>-length.

      APPEND ls_column TO lt_column.

    ENDLOOP.


    "========================================================
    " ALV Sorts
    "
    " POSITION → SORT_POSITION
    "========================================================
    DATA lt_sort TYPE STANDARD TABLE OF zmig_anl_srt
      WITH EMPTY KEY.

    LOOP AT is_result-alv_sorts
      ASSIGNING FIELD-SYMBOL(<alv_sort>).

      DATA ls_sort TYPE zmig_anl_srt.

      CLEAR ls_sort.

      MOVE-CORRESPONDING
        <alv_sort>
        TO ls_sort.

      ls_sort-analysis_id =
        lv_analysis_id.

      ls_sort-sort_position =
        <alv_sort>-position.

      APPEND ls_sort TO lt_sort.

    ENDLOOP.


    "========================================================
    " ALV Filters
    "
    " OPTION → FILTER_OPTION
    "========================================================
    DATA lt_filter TYPE STANDARD TABLE OF zmig_anl_flt
      WITH EMPTY KEY.

    LOOP AT is_result-alv_filters
      ASSIGNING FIELD-SYMBOL(<alv_filter>).

      DATA ls_filter TYPE zmig_anl_flt.

      CLEAR ls_filter.

      MOVE-CORRESPONDING
        <alv_filter>
        TO ls_filter.

      ls_filter-analysis_id =
        lv_analysis_id.

      ls_filter-filter_option =
        <alv_filter>-option.

      APPEND ls_filter TO lt_filter.

    ENDLOOP.


    "========================================================
    " ALV Events
    "========================================================
    DATA lt_event TYPE STANDARD TABLE OF zmig_anl_evt
      WITH EMPTY KEY.

    LOOP AT is_result-alv_events
      ASSIGNING FIELD-SYMBOL(<alv_event>).

      DATA ls_event TYPE zmig_anl_evt.

      CLEAR ls_event.

      MOVE-CORRESPONDING
        <alv_event>
        TO ls_event.

      ls_event-analysis_id =
        lv_analysis_id.

      APPEND ls_event TO lt_event.

    ENDLOOP.


    "========================================================
    " Evidence
    "========================================================
    DATA lt_evidence TYPE STANDARD TABLE OF zmig_anl_evd
      WITH EMPTY KEY.

    LOOP AT is_result-evidences
      ASSIGNING FIELD-SYMBOL(<evidence>).

      DATA ls_evidence TYPE zmig_anl_evd.

      CLEAR ls_evidence.

      MOVE-CORRESPONDING
        <evidence>
        TO ls_evidence.

      ls_evidence-analysis_id =
        lv_analysis_id.

      APPEND ls_evidence TO lt_evidence.

    ENDLOOP.


    "========================================================
    " Recommendations
    "========================================================
    DATA lt_recommendation TYPE STANDARD TABLE OF zmig_anl_rec
      WITH EMPTY KEY.

    LOOP AT is_result-recommendations
      ASSIGNING FIELD-SYMBOL(<recommendation>).

      DATA ls_recommendation TYPE zmig_anl_rec.

      CLEAR ls_recommendation.

      MOVE-CORRESPONDING
        <recommendation>
        TO ls_recommendation.

      ls_recommendation-analysis_id =
        lv_analysis_id.

      APPEND ls_recommendation
        TO lt_recommendation.

    ENDLOOP.


    "========================================================
    " Annotation Proposals
    "========================================================
    DATA lt_annotation TYPE STANDARD TABLE OF zmig_anl_ann
      WITH EMPTY KEY.

    LOOP AT is_result-annotations
      ASSIGNING FIELD-SYMBOL(<annotation>).

      DATA ls_annotation TYPE zmig_anl_ann.

      CLEAR ls_annotation.

      MOVE-CORRESPONDING
        <annotation>
        TO ls_annotation.

      ls_annotation-analysis_id =
        lv_analysis_id.

      APPEND ls_annotation
        TO lt_annotation.

    ENDLOOP.


    "========================================================
    " Messages
    "
    " TY_MESSAGE không có ANALYSIS_ID/MESSAGE_NO.
    "========================================================
    DATA lt_message TYPE STANDARD TABLE OF zmig_anl_msg
      WITH EMPTY KEY.

    LOOP AT is_result-messages
      ASSIGNING FIELD-SYMBOL(<message>).

      DATA ls_message TYPE zmig_anl_msg.

      CLEAR ls_message.

      MOVE-CORRESPONDING
        <message>
        TO ls_message.

      ls_message-analysis_id =
        lv_analysis_id.

      ls_message-message_no =
        sy-tabix.

      APPEND ls_message TO lt_message.

    ENDLOOP.

        TRY.

        "====================================================
        " Header
        "====================================================
        INSERT zmig_anl_h
          FROM @ls_header.

        IF sy-subrc <> 0.
          raise_store_error(
            iv_program_name =
              is_result-overview-program_name
          ).
        ENDIF.


        "====================================================
        " Simple children
        "====================================================
        IF lt_ui IS NOT INITIAL.

          INSERT zmig_anl_ui
            FROM TABLE @lt_ui.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_db IS NOT INITIAL.

          INSERT zmig_anl_db
            FROM TABLE @lt_db.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_logic IS NOT INITIAL.

          INSERT zmig_anl_log
            FROM TABLE @lt_logic.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        "====================================================
        " ALV
        "====================================================
        IF lt_alv IS NOT INITIAL.

          INSERT zmig_anl_alv
            FROM TABLE @lt_alv.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_column IS NOT INITIAL.

          INSERT zmig_anl_col
            FROM TABLE @lt_column.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_sort IS NOT INITIAL.

          INSERT zmig_anl_srt
            FROM TABLE @lt_sort.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_filter IS NOT INITIAL.

          INSERT zmig_anl_flt
            FROM TABLE @lt_filter.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_event IS NOT INITIAL.

          INSERT zmig_anl_evt
            FROM TABLE @lt_event.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        "====================================================
        " Evidence, recommendation, annotation, messages
        "====================================================
        IF lt_evidence IS NOT INITIAL.

          INSERT zmig_anl_evd
            FROM TABLE @lt_evidence.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_recommendation IS NOT INITIAL.

          INSERT zmig_anl_rec
            FROM TABLE @lt_recommendation.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_annotation IS NOT INITIAL.

          INSERT zmig_anl_ann
            FROM TABLE @lt_annotation.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


        IF lt_message IS NOT INITIAL.

          INSERT zmig_anl_msg
            FROM TABLE @lt_message.

          IF sy-subrc <> 0.
            raise_store_error(
              iv_program_name =
                is_result-overview-program_name
            ).
          ENDIF.

        ENDIF.


      CATCH zcx_mig_analysis INTO DATA(lx_mig).

        "Dọn những record đã insert trước khi lỗi xảy ra
        cleanup_analysis(
          iv_analysis_id = lv_analysis_id
        ).

        RAISE EXCEPTION lx_mig.


      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

        cleanup_analysis(
          iv_analysis_id = lv_analysis_id
        ).

        raise_store_error(
          iv_program_name =
            is_result-overview-program_name
          ix_previous =
            lx_sql
        ).

    ENDTRY.

  ENDMETHOD.

    METHOD zif_mig_analysis_store~read.

    IF iv_analysis_id IS INITIAL.

      raise_store_error( ).

    ENDIF.


    "========================================================
    " Header
    "========================================================
    SELECT SINGLE *
      FROM zmig_anl_h
      WHERE analysis_id = @iv_analysis_id
      INTO @DATA(ls_header).

    IF sy-subrc <> 0.

      raise_store_error( ).

    ENDIF.


    CLEAR rs_result.

    rs_result-analysis_id =
      iv_analysis_id.

    MOVE-CORRESPONDING
      ls_header
      TO rs_result-overview.

    rs_result-overview-analysis_id =
      iv_analysis_id.

    "========================================================
    " Read all child tables
    "========================================================
    SELECT *
      FROM zmig_anl_ui
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_ui).

    SELECT *
      FROM zmig_anl_db
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_db).

    SELECT *
      FROM zmig_anl_log
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_logic).

    SELECT *
      FROM zmig_anl_alv
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_alv).

    SELECT *
      FROM zmig_anl_col
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_column).

    SELECT *
      FROM zmig_anl_srt
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_sort).

    SELECT *
      FROM zmig_anl_flt
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_filter).

    SELECT *
      FROM zmig_anl_evt
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_event).

    SELECT *
      FROM zmig_anl_evd
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_evidence).

    SELECT *
      FROM zmig_anl_rec
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_recommendation).

    SELECT *
      FROM zmig_anl_ann
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_annotation).

    SELECT *
      FROM zmig_anl_src
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_source_object).

    SELECT *
      FROM zmig_anl_msg
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @DATA(lt_message).


    "========================================================
    " UI
    "========================================================
    LOOP AT lt_ui
      ASSIGNING FIELD-SYMBOL(<db_ui>).

      DATA ls_ui_result
        TYPE zif_mig_types=>ty_ui_filter.

      CLEAR ls_ui_result.

      MOVE-CORRESPONDING
        <db_ui>
        TO ls_ui_result.

      APPEND ls_ui_result
        TO rs_result-ui_filters.

    ENDLOOP.


    "========================================================
    " Database
    "========================================================
    LOOP AT lt_db
      ASSIGNING FIELD-SYMBOL(<db_database>).

      DATA ls_db_result
        TYPE zif_mig_types=>ty_database_object.

      CLEAR ls_db_result.

      MOVE-CORRESPONDING
        <db_database>
        TO ls_db_result.

      APPEND ls_db_result
        TO rs_result-database_objects.

    ENDLOOP.


    "========================================================
    " Business Logic
    "========================================================
    LOOP AT lt_logic
      ASSIGNING FIELD-SYMBOL(<db_logic>).

      DATA ls_logic_result
        TYPE zif_mig_types=>ty_business_logic.

      CLEAR ls_logic_result.

      MOVE-CORRESPONDING
        <db_logic>
        TO ls_logic_result.

      APPEND ls_logic_result
        TO rs_result-business_logic.

    ENDLOOP.


    "========================================================
    " ALV Outputs
    "========================================================
    LOOP AT lt_alv
      ASSIGNING FIELD-SYMBOL(<db_alv>).

      DATA ls_alv_result
        TYPE zif_mig_types=>ty_alv_output.

      CLEAR ls_alv_result.

      MOVE-CORRESPONDING
        <db_alv>
        TO ls_alv_result.

      APPEND ls_alv_result
        TO rs_result-alv_outputs.

    ENDLOOP.


    "========================================================
    " ALV Columns
    "========================================================
    LOOP AT lt_column
      ASSIGNING FIELD-SYMBOL(<db_column>).

      DATA ls_column_result
        TYPE zif_mig_types=>ty_alv_column.

      CLEAR ls_column_result.

      MOVE-CORRESPONDING
        <db_column>
        TO ls_column_result.

      ls_column_result-label =
        <db_column>-column_label.

      ls_column_result-position =
        <db_column>-column_position.

      ls_column_result-length =
        <db_column>-field_length.

      APPEND ls_column_result
        TO rs_result-alv_columns.

    ENDLOOP.


    "========================================================
    " ALV Sorts
    "========================================================
    LOOP AT lt_sort
      ASSIGNING FIELD-SYMBOL(<db_sort>).

      DATA ls_sort_result
        TYPE zif_mig_types=>ty_alv_sort.

      CLEAR ls_sort_result.

      MOVE-CORRESPONDING
        <db_sort>
        TO ls_sort_result.

      ls_sort_result-position =
        <db_sort>-sort_position.

      APPEND ls_sort_result
        TO rs_result-alv_sorts.

    ENDLOOP.


    "========================================================
    " ALV Filters
    "========================================================
    LOOP AT lt_filter
      ASSIGNING FIELD-SYMBOL(<db_filter>).

      DATA ls_filter_result
        TYPE zif_mig_types=>ty_alv_filter.

      CLEAR ls_filter_result.

      MOVE-CORRESPONDING
        <db_filter>
        TO ls_filter_result.

      ls_filter_result-option =
        <db_filter>-filter_option.

      APPEND ls_filter_result
        TO rs_result-alv_filters.

    ENDLOOP.


    "========================================================
    " ALV Events
    "========================================================
    LOOP AT lt_event
      ASSIGNING FIELD-SYMBOL(<db_event>).

      DATA ls_event_result
        TYPE zif_mig_types=>ty_alv_event.

      CLEAR ls_event_result.

      MOVE-CORRESPONDING
        <db_event>
        TO ls_event_result.

      APPEND ls_event_result
        TO rs_result-alv_events.

    ENDLOOP.


    "========================================================
    " Evidence
    "========================================================
    LOOP AT lt_evidence
      ASSIGNING FIELD-SYMBOL(<db_evidence>).

      DATA ls_evidence_result
        TYPE zif_mig_types=>ty_evidence.

      CLEAR ls_evidence_result.

      MOVE-CORRESPONDING
        <db_evidence>
        TO ls_evidence_result.

      APPEND ls_evidence_result
        TO rs_result-evidences.

    ENDLOOP.


    "========================================================
    " Recommendations
    "========================================================
    LOOP AT lt_recommendation
      ASSIGNING FIELD-SYMBOL(<db_recommendation>).

      DATA ls_recommendation_result
        TYPE zif_mig_types=>ty_recommendation.

      CLEAR ls_recommendation_result.

      MOVE-CORRESPONDING
        <db_recommendation>
        TO ls_recommendation_result.

      APPEND ls_recommendation_result
        TO rs_result-recommendations.

    ENDLOOP.


    "========================================================
    " Annotation proposals
    "========================================================
    LOOP AT lt_annotation
      ASSIGNING FIELD-SYMBOL(<db_annotation>).

      DATA ls_annotation_result
        TYPE zif_mig_types=>ty_annotation_proposal.

      CLEAR ls_annotation_result.

      MOVE-CORRESPONDING
        <db_annotation>
        TO ls_annotation_result.

      APPEND ls_annotation_result
        TO rs_result-annotations.

    ENDLOOP.

    "========================================================
    " Source Objects
    "========================================================
    LOOP AT lt_source_object
      ASSIGNING FIELD-SYMBOL(<db_source_object>).

      APPEND VALUE #(
        item_id       = <db_source_object>-item_id
        analysis_id   = <db_source_object>-analysis_id
        object_name   = <db_source_object>-object_name
        object_type   = <db_source_object>-object_type
        parent_object = <db_source_object>-parent_object
        include_depth = <db_source_object>-include_depth
        line_count    = <db_source_object>-line_count
        source_hash   = <db_source_object>-source_hash
      ) TO rs_result-source_objects.

    ENDLOOP.

    SORT rs_result-source_objects
      BY include_depth
         parent_object
         object_name.


    "========================================================
    " Messages
    "========================================================
    SORT lt_message BY message_no.

    LOOP AT lt_message
      ASSIGNING FIELD-SYMBOL(<db_message>).

      DATA ls_message_result
        TYPE zif_mig_types=>ty_message.

      CLEAR ls_message_result.

      MOVE-CORRESPONDING
        <db_message>
        TO ls_message_result.

      APPEND ls_message_result
        TO rs_result-messages.

    ENDLOOP.


    "========================================================
    " Stable sorting
    "========================================================
    SORT rs_result-ui_filters
      BY field_name.

    SORT rs_result-database_objects
      BY object_name
         operation.

    SORT rs_result-business_logic
      BY object_type
         object_name.

    SORT rs_result-alv_outputs
      BY output_id.

    SORT rs_result-alv_columns
      BY output_id
         position
         field_name.

    SORT rs_result-alv_sorts
      BY output_id
         position
         field_name.

    SORT rs_result-alv_filters
      BY output_id
         field_name
         option.

    SORT rs_result-alv_events
      BY output_id
         event_name.

    SORT rs_result-evidences
      BY source_object
         start_line
         statement_id.

    SORT rs_result-recommendations
      BY target_layer
         rule_id
         source_item_id.

    SORT rs_result-annotations
      BY target_entity
         target_element
         sequence.

  ENDMETHOD.

ENDCLASS.
