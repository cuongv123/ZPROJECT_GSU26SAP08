@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Mail Recipient Projection'
@Metadata.allowExtensions: true

define view entity ZC_MIG_MAIL_RECIP
  as projection on ZI_MIG_MAIL_RECIP
{
  key JobId,
  key RecipientId,

      RecipientType,
      SapUser,  
      EmailAddress,

      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,

      _Job : redirected to parent ZC_MIG_MAIL_JOB
}
