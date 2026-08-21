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

    " Mapping rule identifiers
    CONSTANTS:
      gc_rule_input      TYPE c LENGTH 60 VALUE 'SELECTION_TO_ODATA_PARAMETER',
      gc_rule_output     TYPE c LENGTH 60 VALUE 'ALV_COLUMN_TO_ODATA_FIELD',
      gc_rule_dependency TYPE c LENGTH 60 VALUE 'DB_ACCESS_TO_RAP',
      gc_rule_logic      TYPE c LENGTH 60 VALUE 'BUSINESS_LOGIC_TO_RAP',
      gc_rule_ui         TYPE c LENGTH 60 VALUE 'ALV_EVENT_TO_UI5',
      gc_rule_strategy   TYPE c LENGTH 60 VALUE 'REPORT_TO_RAP_STRATEGY'.

    " Target type / design identifiers used by comparison items
    CONSTANTS:
      gc_target_odata_field     TYPE c LENGTH 40 VALUE 'ODATA_FIELD',
      gc_target_rap_provider    TYPE c LENGTH 40 VALUE 'RAP_PROVIDER',
      gc_target_rap_action      TYPE c LENGTH 40 VALUE 'RAP_ACTION',
      gc_target_rap_query       TYPE c LENGTH 40 VALUE 'RAP_QUERY',
      gc_target_abap_class      TYPE c LENGTH 40 VALUE 'ABAP_CLASS',
      gc_target_abap_method     TYPE c LENGTH 40 VALUE 'ABAP_METHOD',
      gc_target_ui5_event       TYPE c LENGTH 40 VALUE 'UI5_EVENT',
      gc_target_ui5_action      TYPE c LENGTH 40 VALUE 'UI5_ACTION',
      gc_target_rap_behavior    TYPE c LENGTH 40 VALUE 'RAP_BEHAVIOR',
      gc_target_ui_presentation TYPE c LENGTH 40 VALUE 'UI_PRESENTATION',
      gc_target_sapui5          TYPE c LENGTH 40 VALUE 'SAPUI5'.

    " Generic target/source labels
    CONSTANTS:
      gc_manual_provider_design TYPE c LENGTH 120 VALUE 'MANUAL_PROVIDER_DESIGN',
      gc_manual_logic_design    TYPE c LENGTH 120 VALUE 'MANUAL_LOGIC_DESIGN',
      gc_manual_ui_design       TYPE c LENGTH 120 VALUE 'MANUAL_UI_DESIGN',
      gc_application_class      TYPE c LENGTH 120 VALUE 'APPLICATION_CLASS',
      gc_sapui5_navigation      TYPE c LENGTH 120 VALUE 'SAPUI5_NAVIGATION',
      gc_sapui5_redesign        TYPE c LENGTH 120 VALUE 'SAPUI5_REDESIGN',
      gc_sapui5_view            TYPE c LENGTH 120 VALUE 'SAPUI5_VIEW',
      gc_source_abap_program    TYPE c LENGTH 40  VALUE 'ABAP_PROGRAM'.

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

    METHODS compare_business_logic
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
    " 4. Business logic / reusable dependency assessment
    "==========================================================
    compare_business_logic(
      EXPORTING
        is_analysis = is_analysis
        is_target   = is_target
      CHANGING
        ct_items   = rt_items
        cv_item_no = lv_item_no
    ).

    "==========================================================
    " 5. Legacy ALV / GUI interaction assessment
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
    " 6. Overall migration strategy
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
          mapping_rule   = gc_rule_input
          status         = zif_mig_cmp_types=>gc_status_manual
          severity       = zif_mig_cmp_types=>gc_severity_warning
          message        = 'No target OData parameter was generated'
          recommendation = 'Create the missing service parameter manually'
        ) TO ct_items.

        CONTINUE.

      ENDIF.

      DATA(lv_source_kind) =
        to_upper(
          CONV string( ls_filter-field_kind )
        ).

      DATA(lv_target_kind) =
        to_upper(
          CONV string( ls_parameter-odata_kind )
        ).

      CONDENSE lv_source_kind NO-GAPS.
      CONDENSE lv_target_kind NO-GAPS.

      DATA lv_input_status
        TYPE c LENGTH 30.

      DATA lv_input_severity
        TYPE c LENGTH 10.

      DATA lv_input_message
        TYPE c LENGTH 255.

      DATA lv_input_recommendation
        TYPE c LENGTH 255.

      IF lv_source_kind = 'SELECT_OPTIONS'
         AND lv_target_kind <> 'RANGE'.

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
        mapping_rule   = gc_rule_input
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
          mapping_rule   = gc_rule_output
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
        target_type    = gc_target_odata_field
        target_value   = ls_field-edm_type
        mapping_rule   = gc_rule_output
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

      DATA lv_dep_message
        TYPE c LENGTH 255.

      DATA lv_dep_recommendation
        TYPE c LENGTH 255.

      CLEAR:
        lv_dep_status,
        lv_dep_severity,
        lv_dep_target_element,
        lv_dep_target_type,
        lv_dep_message,
        lv_dep_recommendation.

      DATA(lv_operation) =
        to_upper(
          CONV string( ls_database-operation )
        ).

      CONDENSE lv_operation NO-GAPS.

      "==========================================================
      " Dynamic database access
      "==========================================================
      IF ls_database-dynamic_access = abap_true.

        lv_dep_status =
          zif_mig_cmp_types=>gc_status_manual.

        lv_dep_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_dep_target_element =
          gc_manual_provider_design.

        lv_dep_target_type =
          gc_target_rap_provider.

        lv_dep_message =
          'Dynamic database access cannot be mapped deterministically'.

        lv_dep_recommendation =
          'Review dynamic SQL and design the RAP data provider manually'.

      ELSE.

        CASE lv_operation.

          "======================================================
          " Static database read
          "======================================================
          WHEN 'SELECT'.

            lv_dep_status =
              zif_mig_cmp_types=>gc_status_mapped.

            lv_dep_severity =
              zif_mig_cmp_types=>gc_severity_info.

            lv_dep_target_element =
              is_target-blueprint-entity_name.

            lv_dep_target_type =
              gc_target_rap_query.

            lv_dep_message =
              'Static database read can be represented by the target read model'.

            lv_dep_recommendation =
              'Use CDS or RAP query access for the migrated read operation'.

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
              gc_target_rap_action.

            lv_dep_message =
              'Legacy database write requires transactional RAP behavior'.

            lv_dep_recommendation =
              'Refactor the write operation into a RAP action or behavior implementation'.

          "======================================================
          " Defensive fallback
          "======================================================
          WHEN OTHERS.

            lv_dep_status =
              zif_mig_cmp_types=>gc_status_manual.

            lv_dep_severity =
              zif_mig_cmp_types=>gc_severity_warning.

            lv_dep_target_element =
              gc_manual_provider_design.

            lv_dep_target_type =
              gc_target_rap_provider.

            IF ls_database-operation IS INITIAL.
              lv_dep_message =
                'Database operation could not be classified'.
            ELSE.
              lv_dep_message =
                |No deterministic RAP mapping rule exists for database operation { ls_database-operation }|.
            ENDIF.

            lv_dep_recommendation =
              'Review the database operation and define the target RAP design manually'.

        ENDCASE.

      ENDIF.

      APPEND VALUE #(
        item_no        = cv_item_no
        category       = zif_mig_cmp_types=>gc_cat_dependency
        source_element = ls_database-object_name
        source_type    = ls_database-operation
        target_element = lv_dep_target_element
        target_type    = lv_dep_target_type
        mapping_rule   = gc_rule_dependency
        status         = lv_dep_status
        severity       = lv_dep_severity
        message        = lv_dep_message
        recommendation = lv_dep_recommendation
      ) TO ct_items.

    ENDLOOP.

  ENDMETHOD.


  METHOD compare_business_logic.

    LOOP AT is_analysis-business_logic
      INTO DATA(ls_logic).

      cv_item_no = cv_item_no + 1.

      DATA lv_logic_status
        TYPE c LENGTH 30.

      DATA lv_logic_severity
        TYPE c LENGTH 10.

      DATA lv_logic_target_element
        TYPE c LENGTH 120.

      DATA lv_logic_target_type
        TYPE c LENGTH 40.

      DATA lv_logic_message
        TYPE c LENGTH 255.

      DATA lv_logic_recommendation
        TYPE c LENGTH 255.

      CLEAR:
        lv_logic_status,
        lv_logic_severity,
        lv_logic_target_element,
        lv_logic_target_type,
        lv_logic_message,
        lv_logic_recommendation.

      DATA(lv_object_type) =
        to_upper(
          CONV string( ls_logic-object_type )
        ).

      DATA(lv_side_effect) =
        to_upper(
          CONV string( ls_logic-side_effect )
        ).

      DATA(lv_reuse) =
        to_upper(
          CONV string( ls_logic-reuse_feasibility )
        ).

      CONDENSE lv_object_type NO-GAPS.
      CONDENSE lv_side_effect NO-GAPS.
      CONDENSE lv_reuse NO-GAPS.

      "==========================================================
      " GUI-dependent logic has the highest priority.
      " The analyzer already marks MODULE / DYPRO / TRANSACTION
      " as GUI-dependent; the object-type checks are defensive.
      "==========================================================
      IF ls_logic-gui_dependency = abap_true
         OR lv_object_type = 'DYPRO'
         OR lv_object_type = 'MODULE'
         OR lv_object_type = 'TRANSACTION'.

        lv_logic_status =
          zif_mig_cmp_types=>gc_status_manual.

        lv_logic_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_logic_target_element =
          gc_sapui5_redesign.

        lv_logic_target_type =
          zif_mig_types=>gc_target_redesign.

        lv_logic_message =
          'SAP GUI dependent logic has no deterministic direct OData mapping'.

        lv_logic_recommendation =
          'Redesign the interaction in SAPUI5 and move backend processing behind RAP or OData'.

      "==========================================================
      " Explicit transaction / LUW dependency requires review.
      " Commit/rollback sequencing must not be copied into RAP.
      "==========================================================
      ELSEIF ls_logic-transaction_dependency = abap_true
         OR lv_side_effect = 'TRANSACTION'.

        lv_logic_status =
          zif_mig_cmp_types=>gc_status_manual.

        lv_logic_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_logic_target_element =
          is_target-blueprint-service_name.

        lv_logic_target_type =
          zif_mig_types=>gc_target_manual.

        lv_logic_message =
          'Transaction-dependent logic requires explicit RAP save-sequence design'.

        lv_logic_recommendation =
          'Review LUW, commit and rollback behavior and redesign it for RAP transaction handling'.

      "==========================================================
      " Explicit write-side-effect metadata.
      " Kept for compatibility with blueprint logic even though
      " the current logic analyzer mainly emits REVIEW/TRANSACTION.
      "==========================================================
      ELSEIF lv_side_effect = 'WRITE'.

        lv_logic_status =
          zif_mig_cmp_types=>gc_status_refactor.

        lv_logic_severity =
          zif_mig_cmp_types=>gc_severity_warning.

        lv_logic_target_element =
          is_target-blueprint-service_name.

        lv_logic_target_type =
          gc_target_rap_action.

        lv_logic_message =
          'Write-capable business logic must be exposed through transactional RAP behavior'.

        lv_logic_recommendation =
          'Refactor the write logic into a RAP action or behavior implementation'.

      ELSE.

        CASE lv_object_type.

          "======================================================
          " FORM / PERFORM procedural logic
          "======================================================
          WHEN 'FORM_DEFINITION'
            OR 'FORM_CALL'.

            lv_logic_status =
              zif_mig_cmp_types=>gc_status_refactor.

            lv_logic_severity =
              zif_mig_cmp_types=>gc_severity_warning.

            lv_logic_target_element =
              gc_application_class.

            lv_logic_target_type =
              gc_target_abap_class.

            lv_logic_message =
              'Procedural FORM logic should be moved into a reusable ABAP class'.

            lv_logic_recommendation =
              'Refactor FORM/PERFORM logic into typed application or domain service methods before RAP exposure'.

          "======================================================
          " BAPI / Function Module
          " Recommendation engine already treats these as an
          " adapter-review concern and points to RAP action layer.
          "======================================================
          WHEN 'BAPI'
            OR 'FUNCTION_MODULE'
            OR 'FUNCTION_DEFINITION'.

            lv_logic_status =
              zif_mig_cmp_types=>gc_status_refactor.

            lv_logic_severity =
              zif_mig_cmp_types=>gc_severity_warning.

            lv_logic_target_element =
              is_target-blueprint-service_name.

            lv_logic_target_type =
              gc_target_rap_action.

            lv_logic_message =
              'Legacy function dependency requires an explicit typed service adapter'.

            lv_logic_recommendation =
              'Wrap the reusable function behind an application service or RAP action instead of calling it from the UI layer'.

          "======================================================
          " SUBMIT creates hidden report-to-report coupling.
          "======================================================
          WHEN 'REPORT_SUBMIT'.

            lv_logic_status =
              zif_mig_cmp_types=>gc_status_refactor.

            lv_logic_severity =
              zif_mig_cmp_types=>gc_severity_warning.

            lv_logic_target_element =
              is_target-blueprint-entity_name.

            lv_logic_target_type =
              gc_target_rap_query.

            lv_logic_message =
              'SUBMIT-based report coupling should be replaced by an explicit service contract'.

            lv_logic_recommendation =
              'Replace SUBMIT with a typed RAP query or application service call'.

          "======================================================
          " Method definition can be retained as reusable code.
          " A method CALL is treated more conservatively because
          " READ_OR_UNKNOWN does not prove that the call is safe
          " or UI-independent.
          "======================================================
          WHEN 'METHOD_DEFINITION'.

            IF lv_reuse = 'REUSABLE'.

              lv_logic_status =
                zif_mig_cmp_types=>gc_status_mapped.

              lv_logic_severity =
                zif_mig_cmp_types=>gc_severity_info.

              lv_logic_target_element =
                ls_logic-object_name.

              lv_logic_target_type =
                gc_target_abap_method.

              lv_logic_message =
                'Reusable ABAP method definition can remain behind the target service layer'.

              lv_logic_recommendation =
                'Reuse the method through a typed RAP or application-service boundary'.

            ELSE.

              lv_logic_status =
                zif_mig_cmp_types=>gc_status_refactor.

              lv_logic_severity =
                zif_mig_cmp_types=>gc_severity_warning.

              lv_logic_target_element =
                gc_application_class.

              lv_logic_target_type =
                gc_target_abap_class.

              lv_logic_message =
                'ABAP method definition requires refactoring before RAP reuse'.

              lv_logic_recommendation =
                'Refactor the method into a typed reusable application service'.

            ENDIF.

          WHEN 'STATIC_METHOD'
            OR 'INSTANCE_METHOD'.

            lv_logic_status =
              zif_mig_cmp_types=>gc_status_refactor.

            lv_logic_severity =
              zif_mig_cmp_types=>gc_severity_warning.

            lv_logic_target_element =
              ls_logic-object_name.

            lv_logic_target_type =
              gc_target_abap_method.

            lv_logic_message =
              'Method call requires service-boundary review before RAP reuse'.

            lv_logic_recommendation =
              'Verify the called method side effects and reuse it only behind a typed application-service boundary'.

          "======================================================
          " Defensive fallback based on analyzer reuse metadata.
          " Unknown logic is never silently classified as MAPPED.
          "======================================================
          WHEN OTHERS.

            CASE lv_reuse.

              WHEN 'REUSABLE'.

                lv_logic_status =
                  zif_mig_cmp_types=>gc_status_refactor.

                lv_logic_severity =
                  zif_mig_cmp_types=>gc_severity_warning.

                lv_logic_target_element =
                  ls_logic-object_name.

                lv_logic_target_type =
                  gc_target_abap_method.

                lv_logic_message =
                  'Reusable marker alone is not enough for deterministic RAP mapping'.

                lv_logic_recommendation =
                  'Review the logic contract and expose it only through a typed service boundary'.

              WHEN 'REFACTOR'
                OR 'ADAPTER_REVIEW'.

                lv_logic_status =
                  zif_mig_cmp_types=>gc_status_refactor.

                lv_logic_severity =
                  zif_mig_cmp_types=>gc_severity_warning.

                lv_logic_target_element =
                  gc_application_class.

                lv_logic_target_type =
                  gc_target_abap_class.

                lv_logic_message =
                  'Business logic requires refactoring or adapter review before RAP exposure'.

                lv_logic_recommendation =
                  'Refactor the logic behind a typed application-service boundary'.

              WHEN 'REDESIGN'.

                lv_logic_status =
                  zif_mig_cmp_types=>gc_status_manual.

                lv_logic_severity =
                  zif_mig_cmp_types=>gc_severity_warning.

                lv_logic_target_element =
                  gc_manual_logic_design.

                lv_logic_target_type =
                  zif_mig_types=>gc_target_manual.

                lv_logic_message =
                  'Analyzer marked this business logic for redesign'.

                lv_logic_recommendation =
                  'Review the legacy behavior and design the target implementation manually'.

              WHEN OTHERS.

                lv_logic_status =
                  zif_mig_cmp_types=>gc_status_manual.

                lv_logic_severity =
                  zif_mig_cmp_types=>gc_severity_warning.

                lv_logic_target_element =
                  gc_manual_logic_design.

                lv_logic_target_type =
                  zif_mig_types=>gc_target_manual.

                lv_logic_message =
                  'No deterministic migration rule exists for this business logic item'.

                lv_logic_recommendation =
                  'Review the business logic manually and define the target RAP integration'.

            ENDCASE.

        ENDCASE.

      ENDIF.

      APPEND VALUE #(
        item_no        = cv_item_no
        category       = zif_mig_cmp_types=>gc_cat_business_logic
        source_element = ls_logic-object_name
        source_type    = ls_logic-object_type
        source_value   = ls_logic-reuse_feasibility
        target_element = lv_logic_target_element
        target_type    = lv_logic_target_type
        mapping_rule   = gc_rule_logic
        status         = lv_logic_status
        severity       = lv_logic_severity
        message        = lv_logic_message
        recommendation = lv_logic_recommendation
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
            gc_sapui5_navigation.

          lv_ui_target_type =
            gc_target_ui5_event.

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
            gc_target_ui5_action.

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
            gc_target_rap_behavior.

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
            gc_sapui5_view.

          lv_ui_target_type =
            gc_target_ui_presentation.

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
            gc_manual_ui_design.

          lv_ui_target_type =
            gc_target_sapui5.

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
        mapping_rule   = gc_rule_ui
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

    CLEAR:
      lv_status,
      lv_severity,
      lv_message,
      lv_recommendation.

    "==========================================================
    " Blueprint explicitly requires manual review
    "==========================================================
    IF is_target-blueprint-manual_review = abap_true.

      lv_status =
        zif_mig_cmp_types=>gc_status_manual.

      lv_severity =
        zif_mig_cmp_types=>gc_severity_warning.

      lv_message =
        is_target-blueprint-decision_reason.

      IF lv_message IS INITIAL.
        lv_message =
          'Target blueprint requires manual architecture review'.
      ENDIF.

      lv_recommendation =
        'Review the proposed RAP service architecture manually'.

    ELSE.

      "========================================================
      " Only an explicit QUERY strategy is treated as MAPPED.
      " Unknown / initial strategies are never silently MAPPED.
      "========================================================
      CASE is_target-blueprint-strategy.

        WHEN zif_mig_types=>gc_svc_query.

          lv_status =
            zif_mig_cmp_types=>gc_status_mapped.

          lv_severity =
            zif_mig_cmp_types=>gc_severity_info.

          lv_message =
            is_target-blueprint-decision_reason.

          IF lv_message IS INITIAL.
            lv_message =
              'Read-only report can be represented by a RAP query service'.
          ENDIF.

          lv_recommendation =
            'Implement the proposed RAP query service'.

        WHEN zif_mig_types=>gc_svc_action.

          lv_status =
            zif_mig_cmp_types=>gc_status_refactor.

          lv_severity =
            zif_mig_cmp_types=>gc_severity_warning.

          lv_message =
            'Transactional logic requires a RAP action'.

          lv_recommendation =
            'Refactor write operations into RAP actions or behavior methods'.

        WHEN zif_mig_types=>gc_svc_manual.

          lv_status =
            zif_mig_cmp_types=>gc_status_manual.

          lv_severity =
            zif_mig_cmp_types=>gc_severity_warning.

          lv_message =
            is_target-blueprint-decision_reason.

          IF lv_message IS INITIAL.
            lv_message =
              'Target strategy requires manual RAP service design'.
          ENDIF.

          lv_recommendation =
            'Review the target architecture and define the RAP design manually'.

        WHEN OTHERS.

          lv_status =
            zif_mig_cmp_types=>gc_status_manual.

          lv_severity =
            zif_mig_cmp_types=>gc_severity_warning.

          IF is_target-blueprint-strategy IS INITIAL.
            lv_message =
              'Target migration strategy could not be determined'.
          ELSE.
            lv_message =
              |No comparison rule exists for target strategy { is_target-blueprint-strategy }|.
          ENDIF.

          lv_recommendation =
            'Review the generated blueprint strategy before migration'.

      ENDCASE.

    ENDIF.

    APPEND VALUE #(
      item_no        = cv_item_no
      category       = zif_mig_cmp_types=>gc_cat_processing
      source_element = is_analysis-overview-program_name
      source_type    = gc_source_abap_program
      target_element = is_target-blueprint-service_name
      target_type    = is_target-blueprint-strategy
      mapping_rule   = gc_rule_strategy
      status         = lv_status
      severity       = lv_severity
      message        = lv_message
      recommendation = lv_recommendation
    ) TO ct_items.

  ENDMETHOD.

ENDCLASS.

