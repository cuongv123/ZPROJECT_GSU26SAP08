@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis UI Filters'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_UI
  as projection on ZI_MIG_ANL_UI
{
  key AnalysisId,
  key ItemId,

      EvidenceId,
      FieldName,
      FieldKind,
      ReferenceTable,
      ReferenceField,
      DataElement,
      DataType,
      Description,
      SelectionBlock,

      Mandatory,
      Hidden,
      Checkbox,
      RadioGroup,
      MultipleSelection,
      RangeSupported,

      DefaultValue,
      ValidationRoutine,
      Confidence,

      _Analysis : redirected to parent ZC_MIG_ANALYSIS
}
