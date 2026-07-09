@EndUserText.label: 'Custom Entity for FAGL_CHECK_GLFLEX_ACTIVE'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DYNAMIC_RAP_PROVIDER'

@UI.headerInfo: {
  typeName: 'Item',
  typeNamePlural: 'Items'
}
define root custom entity ZCE_GEN_FAGL_CHECK_GLFLEX_ACTI
{
      @UI.lineItem: [{ position: 10 }]
  key dummy_id : abap.char( 32 );
}
