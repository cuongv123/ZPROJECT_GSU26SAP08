CLASS zcl_mig_ai_response_parser DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES
      zif_mig_ai_response_parser.


  PRIVATE SECTION.

    "==========================================================
    " Wire types
    "
    " Names intentionally mirror JSON contract.
    "==========================================================
    TYPES:
      BEGIN OF ty_wire_business_purpose,

        text
          TYPE string,

        confidence
          TYPE string,

        reasoning
          TYPE string,

      END OF ty_wire_business_purpose.


    TYPES:
      BEGIN OF ty_wire_finding,

        title
          TYPE string,

        description
          TYPE string,

        severity
          TYPE string,

        confidence
          TYPE string,

        evidence
          TYPE string,

        manual_review
          TYPE abap_bool,

      END OF ty_wire_finding,

      tt_wire_finding
        TYPE STANDARD TABLE OF ty_wire_finding
        WITH EMPTY KEY.


    TYPES:
      BEGIN OF ty_wire_migration_step,

        sequence
          TYPE i,

        title
          TYPE string,

        description
          TYPE string,

        target_layer
          TYPE string,

        confidence
          TYPE string,

        manual_review
          TYPE abap_bool,

      END OF ty_wire_migration_step,

      tt_wire_migration_step
        TYPE STANDARD TABLE OF ty_wire_migration_step
        WITH EMPTY KEY.


    TYPES:
      BEGIN OF ty_wire_architecture,

        legacy_component
          TYPE string,

        target_component
          TYPE string,

        rationale
          TYPE string,

        confidence
          TYPE string,

      END OF ty_wire_architecture,

      tt_wire_architecture
        TYPE STANDARD TABLE OF ty_wire_architecture
        WITH EMPTY KEY.


    TYPES:
      BEGIN OF ty_wire_code_suggestion,

        title
          TYPE string,

        target_object
          TYPE string,

        suggestion
          TYPE string,

        code
          TYPE string,

        language
          TYPE string,

        confidence
          TYPE string,

        manual_review
          TYPE abap_bool,

      END OF ty_wire_code_suggestion,

      tt_wire_code_suggestion
        TYPE STANDARD TABLE OF ty_wire_code_suggestion
        WITH EMPTY KEY.


    TYPES:
      BEGIN OF ty_wire_response,

        application_summary
          TYPE string,

        business_purpose_inference
          TYPE ty_wire_business_purpose,

        legacy_flow_explanation
          TYPE string,

        risks
          TYPE tt_wire_finding,

        modernization_plan
          TYPE tt_wire_migration_step,

        target_architecture
          TYPE tt_wire_architecture,

        code_suggestions
          TYPE tt_wire_code_suggestion,

        manual_review
          TYPE tt_wire_finding,

      END OF ty_wire_response.


    METHODS normalize_confidence
      IMPORTING
        iv_confidence TYPE string
      RETURNING
        VALUE(rv_confidence)
          TYPE zif_mig_ai_types=>ty_confidence.


    METHODS normalize_severity
      IMPORTING
        iv_severity TYPE string
      RETURNING
        VALUE(rv_severity)
          TYPE zif_mig_types=>ty_severity.


    METHODS normalize_json
      IMPORTING
        iv_response TYPE string
      RETURNING
        VALUE(rv_json) TYPE string.

ENDCLASS.



