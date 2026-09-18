@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Messages'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_MSG
  as projection on ZI_MIG_ANL_MSG
{
  key AnalysisId,
  key MessageNo,

      MessageType,
      MessageCode,
      SourceObject,
      SourceLine,
      MessageText,

      _Analysis : redirected to parent ZC_MIG_ANALYSIS
}
