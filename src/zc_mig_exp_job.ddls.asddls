@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Export Job'
@Metadata.allowExtensions: true

define root view entity ZC_MIG_EXP_JOB
  provider contract transactional_query
  as projection on ZI_MIG_EXP_JOB
{
  key ExportId,

      AnalysisId,
      FileFormat,
      ExportSection,
      SelectedFields,

      Status,
      FileName,
      MimeType,
      Content,
      Message,

      CreatedBy,
      CreatedAt,
      ExpiresAt
}
