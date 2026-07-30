CLASS zcx_mig_analysis DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF source_not_found,
        msgid TYPE symsgid VALUE 'ZMIG_ANALYSIS',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'PROGRAM_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF source_not_found,

      BEGIN OF source_read_failed,
        msgid TYPE symsgid VALUE 'ZMIG_ANALYSIS',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'PROGRAM_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF source_read_failed,

      BEGIN OF scan_failed,
        msgid TYPE symsgid VALUE 'ZMIG_ANALYSIS',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'PROGRAM_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF scan_failed,

      BEGIN OF include_not_found,
        msgid TYPE symsgid VALUE 'ZMIG_ANALYSIS',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'PROGRAM_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF include_not_found,

      BEGIN OF analysis_failed,
        msgid TYPE symsgid VALUE 'ZMIG_ANALYSIS',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE 'PROGRAM_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF analysis_failed.

    DATA program_name TYPE progname READ-ONLY.

    METHODS constructor
      IMPORTING
        textid       LIKE if_t100_message=>t100key OPTIONAL
        previous     TYPE REF TO cx_root OPTIONAL
        program_name TYPE progname OPTIONAL.
   PROTECTED SECTION.
   PRIVATE SECTION.

ENDCLASS.

CLASS zcx_mig_analysis IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor(
      previous = previous
    ).

    me->program_name = program_name.

    CLEAR me->textid.

    IF textid IS INITIAL.

      if_t100_message~t100key =
        if_t100_message=>default_textid.

    ELSE.

      if_t100_message~t100key = textid.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
