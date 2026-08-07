@EndUserText.label: 'Migration Comparison Run'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_MIG_CMP_RUN
  provider contract transactional_query
  as projection on ZI_MIG_CMP_RUN
{
  key CmpRunId,

      @EndUserText.label: 'Analysis ID'
      AnalysisId,

      @EndUserText.label: 'Program Name'
      ProgramName,

      @EndUserText.label: 'Target Strategy'
      TargetStrategy,

      @EndUserText.label: 'Total Items'
      TotalItems,

      @EndUserText.label: 'Mapped'
      MappedCount,

      @EndUserText.label: 'Refactor Required'
      RefactorCount,

      @EndUserText.label: 'Manual Required'
      ManualCount,

      @EndUserText.label: 'Unsupported'
      UnsupportedCount,

      @EndUserText.label: 'Compatibility Rate'
      CompatibilityRate,

      @EndUserText.label: 'Overall Status'
      OverallStatus,

      @EndUserText.label: 'Run Status'
      RunStatus,

      @EndUserText.label: 'Error Message'
      ErrorMessage,

      @EndUserText.label: 'Created By'
      CreatedBy,

      @EndUserText.label: 'Created At'
      CreatedAt,

      @EndUserText.label: 'Last Changed By'
      LastChangedBy,

      @EndUserText.label: 'Last Changed At'
      LastChangedAt,

      _Items : redirected to composition child ZC_MIG_CMP_ITEM
}

