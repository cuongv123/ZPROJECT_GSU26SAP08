@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Chat Session Interface'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_MIG_CHAT_SESSION
  as select from zmig_chat_sesion

  composition [0..*] of ZI_MIG_CHAT_MSG as _Messages
{
  key session_id            as SessionId,

      analysis_id           as AnalysisId,
      program_name          as ProgramName,
      session_name          as SessionName,
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

      _Messages
}
