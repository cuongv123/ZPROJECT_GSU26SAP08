CLASS zcx_mig_query_error DEFINITION
  PUBLIC
  INHERITING FROM cx_rap_query_provider
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    DATA message TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        previous   LIKE previous OPTIONAL
        iv_message TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

ENDCLASS.


CLASS zcx_mig_query_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor(
      previous = previous
    ).

    message = iv_message.

  ENDMETHOD.


  METHOD get_text.

    result =
      COND #(
        WHEN message IS NOT INITIAL
        THEN message
        ELSE super->get_text( )
      ).

  ENDMETHOD.

ENDCLASS.

