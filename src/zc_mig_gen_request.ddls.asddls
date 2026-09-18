@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My OData generation requests'
@Metadata.allowExtensions: true
define view entity ZC_MIG_GEN_REQUEST
  as select from zmig_gen_job
{
  key request_id   as RequestId,
      analysis_id  as AnalysisId,
      requested_by as RequestedBy,
      created_at   as CreatedAt,
      updated_at   as UpdatedAt,
      status       as Status,
      message      as Message
}
where requested_by = $session.user
