@EndUserText.label: 'Projection: Migration Report Filter'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@UI.headerInfo: {
  typeName: 'UI Filter',
  typeNamePlural: 'UI Filters',
  title: { type: #STANDARD, value: 'FieldName' }
}
define view entity ZC_MIG_REPORT_FILTER
  as projection on ZI_MIG_REPORT_FILTER
{
      @UI.hidden: true
  key ReportID,

      @UI.lineItem: [{ position: 10 }]
      @EndUserText.label: 'Field Name'
  key FieldName,

      @UI.lineItem: [{ position: 20 }]
      @EndUserText.label: 'Description'
      Description,

      @UI.lineItem: [{ position: 30 }]
      @EndUserText.label: 'Filter Type'
      FilterType,

      @UI.lineItem: [{ position: 40 }]
      @EndUserText.label: 'Recommendation'
      Recommendation,

      @UI.lineItem: [{ position: 50 }]
      @EndUserText.label: 'Migration Target'
      MigrationTarget,

      @UI.lineItem: [{ position: 60 }]
      @EndUserText.label: 'Data Element'
      DataElement,

      @UI.lineItem: [{ position: 70 }]
      @EndUserText.label: 'Mandatory'
      MandatoryFlag,

      @UI.lineItem: [{ position: 80 }]
      @EndUserText.label: 'Multi Value'
      MultiValueFlag,

      @UI.lineItem: [{ position: 90 }]
      @EndUserText.label: 'Severity'
      Severity,

      @UI.lineItem: [{ position: 100 }]
      @EndUserText.label: 'Fiori Adaptation'
      FioriAdaptation,

      _ReportHeader : redirected to parent ZC_MIG_REPORT_HD
}
