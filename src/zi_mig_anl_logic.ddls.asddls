@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Business Logic'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_LOGIC
  as select from zmig_anl_log

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id             as AnalysisId,
  key item_id                 as ItemId,

      evidence_id             as EvidenceId,

      object_name             as ObjectName,
      object_type             as ObjectType,
      container_name          as ContainerName,
      calling_routine         as CallingRoutine,
      interface_summary       as InterfaceSummary,
      description             as Description,

      side_effect             as SideEffect,
      transaction_dependency  as TransactionDependency,
      gui_dependency          as GuiDependency,
      reuse_feasibility       as ReuseFeasibility,
      confidence              as Confidence,

      _Analysis
}
