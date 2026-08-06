@EndUserText.label: 'Generate OData Result'
define abstract entity ZA_MIG_GEN_ODATA_RESULT
{
  AnalysisId : sysuuid_x16;
  Status : abap.char(20);
  ProviderKind : abap.char(20);
  ProviderObject : abap.char(120);
  QueryProviderClass : abap.char(30);
  EntityName : abap.char(30);
  ServiceName : abap.char(30);
  ServiceBinding : abap.char(30);
  ServiceUrl : abap.string(0);
  Message : abap.string(0);
}
