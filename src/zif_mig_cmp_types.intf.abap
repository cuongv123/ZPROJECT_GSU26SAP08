INTERFACE zif_mig_cmp_types
  PUBLIC.

  " Comparison result status
  CONSTANTS:
    gc_status_mapped      TYPE c LENGTH 30 VALUE 'MAPPED',
    gc_status_refactor    TYPE c LENGTH 30 VALUE 'REFACTOR_REQUIRED',
    gc_status_manual      TYPE c LENGTH 30 VALUE 'MANUAL_REQUIRED',
    gc_status_unsupported TYPE c LENGTH 30 VALUE 'UNSUPPORTED'.

  " Comparison categories
  CONSTANTS:
    gc_cat_input      TYPE c LENGTH 20 VALUE 'INPUT',
    gc_cat_output     TYPE c LENGTH 20 VALUE 'OUTPUT',
    gc_cat_processing TYPE c LENGTH 20 VALUE 'PROCESSING',
    gc_cat_ui         TYPE c LENGTH 20 VALUE 'UI_INTERACTION',
    gc_cat_export     TYPE c LENGTH 20 VALUE 'EXPORT',
    gc_cat_scheduling TYPE c LENGTH 20 VALUE 'SCHEDULING',
    gc_cat_dependency TYPE c LENGTH 20 VALUE 'DEPENDENCY'.

  " Severity
  CONSTANTS:
    gc_severity_info    TYPE c LENGTH 10 VALUE 'INFO',
    gc_severity_warning TYPE c LENGTH 10 VALUE 'WARNING',
    gc_severity_error   TYPE c LENGTH 10 VALUE 'ERROR'.

  " Comparison run status
  CONSTANTS:
    gc_run_new     TYPE c LENGTH 20 VALUE 'NEW',
    gc_run_running TYPE c LENGTH 20 VALUE 'RUNNING',
    gc_run_success TYPE c LENGTH 20 VALUE 'SUCCESS',
    gc_run_failed  TYPE c LENGTH 20 VALUE 'FAILED'.

  " Overall compatibility status
  CONSTANTS:
    gc_overall_high    TYPE c LENGTH 30 VALUE 'HIGH_COMPATIBILITY',
    gc_overall_partial TYPE c LENGTH 30 VALUE 'PARTIALLY_COMPATIBLE',
    gc_overall_manual  TYPE c LENGTH 30 VALUE 'HIGH_MANUAL_EFFORT'.

  " Target strategy
  CONSTANTS:
    gc_strategy_query     TYPE c LENGTH 30 VALUE 'QUERY_SERVICE',
    gc_strategy_managed   TYPE c LENGTH 30 VALUE 'MANAGED_BO',
    gc_strategy_unmanaged TYPE c LENGTH 30 VALUE 'UNMANAGED_BO',
    gc_strategy_manual    TYPE c LENGTH 30 VALUE 'MANUAL_DESIGN'.

  TYPES:
    BEGIN OF ty_cmp_item,
      item_no         TYPE i,
      category        TYPE c LENGTH 20,

      source_element  TYPE c LENGTH 120,
      source_type     TYPE c LENGTH 40,
      source_value    TYPE c LENGTH 255,

      target_element  TYPE c LENGTH 120,
      target_type     TYPE c LENGTH 40,
      target_value    TYPE c LENGTH 255,

      mapping_rule    TYPE c LENGTH 60,
      status          TYPE c LENGTH 30,
      severity        TYPE c LENGTH 10,

      message         TYPE c LENGTH 255,
      recommendation  TYPE c LENGTH 255,
    END OF ty_cmp_item.

  TYPES ty_t_cmp_item
    TYPE STANDARD TABLE OF ty_cmp_item
    WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_run_summary,
      cmp_run_id         TYPE sysuuid_x16,
      analysis_id        TYPE sysuuid_x16,
      program_name       TYPE programm,
      target_strategy    TYPE c LENGTH 30,

      total_items        TYPE i,
      mapped_count       TYPE i,
      refactor_count     TYPE i,
      manual_count       TYPE i,
      unsupported_count  TYPE i,

      compatibility_rate TYPE p LENGTH 3 DECIMALS 2,
      overall_status     TYPE c LENGTH 30,
      run_status         TYPE c LENGTH 20,
      error_message      TYPE c LENGTH 255,
    END OF ty_run_summary.

ENDINTERFACE.
