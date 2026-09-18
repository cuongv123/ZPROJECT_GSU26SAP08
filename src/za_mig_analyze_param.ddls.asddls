@EndUserText.label: 'Migration Analyze Parameters'
define abstract entity ZA_MIG_ANALYZE_PARAM
{
  @EndUserText.label: 'ABAP Program Name'
  @Consumption.valueHelpDefinition: [
    {
      entity: {
        name: 'ZCE_MIG_PROGRAM_VH',
        element: 'ProgramName'
      }
    }
  ]
  ProgramName : progname;
}
