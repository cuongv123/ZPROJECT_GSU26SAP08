@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Saved Migration UI Filter'
define view entity ZI_MIG_REPORT_FILTER
  as select from ztmig_filter
  association to parent ZI_MIG_REPORT_HD as _ReportHeader on $projection.ReportID = _ReportHeader.ReportID
{
  key report_id        as ReportID,
  key field_name       as FieldName,
      description      as Description,
      filter_type      as FilterType,
      recommendation   as Recommendation,
      migration_target as MigrationTarget,
      data_element     as DataElement,
      mandatory_flag   as MandatoryFlag,
      multi_value_flag as MultiValueFlag,
      severity         as Severity,
      fiori_adaptation as FioriAdaptation,
      _ReportHeader
}
