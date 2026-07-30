@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis'
@Metadata.allowExtensions: true

define root view entity ZC_MIG_ANALYSIS
  provider contract transactional_query
  as projection on ZI_MIG_ANALYSIS
{
  key AnalysisId,

      ProgramName,
      ProgramDescription,
      Status,

      TotalSourceObjects,
      TotalUiFilters,
      TotalDatabaseObjects,
      TotalBusinessLogic,
      TotalAlvOutputs,
      TotalAlvColumns,
      TotalRecommendations,

      ComplexityScore,
      ReadinessScore,

      ParserVersion,
      RuleVersion,
      SourceHash,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _UiFilters :
        redirected to composition child ZC_MIG_ANL_UI,

      _DatabaseObjects :
        redirected to composition child ZC_MIG_ANL_DB,

      _BusinessLogic :
        redirected to composition child ZC_MIG_ANL_LOGIC,

      _AlvOutputs :
        redirected to composition child ZC_MIG_ANL_ALV,

      _Evidences :
        redirected to composition child ZC_MIG_ANL_EVD,

      _Recommendations :
        redirected to composition child ZC_MIG_ANL_REC,

      _Messages :
        redirected to composition child ZC_MIG_ANL_MSG
}
