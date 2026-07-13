CLASS lhc_ReportHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ReportHeader RESULT result.

    METHODS analyzeAndSave FOR MODIFY
      IMPORTING keys FOR ACTION ReportHeader~analyzeAndSave RESULT result.

    METHODS exportToExcel FOR MODIFY
      IMPORTING keys FOR ACTION ReportHeader~exportToExcel RESULT result.

ENDCLASS.

CLASS lhc_ReportHeader IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  " XỬ LÝ CHO INSTANCE ACTION (CHẠY ỔN ĐỊNH 100%)
  " BẢN CHUẨN ĐÃ SỬA: Khớp 100% với định nghĩa Instance Action
  METHOD exportToExcel.
    DATA: lv_program_name TYPE program.

    " 1. ĐỌC TRỰC TIẾP TỪ DATABASE BẰNG KHÓA CHÍNH REPORTID
    READ TABLE keys INTO DATA(ls_key) INDEX 1.
    IF sy-subrc = 0.
      SELECT SINGLE program_name
        FROM ztmig_overview
        WHERE report_id = @ls_key-ReportID
        INTO @lv_program_name.
    ENDIF.

    " 2. TRẢ KẾT QUẢ VỀ CHO KHUNG FRAMEWORK ĐỂ ĐÓNG LUỒNG ACTION MƯỢT MÀ
    LOOP AT keys INTO DATA(ls_key_res).
      APPEND VALUE #( ReportID = ls_key_res-ReportID
                      %param   = CORRESPONDING #( ls_key_res ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD analyzeAndSave.
    DATA: lt_source_code TYPE zcl_parser_types=>tt_source_code,
          lt_raw_logic   TYPE zcl_parser_types=>tt_raw_logic,
          lt_raw_filter  TYPE zcl_parser_types=>tt_raw_ui_filter,
          lt_raw_table   TYPE zcl_parser_types=>tt_raw_db_table,
          lt_logic       TYPE zcl_parser_types=>tt_business_logic,
          lt_filter      TYPE zcl_parser_types=>tt_ui_filter,
          lt_table       TYPE zcl_parser_types=>tt_db_table,
          ls_agg         TYPE zcl_parser_types=>ty_overview,
          lv_timestamp   TYPE timestampl.

    DATA: ls_mapped     TYPE RESPONSE FOR MAPPED zi_mig_report_hd,
          ls_failed     TYPE RESPONSE FOR FAILED zi_mig_report_hd,
          ls_reported   TYPE RESPONSE FOR REPORTED zi_mig_report_hd,
          lt_new_header TYPE TABLE FOR READ RESULT zi_mig_report_hd.

    GET TIME STAMP FIELD lv_timestamp.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: ls_mapped, ls_failed, ls_reported, lt_new_header.
      DATA(lv_program) = ls_key-%param-iv_program_name.

      " 1. GỌI PARSER VÀ ENGINE
      DATA(lo_repo) = NEW zcl_source_repository( ).
      lo_repo->get_program_source( EXPORTING iv_program_name = lv_program IMPORTING et_source_code = lt_source_code ).

      DATA(lo_parser) = NEW zcl_abap_source_parser( ).
      lo_parser->zif_code_parser~analyze_program(
        EXPORTING iv_program_name = lv_program it_source_code = lt_source_code
        IMPORTING et_logic = lt_raw_logic et_ui_filter = lt_raw_filter et_db_table = lt_raw_table ).

      DATA(lo_engine) = NEW zcl_recommendation_engine( ).
      lo_engine->zif_recommendation_engine~enrich_business_logic( EXPORTING iv_program_name = lv_program it_raw_logic = lt_raw_logic IMPORTING et_business_logic = lt_logic ).
      lo_engine->zif_recommendation_engine~enrich_ui_filter( EXPORTING iv_program_name = lv_program it_raw_ui_filter = lt_raw_filter IMPORTING et_ui_filter = lt_filter ).
      lo_engine->zif_recommendation_engine~enrich_db_table( EXPORTING iv_program_name = lv_program it_raw_db_table = lt_raw_table IMPORTING et_db_table = lt_table ).

      DATA(lo_aggregator) = NEW zcl_analysis_aggregator( ).
      lo_aggregator->zif_analysis_aggregator~build_overview( EXPORTING iv_program_name = lv_program it_business_logic = lt_logic it_ui_filter = lt_filter it_db_table = lt_table IMPORTING es_overview = ls_agg ).

      DATA(lv_prog_name_conv) = CONV programm( ls_agg-program_name ).

      " 2. LƯU BẰNG EML ĐỒNG THỜI 1 HEADER + 3 CHILD TABLES
      MODIFY ENTITIES OF zi_mig_report_hd IN LOCAL MODE
        ENTITY ReportHeader
          CREATE FIELDS ( ProgramName ProgramDescription TotalBusinessObjects TotalTables TotalFilters ComplexityScore MigrationScore CloudReadinessScore AnalysisStatus AnalyzedBy AnalyzedAt )
          WITH VALUE #( (
            %cid = ls_key-%cid
            ProgramName = ls_agg-program_name
            ProgramDescription = lo_repo->get_program_description( lv_prog_name_conv )
            TotalBusinessObjects = ls_agg-total_business_objects
            TotalTables = ls_agg-total_tables
            TotalFilters = ls_agg-total_filters
            ComplexityScore = ls_agg-complexity_score
            MigrationScore = ls_agg-migration_score
            CloudReadinessScore = ls_agg-cloud_readiness_score
            AnalysisStatus = 'COMPLETED' AnalyzedBy = sy-uname AnalyzedAt = lv_timestamp
          ) )

          CREATE BY \_UiFilter
          FIELDS ( FieldName Description FilterType Recommendation MigrationTarget DataElement MandatoryFlag MultiValueFlag Severity FioriAdaptation )
          WITH VALUE #( (
            %cid_ref = ls_key-%cid
            %target = VALUE #( FOR ls_fil IN lt_filter INDEX INTO j (
                        %cid = ls_key-%cid && '_F_' && j
                        FieldName = ls_fil-field_name Description = ls_fil-description FilterType = ls_fil-filter_type
                        Recommendation = ls_fil-recommendation MigrationTarget = ls_fil-migration_target DataElement = ls_fil-data_element
                        MandatoryFlag = ls_fil-mandatory_flag MultiValueFlag = ls_fil-multi_value_flag Severity = ls_fil-severity FioriAdaptation = ls_fil-fiori_adaptation ) )
          ) )

          CREATE BY \_DbTable
          FIELDS ( TableName Description Operations Fields Recommendation CdsCandidate Priority MigrationApproach )
          WITH VALUE #( (
            %cid_ref = ls_key-%cid
            %target = VALUE #( FOR ls_db IN lt_table INDEX INTO k (
                        %cid = ls_key-%cid && '_D_' && k
                        TableName = ls_db-table_name Description = ls_db-table_description Operations = ls_db-operations Fields = ls_db-fields
                        Recommendation = ls_db-recommendation CdsCandidate = ls_db-cds_candidate Priority = ls_db-priority MigrationApproach = ls_db-migration_approach ) )
          ) )

          CREATE BY \_BusinessLogic
          FIELDS ( ObjectName ObjectType Description MigrationTarget Severity Recommendation RemediationComplexity TargetStructure )
          WITH VALUE #( (
            %cid_ref = ls_key-%cid
            %target  = VALUE #( FOR ls_log IN lt_logic INDEX INTO i (
                         %cid = ls_key-%cid && '_' && i
                         ObjectName = ls_log-object_name ObjectType = ls_log-object_type Description = ls_log-description TargetStructure = ls_log-target_structure
                         MigrationTarget = ls_log-migration_target Severity = ls_log-severity Recommendation = ls_log-recommendation RemediationComplexity = ls_log-remediation_complexity ) )
          ) )
        MAPPED ls_mapped
        FAILED ls_failed
        REPORTED ls_reported.

      IF ls_failed IS NOT INITIAL.
        failed = CORRESPONDING #( BASE ( failed ) ls_failed ).
        reported = CORRESPONDING #( BASE ( reported ) ls_reported ).
        CONTINUE.
      ENDIF.

      " 3. TRẢ VỀ CHO FIORI ĐỂ REDIRECT
      READ ENTITIES OF zi_mig_report_hd IN LOCAL MODE
        ENTITY ReportHeader
          ALL FIELDS WITH CORRESPONDING #( ls_mapped-reportheader )
        RESULT lt_new_header.

      LOOP AT lt_new_header INTO DATA(ls_new_header).
        INSERT VALUE #( %cid = ls_key-%cid %param = ls_new_header ) INTO TABLE result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
