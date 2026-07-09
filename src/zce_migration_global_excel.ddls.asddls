@EndUserText.label: 'Global Excel Export-Multi Sheets Dynamic'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_MIGRATION_GLOBAL_QP'

define root custom entity ZCE_MIGRATION_GLOBAL_EXCEL
{
  key programname   : abap.char(40);
  
  // Hạ cấp xuống abap.string(0) để tương thích với cơ chế truyền text Base64 trên hệ thống cũ
  content           : abap.string(0);
  
  mimetype          : abap.string(0);
  filename          : abap.string(0);
}
