CLASS lhc_ChatSession DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING
        REQUEST requested_authorizations
      FOR ChatSession
      RESULT result.

    METHODS ask
      FOR MODIFY
      IMPORTING
        keys FOR ACTION ChatSession~ask
      RESULT result.

    METHODS initializeSession
      FOR DETERMINE ON MODIFY
      IMPORTING
        keys FOR ChatSession~initializeSession.

    METHODS validateProgramExists
      FOR VALIDATE ON SAVE
      IMPORTING
        keys FOR ChatSession~validateProgramExists.

ENDCLASS.


CLASS lhc_ChatSession IMPLEMENTATION.


  METHOD get_global_authorizations.

    result-%create     = if_abap_behv=>auth-allowed.
    result-%update     = if_abap_behv=>auth-allowed.
    result-%delete     = if_abap_behv=>auth-allowed.
    result-%action-ask = if_abap_behv=>auth-allowed.

  ENDMETHOD.


  METHOD initializeSession.

    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sessions).

    MODIFY ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      UPDATE FIELDS ( ProgramName Status )
      WITH VALUE #(
        FOR session IN lt_sessions
        (
          %tky        = session-%tky
          ProgramName = to_upper(
                          condense(
                            session-ProgramName ) )
          Status      = zif_mig_chat_ai=>session_status-active
        )
      ).

  ENDMETHOD.


  METHOD ask.

  DATA lo_service TYPE REF TO zcl_mig_chat_service.

  DATA lt_seen_session_ids TYPE HASHED TABLE OF sysuuid_x16
    WITH UNIQUE KEY table_line.

  READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
    ENTITY ChatSession
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_sessions).

  SORT lt_sessions BY SessionId.

  LOOP AT keys INTO DATA(ls_key).

    DATA lv_error TYPE string.
    DATA lv_question TYPE string.
    DATA lv_duplicate_key TYPE abap_bool.

    CLEAR:
      lv_error,
      lv_question,
      lv_duplicate_key.

    lv_question =
      condense(
        ls_key-%param-Question ).

    lv_duplicate_key =
      xsdbool(
        line_exists(
          lt_seen_session_ids[
            table_line = ls_key-SessionId ] ) ).

    INSERT ls_key-SessionId
      INTO TABLE lt_seen_session_ids.

    READ TABLE lt_sessions
      WITH KEY SessionId = ls_key-SessionId
      BINARY SEARCH
      INTO DATA(ls_session).

    IF sy-subrc <> 0.

      lv_error = 'Chat session was not found.'.

    ELSEIF lv_duplicate_key = abap_true.

      lv_error =
        'Only one question is allowed for each session per request.'.

    ELSEIF ls_session-Status =
           zif_mig_chat_ai=>session_status-closed.

      lv_error =
        'This chat session is closed. Please create a new session.'.

    ELSEIF lv_question IS INITIAL.

      lv_error =
        'The question must not be empty.'.

    ELSEIF strlen( ls_key-%param-Question )
           > zif_mig_chat_ai=>max_question_chars.

      lv_error =
        |The question must not exceed {
           zif_mig_chat_ai=>max_question_chars } characters.|.

    ENDIF.


    IF lv_error IS INITIAL.

      READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
        ENTITY ChatSession
        BY \_Messages
        ALL FIELDS
        WITH VALUE #(
          (
            %tky = ls_session-%tky
          )
        )
        RESULT DATA(lt_messages).

      SORT lt_messages BY CreatedAt MessageId.


      DATA lv_analysis_id TYPE sysuuid_x16.
      DATA lt_history TYPE zcl_mig_chat_service=>tt_message.

      CLEAR:
        lv_analysis_id,
        lt_history.

      LOOP AT lt_messages INTO DATA(ls_message).

        IF lv_analysis_id IS INITIAL
           AND ls_message-AnalysisIdUsed IS NOT INITIAL.

          lv_analysis_id =
            ls_message-AnalysisIdUsed.

        ENDIF.

        APPEND VALUE #(
          role        = ls_message-Role
          content     = ls_message-Content
          analysis_id = ls_message-AnalysisIdUsed
        ) TO lt_history.

      ENDLOOP.


      TRY.

          IF lo_service IS INITIAL.

            lo_service =
              zcl_mig_chat_service=>create_gemini( ).

          ENDIF.


          DATA(ls_answer) =
            lo_service->answer(
              iv_program_name = ls_session-ProgramName
              iv_question     = ls_key-%param-Question
              iv_analysis_id  = lv_analysis_id
              it_history      = lt_history
            ).


          " Persist USER and AI messages only after a successful AI response.
          " MessageNo is intentionally omitted because it is not part of
          " the current database schema.
          MODIFY ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
            ENTITY ChatSession
            CREATE BY \_Messages
            FIELDS (
              Role
              Content
              AnalysisIdUsed
              AiProvider
              IsOutdated
            )
            WITH VALUE #(
              (
                %tky = ls_session-%tky

                %target = VALUE #(
                  (
                    %cid           = |U{ ls_key-SessionId }|
                    Role           = zif_mig_chat_ai=>role-user
                    Content        = ls_key-%param-Question
                    AnalysisIdUsed = ls_answer-analysis_id
                    IsOutdated     = ls_answer-is_outdated
                  )

                  (
                    %cid           = |A{ ls_key-SessionId }|
                    Role           = zif_mig_chat_ai=>role-ai
                    Content        = ls_answer-content
                    AnalysisIdUsed = ls_answer-analysis_id
                    AiProvider     = ls_answer-provider
                    IsOutdated     = ls_answer-is_outdated
                  )
                )
              )
            )
            FAILED DATA(ls_failed)
            REPORTED DATA(ls_reported).


          IF ls_failed-chatsession IS NOT INITIAL
             OR ls_failed-chatmsg IS NOT INITIAL.

            lv_error =
              'The chat messages could not be saved. Please try again.'.

          ELSE.

            " Touch the session so its ETag changes after each chat turn.
            MODIFY ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
              ENTITY ChatSession
              UPDATE FIELDS ( Status )
              WITH VALUE #(
                (
                  %tky   = ls_session-%tky
                  Status = zif_mig_chat_ai=>session_status-active
                )
              )
              FAILED DATA(ls_touch_failed).

            IF ls_touch_failed-chatsession IS NOT INITIAL.

              lv_error =
                'The chat session could not be updated. Please refresh and try again.'.

            ENDIF.

          ENDIF.


        CATCH zcx_mig_analysis.

          lv_error =
            'The AI answer could not be generated. Please check the analysis, Gemini configuration and connection. Existing chat history was preserved.'.

      ENDTRY.

    ENDIF.


    IF lv_error IS NOT INITIAL.

      APPEND VALUE #(
        %tky = ls_key-%tky
      ) TO failed-chatsession.

      APPEND VALUE #(
        %tky = ls_key-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_error
        )
      ) TO reported-chatsession.

      CONTINUE.

    ENDIF.


    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      ALL FIELDS
      WITH VALUE #(
        (
          %tky = ls_session-%tky
        )
      )
      RESULT DATA(lt_updated).

    LOOP AT lt_updated INTO DATA(ls_updated).

      APPEND VALUE #(
        %tky   = ls_updated-%tky
        %param = ls_updated
      ) TO result.

    ENDLOOP.

  ENDLOOP.

ENDMETHOD.


  METHOD validateProgramExists.

    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      FIELDS ( ProgramName )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_session).

    DATA(lo_repo) =
      NEW zcl_mig_source_repo( ).

    LOOP AT lt_session INTO DATA(ls_session).

      TRY.

          lo_repo->zif_mig_source_repo~read_program(
            ls_session-ProgramName ).

        CATCH zcx_mig_analysis.

          APPEND VALUE #(
            %tky = ls_session-%tky
          ) TO failed-chatsession.

          APPEND VALUE #(
            %tky = ls_session-%tky
            %msg = new_message(
              id       = 'ZMIG_ANALYSIS'
              number   = '001'
              v1       = ls_session-ProgramName
              severity = if_abap_behv_message=>severity-error
            )
          ) TO reported-chatsession.

      ENDTRY.

    ENDLOOP.

  ENDMETHOD.


ENDCLASS.
