CLASS zcl_rule_repository DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS get_ui_rules
      RETURNING VALUE(rt_rules)
                  TYPE zcl_parser_types=>tt_ui_rule.

    METHODS get_db_rules
      RETURNING VALUE(rt_rules)
                  TYPE zcl_parser_types=>tt_db_rule.

    METHODS get_logic_rules
      RETURNING VALUE(rt_rules)
                  TYPE zcl_parser_types=>tt_logic_rule.
ENDCLASS.

CLASS zcl_rule_repository IMPLEMENTATION.

  METHOD get_ui_rules.
    SELECT
      filter_type,
      migration_target,
      severity,
      recommendation,
      fiori_adaptation
    FROM zmig_ui_rule
    INTO CORRESPONDING FIELDS OF TABLE @rt_rules.
  ENDMETHOD.

  METHOD get_db_rules.
    SELECT
      table_name,
      priority,
      cds_candidate,
      recommendation,
      migration_approach
      FROM zmig_db_rule
      INTO CORRESPONDING FIELDS OF TABLE @rt_rules.
  ENDMETHOD.

  METHOD get_logic_rules.
    SELECT
      rule_id,
      object_type,
      object_name,
      migration_target,
      severity,
      cloud_compliant,
      api_released,
      recommendation,
      remediation_complexity
    FROM zmig_logic_rule
    INTO CORRESPONDING FIELDS OF TABLE @rt_rules.
  ENDMETHOD.

ENDCLASS.
