@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Chat Message'

define view entity ZC_MIG_CHAT_MSG
  as projection on ZI_MIG_CHAT_MSG
{
  key SessionId,
  key MessageId,

      @UI.lineItem: [{ position: 10 }]
      Role,

      @UI.lineItem: [{ position: 20 }]
      Content,

      AnalysisIdUsed,
      AiProvider,
      IsOutdated,
      CreatedBy,
      CreatedAt,

      _Session : redirected to parent ZC_MIG_CHAT_SESSION
}
