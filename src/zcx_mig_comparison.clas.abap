CLASS zcx_mig_comparison DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        iv_message TYPE string OPTIONAL
        previous   TYPE REF TO cx_root OPTIONAL.

    DATA message TYPE string READ-ONLY.

  PRIVATE SECTION.

ENDCLASS.


CLASS zcx_mig_comparison IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor(
      previous = previous
    ).

    message = iv_message.

  ENDMETHOD.

ENDCLASS.
