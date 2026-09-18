@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Migration Analysis Messages'
@Metadata.allowExtensions: true

define view entity ZI_MIG_ANL_MSG
  as select from zmig_anl_msg

  association to parent ZI_MIG_ANALYSIS as _Analysis
    on $projection.AnalysisId = _Analysis.AnalysisId
{
  key analysis_id    as AnalysisId,
  key message_no     as MessageNo,

      message_type   as MessageType,
      message_code   as MessageCode,
      source_object  as SourceObject,
      source_line    as SourceLine,
      message_text   as MessageText,

      _Analysis
}
