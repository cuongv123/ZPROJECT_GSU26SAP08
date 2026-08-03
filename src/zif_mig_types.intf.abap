    INTERFACE zif_mig_types
  PUBLIC.

  "============================================================
  " Basic identifiers
  "============================================================
  TYPES:
    ty_analysis_id       TYPE sysuuid_x16,
    ty_item_id           TYPE sysuuid_x16,
    ty_evidence_id       TYPE sysuuid_x16,
    ty_recommendation_id TYPE sysuuid_x16,
    ty_program_name      TYPE progname,
    ty_rule_id           TYPE c LENGTH 30,
    ty_status            TYPE c LENGTH 20,
    ty_confidence        TYPE c LENGTH 10,
    ty_severity          TYPE c LENGTH 10,
    ty_target_layer      TYPE c LENGTH 30.

  CONSTANTS:
    gc_status_new        TYPE ty_status VALUE 'NEW',
    gc_status_running    TYPE ty_status VALUE 'RUNNING',
    gc_status_completed  TYPE ty_status VALUE 'COMPLETED',
    gc_status_warning    TYPE ty_status VALUE 'WARNING',
    gc_status_failed     TYPE ty_status VALUE 'FAILED',
    gc_status_outdated   TYPE ty_status VALUE 'OUTDATED'.

  CONSTANTS:
    gc_conf_high   TYPE ty_confidence VALUE 'HIGH',
    gc_conf_medium TYPE ty_confidence VALUE 'MEDIUM',
    gc_conf_low    TYPE ty_confidence VALUE 'LOW'.

  CONSTANTS:
    gc_sev_info     TYPE ty_severity VALUE 'INFO',
    gc_sev_low      TYPE ty_severity VALUE 'LOW',
    gc_sev_medium   TYPE ty_severity VALUE 'MEDIUM',
    gc_sev_high     TYPE ty_severity VALUE 'HIGH',
    gc_sev_critical TYPE ty_severity VALUE 'CRITICAL'.

  CONSTANTS:
    gc_target_fiori      TYPE ty_target_layer VALUE 'FIORI_ANNOTATION',
    gc_target_cds        TYPE ty_target_layer VALUE 'CDS_MODEL',
    gc_target_rap_query  TYPE ty_target_layer VALUE 'RAP_QUERY',
    gc_target_rap_action TYPE ty_target_layer VALUE 'RAP_ACTION',
    gc_target_redesign   TYPE ty_target_layer VALUE 'UI_REDESIGN',
    gc_target_manual     TYPE ty_target_layer VALUE 'MANUAL_REVIEW'.

  "============================================================
  " Source model
  "============================================================
  TYPES:
    BEGIN OF ty_source_line,
      source_object TYPE ty_program_name,
      line_number   TYPE i,
      source_text   TYPE string,
    END OF ty_source_line,

    tt_source_line TYPE STANDARD TABLE OF ty_source_line
      WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_source_object,
      item_id        TYPE ty_item_id,
      analysis_id    TYPE ty_analysis_id,

      object_name    TYPE ty_program_name,
      object_type    TYPE c LENGTH 15,
      parent_object  TYPE ty_program_name,
      include_depth  TYPE i,
      line_count     TYPE i,
      source_hash    TYPE c LENGTH 64,

      "Chỉ tồn tại trong pipeline runtime.
      "Không persist toàn bộ source text.
      source_lines   TYPE tt_source_line,
    END OF ty_source_object,

    tt_source_object TYPE STANDARD TABLE OF ty_source_object
      WITH EMPTY KEY.

  "============================================================
  " Scanner token
  "============================================================
  TYPES:
    BEGIN OF ty_token,
      statement_id  TYPE i,
      token_index   TYPE i,
      token_type    TYPE c LENGTH 1,
      token_text    TYPE string,
      source_object TYPE ty_program_name,
      source_line   TYPE i,
      source_column TYPE i,
    END OF ty_token,

    tt_token TYPE STANDARD TABLE OF ty_token
      WITH EMPTY KEY.

    "============================================================
  " Scanner statement
  "============================================================
  TYPES:
    BEGIN OF ty_statement,
      statement_id   TYPE i,

      "Native SCAN type:
      "I = valid INCLUDE
      "J = INCLUDE không tồn tại khi scan WITH INCLUDES
      "K = ABAP keyword statement
      "U = unknown statement...
      native_type    TYPE c LENGTH 1,

      "Keyword chuẩn hóa, ví dụ REPORT, PARAMETERS, SELECT...
      statement_type TYPE c LENGTH 30,

      token_from     TYPE i,
      token_to       TYPE i,
      prefix_length  TYPE i,
      terminator     TYPE c LENGTH 1,

      source_object  TYPE ty_program_name,
      start_line     TYPE i,
      end_line       TYPE i,

      parent_routine TYPE c LENGTH 120,
      routine_type   TYPE c LENGTH 20,
      parent_block   TYPE c LENGTH 30,
      block_depth    TYPE i,

      "Tạm thời chưa dựng đầy đủ tại Scanner Core
      statement_text TYPE string,
    END OF ty_statement,

    tt_statement TYPE STANDARD TABLE OF ty_statement
      WITH EMPTY KEY.

    TYPES:
    BEGIN OF ty_scan_result,
      source_object TYPE ty_program_name,
      tokens        TYPE tt_token,
      statements    TYPE tt_statement,
    END OF ty_scan_result.

  "============================================================
  " Source unit đã đọc và scan
  "============================================================
  TYPES:
    BEGIN OF ty_source_unit,
      source_object TYPE ty_source_object,
      scan_result   TYPE ty_scan_result,
    END OF ty_source_unit,

    tt_source_unit TYPE STANDARD TABLE OF ty_source_unit
      WITH EMPTY KEY.



  "============================================================
  " Evidence
  "============================================================
  TYPES:
    BEGIN OF ty_evidence,
      evidence_id    TYPE ty_evidence_id,
      analysis_id    TYPE ty_analysis_id,
      source_object  TYPE ty_program_name,
      start_line     TYPE i,
      end_line       TYPE i,
      statement_id   TYPE i,
      statement_text TYPE string,
      confidence     TYPE ty_confidence,
    END OF ty_evidence,

    tt_evidence TYPE STANDARD TABLE OF ty_evidence
      WITH EMPTY KEY.

  "============================================================
  " UI and Filter facts
  "============================================================
  TYPES:
    BEGIN OF ty_ui_filter,
      item_id             TYPE ty_item_id,
      analysis_id         TYPE ty_analysis_id,
      evidence_id         TYPE ty_evidence_id,
      field_name          TYPE c LENGTH 40,
      field_kind          TYPE c LENGTH 20,
      reference_table     TYPE c LENGTH 30,
      reference_field     TYPE c LENGTH 30,
      data_element        TYPE c LENGTH 30,
      data_type           TYPE c LENGTH 30,
      description         TYPE c LENGTH 120,
      selection_block     TYPE c LENGTH 40,
      mandatory           TYPE abap_bool,
      hidden              TYPE abap_bool,
      checkbox            TYPE abap_bool,
      radio_group         TYPE c LENGTH 10,
      multiple_selection  TYPE abap_bool,
      range_supported     TYPE abap_bool,
      default_value       TYPE string,
      validation_routine  TYPE c LENGTH 120,
      confidence          TYPE ty_confidence,
    END OF ty_ui_filter,

    tt_ui_filter TYPE STANDARD TABLE OF ty_ui_filter
      WITH EMPTY KEY.

  "============================================================
  " Database facts
  "============================================================
  TYPES:
    BEGIN OF ty_database_object,
      item_id            TYPE ty_item_id,
      analysis_id        TYPE ty_analysis_id,
      evidence_id        TYPE ty_evidence_id,
      object_name        TYPE c LENGTH 40,
      object_type        TYPE c LENGTH 20,
      operation          TYPE c LENGTH 20,
      selected_fields    TYPE string,
      where_fields       TYPE string,
      joined_objects     TYPE string,
      join_condition     TYPE string,
      aggregation        TYPE string,
      containing_routine TYPE c LENGTH 120,
      dynamic_access     TYPE abap_bool,
      read_only          TYPE abap_bool,
      paging_capability  TYPE c LENGTH 20,
      description        TYPE c LENGTH 120,
      confidence         TYPE ty_confidence,
    END OF ty_database_object,

    tt_database_object TYPE STANDARD TABLE OF ty_database_object
      WITH EMPTY KEY.

  "============================================================
  " Business Logic facts
  "============================================================
  TYPES:
    BEGIN OF ty_business_logic,
      item_id               TYPE ty_item_id,
      analysis_id           TYPE ty_analysis_id,
      evidence_id           TYPE ty_evidence_id,
      object_name           TYPE c LENGTH 120,
      object_type           TYPE c LENGTH 30,
      container_name        TYPE c LENGTH 120,
      calling_routine       TYPE c LENGTH 120,
      interface_summary     TYPE string,
      description           TYPE c LENGTH 120,
      side_effect           TYPE c LENGTH 20,
      transaction_dependency TYPE abap_bool,
      gui_dependency        TYPE abap_bool,
      reuse_feasibility     TYPE c LENGTH 20,
      confidence            TYPE ty_confidence,
    END OF ty_business_logic,

    tt_business_logic TYPE STANDARD TABLE OF ty_business_logic
      WITH EMPTY KEY.

  "============================================================
  " ALV Output header
  "============================================================
  TYPES:
      BEGIN OF ty_alv_output,
        output_id          TYPE ty_item_id,
        analysis_id        TYPE ty_analysis_id,
        evidence_id        TYPE ty_evidence_id,
        layout_evidence_id TYPE ty_evidence_id,

        output_name        TYPE c LENGTH 120,
        output_kind        TYPE c LENGTH 30,
        framework          TYPE c LENGTH 40,

        control_object     TYPE c LENGTH 80,
        output_table       TYPE c LENGTH 80,
        row_type           TYPE c LENGTH 80,
        field_catalog      TYPE c LENGTH 80,
        sort_table         TYPE c LENGTH 80,
        filter_table       TYPE c LENGTH 80,
        layout_object      TYPE c LENGTH 80,
        variant_object     TYPE c LENGTH 80,

        editable           TYPE abap_bool,
        hierarchical       TYPE abap_bool,
        zebra              TYPE abap_bool,
        auto_width         TYPE abap_bool,
        selection_mode     TYPE c LENGTH 10,

        confidence         TYPE ty_confidence,
      END OF ty_alv_output,

    tt_alv_output TYPE STANDARD TABLE OF ty_alv_output
      WITH EMPTY KEY.

  "============================================================
  " ALV Columns
  "============================================================
  TYPES:
    BEGIN OF ty_alv_column,
      item_id         TYPE ty_item_id,
      analysis_id     TYPE ty_analysis_id,
      output_id       TYPE ty_item_id,
      evidence_id     TYPE ty_evidence_id,
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
      source_mapping  TYPE string,
      confidence      TYPE ty_confidence,
    END OF ty_alv_column,

    tt_alv_column TYPE STANDARD TABLE OF ty_alv_column
      WITH EMPTY KEY.

  "============================================================
  " ALV Sort and Group
  "============================================================
   TYPES:
      BEGIN OF ty_alv_sort,
        item_id      TYPE ty_item_id,
        analysis_id  TYPE ty_analysis_id,
        output_id    TYPE ty_item_id,
        evidence_id  TYPE ty_evidence_id,

        field_name   TYPE c LENGTH 40,
        position     TYPE i,
        ascending    TYPE abap_bool,
        descending   TYPE abap_bool,
        subtotal     TYPE abap_bool,

        confidence   TYPE ty_confidence,
      END OF ty_alv_sort,

      tt_alv_sort TYPE STANDARD TABLE OF ty_alv_sort
        WITH EMPTY KEY.

  "============================================================
  " ALV Filter
  "============================================================
  TYPES:
      BEGIN OF ty_alv_filter,
        item_id      TYPE ty_item_id,
        analysis_id  TYPE ty_analysis_id,
        output_id    TYPE ty_item_id,
        evidence_id  TYPE ty_evidence_id,

        field_name   TYPE c LENGTH 40,
        sign         TYPE c LENGTH 1,
        option       TYPE c LENGTH 2,
        low_value    TYPE string,
        high_value   TYPE string,

        confidence   TYPE ty_confidence,
      END OF ty_alv_filter,

      tt_alv_filter TYPE STANDARD TABLE OF ty_alv_filter
        WITH EMPTY KEY.

  "============================================================
  " ALV Event and Action
  "============================================================
  TYPES:
      BEGIN OF ty_alv_event,
        item_id        TYPE ty_item_id,
        analysis_id    TYPE ty_analysis_id,
        output_id      TYPE ty_item_id,
        evidence_id    TYPE ty_evidence_id,

        event_name     TYPE c LENGTH 40,
        handler_name   TYPE c LENGTH 120,
        handler_kind   TYPE c LENGTH 20,
        control_object TYPE c LENGTH 80,
        gui_dependency TYPE abap_bool,

        confidence     TYPE ty_confidence,
      END OF ty_alv_event,

      tt_alv_event TYPE STANDARD TABLE OF ty_alv_event
        WITH EMPTY KEY.
  "============================================================
  " Complexity
  "============================================================
  TYPES:
    BEGIN OF ty_complexity_finding,
      item_id        TYPE ty_item_id,
      analysis_id    TYPE ty_analysis_id,
      evidence_id    TYPE ty_evidence_id,
      metric_type    TYPE c LENGTH 30,
      metric_value   TYPE i,
      severity       TYPE ty_severity,
      description    TYPE string,
    END OF ty_complexity_finding,

    tt_complexity_finding TYPE STANDARD TABLE OF ty_complexity_finding
      WITH EMPTY KEY.

  "============================================================
  " Recommendation
  "============================================================
  TYPES:
    BEGIN OF ty_recommendation,
      recommendation_id TYPE ty_recommendation_id,
      analysis_id        TYPE ty_analysis_id,
      source_item_id     TYPE ty_item_id,
      evidence_id        TYPE ty_evidence_id,
      rule_id            TYPE ty_rule_id,
      rule_version       TYPE c LENGTH 10,
      target_layer       TYPE ty_target_layer,
      title              TYPE c LENGTH 120,
      display_text       TYPE string,
      explanation        TYPE string,
      severity           TYPE ty_severity,
      confidence         TYPE ty_confidence,
      review_status      TYPE c LENGTH 20,
      manual_review      TYPE abap_bool,
    END OF ty_recommendation,

    tt_recommendation TYPE STANDARD TABLE OF ty_recommendation
      WITH EMPTY KEY.

  "============================================================
  " Annotation proposal
  "============================================================
  TYPES:
    BEGIN OF ty_annotation_proposal,
      item_id            TYPE ty_item_id,
      analysis_id        TYPE ty_analysis_id,
      recommendation_id  TYPE ty_recommendation_id,
      target_entity      TYPE c LENGTH 80,
      target_element     TYPE c LENGTH 80,
      annotation_name    TYPE c LENGTH 120,
      annotation_value   TYPE string,
      sequence           TYPE i,
    END OF ty_annotation_proposal,

    tt_annotation_proposal
      TYPE STANDARD TABLE OF ty_annotation_proposal
      WITH EMPTY KEY.

  "============================================================
  " Overview
  "============================================================
  TYPES:
    BEGIN OF ty_overview,
      analysis_id          TYPE ty_analysis_id,
      program_name         TYPE ty_program_name,
      program_description  TYPE c LENGTH 120,
      status                TYPE ty_status,
      total_source_objects  TYPE i,
      total_ui_filters      TYPE i,
      total_database_objects TYPE i,
      total_business_logic TYPE i,
      total_alv_outputs     TYPE i,
      total_alv_columns     TYPE i,
      total_recommendations TYPE i,
      complexity_score      TYPE decfloat16,
      readiness_score       TYPE decfloat16,
      parser_version        TYPE c LENGTH 10,
      rule_version          TYPE c LENGTH 10,
      source_hash           TYPE c LENGTH 64,
    END OF ty_overview.

  "============================================================
  " Analysis message
  "============================================================
  TYPES:
    BEGIN OF ty_message,
      message_type   TYPE c LENGTH 10,
      message_code   TYPE c LENGTH 30,
      source_object  TYPE ty_program_name,
      source_line    TYPE i,
      message_text   TYPE string,
    END OF ty_message,

    tt_message TYPE STANDARD TABLE OF ty_message
      WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_ui_analysis_result,
        ui_filters TYPE tt_ui_filter,
        evidences  TYPE tt_evidence,
        messages   TYPE tt_message,
      END OF ty_ui_analysis_result.

    "============================================================
    " Database Analysis Result
    "============================================================
    TYPES:
      BEGIN OF ty_db_analysis_result,
        database_objects TYPE tt_database_object,
        evidences         TYPE tt_evidence,
        messages          TYPE tt_message,
      END OF ty_db_analysis_result.

  "============================================================
    " Business Logic Analysis Result
    "============================================================
    TYPES:
      BEGIN OF ty_logic_analysis_result,
        business_logic TYPE tt_business_logic,
        evidences      TYPE tt_evidence,
        messages       TYPE tt_message,
      END OF ty_logic_analysis_result.

   "============================================================
    " ALV Analysis Result
    "============================================================
    TYPES:
      BEGIN OF ty_alv_analysis_result,
        alv_outputs TYPE tt_alv_output,
        alv_columns TYPE tt_alv_column,
        alv_sorts   TYPE tt_alv_sort,
        alv_filters TYPE tt_alv_filter,
        alv_events  TYPE tt_alv_event,
        evidences   TYPE tt_evidence,
        messages    TYPE tt_message,
      END OF ty_alv_analysis_result.

    "============================================================
    " ALV Field Catalog Analysis Result
    "============================================================
    TYPES:
      BEGIN OF ty_alv_fcat_result,
        alv_columns TYPE tt_alv_column,
        evidences   TYPE tt_evidence,
        messages    TYPE tt_message,
      END OF ty_alv_fcat_result.

    "============================================================
    " ALV Sort and Filter Analysis Result
    "============================================================
    TYPES:
      BEGIN OF ty_alv_sf_result,
        alv_sorts   TYPE tt_alv_sort,
        alv_filters TYPE tt_alv_filter,
        evidences   TYPE tt_evidence,
        messages    TYPE tt_message,
      END OF ty_alv_sf_result.


    TYPES:
      BEGIN OF ty_alv_le_result,
        alv_outputs TYPE tt_alv_output,
        alv_events  TYPE tt_alv_event,
        evidences   TYPE tt_evidence,
        messages    TYPE tt_message,
      END OF ty_alv_le_result.


      "============================================================
      " Target OData Service Blueprint
      "============================================================
      TYPES:
        ty_service_strategy TYPE c LENGTH 20.

      CONSTANTS:
        gc_svc_query  TYPE ty_service_strategy VALUE 'QUERY',
        gc_svc_action TYPE ty_service_strategy VALUE 'ACTION',
        gc_svc_manual TYPE ty_service_strategy VALUE 'MANUAL_REVIEW'.


      TYPES:
        BEGIN OF ty_service_parameter,
          source_item_id     TYPE ty_item_id,
          parameter_name     TYPE c LENGTH 40,
          source_kind        TYPE c LENGTH 20,
          odata_kind         TYPE c LENGTH 20,
          edm_type           TYPE c LENGTH 30,
          mandatory          TYPE abap_bool,
          multiple_selection TYPE abap_bool,
          range_supported    TYPE abap_bool,
          default_value      TYPE string,
        END OF ty_service_parameter,

        tt_service_parameter
          TYPE STANDARD TABLE OF ty_service_parameter
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_service_field,
          source_item_id TYPE ty_item_id,
          field_name     TYPE c LENGTH 40,
          label          TYPE c LENGTH 120,
          edm_type       TYPE c LENGTH 30,
          position       TYPE i,
          key_field      TYPE abap_bool,
          visible        TYPE abap_bool,
          filterable     TYPE abap_bool,
          sortable       TYPE abap_bool,
          source_mapping TYPE string,
        END OF ty_service_field,

        tt_service_field
          TYPE STANDARD TABLE OF ty_service_field
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_service_blueprint,
          analysis_id       TYPE ty_analysis_id,
          source_program    TYPE ty_program_name,

          service_name      TYPE c LENGTH 30,
          entity_name       TYPE c LENGTH 30,

          strategy          TYPE ty_service_strategy,

          source_output_id  TYPE ty_item_id,
          source_table      TYPE c LENGTH 80,
          source_row_type   TYPE c LENGTH 80,

          supports_filter   TYPE abap_bool,
          supports_sort     TYPE abap_bool,
          supports_paging   TYPE abap_bool,

          manual_review     TYPE abap_bool,
          decision_reason   TYPE string,
        END OF ty_service_blueprint.


      TYPES:
        BEGIN OF ty_service_blueprint_result,
          blueprint  TYPE ty_service_blueprint,
          parameters TYPE tt_service_parameter,
          fields     TYPE tt_service_field,
          messages   TYPE tt_message,
        END OF ty_service_blueprint_result.



        "============================================================
      " Provider Contract
      "============================================================
      TYPES:
        ty_provider_kind   TYPE c LENGTH 20,
        ty_provider_status TYPE c LENGTH 20.


      CONSTANTS:
        gc_provider_none
          TYPE ty_provider_kind
          VALUE 'NONE',

        gc_provider_class_method
          TYPE ty_provider_kind
          VALUE 'CLASS_METHOD',

        gc_provider_function
          TYPE ty_provider_kind
          VALUE 'FUNCTION_MODULE',

        gc_provider_bapi
          TYPE ty_provider_kind
          VALUE 'BAPI',

        gc_provider_report_logic
          TYPE ty_provider_kind
          VALUE 'REPORT_LOGIC'.


      CONSTANTS:
        gc_provider_ready
          TYPE ty_provider_status
          VALUE 'READY',

        gc_provider_signature
          TYPE ty_provider_status
          VALUE 'SIGNATURE_REQUIRED',

        gc_provider_refactor
          TYPE ty_provider_status
          VALUE 'REFACTOR_REQUIRED',

        gc_provider_review
          TYPE ty_provider_status
          VALUE 'MANUAL_REVIEW',

        gc_provider_unsupported
          TYPE ty_provider_status
          VALUE 'UNSUPPORTED'.


      TYPES:
        BEGIN OF ty_provider_candidate,
          source_item_id         TYPE ty_item_id,

          object_name            TYPE c LENGTH 120,
          object_type            TYPE c LENGTH 30,
          container_name         TYPE c LENGTH 120,
          calling_routine        TYPE c LENGTH 120,
          interface_summary      TYPE string,

          provider_kind          TYPE ty_provider_kind,
          provider_status        TYPE ty_provider_status,
          priority               TYPE i,

          side_effect            TYPE c LENGTH 20,
          transaction_dependency TYPE abap_bool,
          gui_dependency         TYPE abap_bool,
          reuse_feasibility      TYPE c LENGTH 20,

          selected               TYPE abap_bool,
          decision_reason        TYPE string,
        END OF ty_provider_candidate,

        tt_provider_candidate
          TYPE STANDARD TABLE OF ty_provider_candidate
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_provider_contract,
          analysis_id             TYPE ty_analysis_id,
          service_strategy        TYPE ty_service_strategy,

          source_item_id          TYPE ty_item_id,
          provider_kind           TYPE ty_provider_kind,
          provider_status         TYPE ty_provider_status,

          source_object_name      TYPE c LENGTH 120,
          source_container_name   TYPE c LENGTH 120,
          source_interface_summary TYPE string,

          proposed_class_name     TYPE c LENGTH 30,
          proposed_method_name    TYPE c LENGTH 30,

          manual_review           TYPE abap_bool,
          decision_reason         TYPE string,
        END OF ty_provider_contract.


      TYPES:
        BEGIN OF ty_provider_contract_result,
          contract   TYPE ty_provider_contract,
          candidates TYPE tt_provider_candidate,
          messages   TYPE tt_message,
        END OF ty_provider_contract_result.


       "============================================================
      " Provider Signature
      "============================================================
      TYPES:
        ty_sig_name   TYPE c LENGTH 120,
        ty_sig_dir    TYPE c LENGTH 10,
        ty_sig_role   TYPE c LENGTH 10,
        ty_sig_status TYPE c LENGTH 20.


      CONSTANTS:
        gc_sig_imp TYPE ty_sig_dir
          VALUE 'IMPORTING',

        gc_sig_exp TYPE ty_sig_dir
          VALUE 'EXPORTING',

        gc_sig_chg TYPE ty_sig_dir
          VALUE 'CHANGING',

        gc_sig_tab TYPE ty_sig_dir
          VALUE 'TABLES',

        gc_sig_ret TYPE ty_sig_dir
          VALUE 'RETURNING'.


      CONSTANTS:
        gc_sig_in TYPE ty_sig_role
          VALUE 'INPUT',

        gc_sig_out TYPE ty_sig_role
          VALUE 'OUTPUT',

        gc_sig_both TYPE ty_sig_role
          VALUE 'BOTH'.


      CONSTANTS:
        gc_sig_ready TYPE ty_sig_status
          VALUE 'READY',

        gc_sig_not_found TYPE ty_sig_status
          VALUE 'NOT_FOUND',

        gc_sig_review TYPE ty_sig_status
          VALUE 'MANUAL_REVIEW',

        gc_sig_unsup TYPE ty_sig_status
          VALUE 'UNSUPPORTED'.


      TYPES:
        BEGIN OF ty_sig_par,
          par_name   TYPE c LENGTH 30,
          direction  TYPE ty_sig_dir,
          abap_type  TYPE c LENGTH 30,
          type_name  TYPE c LENGTH 80,
          edm_type   TYPE c LENGTH 30,
          odata_role TYPE ty_sig_role,

          optional   TYPE abap_bool,
          is_table   TYPE abap_bool,
          is_ref     TYPE abap_bool,
          is_deep    TYPE abap_bool,
        END OF ty_sig_par,

        tt_sig_par TYPE STANDARD TABLE OF ty_sig_par
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_sig_def,
          provider_kind TYPE ty_provider_kind,

          obj_name      TYPE ty_sig_name,
          class_name    TYPE ty_sig_name,
          method_name   TYPE ty_sig_name,

          exists        TYPE abap_bool,
          is_static     TYPE abap_bool,

          params        TYPE tt_sig_par,
        END OF ty_sig_def.


      TYPES:
        BEGIN OF ty_sig_result,
          analysis_id      TYPE ty_analysis_id,
          service_strategy TYPE ty_service_strategy,
          provider_kind    TYPE ty_provider_kind,

          object_name      TYPE ty_sig_name,
          container_name   TYPE ty_sig_name,

          status           TYPE ty_sig_status,
          manual_review    TYPE abap_bool,
          decision_reason  TYPE string,

          input_params     TYPE tt_sig_par,
          output_params    TYPE tt_sig_par,
          all_params       TYPE tt_sig_par,
        END OF ty_sig_result.

       "============================================================
      " Service Mapping
      "============================================================
      TYPES:
        ty_svc_map_status TYPE c LENGTH 20,
        ty_svc_map_state  TYPE c LENGTH 20.


      CONSTANTS:
        gc_smap_ready TYPE ty_svc_map_status
          VALUE 'READY',

        gc_smap_review TYPE ty_svc_map_status
          VALUE 'MANUAL_REVIEW'.


      CONSTANTS:
        gc_smap_auto TYPE ty_svc_map_state
          VALUE 'AUTO',

        gc_smap_missing TYPE ty_svc_map_state
          VALUE 'MISSING',

        gc_smap_ambig TYPE ty_svc_map_state
          VALUE 'AMBIGUOUS',

        gc_smap_type TYPE ty_svc_map_state
          VALUE 'TYPE_CONFLICT',

        gc_smap_unused TYPE ty_svc_map_state
          VALUE 'UNUSED'.


      TYPES:
        BEGIN OF ty_svc_in_map,
          svc_item_id TYPE ty_item_id,

          svc_name    TYPE c LENGTH 40,
          prv_name    TYPE c LENGTH 30,

          svc_kind    TYPE c LENGTH 20,
          svc_edm     TYPE c LENGTH 30,
          prv_edm     TYPE c LENGTH 30,

          map_state   TYPE ty_svc_map_state,

          exact_name  TYPE abap_bool,
          type_match  TYPE abap_bool,

          mandatory   TYPE abap_bool,
          prv_optional TYPE abap_bool,

          reason      TYPE string,
        END OF ty_svc_in_map,

        tt_svc_in_map TYPE STANDARD TABLE OF ty_svc_in_map
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_svc_out_map,
          prv_name   TYPE c LENGTH 30,
          type_name  TYPE c LENGTH 80,
          edm_type   TYPE c LENGTH 30,

          is_table   TYPE abap_bool,
          name_match TYPE abap_bool,
          selected   TYPE abap_bool,

          map_state  TYPE ty_svc_map_state,
          reason     TYPE string,
        END OF ty_svc_out_map,

        tt_svc_out_map TYPE STANDARD TABLE OF ty_svc_out_map
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_svc_map_result,
          analysis_id    TYPE ty_analysis_id,

          status         TYPE ty_svc_map_status,
          manual_review  TYPE abap_bool,
          decision_reason TYPE string,

          mapped_inputs  TYPE i,
          issue_count    TYPE i,

          input_maps     TYPE tt_svc_in_map,
          output_maps    TYPE tt_svc_out_map,
          selected_out   TYPE ty_sig_par,
        END OF ty_svc_map_result.

       "============================================================
      " Row Type Resolution
      "============================================================
      TYPES:
        ty_row_status TYPE c LENGTH 20,
        ty_row_state  TYPE c LENGTH 20.


      CONSTANTS:
        gc_row_ready TYPE ty_row_status
          VALUE 'READY',

        gc_row_review TYPE ty_row_status
          VALUE 'MANUAL_REVIEW',

        gc_row_not_found TYPE ty_row_status
          VALUE 'NOT_FOUND',

        gc_row_unsup TYPE ty_row_status
          VALUE 'UNSUPPORTED'.


      CONSTANTS:
        gc_row_auto TYPE ty_row_state
          VALUE 'AUTO',

        gc_row_missing TYPE ty_row_state
          VALUE 'MISSING',

        gc_row_ambig TYPE ty_row_state
          VALUE 'AMBIGUOUS',

        gc_row_type TYPE ty_row_state
          VALUE 'TYPE_CONFLICT',

        gc_row_unused TYPE ty_row_state
          VALUE 'UNUSED'.


      TYPES:
        BEGIN OF ty_row_comp,
          comp_name TYPE c LENGTH 30,
          position  TYPE i,

          abap_type TYPE c LENGTH 30,
          type_name TYPE c LENGTH 80,
          edm_type  TYPE c LENGTH 30,

          is_table  TYPE abap_bool,
          is_ref    TYPE abap_bool,
          is_deep   TYPE abap_bool,
        END OF ty_row_comp,

        tt_row_comp TYPE STANDARD TABLE OF ty_row_comp
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_row_def,
          type_name  TYPE ty_sig_name,
          line_name  TYPE ty_sig_name,

          exists     TYPE abap_bool,
          structured TYPE abap_bool,

          components TYPE tt_row_comp,
        END OF ty_row_def.


      TYPES:
        BEGIN OF ty_row_map,
          svc_item_id TYPE ty_item_id,

          svc_name    TYPE c LENGTH 40,
          comp_name   TYPE c LENGTH 30,

          svc_edm     TYPE c LENGTH 30,
          comp_edm    TYPE c LENGTH 30,

          position    TYPE i,
          map_state   TYPE ty_row_state,

          exact_name  TYPE abap_bool,
          type_match  TYPE abap_bool,

          reason      TYPE string,
        END OF ty_row_map,

        tt_row_map TYPE STANDARD TABLE OF ty_row_map
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_row_result,
          analysis_id     TYPE ty_analysis_id,

          status          TYPE ty_row_status,
          manual_review   TYPE abap_bool,
          decision_reason TYPE string,

          output_name     TYPE c LENGTH 30,
          row_type        TYPE ty_sig_name,

          mapped_fields   TYPE i,
          issue_count     TYPE i,

          field_maps      TYPE tt_row_map,
          components      TYPE tt_row_comp,
          unused_comps    TYPE tt_row_comp,
        END OF ty_row_result.


        "============================================================
      " Artifact Manifest
      "============================================================
      TYPES:
        ty_art_type   TYPE c LENGTH 4,
        ty_art_role   TYPE c LENGTH 20,
        ty_art_name   TYPE c LENGTH 30,
        ty_art_cap    TYPE c LENGTH 15,
        ty_art_gen    TYPE c LENGTH 15,
        ty_art_status TYPE c LENGTH 20.


      CONSTANTS:
        gc_art_ddls TYPE ty_art_type
          VALUE 'DDLS',

        gc_art_ddlx TYPE ty_art_type
          VALUE 'DDLX',

        gc_art_clas TYPE ty_art_type
          VALUE 'CLAS',

        gc_art_bdef TYPE ty_art_type
          VALUE 'BDEF',

        gc_art_srvd TYPE ty_art_type
          VALUE 'SRVD',

        gc_art_srvb TYPE ty_art_type
          VALUE 'SRVB'.


      CONSTANTS:
        gc_art_entity TYPE ty_art_role
          VALUE 'ENTITY',

        gc_art_projection TYPE ty_art_role
          VALUE 'PROJECTION',

        gc_art_query_prv TYPE ty_art_role
          VALUE 'QUERY_PROVIDER',

        gc_art_adapter TYPE ty_art_role
          VALUE 'ADAPTER',

        gc_art_bdef_root TYPE ty_art_role
          VALUE 'BDEF_ROOT',

        gc_art_bdef_proj TYPE ty_art_role
          VALUE 'BDEF_PROJ',

        gc_art_bpool TYPE ty_art_role
          VALUE 'BEHAVIOR_POOL',

        gc_art_annot TYPE ty_art_role
          VALUE 'ANNOTATION',

        gc_art_srv_def TYPE ty_art_role
          VALUE 'SERVICE_DEF',

        gc_art_srv_bind TYPE ty_art_role
          VALUE 'SERVICE_BIND'.


      CONSTANTS:
        gc_art_cap_unknown TYPE ty_art_cap
          VALUE 'UNKNOWN',

        gc_art_cap_yes TYPE ty_art_cap
          VALUE 'SUPPORTED',

        gc_art_cap_no TYPE ty_art_cap
          VALUE 'UNSUPPORTED'.


      CONSTANTS:
        gc_art_planned TYPE ty_art_gen
          VALUE 'PLANNED',

        gc_art_blocked TYPE ty_art_gen
          VALUE 'BLOCKED',

        gc_art_created TYPE ty_art_gen
          VALUE 'CREATED',

        gc_art_failed TYPE ty_art_gen
          VALUE 'FAILED'.


      CONSTANTS:
        gc_art_ready TYPE ty_art_status
          VALUE 'READY',

        gc_art_review TYPE ty_art_status
          VALUE 'MANUAL_REVIEW'.


      TYPES:
        BEGIN OF ty_art_item,
          seq         TYPE i,
          art_type    TYPE ty_art_type,
          art_role    TYPE ty_art_role,
          object_name TYPE ty_art_name,
          package     TYPE devclass,

          description TYPE c LENGTH 120,
          gen_order   TYPE i,

          required    TYPE abap_bool,
          cap_state   TYPE ty_art_cap,
          gen_state   TYPE ty_art_gen,

          reason      TYPE string,
        END OF ty_art_item,

        tt_art_item TYPE STANDARD TABLE OF ty_art_item
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_art_dep,
          art_seq TYPE i,
          req_seq TYPE i,
        END OF ty_art_dep,

        tt_art_dep TYPE STANDARD TABLE OF ty_art_dep
          WITH EMPTY KEY.


      TYPES:
        BEGIN OF ty_art_mfst,
          analysis_id     TYPE ty_analysis_id,
          strategy        TYPE ty_service_strategy,
          source_program  TYPE ty_program_name,
          package         TYPE devclass,
          base_name       TYPE c LENGTH 40,

          status          TYPE ty_art_status,
          manual_review   TYPE abap_bool,
          decision_reason TYPE string,

          item_count      TYPE i,
          dep_count       TYPE i,

          items           TYPE tt_art_item,
          dependencies    TYPE tt_art_dep,
        END OF ty_art_mfst.

  "============================================================
  " Complete analysis result
  "============================================================
   TYPES:
      BEGIN OF ty_analysis_result,
        analysis_id      TYPE ty_analysis_id,
        overview         TYPE ty_overview,

        ui_filters       TYPE tt_ui_filter,
        database_objects TYPE tt_database_object,
        business_logic   TYPE tt_business_logic,
        source_objects TYPE tt_source_object,

        alv_outputs      TYPE tt_alv_output,
        alv_columns      TYPE tt_alv_column,
        alv_sorts        TYPE tt_alv_sort,
        alv_filters      TYPE tt_alv_filter,
        alv_events       TYPE tt_alv_event,

        evidences        TYPE tt_evidence,
        messages         TYPE tt_message,


        "Giữ các field này nếu đã tồn tại
        recommendations  TYPE tt_recommendation,
        annotations TYPE tt_annotation_proposal,
      END OF ty_analysis_result.


ENDINTERFACE.
