@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Outputs'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_ALV
  as select from zmig_anl_alv

  composition [0..*] of ZI_MIG_ANL_COL as _Columns

  composition [0..*] of ZI_MIG_ANL_SRT as _Sorts

  composition [0..*] of ZI_MIG_ANL_FLT as _Filters

  composition [0..*] of ZI_MIG_ANL_EVT as _Events

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id         as AnalysisId,
  key output_id           as OutputId,

      evidence_id         as EvidenceId,
      layout_evidence_id  as LayoutEvidenceId,

      output_name         as OutputName,
      output_kind         as OutputKind,
      framework           as Framework,

      control_object      as ControlObject,
      output_table        as OutputTable,
      row_type            as RowType,
      field_catalog       as FieldCatalog,
      sort_table          as SortTable,
      filter_table        as FilterTable,
      layout_object       as LayoutObject,
      variant_object      as VariantObject,

      editable            as Editable,
      hierarchical        as Hierarchical,
      zebra               as Zebra,
      auto_width          as AutoWidth,
      selection_mode      as SelectionMode,

      confidence          as Confidence,

      _Columns,
      _Sorts,
      _Filters,
      _Events,
      _Analysis
}
