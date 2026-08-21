@EndUserText.label: 'Technical Document Result'
define abstract entity ZA_MIG_TECH_DOC_RESULT
{
  ExportId    : sysuuid_x16;
  Status      : abap.char(10);
  FileName    : abap.char(128);
  MimeType    : abap.char(128);
  DownloadUrl : abap.string(0);
}
