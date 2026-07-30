@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Evidence'
@Metadata.allowExtensions: true

define view entity ZC_MIG_ANL_EVD
  as projection on ZI_MIG_ANL_EVD
{
  key AnalysisId,
  key EvidenceId,

      SourceObject,
      StartLine,
      EndLine,
      StatementId,
      StatementText,
      Confidence,

      _Analysis : redirected to parent ZC_MIG_ANALYSIS
}
