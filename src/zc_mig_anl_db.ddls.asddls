@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Database Objects'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_DB
  as projection on ZI_MIG_ANL_DB
{
  key AnalysisId,
  key ItemId,

      EvidenceId,

      ObjectName,
      ObjectType,
      Operation,

      SelectedFields,
      WhereFields,
      JoinedObjects,
      JoinCondition,
      Aggregation,

      ContainingRoutine,
      DynamicAccess,
      ReadOnly,
      PagingCapability,
      Description,
      Confidence,

      _Analysis : redirected to parent ZC_MIG_ANALYSIS
}
