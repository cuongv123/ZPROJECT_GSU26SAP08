@EndUserText.label: 'Migration Export Engine'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_MIG_EXPORT'
define root custom entity ZCE_MIG_EXPORT
{
  key ReportType    : abap.char(40);
  key FileFormat    : abap.char(10);    // <-- Tăng từ char(1) lên char(10)
  key ExportSection : abap.char(20);

      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        contentDispositionPreference: #ATTACHMENT
      }
      Content       : abap.rawstring(0);

      @Semantics.mimeType: true
      MimeType      : abap.char(128);

      FileName      : abap.char(128);
}
