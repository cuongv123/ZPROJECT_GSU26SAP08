@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Source Code Lines'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_CODE
  as projection on ZI_MIG_ANL_CODE
{
  key AnalysisId,
  key SourceItemId,
  key LineNumber,

      SourceText,

      _SourceObject : redirected to parent ZC_MIG_ANL_SRC,
      _Analysis     : redirected to ZC_MIG_ANALYSIS
}
