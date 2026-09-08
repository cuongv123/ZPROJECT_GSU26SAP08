CLASS lhc_ChatSession DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ChatSession RESULT result.

    METHODS ask FOR MODIFY
      IMPORTING keys FOR ACTION ChatSession~ask RESULT result.

    METHODS validateProgramExists FOR VALIDATE ON SAVE
      IMPORTING keys FOR ChatSession~validateProgramExists.

ENDCLASS.

CLASS lhc_ChatSession IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

   METHOD ask.

    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(lt_session).

    result = VALUE #( FOR ls_session IN lt_session
      ( %tky   = ls_session-%tky
        %param = ls_session ) ).

  ENDMETHOD.

   METHOD validateProgramExists.

    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      FIELDS ( ProgramName )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_session).

    DATA(lo_repo) = NEW zcl_mig_source_repo( ).

    LOOP AT lt_session INTO DATA(ls_session).

      TRY.
          lo_repo->zif_mig_source_repo~read_program( ls_session-ProgramName ).

        CATCH zcx_mig_analysis.

          APPEND VALUE #( %tky = ls_session-%tky ) TO failed-chatsession.

          APPEND VALUE #(
            %tky = ls_session-%tky
            %msg = new_message(
                     id       = 'ZMIG_ANALYSIS'
                     number   = '001'
                     v1       = ls_session-ProgramName
                     severity = if_abap_behv_message=>severity-error )
          ) TO reported-chatsession.

      ENDTRY.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
