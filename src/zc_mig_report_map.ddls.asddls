@EndUserText.label: 'Projection: Migration Object Map'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@UI.headerInfo: {
  typeName: 'Roadmap Mapping',
  typeNamePlural: 'Roadmap Mappings',
  title: { type: #STANDARD, value: 'SourceObj' }
}
define view entity ZC_MIG_REPORT_MAP
  as projection on ZI_MIG_REPORT_MAP
{
      @UI.hidden: true
  key ReportID,

      @UI.lineItem: [{ position: 10, label: 'Source Object' }]
  key SourceObj,

      @UI.lineItem: [{ position: 20, label: 'Source Type' }]
  key SourceType,
  
  @UI.lineItem: [{ position: 40, label: 'Target Object' }]
  key TargetObj,

      @UI.lineItem: [{ position: 50, label: 'Target Type' }]
  key TargetType,

      @UI.lineItem: [{ position: 30, label: 'Relation (Edge)' }]
      RelationType,

      

      @UI.hidden: true
      Criticality,
      
      @UI.hidden: true
      Description,

      /* Association */
      _ReportHeader : redirected to parent ZC_MIG_REPORT_HD
}
