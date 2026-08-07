@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Mail Job Projection'
@Metadata.allowExtensions: true

define root view entity ZC_MIG_MAIL_JOB
  provider contract transactional_query
  as projection on ZI_MIG_MAIL_JOB
{
  key JobId,
      AnalysisId,
      JobName,
      ReportType,
      FileFormat,
      Frequency,

      StartDate,
      StartTime,
      DayOfWeek,
      DayOfMonth,
      NextRunAt,

      MailSubject,
      MailBody,
      Status,

      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Recipients : redirected to composition child ZC_MIG_MAIL_RECIP
}
