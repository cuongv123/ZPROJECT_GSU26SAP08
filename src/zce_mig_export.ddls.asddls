@EndUserText.label: 'Migration Export Engine'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_MIG_EXPORT'
define root custom entity ZCE_MIG_EXPORT
{
  key ReportType : abap.char(20);
  key FileFormat : abap.char(1);
  key ExportSection : abap.char(20);


  @Semantics.largeObject: {
    mimeType: 'MimeType',
    fileName: 'FileName'
  }
  Content     : abap.rawstring(0);
  MimeType    : abap.char(128);
  FileName    : abap.char(128);
}
