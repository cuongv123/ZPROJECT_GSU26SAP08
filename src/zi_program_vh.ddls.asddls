@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Program Value Help'
@ObjectModel.dataCategory: #VALUE_HELP
define view entity ZI_PROGRAM_VH
  as select from trdirt
{
    key name as ProgramName,

    @Semantics.text: true
    text as ProgramDescription
}
where sprsl = $session.system_language
