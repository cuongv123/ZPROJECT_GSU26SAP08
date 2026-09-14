@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Call Binding'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_BIND
  as select from zmig_anl_bind

  association to parent ZI_MIG_ANL_LOGIC as _BusinessLogic
    on  $projection.AnalysisId = _BusinessLogic.AnalysisId
    and $projection.CallItemId = _BusinessLogic.ItemId

  association to ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId

{
  key analysis_id        as AnalysisId,
  key item_id            as ItemId,

      call_item_id       as CallItemId,
      evidence_id        as EvidenceId,

      parameter_name     as ParameterName,
      direction          as Direction,
      actual_expression  as ActualExpression,

      binding_position   as BindingPosition,
      confidence         as Confidence,

      _BusinessLogic,
      _Analysis
}
