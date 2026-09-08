INTERFACE zif_mig_chat_context_builder
  PUBLIC.

  TYPES:
    BEGIN OF ty_context,
      program_name    TYPE progname,
      analysis_id     TYPE sysuuid_x16,
      is_outdated     TYPE abap_bool,
      anchor_summary  TYPE string,
      focused_section TYPE string,
      unresolved_note TYPE string,
    END OF ty_context.

  METHODS build
    IMPORTING
      iv_program_name   TYPE progname
      iv_question       TYPE string
    RETURNING
      VALUE(rs_context) TYPE ty_context
    RAISING
      zcx_mig_analysis.

  METHODS classify_intent
    IMPORTING
      iv_question      TYPE string
    RETURNING
      VALUE(rv_intent) TYPE string.

ENDINTERFACE.
