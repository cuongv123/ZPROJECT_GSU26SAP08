CLASS zcl_mig_comparator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS execute
      IMPORTING
        iv_analysis_id TYPE sysuuid_x16
      RETURNING
        VALUE(rs_summary)
          TYPE zif_mig_cmp_types=>ty_run_summary
      RAISING
        zcx_mig_comparison.

  PRIVATE SECTION.

    METHODS read_saved_summary
      IMPORTING
        iv_cmp_run_id TYPE sysuuid_x16
      RETURNING
        VALUE(rs_summary)
          TYPE zif_mig_cmp_types=>ty_run_summary
      RAISING
        zcx_mig_comparison.

ENDCLASS.


CLASS zcl_mig_comparator IMPLEMENTATION.

  METHOD execute.

    IF iv_analysis_id IS INITIAL.

      RAISE EXCEPTION TYPE zcx_mig_comparison
        EXPORTING
          iv_message = 'Analysis ID must not be initial'.

    ENDIF.

    TRY.

        "======================================================
        " 1. Read persisted analysis metadata
        "======================================================
        DATA lo_reader
          TYPE REF TO zif_mig_analysis_reader.

        lo_reader =
          NEW zcl_mig_analysis_reader( ).

        DATA(ls_analysis) =
          lo_reader->read(
            iv_analysis_id = iv_analysis_id
          ).


        "======================================================
        " 2. Build proposed RAP/OData target blueprint
        "======================================================
        DATA lo_blueprint_builder
          TYPE REF TO zif_mig_service_blueprint.

        lo_blueprint_builder =
          NEW zcl_mig_service_blueprint( ).

        DATA(ls_target) =
          lo_blueprint_builder->build(
            is_analysis = ls_analysis
          ).


        "======================================================
        " 3. Compare legacy metadata with target blueprint
        "======================================================
        DATA(lo_rule_engine) =
          NEW zcl_mig_cmp_rule_engine( ).

        DATA(lt_items) =
          lo_rule_engine->evaluate(
            is_analysis = ls_analysis
            is_target   = ls_target
          ).


        "======================================================
        " 4. Persist comparison run and result items
        "======================================================
        DATA(lo_store) =
          NEW zcl_mig_cmp_store( ).

        DATA(lv_cmp_run_id) =
          lo_store->save(
            iv_analysis_id     = iv_analysis_id
            iv_program_name    =
              ls_analysis-overview-program_name
            iv_target_strategy =
              ls_target-blueprint-strategy
            it_items           = lt_items
          ).


        "======================================================
        " 5. Return persisted summary
        "======================================================
        rs_summary =
          read_saved_summary(
            iv_cmp_run_id = lv_cmp_run_id
          ).

      CATCH zcx_mig_analysis INTO DATA(lx_analysis).

        RAISE EXCEPTION TYPE zcx_mig_comparison
          EXPORTING
            iv_message =
              |Migration comparison failed: { lx_analysis->get_text( ) }|
            previous = lx_analysis.

    ENDTRY.

  ENDMETHOD.


  METHOD read_saved_summary.

    SELECT SINGLE
           cmp_run_id,
           analysis_id,
           program_name,
           target_strategy,
           total_items,
           mapped_count,
           refactor_count,
           manual_count,
           unsupported_count,
           compatibility_rate,
           overall_status,
           run_status,
           error_message
      FROM zmig_cmp_run
      WHERE cmp_run_id = @iv_cmp_run_id
      INTO CORRESPONDING FIELDS OF @rs_summary.

    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE zcx_mig_comparison
        EXPORTING
          iv_message =
            |Comparison run { iv_cmp_run_id } could not be read|.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
