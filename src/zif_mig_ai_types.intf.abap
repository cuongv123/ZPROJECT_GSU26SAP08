INTERFACE zif_mig_ai_types
  PUBLIC.


  TYPES:
      ty_confidence TYPE zif_mig_types=>ty_confidence,
      ty_status     TYPE zif_mig_types=>ty_status,
      ty_severity   TYPE zif_mig_types=>ty_severity.


  CONSTANTS:
      gc_conf_high
        TYPE ty_confidence
        VALUE zif_mig_types=>gc_conf_high,

      gc_conf_medium
        TYPE ty_confidence
        VALUE zif_mig_types=>gc_conf_medium,

      gc_conf_low
        TYPE ty_confidence
        VALUE zif_mig_types=>gc_conf_low.


  "============================================================
  " Prompt passed to provider
  "============================================================
  TYPES:
    BEGIN OF ty_prompt,

      system_prompt TYPE string,

      user_prompt   TYPE string,

    END OF ty_prompt.


  "============================================================
  " AI result - business purpose
  "============================================================
  TYPES:
    BEGIN OF ty_business_purpose,

      text
        TYPE string,

      confidence
        TYPE ty_confidence,

      reasoning
        TYPE string,

    END OF ty_business_purpose.


  "============================================================
  " Generic AI finding
  "============================================================
  TYPES:
    BEGIN OF ty_finding,

      title
        TYPE string,

      description
        TYPE string,

      severity
        TYPE ty_severity,

      confidence
        TYPE ty_confidence,

      evidence
        TYPE string,

      manual_review
        TYPE abap_bool,

    END OF ty_finding,


    tt_finding
      TYPE STANDARD TABLE OF ty_finding
      WITH EMPTY KEY.


  "============================================================
  " Migration step
  "============================================================
  TYPES:
    BEGIN OF ty_migration_step,

      sequence
        TYPE i,

      title
        TYPE string,

      description
        TYPE string,

      target_layer
        TYPE string,

      confidence
        TYPE ty_confidence,

      manual_review
        TYPE abap_bool,

    END OF ty_migration_step,


    tt_migration_step
      TYPE STANDARD TABLE OF ty_migration_step
      WITH EMPTY KEY.


  "============================================================
  " Architecture suggestion
  "============================================================
  TYPES:
    BEGIN OF ty_architecture_item,

      legacy_component
        TYPE string,

      target_component
        TYPE string,

      rationale
        TYPE string,

      confidence
        TYPE ty_confidence,

    END OF ty_architecture_item,


    tt_architecture_item
      TYPE STANDARD TABLE OF ty_architecture_item
      WITH EMPTY KEY.


  "============================================================
  " Code suggestion
  "============================================================
  TYPES:
    BEGIN OF ty_code_suggestion,

      title
        TYPE string,

      target_object
        TYPE string,

      suggestion
        TYPE string,

      code
        TYPE string,

      language
        TYPE c LENGTH 20,

      confidence
        TYPE ty_confidence,

      manual_review
        TYPE abap_bool,

    END OF ty_code_suggestion,


    tt_code_suggestion
      TYPE STANDARD TABLE OF ty_code_suggestion
      WITH EMPTY KEY.


  "============================================================
  " Complete AI assessment
  "============================================================
  TYPES:
    BEGIN OF ty_assessment,

      analysis_id
        TYPE zif_mig_types=>ty_analysis_id,

      program_name
        TYPE progname,

      application_summary
        TYPE string,

      business_purpose
        TYPE ty_business_purpose,

      legacy_flow_explanation
        TYPE string,

      risks
        TYPE tt_finding,

      modernization_plan
        TYPE tt_migration_step,

      target_architecture
        TYPE tt_architecture_item,

      code_suggestions
        TYPE tt_code_suggestion,

      manual_review
        TYPE tt_finding,

      raw_response
        TYPE string,

    END OF ty_assessment.


ENDINTERFACE.