CLASS zcl_mig_ai_response_parser IMPLEMENTATION.


  METHOD zif_mig_ai_response_parser~parse.

    CLEAR rs_assessment.


    "==========================================================
    " 1. Validate response
    "==========================================================
    IF iv_response IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            iv_program_name.

    ENDIF.


    "==========================================================
    " 2. Normalize provider output
    "
    " Even though prompt requires JSON only, defensive cleanup
    " protects us from ```json ... ``` responses.
    "==========================================================
    DATA(lv_json) =
      normalize_json(
        iv_response =
          iv_response
      ).


    IF lv_json IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            iv_program_name.

    ENDIF.


    "==========================================================
    " 3. Deserialize JSON
    "==========================================================
    DATA ls_wire
      TYPE ty_wire_response.


    TRY.

        /ui2/cl_json=>deserialize(
          EXPORTING
            json =
              lv_json

            pretty_name =
              /ui2/cl_json=>pretty_mode-camel_case

          CHANGING
            data =
              ls_wire
        ).


      CATCH cx_root INTO DATA(lx_json).

        RAISE EXCEPTION TYPE zcx_mig_analysis
          EXPORTING
            textid =
              zcx_mig_analysis=>analysis_failed

            previous =
              lx_json

            program_name =
              iv_program_name.

    ENDTRY.


    "==========================================================
    " 4. Minimum response contract
    "==========================================================
    IF ls_wire-application_summary IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            iv_program_name.

    ENDIF.


    IF ls_wire-business_purpose_inference-text IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            iv_program_name.

    ENDIF.


    "==========================================================
    " 5. Assessment identity
    "==========================================================
    rs_assessment-analysis_id =
      iv_analysis_id.


    rs_assessment-program_name =
      iv_program_name.


    rs_assessment-raw_response =
      iv_response.


    "==========================================================
    " 6. Main explanation
    "==========================================================
    rs_assessment-application_summary =
      ls_wire-application_summary.


    rs_assessment-legacy_flow_explanation =
      ls_wire-legacy_flow_explanation.


    rs_assessment-business_purpose-text =
      ls_wire-business_purpose_inference-text.


    rs_assessment-business_purpose-confidence =
      normalize_confidence(
        iv_confidence =
          ls_wire-business_purpose_inference-confidence
      ).


    rs_assessment-business_purpose-reasoning =
      ls_wire-business_purpose_inference-reasoning.


    "==========================================================
    " 7. Risks
    "==========================================================
    LOOP AT ls_wire-risks
      INTO DATA(ls_wire_risk).


      APPEND VALUE #(

        title =
          ls_wire_risk-title

        description =
          ls_wire_risk-description

        severity =
          normalize_severity(
            iv_severity =
              ls_wire_risk-severity
          )

        confidence =
          normalize_confidence(
            iv_confidence =
              ls_wire_risk-confidence
          )

        evidence =
          ls_wire_risk-evidence

        manual_review =
          ls_wire_risk-manual_review

      ) TO rs_assessment-risks.


    ENDLOOP.


    "==========================================================
    " 8. Modernization plan
    "==========================================================
    LOOP AT ls_wire-modernization_plan
      INTO DATA(ls_wire_step).


      APPEND VALUE #(

        sequence =
          ls_wire_step-sequence

        title =
          ls_wire_step-title

        description =
          ls_wire_step-description

        target_layer =
          ls_wire_step-target_layer

        confidence =
          normalize_confidence(
            iv_confidence =
              ls_wire_step-confidence
          )

        manual_review =
          ls_wire_step-manual_review

      ) TO rs_assessment-modernization_plan.


    ENDLOOP.


    SORT rs_assessment-modernization_plan
      BY sequence.


    "==========================================================
    " 9. Target architecture
    "==========================================================
    LOOP AT ls_wire-target_architecture
      INTO DATA(ls_wire_architecture).


      APPEND VALUE #(

        legacy_component =
          ls_wire_architecture-legacy_component

        target_component =
          ls_wire_architecture-target_component

        rationale =
          ls_wire_architecture-rationale

        confidence =
          normalize_confidence(
            iv_confidence =
              ls_wire_architecture-confidence
          )

      ) TO rs_assessment-target_architecture.


    ENDLOOP.


    "==========================================================
    " 10. Code suggestions
    "==========================================================
    LOOP AT ls_wire-code_suggestions
      INTO DATA(ls_wire_code).


      APPEND VALUE #(

        title =
          ls_wire_code-title

        target_object =
          ls_wire_code-target_object

        suggestion =
          ls_wire_code-suggestion

        code =
          ls_wire_code-code

        language =
          ls_wire_code-language

        confidence =
          normalize_confidence(
            iv_confidence =
              ls_wire_code-confidence
          )

        manual_review =
          ls_wire_code-manual_review

      ) TO rs_assessment-code_suggestions.


    ENDLOOP.


    "==========================================================
    " 11. Manual review
    "==========================================================
    LOOP AT ls_wire-manual_review
      INTO DATA(ls_wire_review).


      APPEND VALUE #(

        title =
          ls_wire_review-title

        description =
          ls_wire_review-description

        severity =
          normalize_severity(
            iv_severity =
              ls_wire_review-severity
          )

        confidence =
          normalize_confidence(
            iv_confidence =
              ls_wire_review-confidence
          )

        evidence =
          ls_wire_review-evidence

        manual_review =
          abap_true

      ) TO rs_assessment-manual_review.


    ENDLOOP.


  ENDMETHOD.



  METHOD normalize_confidence.

    DATA(lv_confidence) =
      to_upper(
        condense(
          iv_confidence
        )
      ).


    CASE lv_confidence.

      WHEN 'HIGH'.

        rv_confidence =
          zif_mig_ai_types=>gc_conf_high.


      WHEN 'MEDIUM'.

        rv_confidence =
          zif_mig_ai_types=>gc_conf_medium.


      WHEN 'LOW'.

        rv_confidence =
          zif_mig_ai_types=>gc_conf_low.


      WHEN OTHERS.

        "Unknown AI confidence must never become HIGH.
        rv_confidence =
          zif_mig_ai_types=>gc_conf_low.

    ENDCASE.

  ENDMETHOD.



  METHOD normalize_severity.

      DATA(lv_severity) =
        to_upper(
          condense(
            iv_severity
          )
        ).

      CASE lv_severity.

        WHEN 'INFO'
          OR 'LOW'
          OR 'MEDIUM'
          OR 'HIGH'
          OR 'CRITICAL'.

          rv_severity =
            lv_severity.

        WHEN OTHERS.

          rv_severity =
            zif_mig_types=>gc_sev_medium.

      ENDCASE.

    ENDMETHOD.



  METHOD normalize_json.

    rv_json =
      iv_response.


    SHIFT rv_json
      LEFT DELETING LEADING space.


    SHIFT rv_json
      RIGHT DELETING TRAILING space.


    "==========================================================
    " Defensive support:
    "
    " ```json
    " { ... }
    " ```
    "==========================================================
    IF rv_json CP '```json*'.

      REPLACE FIRST OCCURRENCE OF
        '```json'
        IN rv_json
        WITH ''.

    ELSEIF rv_json CP '```*'.

      REPLACE FIRST OCCURRENCE OF
        '```'
        IN rv_json
        WITH ''.

    ENDIF.


    SHIFT rv_json
      LEFT DELETING LEADING space.


    SHIFT rv_json
      RIGHT DELETING TRAILING space.


    IF strlen( rv_json ) >= 3.

      DATA(lv_length) =
        strlen( rv_json ).

      DATA(lv_offset) =
        lv_length - 3.


      IF rv_json+lv_offset(3) = '```'.

        rv_json =
          rv_json(lv_offset).

      ENDIF.

    ENDIF.


    SHIFT rv_json
      LEFT DELETING LEADING space.


    SHIFT rv_json
      RIGHT DELETING TRAILING space.

  ENDMETHOD.


ENDCLASS.
