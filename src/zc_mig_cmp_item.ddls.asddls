@EndUserText.label: 'Migration Comparison Item'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_MIG_CMP_ITEM
  as projection on ZI_MIG_CMP_ITEM
{
  key CmpRunId,
  key ItemId,

      @EndUserText.label: 'Item No'
      ItemNo,

      @EndUserText.label: 'Category'
      Category,

      @EndUserText.label: 'Source Element'
      SourceElement,

      @EndUserText.label: 'Source Type'
      SourceType,

      @EndUserText.label: 'Source Value'
      SourceValue,

      @EndUserText.label: 'Target Element'
      TargetElement,

      @EndUserText.label: 'Target Type'
      TargetType,

      @EndUserText.label: 'Target Value'
      TargetValue,

      @EndUserText.label: 'Mapping Rule'
      MappingRule,

      @EndUserText.label: 'Status'
      Status,

      @EndUserText.label: 'Severity'
      Severity,

      @EndUserText.label: 'Message'
      Message,

      @EndUserText.label: 'Recommendation'
      Recommendation,

      @EndUserText.label: 'Created At'
      CreatedAt,

      _Run : redirected to parent ZC_MIG_CMP_RUN
}
