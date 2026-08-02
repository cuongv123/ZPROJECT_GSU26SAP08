@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Source Objects'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_SRC
  as projection on ZI_MIG_ANL_SRC
{
  key AnalysisId,
  key ItemId,

      ObjectName,
      ObjectType,
      ParentObject,
      IncludeDepth,
      LineCount,
      SourceHash,

      _Analysis : redirected to parent ZC_MIG_ANALYSIS
}
