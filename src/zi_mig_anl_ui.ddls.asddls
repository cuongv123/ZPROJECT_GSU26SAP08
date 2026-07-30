@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis UI Filters'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_UI
  as select from zmig_anl_ui

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id          as AnalysisId,
  key item_id              as ItemId,

      evidence_id          as EvidenceId,

      field_name           as FieldName,
      field_kind           as FieldKind,
      reference_table      as ReferenceTable,
      reference_field      as ReferenceField,
      data_element         as DataElement,
      data_type            as DataType,
      description          as Description,
      selection_block      as SelectionBlock,

      mandatory            as Mandatory,
      hidden               as Hidden,
      checkbox             as Checkbox,
      radio_group          as RadioGroup,
      multiple_selection   as MultipleSelection,
      range_supported      as RangeSupported,

      default_value        as DefaultValue,
      validation_routine   as ValidationRoutine,
      confidence           as Confidence,

      _Analysis
}
