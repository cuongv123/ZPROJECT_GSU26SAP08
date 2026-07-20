@EndUserText.label: 'Projection: Migration Report Header'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@UI.headerInfo: {
  typeName: 'Saved Report',
  typeNamePlural: 'Saved Reports',
  title: { type: #STANDARD, value: 'ProgramName' },
  description: { type: #STANDARD, value: 'ProgramDescription' }
}
define root view entity ZC_MIG_REPORT_HD
  provider contract transactional_query
  as projection on ZI_MIG_REPORT_HD
{
      @UI.facet: [
        { id: 'HeaderInfo', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Overview', position: 10 },
        { id: 'UiFilters',  purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'UI Filters', position: 20, targetElement: '_UiFilter' },
        { id: 'DbTables',   purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Database Tables', position: 30, targetElement: '_DbTable' },
        { id: 'LogicItems', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Business Logic', position: 40, targetElement: '_BusinessLogic' },  
        { id: 'ObjectMap', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Roadmap Data (Graph Ready)', position: 50, targetElement: '_ObjectMap' }      
      ]

      @UI.hidden: true
  key ReportID,

      @UI.selectionField: [{ position: 10 }]
      @UI.lineItem: [
        { position: 10 },
        { type: #FOR_ACTION, dataAction: 'analyzeAndSave', label: 'New Analysis', position: 10 },
        // Thêm nút bấm này vào Toolbar của bảng
        { type: #FOR_ACTION, dataAction: 'generateCode', label: 'Generate RAP Objects', position: 20 }
      ]
      @UI.identification: [
        { position: 10 },
        // Thêm nút bấm này vào màn hình Chi tiết (Object Page)
        { type: #FOR_ACTION, dataAction: 'generateCode', label: 'Generate RAP Objects', position: 20 }
      ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PROGRAM_VH', element: 'ProgramName' } }]
      @EndUserText.label: 'Program Name'
      ProgramName,

      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      @EndUserText.label: 'Description'
      ProgramDescription,

      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
      @EndUserText.label: 'Analyzed By'
      AnalyzedBy,

      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 40 }]
      @EndUserText.label: 'Analyzed At'
      AnalyzedAt,

      @UI.identification: [{ position: 50 }]
      @EndUserText.label: 'Total Tables'
      TotalTables,

      @UI.identification: [{ position: 60 }]
      @EndUserText.label: 'Total Filters'
      TotalFilters,

      @UI.identification: [{ position: 70 }]
      @EndUserText.label: 'Total Business Objects'
      TotalBusinessObjects,

      @UI.lineItem: [{ position: 50 }]
      @UI.identification: [{ position: 80 }]
      @EndUserText.label: 'Migration Score'
      MigrationScore,

      @UI.lineItem: [{ position: 60 }]
      @UI.identification: [{ position: 90 }]
      @EndUserText.label: 'Complexity Score'
      ComplexityScore,

      @UI.identification: [{ position: 100 }]
      @EndUserText.label: 'Cloud Readiness'
      CloudReadinessScore,

      @UI.lineItem: [{ position: 70 }]
      @UI.identification: [{ position: 110 }]
      @EndUserText.label: 'Analysis Status'
      AnalysisStatus,

      /* Associations và Compositions */
      _UiFilter      : redirected to composition child ZC_MIG_REPORT_FILTER,
      _DbTable       : redirected to composition child ZC_MIG_REPORT_DB,
      _BusinessLogic : redirected to composition child ZC_MIG_REPORT_LOGIC,
      _ObjectMap     : redirected to composition child ZC_MIG_REPORT_MAP
}
