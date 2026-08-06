@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Export Job'
@Metadata.allowExtensions: true

define root view entity ZI_MIG_EXP_JOB
  as select from zmig_exp_job
{
  key export_id           as ExportId,

      analysis_id          as AnalysisId,
      file_format           as FileFormat,
      export_section         as ExportSection,
      selected_fields         as SelectedFields,

      status                  as Status,

      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        contentDispositionPreference: #ATTACHMENT
      }
      content                  as Content,

      @Semantics.mimeType: true
      mime_type                as MimeType,

      file_name                as FileName,
      message                  as Message,

      @Semantics.user.createdBy: true
      created_by                as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                 as CreatedAt,

      expires_at                  as ExpiresAt
}
