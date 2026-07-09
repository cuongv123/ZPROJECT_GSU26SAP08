@EndUserText.label: 'Parameter for New Analysis'
define abstract entity ZD_ANALYZE_PARAM
{
  @EndUserText.label: 'Target Program Name'
  
  // Thêm dòng Annotation này để gọi Search Help
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PROGRAM_VH', element: 'ProgramName' } }]
  iv_program_name : programm;
}
