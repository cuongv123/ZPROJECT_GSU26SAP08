CLASS zcx_mig_generation DEFINITION PUBLIC
  INHERITING FROM zcx_mig_analysis CREATE PUBLIC.
  PUBLIC SECTION.
    DATA detail TYPE string READ-ONLY.
    METHODS constructor
      IMPORTING iv_detail TYPE string previous TYPE REF TO cx_root OPTIONAL.
    METHODS get_text REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcx_mig_generation IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    detail = iv_detail.
  ENDMETHOD.

  METHOD get_text.
    result = detail.
  ENDMETHOD.
ENDCLASS.

