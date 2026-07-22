CLASS zcx_mig_analysis DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA program_name TYPE program READ-ONLY.
    DATA error_text   TYPE string  READ-ONLY.

    METHODS constructor
      IMPORTING
        iv_program_name TYPE program OPTIONAL
        iv_error_text   TYPE string OPTIONAL.

ENDCLASS.


CLASS zcx_mig_analysis IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( ).

    program_name = iv_program_name.
    error_text   = iv_error_text.
  ENDMETHOD.

ENDCLASS.
