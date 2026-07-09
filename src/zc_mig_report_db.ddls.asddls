@EndUserText.label: 'Projection: Migration Report DB Table'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@UI.headerInfo: {
  typeName: 'Database Table',
  typeNamePlural: 'Database Tables',
  title: { type: #STANDARD, value: 'TableName' }
}
define view entity ZC_MIG_REPORT_DB
  as projection on ZI_MIG_REPORT_DB
{
      @UI.hidden: true
  key ReportID,

      @UI.lineItem: [{ position: 10 }]
      @EndUserText.label: 'Table Name'
  key TableName,

      @UI.lineItem: [{ position: 20 }]
      @EndUserText.label: 'Description'
      Description,

      @UI.lineItem: [{ position: 40 }]
      @EndUserText.label: 'Operations'
      Operations,

      @UI.lineItem: [{ position: 90 }]
      @EndUserText.label: 'Recommendation'
      Recommendation,

      @UI.lineItem: [{ position: 70 }]
      @EndUserText.label: 'CDS Candidate'
      CdsCandidate,

      @UI.lineItem: [{ position: 80 }]
      @EndUserText.label: 'Priority'
      Priority,

      @UI.lineItem: [{ position: 100 }]
      @EndUserText.label: 'Migration Approach'
      MigrationApproach,

      _ReportHeader : redirected to parent ZC_MIG_REPORT_HD
}
