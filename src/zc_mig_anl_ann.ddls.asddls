@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Annotation Proposals'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_ANN
  as projection on ZI_MIG_ANL_ANN
{
  key AnalysisId,
  key RecommendationId,
  key ItemId,

      TargetEntity,
      TargetElement,
      AnnotationName,
      AnnotationValue,
      AnnotationSequence,

      _Recommendation :
        redirected to parent ZC_MIG_ANL_REC,

      _Analysis :
        redirected to ZC_MIG_ANALYSIS
}
