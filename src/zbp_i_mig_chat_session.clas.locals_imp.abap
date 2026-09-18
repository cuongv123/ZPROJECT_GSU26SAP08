CLASS lhc_ChatSession DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING
        REQUEST requested_authorizations
        FOR ChatSession
      RESULT result.

    METHODS initializeSession
      FOR DETERMINE ON MODIFY
      IMPORTING
        keys FOR ChatSession~initializeSession.

    METHODS validateAnalysis
      FOR VALIDATE ON SAVE
      IMPORTING
        keys FOR ChatSession~validateAnalysis.

    METHODS ask
      FOR MODIFY
      IMPORTING
        keys FOR ACTION ChatSession~ask
      RESULT result.

ENDCLASS.


CLASS lhc_ChatSession IMPLEMENTATION.

  METHOD get_global_authorizations.

    " Preserve the current shared-access policy.
    " Owner/admin authorization must be integrated separately.
    result-%create     = if_abap_behv=>auth-allowed.
    result-%update     = if_abap_behv=>auth-allowed.
    result-%delete     = if_abap_behv=>auth-allowed.
    result-%action-ask = if_abap_behv=>auth-allowed.

  ENDMETHOD.


  METHOD initializeSession.

    DATA lt_updates TYPE TABLE FOR UPDATE ZI_MIG_CHAT_SESSION.
    DATA lt_init_reported LIKE reported-chatsession.
    DATA lv_program TYPE progname.

    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sessions).

    IF lt_sessions IS INITIAL.
      RETURN.
    ENDIF.

    " Read requested analysis headers in bulk.
    SELECT analysis_id, program_name
      FROM zmig_anl_h
      FOR ALL ENTRIES IN @lt_sessions
      WHERE analysis_id = @lt_sessions-AnalysisId
      INTO TABLE @DATA(lt_headers).

    SORT lt_headers BY analysis_id.

    LOOP AT lt_sessions INTO DATA(ls_session).

      CLEAR lv_program.

      READ TABLE lt_headers
        WITH KEY analysis_id = ls_session-AnalysisId
        BINARY SEARCH
        INTO DATA(ls_header).

      IF sy-subrc = 0.
        lv_program = ls_header-program_name.
      ENDIF.

      " Derive ProgramName from the selected analysis.
      APPEND VALUE #(
        %tky        = ls_session-%tky
        ProgramName = lv_program
        Status      = zif_mig_chat_ai=>session_status-active
      ) TO lt_updates.

    ENDLOOP.

    MODIFY ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      UPDATE FIELDS ( ProgramName Status )
      WITH lt_updates
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    lt_init_reported = CORRESPONDING #(
      ls_reported-chatsession ).

    APPEND LINES OF lt_init_reported
      TO reported-chatsession.

  ENDMETHOD.


  METHOD validateAnalysis.

    DATA lv_error TYPE string.

    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      FIELDS ( AnalysisId ProgramName )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sessions).

    IF lt_sessions IS INITIAL.
      RETURN.
    ENDIF.

    SELECT analysis_id, program_name, status
      FROM zmig_anl_h
      FOR ALL ENTRIES IN @lt_sessions
      WHERE analysis_id = @lt_sessions-AnalysisId
      INTO TABLE @DATA(lt_headers).

    SORT lt_headers BY analysis_id.

    LOOP AT lt_sessions INTO DATA(ls_session).

      CLEAR lv_error.

      IF ls_session-AnalysisId IS INITIAL.

        lv_error =
          'Select an analysis before creating a chat session.'.

      ELSE.

        READ TABLE lt_headers
          WITH KEY analysis_id = ls_session-AnalysisId
          BINARY SEARCH
          INTO DATA(ls_header).

        IF sy-subrc <> 0.

          lv_error =
            'The selected analysis no longer exists.'.

        ELSEIF ls_header-status <> 'COMPLETED'
           AND ls_header-status <> 'WARNING'.

          lv_error =
            'The selected analysis is not ready for chat.'.

        ELSEIF ls_session-ProgramName <> ls_header-program_name.

          lv_error =
            'The session program does not match the selected analysis.'.

        ENDIF.

      ENDIF.

      IF lv_error IS NOT INITIAL.

        APPEND VALUE #(
          %tky = ls_session-%tky
        ) TO failed-chatsession.

        APPEND VALUE #(
          %tky = ls_session-%tky
          %element-AnalysisId = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = lv_error )
        ) TO reported-chatsession.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD ask.

    DATA lo_service TYPE REF TO zcl_mig_chat_service.

    DATA lt_seen_session_ids TYPE HASHED TABLE OF sysuuid_x16
      WITH UNIQUE KEY table_line.

    DATA lt_history TYPE zcl_mig_chat_service=>tt_message.

    " Use explicitly typed buffers for EML reported messages.
    DATA lt_session_reported LIKE reported-chatsession.
    DATA lt_message_reported LIKE reported-chatmsg.
    DATA lt_touch_reported LIKE reported-chatsession.

    DATA lv_error TYPE string.
    DATA lv_question TYPE string.
    DATA lv_duplicate TYPE abap_bool.
    DATA lv_start_index TYPE sy-tabix.

    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sessions).

    SORT lt_sessions BY SessionId.

    " Load pinned analysis headers before processing requests.
    IF lt_sessions IS NOT INITIAL.

      SELECT analysis_id, program_name, status
        FROM zmig_anl_h
        FOR ALL ENTRIES IN @lt_sessions
        WHERE analysis_id = @lt_sessions-AnalysisId
        INTO TABLE @DATA(lt_headers).

      SORT lt_headers BY analysis_id.

    ENDIF.

    " Read conversation history in one EML operation.
    READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
      ENTITY ChatSession
      BY \_Messages
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_messages).

    SORT lt_messages BY SessionId CreatedAt MessageId.

    LOOP AT keys INTO DATA(ls_key).

      CLEAR:
        lv_error,
        lv_question,
        lv_duplicate,
        lv_start_index,
        lt_history,
        lt_session_reported,
        lt_message_reported,
        lt_touch_reported.

      lv_question = condense( ls_key-%param-Question ).

      lv_duplicate = xsdbool(
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

ELSEIF ls_session-CreatedBy <> sy-uname.

  lv_error =
    'You are not authorized to access this chat session.'.

ELSEIF lv_duplicate = abap_true.

  lv_error =
    'Send only one question per session in each request.'.

ELSEIF ls_session-Status =
       zif_mig_chat_ai=>session_status-closed.

  lv_error = 'This chat session is closed.'.

ELSEIF ls_session-AnalysisId IS INITIAL.

  lv_error =
    'This legacy session has no pinned analysis. Create a new session.'.

ELSEIF lv_question IS INITIAL
    OR strlen( ls_key-%param-Question )
       > zif_mig_chat_ai=>max_question_chars.

  lv_error =
    |Question must contain 1 to { zif_mig_chat_ai=>max_question_chars } characters.|.

ENDIF.

      IF lv_error IS INITIAL.

        READ TABLE lt_headers
          WITH KEY analysis_id = ls_session-AnalysisId
          BINARY SEARCH
          INTO DATA(ls_header).

        IF sy-subrc <> 0.

          lv_error =
            'The analysis used by this chat no longer exists. Create a new session.'.

        ELSEIF ls_header-program_name <> ls_session-ProgramName.

          lv_error =
            'The session program does not match its analysis.'.

        ELSEIF ls_header-status <> 'COMPLETED'
           AND ls_header-status <> 'WARNING'.

          lv_error =
            'The analysis used by this chat is not ready.'.

        ENDIF.

      ENDIF.

      IF lv_error IS INITIAL.

        " Locate the first history row belonging to this session.
        READ TABLE lt_messages
          WITH KEY SessionId = ls_session-SessionId
          BINARY SEARCH
          TRANSPORTING NO FIELDS.

        IF sy-subrc = 0.

          lv_start_index = sy-tabix.

          LOOP AT lt_messages INTO DATA(ls_message)
            FROM lv_start_index.

            IF ls_message-SessionId <> ls_session-SessionId.
              EXIT.
            ENDIF.

            IF ls_message-AnalysisIdUsed <> ls_session-AnalysisId.

              lv_error =
                'Chat history references a different analysis. Create a new session.'.

              EXIT.

            ENDIF.

            APPEND VALUE #(
              role        = ls_message-Role
              content     = ls_message-Content
              analysis_id = ls_message-AnalysisIdUsed
            ) TO lt_history.

          ENDLOOP.

        ENDIF.

      ENDIF.

      IF lv_error IS INITIAL.

        TRY.

            IF lo_service IS INITIAL.

              lo_service =
                zcl_mig_chat_service=>create_gemini( ).

            ENDIF.

            " Always use the AnalysisId stored on the session.
            DATA(ls_answer) = lo_service->answer(
              iv_program_name = ls_session-ProgramName
              iv_question     = ls_key-%param-Question
              iv_analysis_id  = ls_session-AnalysisId
              it_history      = lt_history ).

            IF ls_answer-analysis_id <> ls_session-AnalysisId.

              lv_error =
                'The AI result references an unexpected analysis.'.

            ELSE.

              " Stage both messages after receiving the AI response.
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
                        %cid = |U{ ls_key-SessionId }|
                        Role = zif_mig_chat_ai=>role-user
                        Content = ls_key-%param-Question
                        AnalysisIdUsed = ls_session-AnalysisId
                        IsOutdated = ls_answer-is_outdated
                      )
                      (
                        %cid = |A{ ls_key-SessionId }|
                        Role = zif_mig_chat_ai=>role-ai
                        Content = ls_answer-content
                        AnalysisIdUsed = ls_session-AnalysisId
                        AiProvider = ls_answer-provider
                        IsOutdated = ls_answer-is_outdated
                      )
                    )
                  )
                )
                FAILED DATA(ls_failed)
                REPORTED DATA(ls_reported).

              lt_session_reported = CORRESPONDING #(
                ls_reported-chatsession ).

              lt_message_reported = CORRESPONDING #(
                ls_reported-chatmsg ).

              APPEND LINES OF lt_session_reported
                TO reported-chatsession.

              APPEND LINES OF lt_message_reported
                TO reported-chatmsg.

              IF ls_failed-chatsession IS NOT INITIAL
                 OR ls_failed-chatmsg IS NOT INITIAL.

                lv_error =
                  'The chat messages could not be saved.'.

              ELSE.

                " Update the root after a conversation turn.
                MODIFY ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
                  ENTITY ChatSession
                  UPDATE FIELDS ( Status )
                  WITH VALUE #(
                    (
                      %tky = ls_session-%tky
                      Status = zif_mig_chat_ai=>session_status-active
                    )
                  )
                  FAILED DATA(ls_touch_failed)
                  REPORTED DATA(ls_touch_reported).

                lt_touch_reported = CORRESPONDING #(
                  ls_touch_reported-chatsession ).

                APPEND LINES OF lt_touch_reported
                  TO reported-chatsession.

                IF ls_touch_failed-chatsession IS NOT INITIAL.

                  lv_error =
                    'The chat session could not be updated.'.

                ENDIF.

              ENDIF.

            ENDIF.

          CATCH zcx_mig_analysis.

            " Specific snapshot errors are checked before this call.
            lv_error =
              'Context building or AI generation failed. Check the backend error.'.

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
            text     = lv_error )
        ) TO reported-chatsession.

        CONTINUE.

      ENDIF.

      READ ENTITIES OF ZI_MIG_CHAT_SESSION IN LOCAL MODE
        ENTITY ChatSession
        ALL FIELDS
        WITH VALUE #(
          ( %tky = ls_session-%tky )
        )
        RESULT DATA(lt_updated).

      LOOP AT lt_updated INTO DATA(ls_updated).

        APPEND VALUE #(
          %tky   = ls_key-%tky
          %param = ls_updated
        ) TO result.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
