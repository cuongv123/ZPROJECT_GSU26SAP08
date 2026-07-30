@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Columns'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_COL
  as select from zmig_anl_col

  association to parent ZI_MIG_ANL_ALV as _AlvOutput
    on  $projection.AnalysisId = _AlvOutput.AnalysisId
    and $projection.OutputId   = _AlvOutput.OutputId

  association to ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id      as AnalysisId,
  key output_id        as OutputId,
  key item_id          as ItemId,

      evidence_id      as EvidenceId,

      field_name       as FieldName,
      column_label     as ColumnLabel,
      column_position  as ColumnPosition,

      data_type        as DataType,
      data_element     as DataElement,
      reference_table  as ReferenceTable,
      reference_field  as ReferenceField,

      field_length     as FieldLength,
      decimals         as Decimals,

      visible          as Visible,
      key_field        as KeyField,
      technical        as Technical,
      editable         as Editable,
      hotspot          as Hotspot,
      checkbox         as Checkbox,
      icon              as Icon,

      currency_field   as CurrencyField,
      unit_field       as UnitField,
      aggregation      as Aggregation,

      source_mapping   as SourceMapping,
      confidence       as Confidence,

      _AlvOutput,
      _Analysis
}
