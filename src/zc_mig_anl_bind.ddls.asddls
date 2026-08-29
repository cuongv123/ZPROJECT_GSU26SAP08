@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Call Binding'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_BIND
  as projection on ZI_MIG_ANL_BIND
{
  key AnalysisId,
  key ItemId,

      CallItemId,
      EvidenceId,

      ParameterName,
      Direction,
      ActualExpression,

      BindingPosition,
      Confidence,

      _BusinessLogic : redirected to parent ZC_MIG_ANL_LOGIC,
      _Analysis      : redirected to ZC_MIG_ANALYSIS
}
