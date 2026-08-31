CLASS zcl_mig_art_cap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS apply
      IMPORTING
        is_mfst TYPE zif_mig_types=>ty_art_mfst
      RETURNING
        VALUE(rs_mfst) TYPE zif_mig_types=>ty_art_mfst.

ENDCLASS.


CLASS zcl_mig_art_cap IMPLEMENTATION.

  METHOD apply.

    rs_mfst = is_mfst.


    LOOP AT rs_mfst-items
      ASSIGNING FIELD-SYMBOL(<ls_item>).

      <ls_item>-cap_state =
        zif_mig_types=>gc_art_cap_no.


      IF rs_mfst-strategy <>
           zif_mig_types=>gc_svc_query.

        <ls_item>-reason =
          'Only read-only query generation is supported.'.

        CONTINUE.

      ENDIF.


      IF ( <ls_item>-art_type = zif_mig_types=>gc_art_clas
           AND <ls_item>-art_role = zif_mig_types=>gc_art_query_prv )
         OR
         ( <ls_item>-art_type = zif_mig_types=>gc_art_ddls
           AND <ls_item>-art_role = zif_mig_types=>gc_art_entity )
         OR
         ( <ls_item>-art_type = zif_mig_types=>gc_art_srvd
           AND <ls_item>-art_role = zif_mig_types=>gc_art_srv_def ).

        <ls_item>-cap_state =
          zif_mig_types=>gc_art_cap_yes.

        <ls_item>-reason =
          'Artifact is supported by the read-only XCO generator.'.

      ELSE.

        <ls_item>-reason =
          'Artifact is not supported by the read-only XCO generator.'.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

