@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Events'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_EVT
  as select from zmig_anl_evt

  association to parent ZI_MIG_ANL_ALV as _AlvOutput
    on  $projection.AnalysisId = _AlvOutput.AnalysisId
    and $projection.OutputId   = _AlvOutput.OutputId

  association to ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id      as AnalysisId,
  key output_id        as OutputId,
  key item_id          as ItemId,

      evidence_id      as EvidenceId,

      event_name       as EventName,
      handler_name     as HandlerName,
      handler_kind     as HandlerKind,
      control_object   as ControlObject,
      gui_dependency   as GuiDependency,

      confidence       as Confidence,

      _AlvOutput,
      _Analysis
}
