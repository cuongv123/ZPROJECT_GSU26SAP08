@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Business Logic'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_LOGIC
  as projection on ZI_MIG_ANL_LOGIC
{
  key AnalysisId,
  key ItemId,

      EvidenceId,

      ObjectName,
      ObjectType,
      ContainerName,
      CallingRoutine,
      InterfaceSummary,
      Description,

      SideEffect,
      TransactionDependency,
      GuiDependency,
      ReuseFeasibility,
      Confidence,

      _Analysis : redirected to parent ZC_MIG_ANALYSIS
}
