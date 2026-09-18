@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Filters'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_FLT
  as projection on ZI_MIG_ANL_FLT
{
  key AnalysisId,
  key OutputId,
  key ItemId,

      EvidenceId,

      FieldName,
      FilterSign,
      FilterOption,
      LowValue,
      HighValue,

      Confidence,

      _AlvOutput : redirected to parent ZC_MIG_ANL_ALV,
      _Analysis  : redirected to ZC_MIG_ANALYSIS
}
