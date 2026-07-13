@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Saved Migration Report Logic'
define view entity ZI_MIG_REPORT_LOGIC
  as select from ztmig_logic
  association to parent ZI_MIG_REPORT_HD as _ReportHeader on $projection.ReportID = _ReportHeader.ReportID
{
  key report_id        as ReportID,
  key object_name      as ObjectName,
      object_type      as ObjectType,
      description      as Description,
      migration_target as MigrationTarget,
      severity         as Severity,
      recommendation   as Recommendation,
      complexity       as RemediationComplexity,
      targetstructure  as  TargetStructure,
      
      _ReportHeader
}
