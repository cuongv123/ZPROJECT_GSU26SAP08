@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Migration Mail Execution Log Consumption'
@Metadata.allowExtensions: true

define view entity ZC_MIG_MAIL_LOG
  as select from ZI_MIG_MAIL_LOG
{
  key JobId,
  key RunId,

      TriggerType,
      Status,

      StartedAt,
      FinishedAt,

      FileName,
      FileFormat,
      FileSize,
      RecipientCount,

      LogMessage,
      CreatedBy,
      CreatedAt,

      _Job
}
