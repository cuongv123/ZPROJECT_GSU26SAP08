CLASS zcl_mig_recommend_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_recommend_engine.

  PRIVATE SECTION.

    TYPES:
      ty_title           TYPE c LENGTH 120,
      ty_review_status   TYPE c LENGTH 20,
      ty_target_entity   TYPE c LENGTH 80,
      ty_target_element  TYPE c LENGTH 80,
      ty_annotation_name TYPE c LENGTH 120.

    TYPES:
      BEGIN OF ty_output_map,
        output_id     TYPE zif_mig_types=>ty_item_id,
        target_entity TYPE ty_target_entity,
      END OF ty_output_map,

      tt_output_map TYPE HASHED TABLE OF ty_output_map
        WITH UNIQUE KEY output_id.

    CONSTANTS:
      gc_rule_version TYPE c LENGTH 10 VALUE '1.0',
      gc_review_new   TYPE ty_review_status VALUE 'NEW'.

    METHODS build_output_map
      IMPORTING
        it_alv_outputs TYPE zif_mig_types=>tt_alv_output
      RETURNING
        VALUE(rt_output_map) TYPE tt_output_map.

    METHODS recommend_ui_filters
      IMPORTING
        iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id
        iv_target_entity TYPE ty_target_entity
        it_ui_filters   TYPE zif_mig_types=>tt_ui_filter
      CHANGING
        ct_recommendations TYPE zif_mig_types=>tt_recommendation
        ct_annotations     TYPE zif_mig_types=>tt_annotation_proposal
      RAISING
        zcx_mig_analysis.

    METHODS recommend_database
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_database_objects
          TYPE zif_mig_types=>tt_database_object
      CHANGING
        ct_recommendations
          TYPE zif_mig_types=>tt_recommendation
      RAISING
        zcx_mig_analysis.

    METHODS recommend_business_logic
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_business_logic
          TYPE zif_mig_types=>tt_business_logic
      CHANGING
        ct_recommendations
          TYPE zif_mig_types=>tt_recommendation
      RAISING
        zcx_mig_analysis.

    METHODS recommend_alv_columns
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_alv_columns TYPE zif_mig_types=>tt_alv_column
        it_output_map  TYPE tt_output_map
      CHANGING
        ct_recommendations TYPE zif_mig_types=>tt_recommendation
        ct_annotations     TYPE zif_mig_types=>tt_annotation_proposal
      RAISING
        zcx_mig_analysis.

    METHODS recommend_alv_sorts
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_alv_sorts   TYPE zif_mig_types=>tt_alv_sort
        it_output_map  TYPE tt_output_map
      CHANGING
        ct_recommendations TYPE zif_mig_types=>tt_recommendation
        ct_annotations     TYPE zif_mig_types=>tt_annotation_proposal
      RAISING
        zcx_mig_analysis.

    METHODS recommend_alv_filters
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_alv_filters TYPE zif_mig_types=>tt_alv_filter
        it_output_map  TYPE tt_output_map
      CHANGING
        ct_recommendations TYPE zif_mig_types=>tt_recommendation
        ct_annotations     TYPE zif_mig_types=>tt_annotation_proposal
      RAISING
        zcx_mig_analysis.

    METHODS recommend_alv_events
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_alv_events  TYPE zif_mig_types=>tt_alv_event
      CHANGING
        ct_recommendations
          TYPE zif_mig_types=>tt_recommendation
      RAISING
        zcx_mig_analysis.

    METHODS add_recommendation
      IMPORTING
        iv_analysis_id    TYPE zif_mig_types=>ty_analysis_id
        iv_source_item_id TYPE zif_mig_types=>ty_item_id
        iv_evidence_id    TYPE zif_mig_types=>ty_evidence_id
        iv_rule_id        TYPE zif_mig_types=>ty_rule_id
        iv_target_layer   TYPE zif_mig_types=>ty_target_layer
        iv_title          TYPE ty_title
        iv_display_text   TYPE string
        iv_explanation    TYPE string
        iv_severity       TYPE zif_mig_types=>ty_severity
        iv_confidence     TYPE zif_mig_types=>ty_confidence
        iv_manual_review  TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_recommendation_id
          TYPE zif_mig_types=>ty_recommendation_id
      CHANGING
        ct_recommendations
          TYPE zif_mig_types=>tt_recommendation
      RAISING
        zcx_mig_analysis.

    METHODS add_annotation
      IMPORTING
        iv_analysis_id       TYPE zif_mig_types=>ty_analysis_id
        iv_recommendation_id TYPE zif_mig_types=>ty_recommendation_id
        iv_target_entity     TYPE ty_target_entity
        iv_target_element    TYPE ty_target_element
        iv_annotation_name   TYPE ty_annotation_name
        iv_annotation_value  TYPE string
        iv_sequence          TYPE i
      CHANGING
        ct_annotations
          TYPE zif_mig_types=>tt_annotation_proposal
      RAISING
        zcx_mig_analysis.

    METHODS create_uuid
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_mig_analysis.

