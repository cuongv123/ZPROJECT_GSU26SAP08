CLASS zcl_mig_service_blueprint DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_service_blueprint.

  PRIVATE SECTION.

      TYPES:
        ty_source_data_type TYPE c LENGTH 30,
        ty_edm_type         TYPE c LENGTH 30,
        ty_target_name      TYPE c LENGTH 30.

    METHODS build_parameters
      IMPORTING
        it_ui_filters
          TYPE zif_mig_types=>tt_ui_filter
      RETURNING
        VALUE(rt_parameters)
          TYPE zif_mig_types=>tt_service_parameter.

    METHODS build_fields
      IMPORTING
        it_alv_columns
          TYPE zif_mig_types=>tt_alv_column
      RETURNING
        VALUE(rt_fields)
          TYPE zif_mig_types=>tt_service_field.

    METHODS determine_strategy
      IMPORTING
        is_analysis
          TYPE zif_mig_types=>ty_analysis_result
      CHANGING
        cs_blueprint
          TYPE zif_mig_types=>ty_service_blueprint.

    METHODS map_edm_type
      IMPORTING
        iv_data_type TYPE ty_source_data_type
        iv_checkbox  TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rv_edm_type) TYPE ty_edm_type.

    METHODS make_target_name
      IMPORTING
        iv_prefix       TYPE string
        iv_program_name TYPE progname
      RETURNING
        VALUE(rv_name) TYPE ty_target_name.

ENDCLASS.

