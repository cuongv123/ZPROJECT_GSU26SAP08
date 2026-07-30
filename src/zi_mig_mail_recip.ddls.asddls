@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Migration Mail Recipient Interface'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_MIG_MAIL_RECIP
  as select from zmig_mail_recip

  association to parent ZI_MIG_MAIL_JOB as _Job
    on $projection.JobId = _Job.JobId

{
  key job_id                as JobId,
  key recipient_id          as RecipientId,

      recipient_type        as RecipientType,
      sap_user              as SapUser,
      email_address         as EmailAddress,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by       as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Job
}
