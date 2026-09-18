@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Mail Execution Log Interface'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_MIG_MAIL_LOG
  as select from zmig_mail_log
  
  association [0..1] to ZI_MIG_MAIL_JOB as _Job
  on $projection.JobId = _Job.JobId
  
{
  key job_id          as JobId,
  key run_id          as RunId,

      trigger_type    as TriggerType,
      status          as Status,

      started_at      as StartedAt,
      finished_at     as FinishedAt,

      file_name       as FileName,
      file_format     as FileFormat,
      file_size       as FileSize,
      recipient_count as RecipientCount,

      log_message     as LogMessage,

      @Semantics.user.createdBy: true
      created_by      as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      
      _Job
}
