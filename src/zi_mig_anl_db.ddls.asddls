@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Database Objects'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_DB
  as select from zmig_anl_db

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id          as AnalysisId,
  key item_id              as ItemId,

      evidence_id          as EvidenceId,

      object_name          as ObjectName,
      object_type          as ObjectType,
      operation            as Operation,

      selected_fields      as SelectedFields,
      where_fields         as WhereFields,
      joined_objects       as JoinedObjects,
      join_condition       as JoinCondition,
      aggregation          as Aggregation,

      containing_routine   as ContainingRoutine,
      dynamic_access       as DynamicAccess,
      read_only            as ReadOnly,
      paging_capability    as PagingCapability,
      description          as Description,
      confidence           as Confidence,

      _Analysis
}
