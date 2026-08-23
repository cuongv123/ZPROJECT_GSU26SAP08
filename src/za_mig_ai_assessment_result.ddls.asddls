@EndUserText.label: 'AI Assessment Result'
define abstract entity ZA_MIG_AI_ASSESSMENT_RESULT
{
  AnalysisId                : sysuuid_x16;
  ProgramName               : abap.char(40);

  ApplicationSummary        : abap.string(0);

  BusinessPurpose           : abap.string(0);
  BusinessPurposeConfidence : abap.char(10);
  BusinessPurposeReasoning  : abap.string(0);

  LegacyFlowExplanation     : abap.string(0);

  RisksJson                 : abap.string(0);
  ModernizationPlanJson     : abap.string(0);
  TargetArchitectureJson    : abap.string(0);
  CodeSuggestionsJson       : abap.string(0);
  ManualReviewJson          : abap.string(0);
}
