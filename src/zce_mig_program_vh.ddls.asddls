@EndUserText.label: 'ABAP Program Value Help'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_MIG_PROGRAM_VH'
@Search.searchable: true
define custom entity ZCE_MIG_PROGRAM_VH
{
  @EndUserText.label: 'ABAP Program'
  @Search.defaultSearchElement: true
  key ProgramName : progname;
}
