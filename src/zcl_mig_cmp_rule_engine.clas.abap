CLASS zcl_mig_cmp_rule_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS evaluate
      IMPORTING
        is_analysis TYPE zif_mig_types=>ty_analysis_result
        is_target   TYPE zif_mig_types=>ty_service_blueprint_result
      RETURNING
        VALUE(rt_items) TYPE zif_mig_cmp_types=>ty_t_cmp_item.

  PRIVATE SECTION.

    METHODS compare_inputs
      IMPORTING
        is_analysis TYPE zif_mig_types=>ty_analysis_result
        is_target   TYPE zif_mig_types=>ty_service_blueprint_result
      CHANGING
        ct_items    TYPE zif_mig_cmp_types=>ty_t_cmp_item
        cv_item_no  TYPE i.

    METHODS compare_outputs
      IMPORTING
        is_analysis TYPE zif_mig_types=>ty_analysis_result
        is_target   TYPE zif_mig_types=>ty_service_blueprint_result
      CHANGING
        ct_items    TYPE zif_mig_cmp_types=>ty_t_cmp_item
        cv_item_no  TYPE i.

    METHODS compare_dependencies
      IMPORTING
        is_analysis TYPE zif_mig_types=>ty_analysis_result
        is_target   TYPE zif_mig_types=>ty_service_blueprint_result
      CHANGING
        ct_items    TYPE zif_mig_cmp_types=>ty_t_cmp_item
        cv_item_no  TYPE i.

    METHODS compare_ui_interactions
      IMPORTING
        is_analysis TYPE zif_mig_types=>ty_analysis_result
        is_target   TYPE zif_mig_types=>ty_service_blueprint_result
      CHANGING
        ct_items    TYPE zif_mig_cmp_types=>ty_t_cmp_item
        cv_item_no  TYPE i.

    METHODS compare_strategy
      IMPORTING
        is_analysis TYPE zif_mig_types=>ty_analysis_result
        is_target   TYPE zif_mig_types=>ty_service_blueprint_result
      CHANGING
        ct_items    TYPE zif_mig_cmp_types=>ty_t_cmp_item
        cv_item_no  TYPE i.

ENDCLASS.


