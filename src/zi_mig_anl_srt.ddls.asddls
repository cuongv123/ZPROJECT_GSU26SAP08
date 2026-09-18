@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Sorts'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_SRT
  as select from zmig_anl_srt

  association to parent ZI_MIG_ANL_ALV as _AlvOutput
    on  $projection.AnalysisId = _AlvOutput.AnalysisId
    and $projection.OutputId   = _AlvOutput.OutputId

  association to ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id    as AnalysisId,
  key output_id      as OutputId,
  key item_id        as ItemId,

      evidence_id    as EvidenceId,

      field_name     as FieldName,
      sort_position  as SortPosition,
      ascending      as Ascending,
      descending     as Descending,
      subtotal       as Subtotal,

      confidence     as Confidence,

      _AlvOutput,
      _Analysis
}
