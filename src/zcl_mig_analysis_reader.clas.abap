CLASS zcl_mig_analysis_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_analysis_reader.

  PRIVATE SECTION.

    METHODS raise_read_error
      IMPORTING
        iv_program_name TYPE progname OPTIONAL
        ix_previous     TYPE REF TO cx_root OPTIONAL
      RAISING
        zcx_mig_analysis.

ENDCLASS.


CLASS zcl_mig_analysis_reader IMPLEMENTATION.

  METHOD raise_read_error.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid       = zcx_mig_analysis=>analysis_failed
      previous     = ix_previous
      program_name = iv_program_name
    ).

  ENDMETHOD.


  METHOD zif_mig_analysis_reader~read.

    CLEAR rs_result.


    IF iv_analysis_id IS INITIAL.

      raise_read_error( ).

    ENDIF.


    TRY.

        "========================================================
        " 1. Header / Overview
        "========================================================
        SELECT SINGLE *
          FROM zmig_anl_h
          WHERE analysis_id = @iv_analysis_id
          INTO @DATA(ls_header).


        IF sy-subrc <> 0.

          raise_read_error( ).

        ENDIF.


        rs_result-analysis_id =
          iv_analysis_id.


        MOVE-CORRESPONDING
          ls_header
          TO rs_result-overview.


        rs_result-overview-analysis_id =
          iv_analysis_id.


        "========================================================
        " 2. Source objects
        "
        " SOURCE_LINES là runtime-only và không được persistence
        " store lưu xuống database.
        "========================================================
        SELECT *
          FROM zmig_anl_src
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_source_db).


        LOOP AT lt_source_db
          ASSIGNING FIELD-SYMBOL(<source_db>).

          DATA ls_source
            TYPE zif_mig_types=>ty_source_object.

          CLEAR ls_source.


          MOVE-CORRESPONDING
            <source_db>
            TO ls_source.


          ls_source-analysis_id =
            iv_analysis_id.


          CLEAR ls_source-source_lines.


          APPEND ls_source
            TO rs_result-source_objects.

        ENDLOOP.


        "========================================================
        " 3. UI filters
        "========================================================
        SELECT *
          FROM zmig_anl_ui
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_ui_db).


        LOOP AT lt_ui_db
          ASSIGNING FIELD-SYMBOL(<ui_db>).

          DATA ls_ui
            TYPE zif_mig_types=>ty_ui_filter.

          CLEAR ls_ui.


          MOVE-CORRESPONDING
            <ui_db>
            TO ls_ui.


          ls_ui-analysis_id =
            iv_analysis_id.


          APPEND ls_ui
            TO rs_result-ui_filters.

        ENDLOOP.


        "========================================================
        " 4. Database objects
        "========================================================
        SELECT *
          FROM zmig_anl_db
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_db_db).


        LOOP AT lt_db_db
          ASSIGNING FIELD-SYMBOL(<db_db>).

          DATA ls_database
            TYPE zif_mig_types=>ty_database_object.

          CLEAR ls_database.


          MOVE-CORRESPONDING
            <db_db>
            TO ls_database.


          ls_database-analysis_id =
            iv_analysis_id.


          APPEND ls_database
            TO rs_result-database_objects.

        ENDLOOP.


        "========================================================
        " 5. Business logic
        "========================================================
        SELECT *
          FROM zmig_anl_log
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_logic_db).


        LOOP AT lt_logic_db
          ASSIGNING FIELD-SYMBOL(<logic_db>).

          DATA ls_logic
            TYPE zif_mig_types=>ty_business_logic.

          CLEAR ls_logic.


          MOVE-CORRESPONDING
            <logic_db>
            TO ls_logic.


          ls_logic-analysis_id =
            iv_analysis_id.


          APPEND ls_logic
            TO rs_result-business_logic.

        ENDLOOP.


        "========================================================
        " 6. ALV outputs
        "========================================================
        SELECT *
          FROM zmig_anl_alv
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_alv_db).


        LOOP AT lt_alv_db
          ASSIGNING FIELD-SYMBOL(<alv_db>).

          DATA ls_alv
            TYPE zif_mig_types=>ty_alv_output.

          CLEAR ls_alv.


          MOVE-CORRESPONDING
            <alv_db>
            TO ls_alv.


          ls_alv-analysis_id =
            iv_analysis_id.


          APPEND ls_alv
            TO rs_result-alv_outputs.

        ENDLOOP.


        "========================================================
        " 7. ALV columns
        "
        " Persistence mapping:
        " COLUMN_LABEL    -> LABEL
        " COLUMN_POSITION -> POSITION
        " FIELD_LENGTH    -> LENGTH
        "========================================================
        SELECT *
          FROM zmig_anl_col
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_column_db).


        LOOP AT lt_column_db
          ASSIGNING FIELD-SYMBOL(<column_db>).

          DATA ls_column
            TYPE zif_mig_types=>ty_alv_column.

          CLEAR ls_column.


          MOVE-CORRESPONDING
            <column_db>
            TO ls_column.


          ls_column-analysis_id =
            iv_analysis_id.

          ls_column-label =
            <column_db>-column_label.

          ls_column-position =
            <column_db>-column_position.

          ls_column-length =
            <column_db>-field_length.


          APPEND ls_column
            TO rs_result-alv_columns.

        ENDLOOP.


        "========================================================
        " 8. ALV sorts
        "
        " SORT_POSITION -> POSITION
        "========================================================
        SELECT *
          FROM zmig_anl_srt
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_sort_db).


        LOOP AT lt_sort_db
          ASSIGNING FIELD-SYMBOL(<sort_db>).

          DATA ls_sort
            TYPE zif_mig_types=>ty_alv_sort.

          CLEAR ls_sort.


          MOVE-CORRESPONDING
            <sort_db>
            TO ls_sort.


          ls_sort-analysis_id =
            iv_analysis_id.

          ls_sort-position =
            <sort_db>-sort_position.


          APPEND ls_sort
            TO rs_result-alv_sorts.

        ENDLOOP.


        "========================================================
        " 9. ALV filters
        "
        " FILTER_OPTION -> OPTION
        "========================================================
        SELECT *
          FROM zmig_anl_flt
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_filter_db).


        LOOP AT lt_filter_db
          ASSIGNING FIELD-SYMBOL(<filter_db>).

          DATA ls_filter
            TYPE zif_mig_types=>ty_alv_filter.

          CLEAR ls_filter.


          MOVE-CORRESPONDING
            <filter_db>
            TO ls_filter.


          ls_filter-analysis_id =
            iv_analysis_id.

          ls_filter-option =
            <filter_db>-filter_option.


          APPEND ls_filter
            TO rs_result-alv_filters.

        ENDLOOP.


        "========================================================
        " 10. ALV events
        "========================================================
        SELECT *
          FROM zmig_anl_evt
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_event_db).


        LOOP AT lt_event_db
          ASSIGNING FIELD-SYMBOL(<event_db>).

          DATA ls_event
            TYPE zif_mig_types=>ty_alv_event.

          CLEAR ls_event.


          MOVE-CORRESPONDING
            <event_db>
            TO ls_event.


          ls_event-analysis_id =
            iv_analysis_id.


          APPEND ls_event
            TO rs_result-alv_events.

        ENDLOOP.


        "========================================================
        " 11. Evidences
        "========================================================
        SELECT *
          FROM zmig_anl_evd
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_evidence_db).


        LOOP AT lt_evidence_db
          ASSIGNING FIELD-SYMBOL(<evidence_db>).

          DATA ls_evidence
            TYPE zif_mig_types=>ty_evidence.

          CLEAR ls_evidence.


          MOVE-CORRESPONDING
            <evidence_db>
            TO ls_evidence.


          ls_evidence-analysis_id =
            iv_analysis_id.


          APPEND ls_evidence
            TO rs_result-evidences.

        ENDLOOP.


        "========================================================
        " 12. Recommendations
        "========================================================
        SELECT *
          FROM zmig_anl_rec
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_recommendation_db).


        LOOP AT lt_recommendation_db
          ASSIGNING FIELD-SYMBOL(<recommendation_db>).

          DATA ls_recommendation
            TYPE zif_mig_types=>ty_recommendation.

          CLEAR ls_recommendation.


          MOVE-CORRESPONDING
            <recommendation_db>
            TO ls_recommendation.


          ls_recommendation-analysis_id =
            iv_analysis_id.


          APPEND ls_recommendation
            TO rs_result-recommendations.

        ENDLOOP.


        "========================================================
        " 13. Annotation proposals
        "========================================================
        SELECT *
          FROM zmig_anl_ann
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_annotation_db).


        LOOP AT lt_annotation_db
          ASSIGNING FIELD-SYMBOL(<annotation_db>).

          DATA ls_annotation
            TYPE zif_mig_types=>ty_annotation_proposal.

          CLEAR ls_annotation.


          MOVE-CORRESPONDING
            <annotation_db>
            TO ls_annotation.


          ls_annotation-analysis_id =
            iv_analysis_id.


          APPEND ls_annotation
            TO rs_result-annotations.

        ENDLOOP.


        "========================================================
        " 14. Messages
        "
        " TY_MESSAGE không có ANALYSIS_ID và MESSAGE_NO.
        " MOVE-CORRESPONDING sẽ chỉ lấy business fields.
        "========================================================
        SELECT *
          FROM zmig_anl_msg
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @DATA(lt_message_db).


        LOOP AT lt_message_db
          ASSIGNING FIELD-SYMBOL(<message_db>).

          DATA ls_message
            TYPE zif_mig_types=>ty_message.

          CLEAR ls_message.


          MOVE-CORRESPONDING
            <message_db>
            TO ls_message.


          APPEND ls_message
            TO rs_result-messages.

        ENDLOOP.


      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

        raise_read_error(
          iv_program_name =
            rs_result-overview-program_name

          ix_previous =
            lx_sql
        ).

    ENDTRY.


    "==========================================================
    " Stable sorting
    "==========================================================
    SORT rs_result-source_objects
      BY include_depth
         parent_object
         object_name.

    SORT rs_result-ui_filters
      BY field_name.

    SORT rs_result-database_objects
      BY object_name
         operation.

    SORT rs_result-business_logic
      BY object_type
         object_name.

    SORT rs_result-alv_outputs
      BY framework
         output_name.

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
         event_name
         handler_name.

    SORT rs_result-evidences
      BY source_object
         start_line
         statement_id.

    SORT rs_result-recommendations
      BY recommendation_id.

    SORT rs_result-annotations
      BY recommendation_id
         sequence.

    SORT rs_result-messages
      BY message_type
         message_code
         source_object
         source_line.

  ENDMETHOD.

ENDCLASS.
