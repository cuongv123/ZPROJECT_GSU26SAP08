@EndUserText.label: 'Migration Analysis Overview'

@ObjectModel.query.implementedBy:
  'ABAP:ZCL_CE_ANALYSIS_OVERVIEW_QP'

@UI.headerInfo: {
  typeName: 'Program Analysis',
  typeNamePlural: 'Program Analysis',
  title: {
    type : #STANDARD,
    value: 'ProgramName'
  }
}

define root custom entity ZCE_ANALYSIS_OVERVIEW
{
      @UI.selectionField        : [{ position: 10 }]
      @UI.lineItem              : [ { position: 10 } ]
      @UI.identification        : [ { position: 10 } ]

      @Consumption.valueHelpDefinition: [{
          entity                    : {
            name                    : 'ZI_PROGRAM_VH',
            element                 : 'ProgramName'
          }
      }]

      @EndUserText.label        : 'Program Name'
  key ProgramName               : abap.char(40);

      @UI.hidden                : true
      AnalysisStatusCriticality : abap.int1;

      @UI.lineItem              : [ {
      position                  : 90,
      criticality               : 'AnalysisStatusCriticality'
      } ]

      @UI.identification        : [ {
          position              : 90,
          criticality           : 'AnalysisStatusCriticality'
      } ]

      @EndUserText.label        : 'Analysis Status'
      AnalysisStatus            : abap.char(30);

      @UI.lineItem              : [{ position: 20 }]
      @EndUserText.label        : 'Description'
      ProgramDescription        : abap.char(255);

      @UI.lineItem              : [ { position: 30 } ]
      @UI.identification        : [ { position: 30 } ]
      @EndUserText.label        : 'Total Tables'
      TotalTables               : abap.int4;

      @UI.lineItem              : [ { position: 40 } ]
      @UI.identification        : [ { position: 40 } ]
      @EndUserText.label        : 'Total Filters'
      TotalFilters              : abap.int4;

      @UI.lineItem              : [ { position: 50 } ]
      @UI.identification        : [ { position: 50 } ]
      @EndUserText.label        : 'Business Objects'
      TotalBusinessObjects      : abap.int4;

      @UI.lineItem              : [ { position: 60 } ]
      @UI.identification        : [ { position: 60 } ]
      @EndUserText.label        : 'Migration Score'
      MigrationScore            : abap.dec(5,2);

      @UI.lineItem              : [ { position: 70 } ]
      @UI.identification        : [ { position: 70 } ]
      @EndUserText.label        : 'Complexity Score'
      ComplexityScore           : abap.dec(5,2);

      @UI.lineItem              : [ { position: 80 } ]
      @UI.identification        : [ { position: 80 } ]
      @EndUserText.label        : 'Cloud Readiness'
      CloudReadinessScore       : abap.dec(5,2);

      @UI.facet                 : [
              {
                id              : 'Overview',
                type            : #IDENTIFICATION_REFERENCE,
                label           : 'Overview',
                position        : 10
              },

              {
                id              : 'UiFilters',
                type            : #LINEITEM_REFERENCE,
                label           : 'UI Filters',
                targetElement   : '_UiFilter',
                position        : 20
              },

              {
                id              : 'DbTables',
                type            : #LINEITEM_REFERENCE,
                label           : 'Database Tables',
                targetElement   : '_DbTable',
                position        : 30
              },

              {
                id              : 'BusinessLogic',
                type            : #LINEITEM_REFERENCE,
                label           : 'Business Logic',
                targetElement   : '_BusinessLogic',
                position        : 40
              }

            ]

      _UiFilter                 : association [0..*] to ZCE_UI_FILTER on $projection.ProgramName = _UiFilter.ProgramName;
      _DbTable                  : association [0..*] to ZCE_DB_TABLE on $projection.ProgramName = _DbTable.ProgramName;
      _BusinessLogic            : association [0..*] to ZCE_BUSINESS_LOGIC on $projection.ProgramName = _BusinessLogic.ProgramName;

}
