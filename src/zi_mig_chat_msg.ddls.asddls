@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Chat Message Interface'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_MIG_CHAT_MSG
  as select from zmig_chat_msg

  association to parent ZI_MIG_CHAT_SESSION as _Session
    on $projection.SessionId = _Session.SessionId
{
  key session_id        as SessionId,
  key message_id        as MessageId,

      role               as Role,
      content            as Content,

      analysis_id_used   as AnalysisIdUsed,
      ai_provider        as AiProvider,
      is_outdated        as IsOutdated,

      @Semantics.user.createdBy: true
      created_by         as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at         as CreatedAt,

      _Session
}

where _Session.CreatedBy = $session.user