CLASS zcl_mig_service_blueprint IMPLEMENTATION.

  METHOD zif_mig_service_blueprint~build.

    IF is_analysis-analysis_id IS INITIAL
       OR is_analysis-overview-program_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        program_name = is_analysis-overview-program_name
      ).

    ENDIF.


    rs_blueprint-blueprint-analysis_id =
      is_analysis-analysis_id.

    rs_blueprint-blueprint-source_program =
      is_analysis-overview-program_name.


    rs_blueprint-blueprint-service_name =
      make_target_name(
        iv_prefix       = 'ZUI_'
        iv_program_name =
          is_analysis-overview-program_name
      ).

    rs_blueprint-blueprint-entity_name =
      make_target_name(
        iv_prefix       = 'ZC_'
        iv_program_name =
          is_analysis-overview-program_name
      ).


    rs_blueprint-parameters =
      build_parameters(
        it_ui_filters = is_analysis-ui_filters
      ).

    rs_blueprint-fields =
      build_fields(
        it_alv_columns = is_analysis-alv_columns
      ).


    READ TABLE is_analysis-alv_outputs
      INDEX 1
      INTO DATA(ls_output).

    IF sy-subrc = 0.

      rs_blueprint-blueprint-source_output_id =
        ls_output-output_id.

      rs_blueprint-blueprint-source_table =
        ls_output-output_table.

      rs_blueprint-blueprint-source_row_type =
        ls_output-row_type.

    ENDIF.


    determine_strategy(
      EXPORTING
        is_analysis =
          is_analysis
      CHANGING
        cs_blueprint =
          rs_blueprint-blueprint
    ).

  ENDMETHOD.

    METHOD build_parameters.

    LOOP AT it_ui_filters
      INTO DATA(ls_filter).

      DATA(lv_odata_kind) =
        COND #( WHEN ls_filter-field_kind = 'SELECT_OPTIONS'
                THEN 'RANGE'
                ELSE 'PROPERTY' ).

      APPEND VALUE #(
        source_item_id =
          ls_filter-item_id

        parameter_name =
          ls_filter-field_name

        source_kind =
          ls_filter-field_kind

        odata_kind =
          lv_odata_kind

        edm_type =
          map_edm_type(
            iv_data_type = ls_filter-data_type
            iv_checkbox  = ls_filter-checkbox
          )

        mandatory =
          ls_filter-mandatory

        multiple_selection =
          ls_filter-multiple_selection

        range_supported =
          ls_filter-range_supported

        default_value =
          ls_filter-default_value
      ) TO rt_parameters.

    ENDLOOP.

    SORT rt_parameters
      BY parameter_name.

  ENDMETHOD.

    METHOD build_fields.

    LOOP AT it_alv_columns
      INTO DATA(ls_column).

      APPEND VALUE #(
        source_item_id =
          ls_column-item_id

        field_name =
          ls_column-field_name

        label =
          ls_column-label

        edm_type =
          map_edm_type(
            iv_data_type = ls_column-data_type
            iv_checkbox  = ls_column-checkbox
          )

        position =
          ls_column-position

        key_field =
          ls_column-key_field

        visible =
          ls_column-visible

        filterable =
          xsdbool(
            ls_column-technical = abap_false
            AND ls_column-icon = abap_false
          )

        sortable =
          xsdbool(
            ls_column-technical = abap_false
            AND ls_column-icon = abap_false
          )

        source_mapping =
          ls_column-source_mapping
      ) TO rt_fields.

    ENDLOOP.

    SORT rt_fields
      BY position
         field_name.

  ENDMETHOD.

    METHOD map_edm_type.

    IF iv_checkbox = abap_true.

      rv_edm_type = 'Edm.Boolean'.
      RETURN.

    ENDIF.


    DATA(lv_type) =
    to_upper(
      CONV string( iv_data_type )
    ).

    CONDENSE lv_type NO-GAPS.


    CASE lv_type.

      WHEN 'I'
        OR 'INT1'
        OR 'INT2'
        OR 'INT4'.

        rv_edm_type = 'Edm.Int32'.


      WHEN 'INT8'.

        rv_edm_type = 'Edm.Int64'.


      WHEN 'P'
        OR 'DEC'
        OR 'CURR'
        OR 'QUAN'
        OR 'DECFLOAT16'
        OR 'DECFLOAT34'.

        rv_edm_type = 'Edm.Decimal'.


      WHEN 'D'
        OR 'DATS'.

        rv_edm_type = 'Edm.Date'.


      WHEN 'T'
        OR 'TIMS'.

        rv_edm_type = 'Edm.TimeOfDay'.


      WHEN 'F'
        OR 'FLTP'.

        rv_edm_type = 'Edm.Double'.


      WHEN OTHERS.

        rv_edm_type = 'Edm.String'.

    ENDCASE.

  ENDMETHOD.

    METHOD determine_strategy.

    CLEAR:
      cs_blueprint-supports_filter,
      cs_blueprint-supports_sort,
      cs_blueprint-supports_paging,
      cs_blueprint-manual_review,
      cs_blueprint-decision_reason.


    "==========================================================
    " Output contract phải resolve được
    "==========================================================
    IF is_analysis-alv_outputs IS INITIAL.

      cs_blueprint-strategy =
        zif_mig_types=>gc_svc_manual.

      cs_blueprint-manual_review =
        abap_true.

      cs_blueprint-decision_reason =
        'No tabular ALV output was resolved.'.

      RETURN.

    ENDIF.


    IF lines( is_analysis-alv_outputs ) > 1.

      cs_blueprint-strategy =
        zif_mig_types=>gc_svc_manual.

      cs_blueprint-manual_review =
        abap_true.

      cs_blueprint-decision_reason =
        'Multiple ALV outputs require explicit target design.'.

      RETURN.

    ENDIF.


    IF is_analysis-alv_columns IS INITIAL.

      cs_blueprint-strategy =
        zif_mig_types=>gc_svc_manual.

      cs_blueprint-manual_review =
        abap_true.

      cs_blueprint-decision_reason =
        'ALV output columns could not be resolved.'.

      RETURN.

    ENDIF.


    "==========================================================
    " Dynamic DB access
    "==========================================================
    LOOP AT is_analysis-database_objects
      TRANSPORTING NO FIELDS
      WHERE dynamic_access = abap_true.

      cs_blueprint-strategy =
        zif_mig_types=>gc_svc_manual.

      cs_blueprint-manual_review =
        abap_true.

      cs_blueprint-decision_reason =
        'Dynamic database access requires manual provider design.'.

      RETURN.

    ENDLOOP.


    "==========================================================
    " GUI dependency
    "==========================================================
    LOOP AT is_analysis-business_logic
      TRANSPORTING NO FIELDS
      WHERE gui_dependency = abap_true.

      cs_blueprint-strategy =
        zif_mig_types=>gc_svc_manual.

      cs_blueprint-manual_review =
        abap_true.

      cs_blueprint-decision_reason =
        'GUI-dependent logic cannot be exposed directly as OData.'.

      RETURN.

    ENDLOOP.


    DATA(lv_requires_action) =
      abap_false.


    "==========================================================
    " Database write
    "==========================================================
    LOOP AT is_analysis-database_objects
      INTO DATA(ls_database).

      CASE ls_database-operation.

        WHEN 'INSERT'
          OR 'UPDATE'
          OR 'MODIFY'
          OR 'DELETE'.

          lv_requires_action =
            abap_true.

          EXIT.

      ENDCASE.

    ENDLOOP.


    "==========================================================
    " Transactional business logic
    "==========================================================
    IF lv_requires_action = abap_false.

      LOOP AT is_analysis-business_logic
        INTO DATA(ls_logic).

        IF ls_logic-transaction_dependency = abap_true
           OR ls_logic-side_effect = 'WRITE'.

          lv_requires_action =
            abap_true.

          EXIT.

        ENDIF.

      ENDLOOP.

    ENDIF.


    IF lv_requires_action = abap_true.

      cs_blueprint-strategy =
        zif_mig_types=>gc_svc_action.

      cs_blueprint-decision_reason =
        'Transactional behavior should be exposed through a RAP action.'.

      RETURN.

    ENDIF.


    "==========================================================
    " Read-only tabular report
    "==========================================================
    cs_blueprint-strategy =
      zif_mig_types=>gc_svc_query.

    cs_blueprint-supports_filter =
      abap_true.

    cs_blueprint-supports_sort =
      abap_true.

    cs_blueprint-supports_paging =
      abap_true.

    cs_blueprint-decision_reason =
      'Read-only tabular report is suitable for a RAP query provider.'.

  ENDMETHOD.

    METHOD make_target_name.

    DATA(lv_base) =
      to_upper(
        CONV string(
          iv_program_name
        )
      ).

    CONDENSE lv_base NO-GAPS.


    DATA(lv_max_base_length) =
      30 - strlen( iv_prefix ).

    IF strlen( lv_base ) > lv_max_base_length.

      lv_base =
        substring(
          val = lv_base
          len = lv_max_base_length
        ).

    ENDIF.


    rv_name =
      |{ iv_prefix }{ lv_base }|.

  ENDMETHOD.

ENDCLASS.
