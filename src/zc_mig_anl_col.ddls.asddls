@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Columns'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_COL
  as projection on ZI_MIG_ANL_COL
{
  key AnalysisId,
  key OutputId,
  key ItemId,

      EvidenceId,

      FieldName,
      ColumnLabel,
      ColumnPosition,

      DataType,
      DataElement,
      ReferenceTable,
      ReferenceField,

      FieldLength,
      Decimals,

      Visible,
      KeyField,
      Technical,
      Editable,
      Hotspot,
      Checkbox,
      Icon,

      CurrencyField,
      UnitField,
      Aggregation,

      SourceMapping,
      Confidence,

      _AlvOutput : redirected to parent ZC_MIG_ANL_ALV,
      _Analysis  : redirected to ZC_MIG_ANALYSIS
}
