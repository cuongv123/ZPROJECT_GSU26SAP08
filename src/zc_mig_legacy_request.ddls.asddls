@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My original report capture requests'
@Metadata.allowExtensions: true
define view entity ZC_MIG_LEGACY_REQUEST
  as select from zmig_legacy_job
{
  key request_id   as RequestId,
      analysis_id  as AnalysisId,
      requested_by as RequestedBy,
      created_at   as CreatedAt,
      updated_at   as UpdatedAt,
      status       as Status,
      row_count    as CountRow,
      message      as Message
}
where requested_by = $session.user
