@EndUserText.label: 'Original report runtime rows'
define abstract entity ZA_MIG_LEGACY_RESULT
{
  AnalysisId : sysuuid_x16;
  RequestId  : sysuuid_x16;
  Status     : abap.char(20);
  CountRow   : abap.int4;
  RowsJson   : abap.string(0);
  Message    : abap.string(0);
}
