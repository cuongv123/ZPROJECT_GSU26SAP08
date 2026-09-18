@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Evidence'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_EVD
  as select from zmig_anl_evd

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id     as AnalysisId,
  key evidence_id     as EvidenceId,

      source_object   as SourceObject,
      start_line      as StartLine,
      end_line        as EndLine,
      statement_id    as StatementId,
      statement_text  as StatementText,
      confidence      as Confidence,

      _Analysis
}
