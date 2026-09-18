CLASS zcx_mig_export_error DEFINITION
  PUBLIC
  INHERITING FROM cx_rap_query_provider
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_message TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        previous   LIKE previous OPTIONAL
        mv_message TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

ENDCLASS.

CLASS zcx_mig_export_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->mv_message = mv_message.
  ENDMETHOD.

  METHOD get_text.
    result = COND #( WHEN mv_message IS NOT INITIAL
                      THEN mv_message
                      ELSE super->get_text( ) ).
  ENDMETHOD.

ENDCLASS.
