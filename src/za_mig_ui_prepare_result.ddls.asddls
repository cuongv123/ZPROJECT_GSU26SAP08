@EndUserText.label: 'Prepare Fiori UI Result'
define abstract entity ZA_MIG_UI_PREPARE_RESULT
{
  AnalysisId   : sysuuid_x16;
  Status       : abap.char(20);
  RuntimeCheck : abap.char(30);
  IssueCount   : abap.int4;
  ConfigJson   : abap.string(0);
}
