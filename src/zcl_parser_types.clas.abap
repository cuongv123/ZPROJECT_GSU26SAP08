CLASS zcl_parser_types DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES tt_source_code TYPE string_table.

    "=========================================
    " OVERVIEW DTO
    "=========================================
    TYPES:
      BEGIN OF ty_overview,
        program_name           TYPE string,
        program_description    TYPE string,
        total_tables           TYPE i,
        total_filters          TYPE i,
        total_business_objects TYPE i,
        migration_score        TYPE decfloat16,
        complexity_score       TYPE decfloat16,
        cloud_readiness_score  TYPE decfloat16,
        analysis_status        TYPE string,
      END OF ty_overview.
    TYPES tt_overview TYPE STANDARD TABLE OF ty_overview WITH EMPTY KEY.

    "=========================================
    " RAW UI FILTER DTO
    "=========================================
     TYPES:
      BEGIN OF ty_raw_ui_filter,
        field_name       TYPE string,
        filter_type      TYPE string,
        data_element     TYPE string,
        mandatory_flag   TYPE abap_bool, " <--- MỚI: Cờ bắt buộc nhập
        matchcode_object TYPE string,    " <--- MỚI: Tên Search Help
      END OF ty_raw_ui_filter.
    TYPES tt_raw_ui_filter TYPE STANDARD TABLE OF ty_raw_ui_filter WITH EMPTY KEY.

    "=========================================
    " FINAL UI FILTER DTO
    "=========================================
    TYPES:
      BEGIN OF ty_ui_filter,
        program_name     TYPE program,
        field_name       TYPE fieldname,
        description      TYPE string,
        filter_type      TYPE string,
        data_element     TYPE string,
        mandatory_flag   TYPE abap_bool,
        multi_value_flag TYPE abap_bool,
        migration_target TYPE string,
        severity         TYPE string,
        recommendation   TYPE string,
        fiori_adaptation TYPE string,
      END OF ty_ui_filter.
    TYPES tt_ui_filter TYPE STANDARD TABLE OF ty_ui_filter WITH EMPTY KEY.

    "=========================================
    " MIGRATION UI FILTERS RULES DTO
    "=========================================
    TYPES:
      BEGIN OF ty_ui_rule,
        filter_type      TYPE string,
        migration_target TYPE string,
        severity         TYPE string,
        recommendation   TYPE string,
        fiori_adaptation TYPE string,
      END OF ty_ui_rule.
    TYPES tt_ui_rule TYPE STANDARD TABLE OF ty_ui_rule WITH EMPTY KEY.

    "=========================================
    " RAW DB TABLE DTO
    "=========================================
    TYPES:
      BEGIN OF ty_raw_db_table,
        table_name TYPE string,
        operation  TYPE string,
        fields     TYPE string,
      END OF ty_raw_db_table.
    TYPES tt_raw_db_table TYPE STANDARD TABLE OF ty_raw_db_table WITH EMPTY KEY.

    "=========================================
    " FINAL DB TABLE DTO
    "=========================================
    TYPES:
      BEGIN OF ty_db_table,
        program_name       TYPE program,
        table_name         TYPE tabname,
        table_description  TYPE string,
        operations         TYPE string,
        fields             TYPE string,
        cds_candidate      TYPE string,
        priority           TYPE string,
        recommendation     TYPE string,
        migration_approach TYPE string,
      END OF ty_db_table.
    TYPES tt_db_table
    TYPE STANDARD TABLE OF ty_db_table WITH EMPTY KEY.

    "=========================================
    " MIGRATION BUSINESS LOGIC RULES DTO
    "=========================================
    TYPES:
      BEGIN OF ty_db_rule,
        table_name         TYPE string,
        priority           TYPE string,
        cds_candidate      TYPE string,
        recommendation     TYPE string,
        migration_approach TYPE string,
      END OF ty_db_rule.
    TYPES tt_db_rule TYPE STANDARD TABLE OF ty_db_rule WITH EMPTY KEY.

    "=========================================
    " RAW BUSINESS LOGIC DTO
    "=========================================
    TYPES:
      BEGIN OF ty_raw_logic,
        object_name TYPE string,
        object_type TYPE string,
        target_structure TYPE string,
      END OF ty_raw_logic.
    TYPES tt_raw_logic TYPE STANDARD TABLE OF ty_raw_logic WITH EMPTY KEY.

    "=========================================
    " FINAL BUSINESS LOGIC DTO
    "=========================================
    TYPES:
      BEGIN OF ty_business_logic,
        program_name           TYPE program,
        object_name            TYPE string,
        object_type            TYPE string,
        description            TYPE string,
        target_structure       TYPE string,
        api_released_flag      TYPE abap_bool,
        cloud_compliant        TYPE abap_bool,
        migration_target       TYPE string,
        severity               TYPE string,
        recommendation         TYPE string,
        remediation_complexity TYPE string,
      END OF ty_business_logic.
    TYPES tt_business_logic TYPE STANDARD TABLE OF ty_business_logic WITH EMPTY KEY.

    "=========================================
    " MIGRATION BUSINESS LOGIC RULES DTO
    "=========================================
    TYPES:
      BEGIN OF ty_logic_rule,
        rule_id                TYPE char30,
        object_type            TYPE char30,
        object_name            TYPE char100,
        migration_target       TYPE char100,
        severity               TYPE char20,
        cloud_compliant        TYPE abap_bool,
        api_released           TYPE abap_bool,
        recommendation         TYPE char255,
        remediation_complexity TYPE char20,
      END OF ty_logic_rule.
    TYPES tt_logic_rule TYPE STANDARD TABLE OF ty_logic_rule WITH EMPTY KEY.

ENDCLASS.

CLASS zcl_parser_types IMPLEMENTATION.
ENDCLASS.
