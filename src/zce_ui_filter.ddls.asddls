@EndUserText.label: 'UI Filter Analysis'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_UI_FILTER_QP'
define root custom entity ZCE_UI_FILTER
{
      //      @UI.lineItem    : [ { position: 10 } ]
      @UI.hidden      : true
      @EndUserText.label:'Program Name'
  key ProgramName     : abap.char(40);

      @UI.lineItem    : [ { position: 10 } ]
      @EndUserText.label:'Field Name'
  key FieldName       : abap.char(40);

      @UI.lineItem    : [ { position: 20 } ]
      @EndUserText.label:'Description'
      Description     : abap.char(255);

      @UI.lineItem    : [ { position: 30 } ]
      @EndUserText.label:'Filter Type'
      FilterType      : abap.char(30);

      @UI.lineItem    : [{ position: 40 }]
      @EndUserText.label: 'Recommendation'
      Recommendation  : abap.char(255);

      @UI.lineItem    : [ { position: 50 } ]
      @EndUserText.label: 'Migration Target'
      MigrationTarget : abap.char(100);

      @UI.lineItem    : [ { position: 60 } ]
      @EndUserText.label:'Data Element'
      DataElement     : abap.char(40);

      @UI.lineItem    : [ { position: 70 } ]
      @EndUserText.label:'Mandatory'
      MandatoryFlag   : abap.char(1);

      @UI.lineItem    : [ { position: 80 } ]
      @EndUserText.label:'Multi Value'
      MultiValueFlag  : abap.char(1);

      @UI.lineItem    : [ { position: 90 } ]
      @EndUserText.label:'Severity'
      Severity        : abap.char(20);

      @UI.lineItem    : [{ position: 100 }]
      @EndUserText.label: 'Fiori Adaptation'
      FioriAdaptation : abap.char(255);
}