ENDCLASS.

CLASS zcl_mig_recommend_engine IMPLEMENTATION.

  METHOD zif_mig_recommend_engine~enrich.

    DATA lv_analysis_id
      TYPE zif_mig_types=>ty_analysis_id.

    lv_analysis_id =
      cs_result-analysis_id.

    IF lv_analysis_id IS INITIAL.

      lv_analysis_id =
        cs_result-overview-analysis_id.

    ENDIF.

    IF lv_analysis_id IS INITIAL.

      lv_analysis_id =
        create_uuid(
          iv_source_object =
            cs_result-overview-program_name
        ).

    ENDIF.

    cs_result-analysis_id =
      lv_analysis_id.

    cs_result-overview-analysis_id =
      lv_analysis_id.


    "Engine được thiết kế idempotent:
    "chạy lại sẽ rebuild thay vì append trùng.
    CLEAR:
      cs_result-recommendations,
      cs_result-annotations.


    DATA lv_target_entity TYPE ty_target_entity.

    lv_target_entity =
      cs_result-overview-program_name.

    IF lv_target_entity IS INITIAL.
      lv_target_entity = 'ROOT_ENTITY'.
    ENDIF.


    DATA(lt_output_map) =
      build_output_map(
        it_alv_outputs =
          cs_result-alv_outputs
      ).


    recommend_ui_filters(
      EXPORTING
        iv_analysis_id    = lv_analysis_id
        iv_target_entity  = lv_target_entity
        it_ui_filters     = cs_result-ui_filters
      CHANGING
        ct_recommendations = cs_result-recommendations
        ct_annotations     = cs_result-annotations
    ).


    recommend_database(
      EXPORTING
        iv_analysis_id =
          lv_analysis_id
        it_database_objects =
          cs_result-database_objects
      CHANGING
        ct_recommendations =
          cs_result-recommendations
    ).


    recommend_business_logic(
      EXPORTING
        iv_analysis_id =
          lv_analysis_id
        it_business_logic =
          cs_result-business_logic
      CHANGING
        ct_recommendations =
          cs_result-recommendations
    ).


    recommend_alv_columns(
      EXPORTING
        iv_analysis_id =
          lv_analysis_id
        it_alv_columns =
          cs_result-alv_columns
        it_output_map =
          lt_output_map
      CHANGING
        ct_recommendations =
          cs_result-recommendations
        ct_annotations =
          cs_result-annotations
    ).


    recommend_alv_sorts(
      EXPORTING
        iv_analysis_id =
          lv_analysis_id
        it_alv_sorts =
          cs_result-alv_sorts
        it_output_map =
          lt_output_map
      CHANGING
        ct_recommendations =
          cs_result-recommendations
        ct_annotations =
          cs_result-annotations
    ).


    recommend_alv_filters(
      EXPORTING
        iv_analysis_id =
          lv_analysis_id
        it_alv_filters =
          cs_result-alv_filters
        it_output_map =
          lt_output_map
      CHANGING
        ct_recommendations =
          cs_result-recommendations
        ct_annotations =
          cs_result-annotations
    ).


    recommend_alv_events(
      EXPORTING
        iv_analysis_id =
          lv_analysis_id
        it_alv_events =
          cs_result-alv_events
      CHANGING
        ct_recommendations =
          cs_result-recommendations
    ).


    SORT cs_result-recommendations
      BY target_layer
         rule_id
         source_item_id.

    SORT cs_result-annotations
      BY target_entity
         target_element
         sequence
         annotation_name.


    cs_result-overview-total_recommendations =
      lines( cs_result-recommendations ).

    cs_result-overview-rule_version =
      gc_rule_version.

  ENDMETHOD.

    METHOD build_output_map.

    LOOP AT it_alv_outputs
      ASSIGNING FIELD-SYMBOL(<output>).

      DATA lv_target_entity TYPE ty_target_entity.

      lv_target_entity =
        <output>-output_name.

      IF lv_target_entity IS INITIAL.

        lv_target_entity =
          <output>-output_table.

      ENDIF.

      IF lv_target_entity IS INITIAL.

        lv_target_entity =
          'ALV_OUTPUT'.

      ENDIF.

      INSERT VALUE #(
        output_id     = <output>-output_id
        target_entity = lv_target_entity
      ) INTO TABLE rt_output_map.

    ENDLOOP.

  ENDMETHOD.

    METHOD recommend_ui_filters.

    LOOP AT it_ui_filters
      ASSIGNING FIELD-SYMBOL(<filter>).

      DATA(lv_field_kind) =
        to_upper(
          CONV string(
            <filter>-field_kind
          )
        ).

      DATA(lv_is_range) =
        xsdbool(
          <filter>-multiple_selection = abap_true
          OR <filter>-range_supported = abap_true
          OR lv_field_kind = 'SELECT_OPTION'
          OR lv_field_kind = 'SELECT_OPTIONS'
          OR lv_field_kind = 'SELECT-OPTIONS'
        ).

      DATA:
        lv_rule_id    TYPE zif_mig_types=>ty_rule_id,
        lv_title      TYPE ty_title,
        lv_value      TYPE string,
        lv_display    TYPE string,
        lv_explanation TYPE string.

      IF lv_is_range = abap_true.

        lv_rule_id =
          'UI_FILTER_RANGE'.

        lv_title =
          'Convert range selection to FilterBar'.

        lv_value =
          '#RANGE'.

        lv_display =
          |Map { <filter>-field_name } to a range-capable Fiori filter.|.

        lv_explanation =
          |The legacy selection field supports ranges or multiple values and should remain range-capable in the target UI.|.

      ELSE.

        lv_rule_id =
          'UI_FILTER_SINGLE'.

        lv_title =
          'Convert parameter to FilterBar'.

        lv_value =
          '#SINGLE'.

        lv_display =
          |Map { <filter>-field_name } to a single-value Fiori filter.|.

        lv_explanation =
          |The legacy parameter can be represented as a standard single-value filter in the target application.|.

      ENDIF.

      DATA lv_recommendation_id
        TYPE zif_mig_types=>ty_recommendation_id.

      add_recommendation(
        EXPORTING
          iv_analysis_id =
            iv_analysis_id
          iv_source_item_id =
            <filter>-item_id
          iv_evidence_id =
            <filter>-evidence_id
          iv_rule_id =
            lv_rule_id
          iv_target_layer =
            zif_mig_types=>gc_target_fiori
          iv_title =
            lv_title
          iv_display_text =
            lv_display
          iv_explanation =
            lv_explanation
          iv_severity =
            zif_mig_types=>gc_sev_low
          iv_confidence =
            <filter>-confidence
          iv_manual_review =
            abap_false
        IMPORTING
          ev_recommendation_id =
            lv_recommendation_id
        CHANGING
          ct_recommendations =
            ct_recommendations
      ).

      add_annotation(
        EXPORTING
          iv_analysis_id =
            iv_analysis_id
          iv_recommendation_id =
            lv_recommendation_id
          iv_target_entity =
            iv_target_entity
          iv_target_element =
          CONV ty_target_element(
            <filter>-field_name
          )
          iv_annotation_name =
            '@Consumption.filter.selectionType'
          iv_annotation_value =
            lv_value
          iv_sequence =
            10
        CHANGING
          ct_annotations =
            ct_annotations
      ).

      IF <filter>-mandatory = abap_true.

        add_annotation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_recommendation_id =
              lv_recommendation_id
            iv_target_entity =
              iv_target_entity
            iv_target_element =
              CONV ty_target_element(
                <filter>-field_name
              )
            iv_annotation_name =
              '@Consumption.filter.mandatory'
            iv_annotation_value =
              'true'
            iv_sequence =
              20
          CHANGING
            ct_annotations =
              ct_annotations
        ).

      ENDIF.

      IF <filter>-hidden = abap_true.

        add_annotation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_recommendation_id =
              lv_recommendation_id
            iv_target_entity =
              iv_target_entity
            iv_target_element =
              CONV ty_target_element(
                <filter>-field_name
              )
            iv_annotation_name =
              '@Consumption.filter.hidden'
            iv_annotation_value =
              'true'
            iv_sequence =
              30
          CHANGING
            ct_annotations =
              ct_annotations
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD recommend_database.

    LOOP AT it_database_objects
      ASSIGNING FIELD-SYMBOL(<database_object>).

      DATA(lv_operation) =
        to_upper(
          CONV string(
            <database_object>-operation
          )
        ).

      DATA lv_recommendation_id
        TYPE zif_mig_types=>ty_recommendation_id.


      "======================================================
      " Read access → CDS View Entity
      "======================================================
      IF lv_operation = 'SELECT'
         OR <database_object>-read_only = abap_true.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <database_object>-item_id
            iv_evidence_id =
              <database_object>-evidence_id
            iv_rule_id =
              'DB_READ_CDS'
            iv_target_layer =
              zif_mig_types=>gc_target_cds
            iv_title =
              'Model database read as CDS view entity'
            iv_display_text =
              |Expose read access to { <database_object>-object_name } through a CDS view entity.|
            iv_explanation =
              |The legacy report reads database data directly. Move the reusable read model to CDS and expose it through RAP query capabilities.|
            iv_severity =
              zif_mig_types=>gc_sev_medium
            iv_confidence =
              <database_object>-confidence
            iv_manual_review =
              abap_false
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

      ENDIF.


      "======================================================
      " Write access → RAP behavior/action
      "======================================================
      CASE lv_operation.

        WHEN 'INSERT'
          OR 'UPDATE'
          OR 'MODIFY'
          OR 'DELETE'.

          add_recommendation(
            EXPORTING
              iv_analysis_id =
                iv_analysis_id
              iv_source_item_id =
                <database_object>-item_id
              iv_evidence_id =
                <database_object>-evidence_id
              iv_rule_id =
                'DB_WRITE_RAP'
              iv_target_layer =
                zif_mig_types=>gc_target_rap_action
              iv_title =
                'Move database write into RAP behavior'
              iv_display_text =
                |Replace direct { lv_operation } access to { <database_object>-object_name } with RAP behavior logic.|
              iv_explanation =
                |Direct database modification should be placed behind controlled RAP create, update, delete, determination, validation or action processing.|
              iv_severity =
                zif_mig_types=>gc_sev_high
              iv_confidence =
                <database_object>-confidence
              iv_manual_review =
                abap_true
            IMPORTING
              ev_recommendation_id =
                lv_recommendation_id
            CHANGING
              ct_recommendations =
                ct_recommendations
          ).

      ENDCASE.


      "======================================================
      " Dynamic access requires manual review
      "======================================================
      IF <database_object>-dynamic_access = abap_true.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <database_object>-item_id
            iv_evidence_id =
              <database_object>-evidence_id
            iv_rule_id =
              'DB_DYNAMIC_ACCESS'
            iv_target_layer =
              zif_mig_types=>gc_target_manual
            iv_title =
              'Review dynamic database access'
            iv_display_text =
              |Dynamic access to { <database_object>-object_name } requires redesign.|
            iv_explanation =
              |The target entity cannot be derived reliably at design time. Replace dynamic access with a controlled allow-list or explicit query implementation.|
            iv_severity =
              zif_mig_types=>gc_sev_high
            iv_confidence =
              <database_object>-confidence
            iv_manual_review =
              abap_true
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD recommend_business_logic.

    LOOP AT it_business_logic
      ASSIGNING FIELD-SYMBOL(<logic>).

      DATA(lv_object_type) =
        to_upper(
          CONV string(
            <logic>-object_type
          )
        ).

      DATA lv_recommendation_id
        TYPE zif_mig_types=>ty_recommendation_id.


      IF <logic>-gui_dependency = abap_true.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <logic>-item_id
            iv_evidence_id =
              <logic>-evidence_id
            iv_rule_id =
              'LOGIC_GUI_REDESIGN'
            iv_target_layer =
              zif_mig_types=>gc_target_redesign
            iv_title =
              'Redesign SAP GUI dependent logic'
            iv_display_text =
              |Redesign GUI-dependent logic { <logic>-object_name } for SAPUI5.|
            iv_explanation =
              |Dynpro, GUI control and interactive report behavior cannot be transferred directly to Fiori and requires an explicit UI design.|
            iv_severity =
              zif_mig_types=>gc_sev_high
            iv_confidence =
              <logic>-confidence
            iv_manual_review =
              abap_true
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

      ENDIF.


      IF <logic>-transaction_dependency = abap_true.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <logic>-item_id
            iv_evidence_id =
              <logic>-evidence_id
            iv_rule_id =
              'LOGIC_TRANSACTION_REVIEW'
            iv_target_layer =
              zif_mig_types=>gc_target_manual
            iv_title =
              'Review transaction dependency'
            iv_display_text =
              |Review transaction-dependent logic { <logic>-object_name }.|
            iv_explanation =
              |Transaction calls and implicit LUW behavior must be redesigned for RAP save sequencing and controlled commit handling.|
            iv_severity =
              zif_mig_types=>gc_sev_high
            iv_confidence =
              <logic>-confidence
            iv_manual_review =
              abap_true
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

      ENDIF.


      CASE lv_object_type.

        WHEN 'FORM_DEFINITION'
          OR 'FORM_CALL'.

          add_recommendation(
            EXPORTING
              iv_analysis_id =
                iv_analysis_id
              iv_source_item_id =
                <logic>-item_id
              iv_evidence_id =
                <logic>-evidence_id
              iv_rule_id =
                'LOGIC_FORM_CLASS'
              iv_target_layer =
                zif_mig_types=>gc_target_manual
              iv_title =
                'Refactor FORM logic into ABAP class'
              iv_display_text =
                |Move { <logic>-object_name } from FORM/PERFORM into a reusable class method.|
              iv_explanation =
                |Procedural FORM routines should be separated into typed application or domain services before RAP exposure.|
              iv_severity =
                zif_mig_types=>gc_sev_medium
              iv_confidence =
                <logic>-confidence
              iv_manual_review =
                abap_true
            IMPORTING
              ev_recommendation_id =
                lv_recommendation_id
            CHANGING
              ct_recommendations =
                ct_recommendations
          ).


        WHEN 'BAPI'
          OR 'FUNCTION_MODULE'
          OR 'FUNCTION_DEFINITION'.

          add_recommendation(
            EXPORTING
              iv_analysis_id =
                iv_analysis_id
              iv_source_item_id =
                <logic>-item_id
              iv_evidence_id =
                <logic>-evidence_id
              iv_rule_id =
                'LOGIC_FM_ADAPTER'
              iv_target_layer =
                zif_mig_types=>gc_target_rap_action
              iv_title =
                'Wrap reusable function behind adapter'
              iv_display_text =
                |Expose { <logic>-object_name } through an application service or RAP action.|
              iv_explanation =
                |Keep reusable business behavior behind a typed adapter instead of invoking the function directly from the UI service layer.|
              iv_severity =
                zif_mig_types=>gc_sev_medium
              iv_confidence =
                <logic>-confidence
              iv_manual_review =
                abap_true
            IMPORTING
              ev_recommendation_id =
                lv_recommendation_id
            CHANGING
              ct_recommendations =
                ct_recommendations
          ).


        WHEN 'REPORT_SUBMIT'.

          add_recommendation(
            EXPORTING
              iv_analysis_id =
                iv_analysis_id
              iv_source_item_id =
                <logic>-item_id
              iv_evidence_id =
                <logic>-evidence_id
              iv_rule_id =
                'LOGIC_SUBMIT_QUERY'
              iv_target_layer =
                zif_mig_types=>gc_target_rap_query
              iv_title =
                'Replace SUBMIT with explicit query service'
              iv_display_text =
                |Replace report submission { <logic>-object_name } with a typed query or application service.|
              iv_explanation =
                |SUBMIT creates hidden coupling to another executable report and should not become part of the OData request flow.|
              iv_severity =
                zif_mig_types=>gc_sev_high
              iv_confidence =
                <logic>-confidence
              iv_manual_review =
                abap_true
            IMPORTING
              ev_recommendation_id =
                lv_recommendation_id
            CHANGING
              ct_recommendations =
                ct_recommendations
          ).

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

    METHOD recommend_alv_columns.

    LOOP AT it_alv_columns
      ASSIGNING FIELD-SYMBOL(<column>).

      DATA lv_target_entity TYPE ty_target_entity.

      READ TABLE it_output_map
        WITH TABLE KEY
          output_id = <column>-output_id
        INTO DATA(ls_output_map).

      IF sy-subrc = 0.
        lv_target_entity = ls_output_map-target_entity.
      ELSE.
        lv_target_entity = 'ALV_OUTPUT'.
      ENDIF.

      DATA lv_recommendation_id
        TYPE zif_mig_types=>ty_recommendation_id.


      "======================================================
      " Technical field → hidden
      "======================================================
      IF <column>-technical = abap_true.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <column>-item_id
            iv_evidence_id =
              <column>-evidence_id
            iv_rule_id =
              'ALV_COLUMN_HIDDEN'
            iv_target_layer =
              zif_mig_types=>gc_target_fiori
            iv_title =
              'Hide technical ALV column'
            iv_display_text =
              |Keep technical column { <column>-field_name } hidden in Fiori.|
            iv_explanation =
              |The legacy field catalog marks this column as technical and it should not be displayed as a normal line item.|
            iv_severity =
              zif_mig_types=>gc_sev_info
            iv_confidence =
              <column>-confidence
            iv_manual_review =
              abap_false
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

        add_annotation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_recommendation_id =
              lv_recommendation_id
            iv_target_entity =
              lv_target_entity
            iv_target_element =
              CONV ty_target_element(
                <column>-field_name
              )
            iv_annotation_name =
              '@UI.hidden'
            iv_annotation_value =
              'true'
            iv_sequence =
              10
          CHANGING
            ct_annotations =
              ct_annotations
        ).

      ELSE.

        "====================================================
        " Normal field → line item
        "====================================================
        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <column>-item_id
            iv_evidence_id =
              <column>-evidence_id
            iv_rule_id =
              'ALV_COLUMN_LINEITEM'
            iv_target_layer =
              zif_mig_types=>gc_target_fiori
            iv_title =
              'Map ALV column to line item'
            iv_display_text =
              |Expose { <column>-field_name } as a Fiori line item.|
            iv_explanation =
              |Visible ALV field catalog columns should be represented through UI line-item metadata in the target application.|
            iv_severity =
              zif_mig_types=>gc_sev_info
            iv_confidence =
              <column>-confidence
            iv_manual_review =
              abap_false
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

        DATA(lv_line_item_value) =
          |position={ <column>-position }; label={ <column>-label }|.

        add_annotation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_recommendation_id =
              lv_recommendation_id
            iv_target_entity =
              lv_target_entity
            iv_target_element =
              CONV ty_target_element(
                <column>-field_name
              )
            iv_annotation_name =
              '@UI.lineItem'
            iv_annotation_value =
              lv_line_item_value
            iv_sequence =
              10
          CHANGING
            ct_annotations =
              ct_annotations
        ).

        IF <column>-key_field = abap_true.

          add_annotation(
            EXPORTING
              iv_analysis_id =
                iv_analysis_id
              iv_recommendation_id =
                lv_recommendation_id
              iv_target_entity =
                lv_target_entity
              iv_target_element =
                  CONV ty_target_element(
                    <column>-field_name
                  )
              iv_annotation_name =
                '@UI.identification'
              iv_annotation_value =
                lv_line_item_value
              iv_sequence =
                20
            CHANGING
              ct_annotations =
                ct_annotations
          ).

        ENDIF.

      ENDIF.


      "======================================================
      " Amount/currency semantics
      "======================================================
      IF <column>-currency_field IS NOT INITIAL.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <column>-item_id
            iv_evidence_id =
              <column>-evidence_id
            iv_rule_id =
              'ALV_AMOUNT_SEMANTICS'
            iv_target_layer =
              zif_mig_types=>gc_target_cds
            iv_title =
              'Define amount currency semantics'
            iv_display_text =
              |Link amount field { <column>-field_name } to currency field { <column>-currency_field }.|
            iv_explanation =
              |Currency semantics must be explicit in the CDS model so Fiori can format and aggregate the amount correctly.|
            iv_severity =
              zif_mig_types=>gc_sev_medium
            iv_confidence =
              <column>-confidence
            iv_manual_review =
              abap_false
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

        add_annotation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_recommendation_id =
              lv_recommendation_id
            iv_target_entity =
              lv_target_entity
            iv_target_element =
              CONV ty_target_element(
                <column>-field_name
              )
            iv_annotation_name =
              '@Semantics.amount.currencyCode'
            iv_annotation_value =
              CONV string(
                <column>-currency_field
              )
            iv_sequence =
              10
          CHANGING
            ct_annotations =
              ct_annotations
        ).

      ENDIF.


      "======================================================
      " Quantity/unit semantics
      "======================================================
      IF <column>-unit_field IS NOT INITIAL.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <column>-item_id
            iv_evidence_id =
              <column>-evidence_id
            iv_rule_id =
              'ALV_QUANTITY_SEMANTICS'
            iv_target_layer =
              zif_mig_types=>gc_target_cds
            iv_title =
              'Define quantity unit semantics'
            iv_display_text =
              |Link quantity field { <column>-field_name } to unit field { <column>-unit_field }.|
            iv_explanation =
              |Quantity semantics must be explicit in the CDS model for correct formatting and aggregation.|
            iv_severity =
              zif_mig_types=>gc_sev_medium
            iv_confidence =
              <column>-confidence
            iv_manual_review =
              abap_false
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

        add_annotation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_recommendation_id =
              lv_recommendation_id
            iv_target_entity =
              lv_target_entity
            iv_target_element =
              CONV ty_target_element(
                <column>-field_name
              )
            iv_annotation_name =
              '@Semantics.quantity.unitOfMeasure'
            iv_annotation_value =
              CONV string(
                <column>-unit_field
              )
            iv_sequence =
              10
          CHANGING
            ct_annotations =
              ct_annotations
        ).

      ENDIF.


      "======================================================
      " Aggregation
      "======================================================
      IF <column>-aggregation IS NOT INITIAL.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <column>-item_id
            iv_evidence_id =
              <column>-evidence_id
            iv_rule_id =
              'ALV_AGGREGATION'
            iv_target_layer =
              zif_mig_types=>gc_target_cds
            iv_title =
              'Preserve ALV aggregation'
            iv_display_text =
              |Preserve aggregation for field { <column>-field_name }.|
            iv_explanation =
              |The legacy ALV applies aggregation and the target CDS analytical semantics should retain equivalent behavior.|
            iv_severity =
              zif_mig_types=>gc_sev_low
            iv_confidence =
              <column>-confidence
            iv_manual_review =
              abap_false
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

        add_annotation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_recommendation_id =
              lv_recommendation_id
            iv_target_entity =
              lv_target_entity
            iv_target_element =
              CONV ty_target_element(
                <column>-field_name
              )
            iv_annotation_name =
              '@Aggregation.default'
            iv_annotation_value =
              CONV string(
                <column>-aggregation
              )
            iv_sequence =
              10
          CHANGING
            ct_annotations =
              ct_annotations
        ).

      ENDIF.


      "======================================================
      " Editable field
      "======================================================
      IF <column>-editable = abap_true.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <column>-item_id
            iv_evidence_id =
              <column>-evidence_id
            iv_rule_id =
              'ALV_EDITABLE_RAP'
            iv_target_layer =
              zif_mig_types=>gc_target_rap_action
            iv_title =
              'Implement editable column through RAP'
            iv_display_text =
              |Implement updates for editable field { <column>-field_name } through RAP behavior.|
            iv_explanation =
              |Editable ALV behavior requires transactional RAP support, validation and save handling rather than direct client-side changes.|
            iv_severity =
              zif_mig_types=>gc_sev_high
            iv_confidence =
              <column>-confidence
            iv_manual_review =
              abap_true
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

      ENDIF.


      IF <column>-hotspot = abap_true.

        add_recommendation(
          EXPORTING
            iv_analysis_id =
              iv_analysis_id
            iv_source_item_id =
              <column>-item_id
            iv_evidence_id =
              <column>-evidence_id
            iv_rule_id =
              'ALV_HOTSPOT_NAV'
            iv_target_layer =
              zif_mig_types=>gc_target_redesign
            iv_title =
              'Redesign hotspot navigation'
            iv_display_text =
              |Map hotspot field { <column>-field_name } to a Fiori navigation pattern.|
            iv_explanation =
              |ALV hotspot behavior should become semantic navigation, an application action or a controller extension.|
            iv_severity =
              zif_mig_types=>gc_sev_medium
            iv_confidence =
              <column>-confidence
            iv_manual_review =
              abap_true
          IMPORTING
            ev_recommendation_id =
              lv_recommendation_id
          CHANGING
            ct_recommendations =
              ct_recommendations
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

    METHOD recommend_alv_sorts.

    LOOP AT it_alv_sorts
      ASSIGNING FIELD-SYMBOL(<sort>).

      DATA lv_target_entity TYPE ty_target_entity.

      READ TABLE it_output_map
        WITH TABLE KEY
          output_id = <sort>-output_id
        INTO DATA(ls_output_map).

      IF sy-subrc = 0.
        lv_target_entity = ls_output_map-target_entity.
      ELSE.
        lv_target_entity = 'ALV_OUTPUT'.
      ENDIF.

      DATA lv_direction TYPE string.

      IF <sort>-descending = abap_true.
        lv_direction = '#DESC'.
      ELSE.
        lv_direction = '#ASC'.
      ENDIF.

      DATA lv_recommendation_id
        TYPE zif_mig_types=>ty_recommendation_id.

      add_recommendation(
        EXPORTING
          iv_analysis_id =
            iv_analysis_id
          iv_source_item_id =
            <sort>-item_id
          iv_evidence_id =
            <sort>-evidence_id
          iv_rule_id =
            'ALV_SORT_VARIANT'
          iv_target_layer =
            zif_mig_types=>gc_target_fiori
          iv_title =
            'Preserve ALV default sort'
          iv_display_text =
            |Apply default sort { <sort>-field_name } { lv_direction }.|
          iv_explanation =
            |The legacy ALV sort order can be represented as presentation variant metadata in the target application.|
          iv_severity =
            zif_mig_types=>gc_sev_low
          iv_confidence =
            <sort>-confidence
          iv_manual_review =
            abap_false
        IMPORTING
          ev_recommendation_id =
            lv_recommendation_id
        CHANGING
          ct_recommendations =
            ct_recommendations
      ).

      DATA(lv_annotation_value) =
        |field={ <sort>-field_name };direction={ lv_direction };position={ <sort>-position }|.

      add_annotation(
        EXPORTING
          iv_analysis_id =
            iv_analysis_id
          iv_recommendation_id =
            lv_recommendation_id
          iv_target_entity =
            lv_target_entity
          iv_target_element =
          CONV ty_target_element(
            <sort>-field_name
          )
          iv_annotation_name =
            '@UI.presentationVariant.sortOrder'
          iv_annotation_value =
            lv_annotation_value
          iv_sequence =
            <sort>-position
        CHANGING
          ct_annotations =
            ct_annotations
      ).

    ENDLOOP.

  ENDMETHOD.

    METHOD recommend_alv_filters.

    LOOP AT it_alv_filters
      ASSIGNING FIELD-SYMBOL(<filter>).

      DATA lv_target_entity TYPE ty_target_entity.

      READ TABLE it_output_map
        WITH TABLE KEY
          output_id = <filter>-output_id
        INTO DATA(ls_output_map).

      IF sy-subrc = 0.
        lv_target_entity = ls_output_map-target_entity.
      ELSE.
        lv_target_entity = 'ALV_OUTPUT'.
      ENDIF.

      DATA lv_recommendation_id
        TYPE zif_mig_types=>ty_recommendation_id.

      add_recommendation(
        EXPORTING
          iv_analysis_id =
            iv_analysis_id
          iv_source_item_id =
            <filter>-item_id
          iv_evidence_id =
            <filter>-evidence_id
          iv_rule_id =
            'ALV_DEFAULT_FILTER'
          iv_target_layer =
            zif_mig_types=>gc_target_fiori
          iv_title =
            'Preserve ALV default filter'
          iv_display_text =
            |Apply the legacy default filter for { <filter>-field_name }.|
          iv_explanation =
            |Default ALV filters should be represented through a selection variant or initial filter state.|
          iv_severity =
            zif_mig_types=>gc_sev_low
          iv_confidence =
            <filter>-confidence
          iv_manual_review =
            abap_false
        IMPORTING
          ev_recommendation_id =
            lv_recommendation_id
        CHANGING
          ct_recommendations =
            ct_recommendations
      ).

      DATA(lv_annotation_value) =
        |sign={ <filter>-sign };option={ <filter>-option };low={ <filter>-low_value };high={ <filter>-high_value }|.

      add_annotation(
        EXPORTING
          iv_analysis_id =
            iv_analysis_id
          iv_recommendation_id =
            lv_recommendation_id
          iv_target_entity =
            lv_target_entity
          iv_target_element =
          CONV ty_target_element(
            <filter>-field_name
          )
          iv_annotation_name =
            '@UI.selectionVariant.selectOptions'
          iv_annotation_value =
            lv_annotation_value
          iv_sequence =
            10
        CHANGING
          ct_annotations =
            ct_annotations
      ).

    ENDLOOP.

  ENDMETHOD.

    METHOD recommend_alv_events.

    LOOP AT it_alv_events
      ASSIGNING FIELD-SYMBOL(<event>).

      DATA(lv_event_name) =
        to_upper(
          CONV string(
            <event>-event_name
          )
        ).

      DATA:
        lv_rule_id       TYPE zif_mig_types=>ty_rule_id,
        lv_target_layer  TYPE zif_mig_types=>ty_target_layer,
        lv_title         TYPE ty_title,
        lv_display_text  TYPE string,
        lv_explanation   TYPE string,
        lv_severity      TYPE zif_mig_types=>ty_severity.

      CASE lv_event_name.

        WHEN 'DATA_CHANGED'.

          lv_rule_id =
            'ALV_EVENT_DATA_CHANGED'.

          lv_target_layer =
            zif_mig_types=>gc_target_rap_action.

          lv_title =
            'Move data-change logic into RAP'.

          lv_display_text =
            |Replace ALV DATA_CHANGED handler { <event>-handler_name } with RAP validation or determination.|.

          lv_explanation =
            |Data-change handling should execute through transactional behavior and server-side validation rather than GUI event processing.|.

          lv_severity =
            zif_mig_types=>gc_sev_high.


        WHEN 'USER_COMMAND'.

          lv_rule_id =
            'ALV_EVENT_USER_COMMAND'.

          lv_target_layer =
            zif_mig_types=>gc_target_rap_action.

          lv_title =
            'Map user command to application action'.

          lv_display_text =
            |Convert handler { <event>-handler_name } into a RAP or SAPUI5 action.|.

          lv_explanation =
            |ALV user commands need explicit action contracts and authorization behavior in the target application.|.

          lv_severity =
            zif_mig_types=>gc_sev_medium.


        WHEN 'DOUBLE_CLICK'
          OR 'HOTSPOT_CLICK'.

          lv_rule_id =
            'ALV_EVENT_NAVIGATION'.

          lv_target_layer =
            zif_mig_types=>gc_target_redesign.

          lv_title =
            'Redesign ALV navigation event'.

          lv_display_text =
            |Convert { lv_event_name } handler { <event>-handler_name } into Fiori navigation.|.

          lv_explanation =
            |Double-click and hotspot interaction should become semantic navigation, intent-based navigation or an explicit UI action.|.

          lv_severity =
            zif_mig_types=>gc_sev_medium.


        WHEN OTHERS.

          lv_rule_id =
            'ALV_EVENT_MANUAL'.

          lv_target_layer =
            zif_mig_types=>gc_target_manual.

          lv_title =
            'Review custom ALV event'.

          lv_display_text =
            |Review event { lv_event_name } handled by { <event>-handler_name }.|.

          lv_explanation =
            |No direct target mapping is available for this ALV event and manual redesign is required.|.

          lv_severity =
            zif_mig_types=>gc_sev_medium.

      ENDCASE.

      DATA lv_recommendation_id
        TYPE zif_mig_types=>ty_recommendation_id.

      add_recommendation(
        EXPORTING
          iv_analysis_id =
            iv_analysis_id
          iv_source_item_id =
            <event>-item_id
          iv_evidence_id =
            <event>-evidence_id
          iv_rule_id =
            lv_rule_id
          iv_target_layer =
            lv_target_layer
          iv_title =
            lv_title
          iv_display_text =
            lv_display_text
          iv_explanation =
            lv_explanation
          iv_severity =
            lv_severity
          iv_confidence =
            <event>-confidence
          iv_manual_review =
            abap_true
        IMPORTING
          ev_recommendation_id =
            lv_recommendation_id
        CHANGING
          ct_recommendations =
            ct_recommendations
      ).

    ENDLOOP.

  ENDMETHOD.

    METHOD add_recommendation.

    ev_recommendation_id =
      create_uuid(
        iv_source_object = ''
      ).

    APPEND VALUE #(
      recommendation_id = ev_recommendation_id
      analysis_id        = iv_analysis_id
      source_item_id     = iv_source_item_id
      evidence_id        = iv_evidence_id
      rule_id            = iv_rule_id
      rule_version       = gc_rule_version
      target_layer       = iv_target_layer
      title              = iv_title
      display_text       = iv_display_text
      explanation        = iv_explanation
      severity           = iv_severity
      confidence         = iv_confidence
      review_status      = gc_review_new
      manual_review      = iv_manual_review
    ) TO ct_recommendations.

  ENDMETHOD.

    METHOD add_annotation.

    DATA(lv_item_id) =
      create_uuid(
        iv_source_object = ''
      ).

    APPEND VALUE #(
      item_id           = lv_item_id
      analysis_id       = iv_analysis_id
      recommendation_id = iv_recommendation_id
      target_entity     = iv_target_entity
      target_element    = iv_target_element
      annotation_name   = iv_annotation_name
      annotation_value  = iv_annotation_value
      sequence          = iv_sequence
    ) TO ct_annotations.

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
