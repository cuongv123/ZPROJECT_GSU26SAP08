@EndUserText.label: 'Migration Comparison Run'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZI_MIG_CMP_RUN
  as select from zmig_cmp_run
  composition [0..*] of ZI_MIG_CMP_ITEM as _Items
{
  key cmp_run_id         as CmpRunId,

      analysis_id        as AnalysisId,
      program_name       as ProgramName,
      target_strategy    as TargetStrategy,

      total_items        as TotalItems,
      mapped_count       as MappedCount,
      refactor_count     as RefactorCount,
      manual_count       as ManualCount,
      unsupported_count  as UnsupportedCount,

      compatibility_rate as CompatibilityRate,
      overall_status     as OverallStatus,
      run_status         as RunStatus,
      error_message      as ErrorMessage,

      @Semantics.user.createdBy: true
      created_by         as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at         as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by    as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at    as LastChangedAt,

      _Items
}
