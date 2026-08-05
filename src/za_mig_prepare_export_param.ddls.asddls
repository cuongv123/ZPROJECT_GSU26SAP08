@EndUserText.label: 'Prepare Selected Export Parameters'
define abstract entity ZA_MIG_PREPARE_EXPORT_PARAM
{
  FileFormat     : zmig_e_file_format;
  ExportSection  : zmig_e_report_section;
  SelectedFields : abap.string(0);
}
