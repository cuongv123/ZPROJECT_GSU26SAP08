@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Saved Migration Object Map'
define view entity ZI_MIG_REPORT_MAP
  as select from ztmig_obj_map
  association to parent ZI_MIG_REPORT_HD as _ReportHeader on $projection.ReportID = _ReportHeader.ReportID
{
  key report_id     as ReportID,
  key source_obj    as SourceObj,
  key source_type   as SourceType,
  key target_obj    as TargetObj,
  key target_type   as TargetType,
      relation_type as RelationType,
      criticality   as Criticality,
      description   as Description,
      
      _ReportHeader
}