CLASS zcl_mig_cmp_rule_engine IMPLEMENTATION.

  METHOD evaluate.

    DATA lv_item_no TYPE i VALUE 0.

    "==========================================================
    " 1. Selection screen / input mapping
    "==========================================================
    compare_inputs(
      EXPORTING
        is_analysis = is_analysis
        is_target   = is_target
      CHANGING
        ct_items   = rt_items
        cv_item_no = lv_item_no
    ).

    "==========================================================
    " 2. ALV output mapping
    "==========================================================
    compare_outputs(
      EXPORTING
        is_analysis = is_analysis
        is_target   = is_target
      CHANGING
        ct_items   = rt_items
        cv_item_no = lv_item_no
    ).

    "==========================================================
    " 3. Database / technical dependency assessment
    "==========================================================
    compare_dependencies(
      EXPORTING
        is_analysis = is_analysis
        is_target   = is_target
      CHANGING
        ct_items   = rt_items
        cv_item_no = lv_item_no
    ).

    "==========================================================
    " 4. Legacy ALV / GUI interaction assessment
    "==========================================================
    compare_ui_interactions(
      EXPORTING
        is_analysis = is_analysis
        is_target   = is_target
      CHANGING
        ct_items   = rt_items
        cv_item_no = lv_item_no
    ).

    "==========================================================
    " 5. Overall migration strategy
    "==========================================================
    compare_strategy(
      EXPORTING
        is_analysis = is_analysis
        is_target   = is_target
      CHANGING
        ct_items   = rt_items
        cv_item_no = lv_item_no
    ).

  ENDMETHOD.


  METHOD compare_inputs.

    LOOP AT is_analysis-ui_filters
      INTO DATA(ls_filter).

      cv_item_no = cv_item_no + 1.

      READ TABLE is_target-parameters
        INTO DATA(ls_parameter)
        WITH KEY source_item_id = ls_filter-item_id.

      IF sy-subrc <> 0.

        APPEND VALUE #(
          item_no        = cv_item_no
          category       = zif_mig_cmp_types=>gc_cat_input
          source_element = ls_filter-field_name
          source_type    = ls_filter-field_kind
          source_value   = ls_filter-data_type
          mapping_rule   = 'SELECTION_TO_ODATA_PARAMETER'
          status         = zif_mig_cmp_types=>gc_status_manual
          severity       = zif_mig_cmp_types=>gc_severity_warning
          message        = 'No target OData parameter was generated'
          recommendation = 'Create the missing service parameter manually'
        ) TO ct_items.

        CONTINUE.

      ENDIF.

      DATA lv_input_status
        TYPE c LENGTH 30.

      DATA lv_input_severity
        TYPE c LENGTH 10.

      DATA lv_input_message
        TYPE c LENGTH 255.

      DATA lv_input_recommendation
        TYPE c LENGTH 255.


      IF ls_filter-field_kind = 'SELECT_OPTIONS'
         AND ls_parameter-odata_kind <> 'RANGE'.

        lv_input_status =
          zif_mig_cmp_types=>gc_status_refactor.

        lv_input_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_input_message =
          'Select-option was not mapped as an OData range'.

        lv_input_recommendation =
          'Implement range parsing and multiple-selection support'.


      ELSEIF ls_filter-data_type IS NOT INITIAL
         AND ls_parameter-edm_type IS INITIAL.

        lv_input_status =
          zif_mig_cmp_types=>gc_status_refactor.

        lv_input_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_input_message =
          'Target EDM data type could not be determined'.

        lv_input_recommendation =
          'Review the ABAP to EDM type mapping'.


      ELSE.

        lv_input_status =
          zif_mig_cmp_types=>gc_status_mapped.

        lv_input_severity =
          zif_mig_cmp_types=>gc_severity_info.

        lv_input_message =
          'Selection field was mapped to an OData parameter'.

        lv_input_recommendation =
          'No manual action is required'.

      ENDIF.


      APPEND VALUE #(
        item_no        = cv_item_no
        category       = zif_mig_cmp_types=>gc_cat_input
        source_element = ls_filter-field_name
        source_type    = ls_filter-field_kind
        source_value   = ls_filter-data_type
        target_element = ls_parameter-parameter_name
        target_type    = ls_parameter-odata_kind
        target_value   = ls_parameter-edm_type
        mapping_rule   = 'SELECTION_TO_ODATA_PARAMETER'
        status         = lv_input_status
        severity       = lv_input_severity
        message        = lv_input_message
        recommendation = lv_input_recommendation
      ) TO ct_items.

    ENDLOOP.

  ENDMETHOD.


  METHOD compare_outputs.

    LOOP AT is_analysis-alv_columns
      INTO DATA(ls_column).

      cv_item_no = cv_item_no + 1.

      READ TABLE is_target-fields
        INTO DATA(ls_field)
        WITH KEY source_item_id = ls_column-item_id.

      IF sy-subrc <> 0.

        APPEND VALUE #(
          item_no        = cv_item_no
          category       = zif_mig_cmp_types=>gc_cat_output
          source_element = ls_column-field_name
          source_type    = ls_column-data_type
          source_value   = ls_column-label
          mapping_rule   = 'ALV_COLUMN_TO_ODATA_FIELD'
          status         = zif_mig_cmp_types=>gc_status_manual
          severity       = zif_mig_cmp_types=>gc_severity_warning
          message        = 'No target service field was generated'
          recommendation = 'Create or map the missing target field'
        ) TO ct_items.

        CONTINUE.

      ENDIF.

      DATA lv_output_status
        TYPE c LENGTH 30.

      DATA lv_output_severity
        TYPE c LENGTH 10.

      DATA lv_output_message
        TYPE c LENGTH 255.

      DATA lv_output_recommendation
        TYPE c LENGTH 255.


      IF ls_field-edm_type IS INITIAL.

        lv_output_status =
          zif_mig_cmp_types=>gc_status_refactor.

        lv_output_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_output_message =
          'Target field has no resolved EDM type'.

        lv_output_recommendation =
          'Review the output type mapping manually'.


      ELSE.

        lv_output_status =
          zif_mig_cmp_types=>gc_status_mapped.

        lv_output_severity =
          zif_mig_cmp_types=>gc_severity_info.

        lv_output_message =
          'ALV column was mapped to a service field'.

        lv_output_recommendation =
          'No manual action is required'.

      ENDIF.


      APPEND VALUE #(
        item_no        = cv_item_no
        category       = zif_mig_cmp_types=>gc_cat_output
        source_element = ls_column-field_name
        source_type    = ls_column-data_type
        source_value   = ls_column-label
        target_element = ls_field-field_name
        target_type    = 'ODATA_FIELD'
        target_value   = ls_field-edm_type
        mapping_rule   = 'ALV_COLUMN_TO_ODATA_FIELD'
        status         = lv_output_status
        severity       = lv_output_severity
        message        = lv_output_message
        recommendation = lv_output_recommendation
      ) TO ct_items.

    ENDLOOP.

  ENDMETHOD.


  METHOD compare_dependencies.

    LOOP AT is_analysis-database_objects
      INTO DATA(ls_database).

      cv_item_no = cv_item_no + 1.

      DATA lv_dep_status
        TYPE c LENGTH 30.

      DATA lv_dep_severity
        TYPE c LENGTH 10.

      DATA lv_dep_target_element
        TYPE c LENGTH 120.

      DATA lv_dep_target_type
        TYPE c LENGTH 40.

      DATA lv_dep_target_value
        TYPE c LENGTH 255.

      DATA lv_dep_message
        TYPE c LENGTH 255.

      DATA lv_dep_recommendation
        TYPE c LENGTH 255.


      CLEAR:
        lv_dep_status,
        lv_dep_severity,
        lv_dep_target_element,
        lv_dep_target_type,
        lv_dep_target_value,
        lv_dep_message,
        lv_dep_recommendation.


      "==========================================================
      " Dynamic database access
      "==========================================================
      IF ls_database-dynamic_access = abap_true.

        lv_dep_status =
          zif_mig_cmp_types=>gc_status_manual.

        lv_dep_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_dep_target_element =
          'MANUAL_PROVIDER_DESIGN'.

        lv_dep_target_type =
          'RAP_PROVIDER'.

        lv_dep_target_value =
          is_target-blueprint-strategy.

        lv_dep_message =
          'Dynamic database access cannot be mapped deterministically'.

        lv_dep_recommendation =
          'Review dynamic SQL and design the RAP data provider manually'.


      ELSE.

        CASE ls_database-operation.

          "======================================================
          " Database write
          "======================================================
          WHEN 'INSERT'
            OR 'UPDATE'
            OR 'MODIFY'
            OR 'DELETE'.

            lv_dep_status =
              zif_mig_cmp_types=>gc_status_refactor.

            lv_dep_severity =
              zif_mig_cmp_types=>gc_severity_warning.

            lv_dep_target_element =
              is_target-blueprint-service_name.

            lv_dep_target_type =
              'RAP_ACTION'.

            lv_dep_target_value =
              is_target-blueprint-strategy.

            lv_dep_message =
              'Legacy database write requires transactional RAP behavior'.

            lv_dep_recommendation =
              'Refactor the write operation into a RAP action or behavior implementation'.


          "======================================================
          " Static database read
          "======================================================
          WHEN OTHERS.

            lv_dep_status =
              zif_mig_cmp_types=>gc_status_mapped.

            lv_dep_severity =
              zif_mig_cmp_types=>gc_severity_info.

            lv_dep_target_element =
              is_target-blueprint-entity_name.

            lv_dep_target_type =
              'RAP_QUERY'.

            lv_dep_target_value =
              is_target-blueprint-strategy.

            lv_dep_message =
              'Static database read can be represented by the target read model'.

            lv_dep_recommendation =
              'Use CDS or RAP query access for the migrated read operation'.

        ENDCASE.

      ENDIF.


      APPEND VALUE #(
        item_no        = cv_item_no
        category       = zif_mig_cmp_types=>gc_cat_dependency
        source_element = ls_database-object_name
        source_type    = ls_database-operation
        target_element = lv_dep_target_element
        target_type    = lv_dep_target_type
        target_value   = lv_dep_target_value
        mapping_rule   = 'DB_ACCESS_TO_RAP'
        status         = lv_dep_status
        severity       = lv_dep_severity
        message        = lv_dep_message
        recommendation = lv_dep_recommendation
      ) TO ct_items.

    ENDLOOP.

  ENDMETHOD.


  METHOD compare_ui_interactions.

    LOOP AT is_analysis-alv_events
      INTO DATA(ls_event).

      cv_item_no = cv_item_no + 1.

      DATA lv_ui_status
        TYPE c LENGTH 30.

      DATA lv_ui_severity
        TYPE c LENGTH 10.

      DATA lv_ui_target_element
        TYPE c LENGTH 120.

      DATA lv_ui_target_type
        TYPE c LENGTH 40.

      DATA lv_ui_message
        TYPE c LENGTH 255.

      DATA lv_ui_recommendation
        TYPE c LENGTH 255.

      CLEAR:
        lv_ui_status,
        lv_ui_severity,
        lv_ui_target_element,
        lv_ui_target_type,
        lv_ui_message,
        lv_ui_recommendation.

      DATA(lv_event_name) =
        to_upper(
          CONV string( ls_event-event_name )
        ).

      CONDENSE lv_event_name NO-GAPS.


      CASE lv_event_name.

        "======================================================
        " Navigation / row interaction
        "======================================================
        WHEN 'DOUBLE_CLICK'
          OR 'HOTSPOT_CLICK'
          OR 'LINK_CLICK'.

          lv_ui_status =
            zif_mig_cmp_types=>gc_status_refactor.

          lv_ui_severity =
            zif_mig_cmp_types=>gc_severity_warning.

          lv_ui_target_element =
            'SAPUI5_NAVIGATION'.

          lv_ui_target_type =
            'UI5_EVENT'.

          lv_ui_message =
            'Legacy ALV navigation event requires SAPUI5 interaction handling'.

          lv_ui_recommendation =
            'Refactor the event into SAPUI5 press or navigation logic'.


        "======================================================
        " Toolbar / user command
        "======================================================
        WHEN 'USER_COMMAND'
          OR 'TOOLBAR'
          OR 'BUTTON_CLICK'.

          lv_ui_status =
            zif_mig_cmp_types=>gc_status_refactor.

          lv_ui_severity =
            zif_mig_cmp_types=>gc_severity_warning.

          lv_ui_target_element =
            is_target-blueprint-service_name.

          lv_ui_target_type =
            'UI5_ACTION'.

          lv_ui_message =
            'Legacy ALV command requires explicit SAPUI5 action handling'.

          lv_ui_recommendation =
            'Implement the command as a SAPUI5 action and call RAP or OData when backend processing is required'.


        "======================================================
        " Editable ALV
        "======================================================
        WHEN 'DATA_CHANGED'
          OR 'DATA_CHANGED_FINISHED'.

          lv_ui_status =
            zif_mig_cmp_types=>gc_status_refactor.

          lv_ui_severity =
            zif_mig_cmp_types=>gc_severity_warning.

          lv_ui_target_element =
            is_target-blueprint-service_name.

          lv_ui_target_type =
            'RAP_BEHAVIOR'.

          lv_ui_message =
            'Editable ALV interaction requires transactional redesign'.

          lv_ui_recommendation =
            'Move validation and update logic into RAP behavior and trigger it from SAPUI5'.


        "======================================================
        " Presentation-only ALV events
        "======================================================
        WHEN 'TOP_OF_PAGE'
          OR 'END_OF_PAGE'.

          lv_ui_status =
            zif_mig_cmp_types=>gc_status_refactor.

          lv_ui_severity =
            zif_mig_cmp_types=>gc_severity_info.

          lv_ui_target_element =
            'SAPUI5_VIEW'.

          lv_ui_target_type =
            'UI_PRESENTATION'.

          lv_ui_message =
            'Legacy ALV presentation event has no direct OData equivalent'.

          lv_ui_recommendation =
            'Recreate the presentation behavior in SAPUI5 if it is still required'.


        "======================================================
        " Event exists but there is no deterministic mapping
        "======================================================
        WHEN OTHERS.

          lv_ui_status =
            zif_mig_cmp_types=>gc_status_manual.

          lv_ui_severity =
            zif_mig_cmp_types=>gc_severity_warning.

          lv_ui_target_element =
            'MANUAL_UI_DESIGN'.

          lv_ui_target_type =
            'SAPUI5'.

          lv_ui_message =
            'No deterministic SAPUI5 mapping rule exists for this ALV event'.

          lv_ui_recommendation =
            'Review the legacy event behavior and design the equivalent SAPUI5 interaction manually'.

      ENDCASE.


      APPEND VALUE #(
        item_no        = cv_item_no
        category       = zif_mig_cmp_types=>gc_cat_ui
        source_element = ls_event-event_name
        source_type    = 'ALV_EVENT'
        source_value   = ls_event-handler_name
        target_element = lv_ui_target_element
        target_type    = lv_ui_target_type
        mapping_rule   = 'ALV_EVENT_TO_UI5'
        status         = lv_ui_status
        severity       = lv_ui_severity
        message        = lv_ui_message
        recommendation = lv_ui_recommendation
      ) TO ct_items.

    ENDLOOP.

  ENDMETHOD.


  METHOD compare_strategy.

    cv_item_no = cv_item_no + 1.

    DATA lv_status
      TYPE c LENGTH 30.

    DATA lv_severity
      TYPE c LENGTH 10.

    DATA lv_message
      TYPE c LENGTH 255.

    DATA lv_recommendation
      TYPE c LENGTH 255.


    IF is_target-blueprint-manual_review = abap_true.

      lv_status =
        zif_mig_cmp_types=>gc_status_manual.

      lv_severity =
        zif_mig_cmp_types=>gc_severity_warning.

      lv_message =
        is_target-blueprint-decision_reason.

      lv_recommendation =
        'Review the proposed RAP service architecture manually'.


    ELSEIF is_target-blueprint-strategy =
           zif_mig_types=>gc_svc_action.

      lv_status =
        zif_mig_cmp_types=>gc_status_refactor.

      lv_severity =
        zif_mig_cmp_types=>gc_severity_warning.

      lv_message =
        'Transactional logic requires a RAP action'.

      lv_recommendation =
        'Refactor write operations into RAP actions or behavior methods'.


    ELSE.

      lv_status =
        zif_mig_cmp_types=>gc_status_mapped.

      lv_severity =
        zif_mig_cmp_types=>gc_severity_info.

      lv_message =
        is_target-blueprint-decision_reason.

      lv_recommendation =
        'Implement the proposed RAP query service'.

    ENDIF.


    APPEND VALUE #(
      item_no        = cv_item_no
      category       = zif_mig_cmp_types=>gc_cat_processing
      source_element = is_analysis-overview-program_name
      source_type    = 'ABAP_REPORT'
      target_element = is_target-blueprint-service_name
      target_type    = is_target-blueprint-strategy
      mapping_rule   = 'REPORT_TO_RAP_STRATEGY'
      status         = lv_status
      severity       = lv_severity
      message        = lv_message
      recommendation = lv_recommendation
    ) TO ct_items.

  ENDMETHOD.

ENDCLASS.
