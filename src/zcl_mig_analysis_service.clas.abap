CLASS zcl_mig_analysis_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_analysis_service.

ENDCLASS.


CLASS zcl_mig_analysis_service IMPLEMENTATION.

  METHOD zif_mig_analysis_service~analyze.

    DATA:
      lt_source_code TYPE zcl_parser_types=>tt_source_code,
      lt_raw_logic   TYPE zcl_parser_types=>tt_raw_logic,
      lt_raw_filter  TYPE zcl_parser_types=>tt_raw_ui_filter,
      lt_raw_table   TYPE zcl_parser_types=>tt_raw_db_table.

    IF iv_program IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          iv_error_text = 'Program name is required'.
    ENDIF.

    DATA(lo_repository) = NEW zcl_source_repository( ).

    lo_repository->get_program_source(
      EXPORTING
        iv_program_name = iv_program
      IMPORTING
        et_source_code  = lt_source_code
    ).

    IF lt_source_code IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_analysis
        EXPORTING
          iv_program_name = iv_program
          iv_error_text   =
            |No active source was found for program { iv_program }|.
    ENDIF.

    DATA(lo_parser) = NEW zcl_abap_source_parser( ).

    lo_parser->zif_code_parser~analyze_program(
      EXPORTING
        iv_program_name = iv_program
        it_source_code  = lt_source_code
      IMPORTING
        et_logic        = lt_raw_logic
        et_ui_filter    = lt_raw_filter
        et_db_table     = lt_raw_table
    ).

    DATA(lo_recommendation) =
      NEW zcl_recommendation_engine( ).

    lo_recommendation->zif_recommendation_engine~enrich_business_logic(
      EXPORTING
        iv_program_name = iv_program
        it_raw_logic    = lt_raw_logic
      IMPORTING
        et_business_logic = rs_result-business_logic
    ).

    lo_recommendation->zif_recommendation_engine~enrich_ui_filter(
      EXPORTING
        iv_program_name = iv_program
        it_raw_ui_filter = lt_raw_filter
      IMPORTING
        et_ui_filter = rs_result-ui_filters
    ).

    lo_recommendation->zif_recommendation_engine~enrich_db_table(
      EXPORTING
        iv_program_name = iv_program
        it_raw_db_table = lt_raw_table
      IMPORTING
        et_db_table = rs_result-db_tables
    ).

    rs_result-object_map =
      lo_recommendation->zif_recommendation_engine~build_object_mapping(
        it_ui_filter = rs_result-ui_filters
        it_db_table  = rs_result-db_tables
        it_logic     = rs_result-business_logic
      ).

    DATA(lo_aggregator) =
      NEW zcl_analysis_aggregator( ).

    lo_aggregator->zif_analysis_aggregator~build_overview(
      EXPORTING
        iv_program_name   = iv_program
        it_business_logic = rs_result-business_logic
        it_ui_filter      = rs_result-ui_filters
        it_db_table       = rs_result-db_tables
      IMPORTING
        es_overview       = rs_result-overview
    ).

    rs_result-overview-description =
      lo_repository->get_program_description( iv_program ).

  ENDMETHOD.

ENDCLASS.
