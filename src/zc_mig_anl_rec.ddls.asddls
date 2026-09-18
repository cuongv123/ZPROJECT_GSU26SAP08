@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Recommendations'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_REC
  as projection on ZI_MIG_ANL_REC
{
  key AnalysisId,
  key RecommendationId,

      SourceItemId,
      EvidenceId,

      RuleId,
      RuleVersion,
      TargetLayer,

      Title,
      DisplayText,
      Explanation,

      Severity,
      Confidence,
      ReviewStatus,
      ManualReview,

      _Annotations :
        redirected to composition child ZC_MIG_ANL_ANN,

      _Analysis :
        redirected to parent ZC_MIG_ANALYSIS
}
