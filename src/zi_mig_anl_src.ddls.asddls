@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Source Objects'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_SRC
  as select from zmig_anl_src

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id   as AnalysisId,
  key item_id       as ItemId,

      object_name   as ObjectName,
      object_type   as ObjectType,
      parent_object as ParentObject,
      include_depth as IncludeDepth,
      line_count    as LineCount,
      source_hash   as SourceHash,

      _Analysis
}
