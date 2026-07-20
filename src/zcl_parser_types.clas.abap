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
        description            TYPE string,
        analyzed_by            TYPE string,
        analyzed_at            TYPE utclong,
        total_tables           TYPE i,
        total_filters          TYPE i,
        total_business_objects TYPE i,
        migration_score        TYPE i,
        complexity_score       TYPE i,
        cloud_readiness_score  TYPE i,
        analysis_status        TYPE string,
      END OF ty_overview.
    TYPES tt_overview TYPE STANDARD TABLE OF ty_overview WITH EMPTY KEY.

    "=========================================
    " SCANNER DTO
    "=========================================
    TYPES:
      BEGIN OF ty_scan_result,
        statements TYPE sstmnt_tab,
        tokens     TYPE stokesx_tab,
      END OF ty_scan_result.
    TYPES tt_scan_tokens     TYPE stokesx_tab.
    TYPES tt_scan_statements TYPE sstmnt_tab.

    "=========================================
    " SYMBOL TABLE DTO
    "=========================================
    TYPES:
      BEGIN OF ty_symbol,
        symbol_name      TYPE string,
        symbol_kind      TYPE string,
        declaration_kind TYPE string,
        referenced_type  TYPE string,
        mandatory_flag   TYPE abap_bool,
        default_value    TYPE string,
        matchcode_object TYPE string,
        lower_case_flag  TYPE abap_bool,
        scope            TYPE string,
        statement_index  TYPE i,
        token_from       TYPE i,
        token_to         TYPE i,
      END OF ty_symbol.
    TYPES tt_symbol TYPE STANDARD TABLE OF ty_symbol WITH EMPTY KEY.

    "=========================================
    " SEMANTIC SYMBOL DTO
    "=========================================
    TYPES:
      BEGIN OF ty_semantic_symbol,

        " Syntax information
        symbol_name      TYPE string,
        symbol_kind      TYPE string,
        declaration_kind TYPE string,
        referenced_type  TYPE string,

        " Semantic information
        description      TYPE string,
        ddic_object_type TYPE string,
        ddic_object_name TYPE string,
        domain_name      TYPE domname,
        abap_type        TYPE string,
        length           TYPE i,
        decimals         TYPE i,
        search_help      TYPE string,
        conversion_exit  TYPE string,

        " Parameter attributes
        mandatory_flag   TYPE abap_bool,
        default_value    TYPE string,
        matchcode_object TYPE string,
        lower_case_flag  TYPE abap_bool,

        " Position
        scope            TYPE string,
        statement_index  TYPE i,
        token_from       TYPE i,
        token_to         TYPE i,
      END OF ty_semantic_symbol.

    TYPES tt_semantic_symbol
      TYPE STANDARD TABLE OF ty_semantic_symbol
      WITH EMPTY KEY.

    "=========================================
    " RAW UI FILTER DTO
    "=========================================
    TYPES:
      BEGIN OF ty_raw_ui_filter,
        field_name       TYPE fieldname,
        filter_type      TYPE string,
        data_element     TYPE rollname,
        mandatory_flag   TYPE abap_bool, " <--- MỚI: Cờ bắt buộc nhập
        matchcode_object TYPE string,    " <--- MỚI: Tên Search Help
      END OF ty_raw_ui_filter.
    TYPES tt_raw_ui_filter TYPE STANDARD TABLE OF ty_raw_ui_filter WITH EMPTY KEY.

    "=========================================
    " SEMANTIC UI FILTER DTO
    "=========================================
    TYPES:
      BEGIN OF ty_semantic_ui_filter,
        field_name       TYPE fieldname,
        filter_type      TYPE string,
        data_element     TYPE rollname,

        description      TYPE string,
        domain_name      TYPE domname,
        data_type        TYPE string,
        length           TYPE i,
        decimals         TYPE i,

        search_help      TYPE string,
        conversion_exit  TYPE string,

        mandatory_flag   TYPE abap_bool,
        multi_value_flag TYPE abap_bool,
      END OF ty_semantic_ui_filter.

    TYPES tt_semantic_ui_filter
      TYPE STANDARD TABLE OF ty_semantic_ui_filter
      WITH EMPTY KEY.

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
    " FINAL UI FILTER DTO
    "=========================================
    TYPES:
      BEGIN OF ty_ui_filter,
        program_name     TYPE program,
        field_name       TYPE fieldname,
        description      TYPE string,
        filter_type      TYPE string,
        data_element     TYPE rollname,
        mandatory_flag   TYPE abap_bool,
        multi_value_flag TYPE abap_bool,
        migration_target TYPE string,
        severity         TYPE string,
        recommendation   TYPE string,
        fiori_adaptation TYPE string,
      END OF ty_ui_filter.
    TYPES tt_ui_filter TYPE STANDARD TABLE OF ty_ui_filter WITH EMPTY KEY.

    "=========================================
    " RAW DB TABLE DTO
    "=========================================
    TYPES:
      BEGIN OF ty_raw_db_table,
        table_name TYPE tabname,
        operation  TYPE string,
        fields     TYPE string,
      END OF ty_raw_db_table.
    TYPES tt_raw_db_table TYPE STANDARD TABLE OF ty_raw_db_table WITH EMPTY KEY.

    "=========================================
    " SEMANTIC DB TABLE DTO
    "=========================================
    TYPES:
      BEGIN OF ty_semantic_db_table,

        table_name        TYPE tabname,
        operation         TYPE string,
        fields            TYPE string,

        table_description TYPE string,
        table_category    TYPE string,
        delivery_class    TYPE string,
        primary_key       TYPE string,
        field_count       TYPE i,

      END OF ty_semantic_db_table.

    TYPES tt_semantic_db_table
      TYPE STANDARD TABLE OF ty_semantic_db_table
      WITH EMPTY KEY.

    "=========================================
    " MIGRATION BUSINESS LOGIC RULES DTO
    "=========================================
    TYPES:
      BEGIN OF ty_db_rule,
        table_name         TYPE tabname,
        priority           TYPE string,
        cds_candidate      TYPE string,
        recommendation     TYPE string,
        migration_approach TYPE string,
      END OF ty_db_rule.
    TYPES tt_db_rule TYPE STANDARD TABLE OF ty_db_rule WITH EMPTY KEY.


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
    " RAW BUSINESS LOGIC DTO
    "=========================================
    TYPES:
      BEGIN OF ty_raw_logic,
        object_name      TYPE string,
        object_type      TYPE string,
        target_structure TYPE string,
      END OF ty_raw_logic.
    TYPES tt_raw_logic TYPE STANDARD TABLE OF ty_raw_logic WITH EMPTY KEY.

    "=========================================
    " SEMANTIC BUSINESS LOGIC DTO
    "=========================================
    TYPES:
      BEGIN OF ty_semantic_business_logic,

        object_name       TYPE string,
        object_type       TYPE string,
        target_structure  TYPE string,

        description       TYPE string,
        package           TYPE devclass,

        api_released_flag TYPE abap_bool,
        cloud_compliant   TYPE abap_bool,

      END OF ty_semantic_business_logic.

    TYPES tt_semantic_business_logic
      TYPE STANDARD TABLE OF ty_semantic_business_logic
      WITH EMPTY KEY.

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
    " FINAL OBJECT MAPPING DTO (Giai đoạn 2)
    "=========================================
    TYPES:
      BEGIN OF ty_object_map,
        source_obj    TYPE string,
        source_type   TYPE string,
        target_obj    TYPE string,
        target_type   TYPE string,
        relation_type TYPE string,
      END OF ty_object_map.

    TYPES tt_object_map TYPE STANDARD TABLE OF ty_object_map WITH EMPTY KEY.

ENDCLASS.

CLASS zcl_parser_types IMPLEMENTATION.
ENDCLASS.
