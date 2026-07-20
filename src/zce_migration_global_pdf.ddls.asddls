@EndUserText.label: 'Export Migration Global PDF'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_MIGRATION_GLOBAL_PDF'
define root custom entity ZCE_MIGRATION_GLOBAL_PDF
{
  key ProgramName : abap.char(40);

  @Semantics.largeObject: {
    mimeType: 'MimeType',
    fileName: 'FileName'
  }
  Content     : abap.rawstring(0);
  MimeType    : abap.char(128);
  FileName    : abap.char(128);
}
