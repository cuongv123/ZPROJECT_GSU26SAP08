@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Saved Migration Report Header'
define root view entity ZI_MIG_REPORT_HD
  as select from ztmig_overview
  composition [0..*] of ZI_MIG_REPORT_FILTER as _UiFilter
  composition [0..*] of ZI_MIG_REPORT_DB     as _DbTable
  composition [0..*] of ZI_MIG_REPORT_LOGIC  as _BusinessLogic

{
  key report_id        as ReportID,
      program_name     as ProgramName,
      description      as ProgramDescription,
      analyzed_by      as AnalyzedBy,
      analyzed_at      as AnalyzedAt,
      total_tables     as TotalTables,
      total_filters    as TotalFilters,
      total_objects    as TotalBusinessObjects,
      migration_score  as MigrationScore,
      complexity_score as ComplexityScore,
      cloud_readiness  as CloudReadinessScore,
      status           as AnalysisStatus,
      
      // Công khai (Expose) các thành phần liên kết cấu trúc
      _UiFilter,
      _DbTable,
      _BusinessLogic
}
