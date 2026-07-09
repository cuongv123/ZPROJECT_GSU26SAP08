@EndUserText.label: 'Custom Entity for RS_VARIANT_CATALOG'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DYNAMIC_RAP_PROVIDER'

@UI.headerInfo: {
  typeName: 'Item',
  typeNamePlural: 'Items'
}
define root custom entity ZCE_GEN_RS_VARIANT_CATALOG
{
      @UI.lineItem: [{ position: 10 }]
  key dummy_id : abap.char( 32 );
}
