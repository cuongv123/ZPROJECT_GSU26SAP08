@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Recommendations'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_REC
  as select from zmig_anl_rec

  composition [0..*] of ZI_MIG_ANL_ANN as _Annotations

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id        as AnalysisId,
  key recommendation_id  as RecommendationId,

      source_item_id      as SourceItemId,
      evidence_id         as EvidenceId,

      rule_id             as RuleId,
      rule_version        as RuleVersion,
      target_layer        as TargetLayer,

      title               as Title,
      display_text        as DisplayText,
      explanation         as Explanation,

      severity            as Severity,
      confidence          as Confidence,
      review_status       as ReviewStatus,
      manual_review       as ManualReview,

      _Annotations,
      _Analysis
}
