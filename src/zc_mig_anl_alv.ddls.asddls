@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis ALV Outputs'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_ALV
  as projection on ZI_MIG_ANL_ALV
{
  key AnalysisId,
  key OutputId,

      EvidenceId,
      LayoutEvidenceId,

      OutputName,
      OutputKind,
      Framework,

      ControlObject,
      OutputTable,
      RowType,
      FieldCatalog,
      SortTable,
      FilterTable,
      LayoutObject,
      VariantObject,

      Editable,
      Hierarchical,
      Zebra,
      AutoWidth,
      SelectionMode,

      Confidence,

      _Columns  : redirected to composition child ZC_MIG_ANL_COL,
      _Sorts    : redirected to composition child ZC_MIG_ANL_SRT,
      _Filters  : redirected to composition child ZC_MIG_ANL_FLT,
      _Events   : redirected to composition child ZC_MIG_ANL_EVT,

      _Analysis : redirected to parent ZC_MIG_ANALYSIS
}
