@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Sorts'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_SRT
  as projection on ZI_MIG_ANL_SRT
{
  key AnalysisId,
  key OutputId,
  key ItemId,

      EvidenceId,

      FieldName,
      SortPosition,
      Ascending  as IsAscending,
      Descending as IsDescending,
      Subtotal,

      Confidence,

      _AlvOutput : redirected to parent ZC_MIG_ANL_ALV,
      _Analysis  : redirected to ZC_MIG_ANALYSIS
}
