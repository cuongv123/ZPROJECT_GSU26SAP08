@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Source Code Lines'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_CODE
  as select from zmig_anl_code

  association to parent ZI_MIG_ANL_SRC as _SourceObject
    on  $projection.AnalysisId   = _SourceObject.AnalysisId
    and $projection.SourceItemId = _SourceObject.ItemId

  association to ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id    as AnalysisId,
  key source_item_id as SourceItemId,
  key line_number    as LineNumber,

      source_text    as SourceText,

      _SourceObject,
      _Analysis
}
