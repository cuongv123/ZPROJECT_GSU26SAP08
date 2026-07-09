@EndUserText.label: 'Custom Entity for FI_EWU_CONVERTED_COMPANYCODES'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DYNAMIC_RAP_PROVIDER'

@UI.headerInfo: {
  typeName: 'Item',
  typeNamePlural: 'Items'
}
define root custom entity ZCE_GEN_FI_EWU_CONVERTED_COMPA
{
      @UI.lineItem: [{ position: 10 }]
  key dummy_id : abap.char( 32 );
}
