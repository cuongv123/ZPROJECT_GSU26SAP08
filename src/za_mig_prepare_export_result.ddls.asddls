@EndUserText.label: 'Prepare Selected Export Result'
define abstract entity ZA_MIG_PREPARE_EXPORT_RESULT
{
  ExportId    : sysuuid_x16;
  Status      : abap.char(10);
  FileName    : abap.char(128);
  MimeType    : abap.char(128);
  DownloadUrl : abap.string(0);
}
  
