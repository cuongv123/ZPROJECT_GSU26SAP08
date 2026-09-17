@EndUserText.label: 'OData generation parameters'
define abstract entity ZA_MIG_GEN_PARAM
{
  TargetPackage : abap.char(30);
  ProviderPackage : abap.char(30);
  ProviderLanguage : abap.char(10);
  TransportRequest : abap.char(20);
  RequestId : sysuuid_x16;
}

