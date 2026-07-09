@EndUserText.label: 'Business Logic Migration Analysis'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_BUSINESS_LOGIC_QP'
define root custom entity ZCE_BUSINESS_LOGIC
{
      //      @UI.lineItem          : [ { position: 10 } ]
      @UI.hidden     : true
      @EndUserText.label    : 'Program Name'
  key ProgramName    : abap.char(40);

      @UI.lineItem   : [ { position: 10 } ]
      @EndUserText.label    : 'Function/ Method Name'
  key ObjectName     : abap.char(100);

      @UI.lineItem   : [ { position: 30 } ]
      @EndUserText.label    : 'Description'
      Description    : abap.char(255);

      @UI.lineItem   : [ { position: 20 } ]
      @EndUserText.label    : 'Type'
      ObjectType     : abap.char(50);

      @UI.lineItem   : [{ position: 80 }]
      @EndUserText.label    : 'Recommendation'
      Recommendation : abap.char(255);

      //      @UI.lineItem          : [ { position: 40 } ]
      //      @EndUserText.label    : 'API Released'
      //      ApiReleasedFlag       : abap.char(1);
      //
      //      @UI.lineItem          : [ { position: 50 } ]
      //      @EndUserText.label    : 'Cloud Compliant'
      //      CloudCompliant        : abap.char(1);
      //
            @UI.lineItem          : [ { position: 60 } ]
            @EndUserText.label    : 'Migration Target'
            MigrationTarget       : abap.char(100);
      
            @UI.lineItem          : [ { position: 70 } ]
            @EndUserText.label    : 'Severity'
            Severity              : abap.char(20);
      
            @UI.lineItem          : [{ position: 90 }]
            @EndUserText.label    : 'Complexity'
            RemediationComplexity : abap.char(30);
}
