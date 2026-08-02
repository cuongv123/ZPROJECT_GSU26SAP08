@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Migration Mail Job Interface'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_MIG_MAIL_JOB
  as select from zmig_mail_job
  
  composition [0..*] of ZI_MIG_MAIL_RECIP as _Recipients
  
   association [0..*] to ZI_MIG_MAIL_LOG as _Logs
    on $projection.JobId = _Logs.JobId
{
  key job_id                as JobId,

      job_name              as JobName,
      analysis_id           as AnalysisId,
      report_type           as ReportType,
      file_format           as FileFormat,
      frequency             as Frequency,
      start_date            as StartDate,
      start_time            as StartTime,
      day_of_week           as DayOfWeek,
      day_of_month          as DayOfMonth,
      next_run_at           as NextRunAt,

      mail_subject          as MailSubject,
      mail_body             as MailBody,
      status                as Status,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by       as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      
      _Recipients,
      _Logs
}
