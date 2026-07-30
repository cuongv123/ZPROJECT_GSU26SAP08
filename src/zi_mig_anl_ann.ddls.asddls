@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Annotation Proposals'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_ANN
  as select from zmig_anl_ann

  association to parent ZI_MIG_ANL_REC as _Recommendation
    on  $projection.AnalysisId       = _Recommendation.AnalysisId
    and $projection.RecommendationId = _Recommendation.RecommendationId

  association to ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id        as AnalysisId,
  key recommendation_id  as RecommendationId,
  key item_id             as ItemId,

      target_entity       as TargetEntity,
      target_element      as TargetElement,
      annotation_name     as AnnotationName,
      annotation_value    as AnnotationValue,
      sequence            as AnnotationSequence,

      _Recommendation,
      _Analysis
}
