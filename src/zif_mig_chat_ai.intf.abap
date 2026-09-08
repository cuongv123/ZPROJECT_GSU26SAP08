INTERFACE zif_mig_chat_ai
   PUBLIC.

  "==========================================================
  " Role của message trong 1 chat session
  "==========================================================
  CONSTANTS:
    BEGIN OF role,
      user TYPE zmig_e_chat_role VALUE 'USER',
      ai   TYPE zmig_e_chat_role VALUE 'AI',
    END OF role.

  "==========================================================
  " Intent - dùng để classify câu hỏi trong context_builder
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
  " AI Provider - dùng cho factory + log lại provider nào đã trả lời
  "==========================================================
  CONSTANTS:
    BEGIN OF provider,
      gemini   TYPE string VALUE 'GEMINI',
      deepseek TYPE string VALUE 'DEEPSEEK',
    END OF provider.

  "==========================================================
  " Execution kind của 1 lệnh gọi trong zmig_anl_log
  " (dùng để phát hiện phần UNRESOLVED - dynamic call)
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
  " Giới hạn kỹ thuật - tránh magic number rải rác
  "==========================================================
  CONSTANTS:
    max_history_messages TYPE i VALUE 6,   " số message gần nhất đưa vào prompt
    max_history_pairs    TYPE i VALUE 3,   " = 3 cặp USER/AI
    max_question_chars   TYPE i VALUE 4000,
    max_message_chars    TYPE i VALUE 4000,
    max_doc_chars        TYPE i VALUE 24000,
    max_focused_chars    TYPE i VALUE 20000,
    max_source_chars     TYPE i VALUE 32000,
    max_unresolved_chars TYPE i VALUE 4000,
    max_context_chars    TYPE i VALUE 60000.

ENDINTERFACE.
