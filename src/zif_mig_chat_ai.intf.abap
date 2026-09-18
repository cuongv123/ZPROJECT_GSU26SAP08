INTERFACE zif_mig_chat_ai
   PUBLIC.

  "==========================================================
  "" The role of messages in a chat session
  "==========================================================
  CONSTANTS:
    BEGIN OF role,
      user TYPE zmig_e_chat_role VALUE 'USER',
      ai   TYPE zmig_e_chat_role VALUE 'AI',
    END OF role.

  "==========================================================
  " Intent - used to classify questions in context_builder
  "==========================================================
  CONSTANTS:
    BEGIN OF intent,
      db        TYPE string VALUE 'DB',
      bapi      TYPE string VALUE 'BAPI',
      logic     TYPE string VALUE 'LOGIC',
      alv       TYPE string VALUE 'ALV',
      ui        TYPE string VALUE 'UI',
      recommend TYPE string VALUE 'RECOMMEND',
      overview  TYPE string VALUE 'OVERVIEW',
    END OF intent.

  "==========================================================
  " AI Provider - used for factory + log which provider responded
  "==========================================================
  CONSTANTS:
    BEGIN OF provider,
      gemini   TYPE string VALUE 'GEMINI',
      "deepseek TYPE string VALUE 'DEEPSEEK'",
    END OF provider.

  "==========================================================
  " Execution kind of a call in zmig_anl_log
  " (used to detect the UNRESOLVED part - dynamic call)
  "==========================================================
  CONSTANTS:
    BEGIN OF execution_kind,
      static  TYPE string VALUE 'STATIC',
      dynamic TYPE string VALUE 'DYNAMIC',
    END OF execution_kind.

  "==========================================================
  " Session status
  "==========================================================
  CONSTANTS:
    BEGIN OF session_status,
      active TYPE string VALUE 'ACTIVE',
      closed TYPE string VALUE 'CLOSED',
    END OF session_status.

  "==========================================================
  " Technical limitations - avoid scattered magic numbers
  "==========================================================
  CONSTANTS:
    max_history_messages TYPE i VALUE 6,
    max_history_pairs    TYPE i VALUE 3,
    max_question_chars   TYPE i VALUE 4000,
    max_message_chars    TYPE i VALUE 4000,
    max_doc_chars        TYPE i VALUE 24000,
    max_focused_chars    TYPE i VALUE 20000,
    max_source_chars     TYPE i VALUE 32000,
    max_unresolved_chars TYPE i VALUE 4000,
    max_context_chars    TYPE i VALUE 60000.

ENDINTERFACE.
