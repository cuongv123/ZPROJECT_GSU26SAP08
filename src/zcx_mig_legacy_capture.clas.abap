CLASS zcx_mig_legacy_capture DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA message TYPE string READ-ONLY.
    METHODS constructor
      IMPORTING
        iv_message TYPE string
        previous TYPE REF TO cx_root OPTIONAL.

  PRIVATE SECTION.
ENDCLASS.

CLASS zcx_mig_legacy_capture IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    message = iv_message.
  ENDMETHOD.
ENDCLASS.

