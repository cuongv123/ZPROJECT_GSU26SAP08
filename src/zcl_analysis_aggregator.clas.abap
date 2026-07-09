CLASS zcl_analysis_aggregator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_analysis_aggregator.

  PRIVATE SECTION.
    METHODS calculate_complexity_score
      IMPORTING
                it_business_logic TYPE zcl_parser_types=>tt_business_logic
      RETURNING VALUE(rv_score)   TYPE decfloat16.

    METHODS calculate_cloud_readiness
      IMPORTING
                it_business_logic TYPE zcl_parser_types=>tt_business_logic
      RETURNING VALUE(rv_score)   TYPE decfloat16.

    METHODS calculate_migration_score
      IMPORTING
        iv_complexity   TYPE decfloat16
      RETURNING
        VALUE(rv_score) TYPE decfloat16.
ENDCLASS.

CLASS zcl_analysis_aggregator IMPLEMENTATION.
  METHOD calculate_complexity_score.
  DATA:
    lv_actual TYPE decfloat16 VALUE 0,
    lv_max    TYPE decfloat16 VALUE 0.
  LOOP AT it_business_logic INTO DATA(ls_logic).
    lv_max += 3.
    CASE ls_logic-severity.
      WHEN 'HIGH'.
        lv_actual += 3.
      WHEN 'MEDIUM'.
        lv_actual += 2.
      WHEN 'LOW'.
        lv_actual += 1.
    ENDCASE.
  ENDLOOP.

  IF lv_max = 0.
    rv_score = 0.
  ELSE.
    rv_score = ( lv_actual / lv_max ) * 100.
  ENDIF.
ENDMETHOD.

  METHOD calculate_cloud_readiness.
  DATA:
    lv_ready TYPE decfloat16 VALUE 0,
    lv_total TYPE decfloat16 VALUE 0.
  LOOP AT it_business_logic INTO DATA(ls_logic).
    lv_total += 1.
    IF ls_logic-cloud_compliant = abap_true.
      lv_ready += 1.
    ENDIF.
  ENDLOOP.

  IF lv_total = 0.
    rv_score = 100.
  ELSE.
    rv_score = ( lv_ready / lv_total ) * 100.
  ENDIF.
ENDMETHOD.

  METHOD calculate_migration_score.
    rv_score = 100 - iv_complexity.
    IF rv_score < 0.
      rv_score = 0.
    ENDIF.
  ENDMETHOD.

  METHOD zif_analysis_aggregator~build_overview.
    es_overview-program_name = iv_program_name.
    es_overview-total_tables = lines( it_db_table ).
    es_overview-total_filters = lines( it_ui_filter ).
    es_overview-total_business_objects = lines( it_business_logic ).
    es_overview-complexity_score = calculate_complexity_score( it_business_logic ).
    es_overview-migration_score = calculate_migration_score( es_overview-complexity_score ).
    es_overview-cloud_readiness_score = calculate_cloud_readiness( it_business_logic ).
    es_overview-analysis_status = 'COMPLETED'.
  ENDMETHOD.
ENDCLASS.
