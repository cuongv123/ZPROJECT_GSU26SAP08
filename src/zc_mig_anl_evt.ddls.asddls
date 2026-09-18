@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Events'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_EVT
  as projection on ZI_MIG_ANL_EVT
{
  key AnalysisId,
  key OutputId,
  key ItemId,

      EvidenceId,

      EventName,
      HandlerName,
      HandlerKind,
      ControlObject,
      GuiDependency,

      Confidence,

      _AlvOutput : redirected to parent ZC_MIG_ANL_ALV,
      _Analysis  : redirected to ZC_MIG_ANALYSIS
}
