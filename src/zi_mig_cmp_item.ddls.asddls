@EndUserText.label: 'Migration Comparison Item'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZI_MIG_CMP_ITEM
  as select from zmig_cmp_item
  association to parent ZI_MIG_CMP_RUN as _Run
    on $projection.CmpRunId = _Run.CmpRunId
{
  key cmp_run_id      as CmpRunId,
  key item_id         as ItemId,

      item_no         as ItemNo,
      category        as Category,

      source_element  as SourceElement,
      source_type     as SourceType,
      source_value    as SourceValue,

      target_element  as TargetElement,
      target_type     as TargetType,
      target_value    as TargetValue,

      mapping_rule    as MappingRule,
      status          as Status,
      severity        as Severity,

      message         as Message,
      recommendation  as Recommendation,

      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,

      _Run
}
