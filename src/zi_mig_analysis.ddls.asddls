@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis'
@Metadata.allowExtensions: true

define root view entity ZI_MIG_ANALYSIS
  as select from zmig_anl_h

  composition [0..*] of ZI_MIG_ANL_UI
    as _UiFilters

  composition [0..*] of ZI_MIG_ANL_DB
    as _DatabaseObjects

  composition [0..*] of ZI_MIG_ANL_LOGIC
    as _BusinessLogic

  composition [0..*] of ZI_MIG_ANL_ALV
    as _AlvOutputs

  composition [0..*] of ZI_MIG_ANL_EVD
    as _Evidences

  composition [0..*] of ZI_MIG_ANL_REC
    as _Recommendations

  composition [0..*] of ZI_MIG_ANL_MSG
    as _Messages
{
  key analysis_id                as AnalysisId,

      program_name               as ProgramName,
      program_description        as ProgramDescription,
      status                     as Status,

      total_source_objects       as TotalSourceObjects,
      total_ui_filters           as TotalUiFilters,
      total_database_objects     as TotalDatabaseObjects,
      total_business_logic       as TotalBusinessLogic,
      total_alv_outputs          as TotalAlvOutputs,
      total_alv_columns          as TotalAlvColumns,
      total_recommendations      as TotalRecommendations,

        
      complexity_score           as ComplexityScore,
      readiness_score            as ReadinessScore,

      parser_version             as ParserVersion,
      rule_version               as RuleVersion,
      source_hash                as SourceHash,

      @Semantics.user.createdBy: true
      created_by                 as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                 as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by            as LastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at            as LocalLastChangedAt,

      _UiFilters,
      _DatabaseObjects,
      _BusinessLogic,
      _AlvOutputs,
      _Evidences,
      _Recommendations,
      _Messages
}
