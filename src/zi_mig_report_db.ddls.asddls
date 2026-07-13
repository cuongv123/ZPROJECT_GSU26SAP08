@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Saved Migration DB Table'
define view entity ZI_MIG_REPORT_DB
  as select from ztmig_dbtable
  association to parent ZI_MIG_REPORT_HD as _ReportHeader on $projection.ReportID = _ReportHeader.ReportID
{
  key report_id          as ReportID,
  key table_name         as TableName,
      description        as Description,
      operations         as Operations,
      fields     as Fields,
      recommendation     as Recommendation,
      cds_candidate      as CdsCandidate,
      priority           as Priority,
      migration_approach as MigrationApproach,
      _ReportHeader
}
