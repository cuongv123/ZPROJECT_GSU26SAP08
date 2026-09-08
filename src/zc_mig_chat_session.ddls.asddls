@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Chat Session'
@Metadata.allowExtensions: true
@UI.headerInfo.typeName: 'Chat Session'
@UI.headerInfo.typeNamePlural: 'Chat Sessions'

define root view entity ZC_MIG_CHAT_SESSION
  provider contract transactional_query
  as projection on ZI_MIG_CHAT_SESSION
{
@UI.facet: [{
  id: 'Messages',
  type: #LINEITEM_REFERENCE,
  label: 'Hội thoại',
  targetElement: '_Messages'
}]
  key SessionId,

      @UI.lineItem: [{ position: 10 }]
@UI.identification: [
  { position: 10 },
  {
    type: #FOR_ACTION,
    dataAction: 'ask',
    label: 'Hỏi AI'
  }
]
      ProgramName,

      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      SessionName,

      @UI.lineItem: [{ position: 30 }]
      Status,

      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Messages : redirected to composition child ZC_MIG_CHAT_MSG
}
