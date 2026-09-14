@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Chat Session'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Chat Session',
  typeNamePlural: 'Chat Sessions',
  title: {
    type: #STANDARD,
    value: 'SessionName'
  },
  description: {
    type: #STANDARD,
    value: 'ProgramName'
  }
}

define root view entity ZC_MIG_CHAT_SESSION
  provider contract transactional_query
  as projection on ZI_MIG_CHAT_SESSION
{
      @UI.facet: [
        {
          id: 'SessionDetails',
          type: #IDENTIFICATION_REFERENCE,
          label: 'Thông tin hội thoại',
          position: 10
        },
        {
          id: 'Messages',
          type: #LINEITEM_REFERENCE,
          label: 'Hội thoại',
          position: 20,
          targetElement: '_Messages'
        }
      ]
  key SessionId,

      @UI.identification: [{ position: 10 }]
      AnalysisId,

      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [
        { position: 20 },
        {
          type: #FOR_ACTION,
          dataAction: 'ask',
          label: 'Hỏi AI'
        }
      ]
      ProgramName,

      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 30 }]
      SessionName,

      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 40 }]
      Status,

      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Messages :
        redirected to composition child ZC_MIG_CHAT_MSG
}
