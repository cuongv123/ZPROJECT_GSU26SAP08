@EndUserText.label: 'Database Table Analysis'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_DB_TABLE_QP'
define root custom entity ZCE_DB_TABLE
{
      //      @UI.lineItem      : [ { position: 10 } ]
      @UI.hidden        : true
      @EndUserText.label: 'Program Name'
  key ProgramName       : abap.char(40);

      @UI.lineItem      : [ { position: 10 } ]
      @EndUserText.label: 'Table Name'
  key TableName         : abap.char(30);

      @UI.lineItem      : [ { position: 20 } ]
      @EndUserText.label: 'Description'
      Description       : abap.char(255);

      @UI.lineItem      : [ { position: 40 } ]
      @EndUserText.label: 'Operations'
      Operations        : abap.char(100);
      
      @UI.lineItem: [{ position: 45 }]
      @EndUserText.label: 'Selected Fields'
      Fields : abap.char( 255 );

      @UI.lineItem      : [{ position: 90 }]
      @EndUserText.label: 'Recommendation'
      Recommendation    : abap.char(255);

      @UI.lineItem      : [ { position: 70 } ]
      @EndUserText.label: 'CDS Candidate'
      CdsCandidate      : abap.char(80);

      @UI.lineItem      : [ { position: 80 } ]
      @EndUserText.label: 'Priority'
      Priority          : abap.char(20);

      @UI.lineItem      : [{ position: 100 }]
      @EndUserText.label: 'Migration Approach'
      MigrationApproach : abap.char(255);
}
