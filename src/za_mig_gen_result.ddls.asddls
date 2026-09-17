@EndUserText.label: 'OData generation outcome'
define abstract entity ZA_MIG_GEN_RESULT
{
  AnalysisId : sysuuid_x16;
  RequestId : sysuuid_x16;
  Status : abap.char(20);
  RuntimeCheck : abap.char(30);
  ResultJson : abap.string(0);
  Message : abap.string(0);
}

