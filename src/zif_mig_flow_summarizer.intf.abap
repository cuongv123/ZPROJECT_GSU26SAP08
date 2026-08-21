INTERFACE zif_mig_flow_summarizer
  PUBLIC.

  TYPES:
    ty_step_kind    TYPE c LENGTH 20,
    ty_name         TYPE c LENGTH 120,
    ty_object_type  TYPE c LENGTH 40,
    ty_relation     TYPE c LENGTH 30.


  TYPES:
    BEGIN OF ty_flow_step,

      sequence      TYPE i,
      level         TYPE i,

      step_kind     TYPE ty_step_kind,

      context_name  TYPE ty_name,
      object_name   TYPE ty_name,
      object_type   TYPE ty_object_type,

      relation      TYPE ty_relation,
      detail        TYPE string,

      source_object TYPE progname,
      source_line   TYPE i,

      evidence_id
        TYPE zif_mig_types=>ty_evidence_id,

      confidence
        TYPE zif_mig_types=>ty_confidence,

      manual_review TYPE abap_bool,

    END OF ty_flow_step,

    tt_flow_step
      TYPE STANDARD TABLE OF ty_flow_step
      WITH EMPTY KEY.


  TYPES:
    BEGIN OF ty_flow_summary,

      program_name TYPE progname,

      steps
        TYPE tt_flow_step,

    END OF ty_flow_summary.


  METHODS summarize
    IMPORTING
      is_result
        TYPE zif_mig_types=>ty_analysis_result

    RETURNING
      VALUE(rs_summary)
        TYPE ty_flow_summary.

ENDINTERFACE.
