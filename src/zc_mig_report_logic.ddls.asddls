@EndUserText.label: 'Projection: Migration Report Logic'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@UI.headerInfo: {
  typeName: 'Business Logic',
  typeNamePlural: 'Business Logic Items',
  title: { type: #STANDARD, value: 'ObjectName' }
}
define view entity ZC_MIG_REPORT_LOGIC
  as projection on ZI_MIG_REPORT_LOGIC
{
      @UI.hidden: true
  key ReportID,

      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
      @EndUserText.label: 'Object Name'
  key ObjectName,

      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      @EndUserText.label: 'Object Type'
      ObjectType,

      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
      @EndUserText.label: 'Description'
      Description,

      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 40 }]
      @EndUserText.label: 'Migration Target'
      MigrationTarget,

      @UI.lineItem: [{ position: 50 }]
      @UI.identification: [{ position: 50 }]
      @EndUserText.label: 'Severity'
      Severity,

      @UI.lineItem: [{ position: 60 }]
      @UI.identification: [{ position: 60 }]
      @EndUserText.label: 'Recommendation'
      Recommendation,

      @UI.lineItem: [{ position: 70 }]
      @UI.identification: [{ position: 70 }]
      @EndUserText.label: 'Complexity'
      RemediationComplexity,

      /* Associations */
     _ReportHeader : redirected to parent ZC_MIG_REPORT_HD
}
