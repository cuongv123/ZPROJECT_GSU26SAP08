CLASS zcl_mig_stmt_normalizer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_stmt_normalizer.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_text_entry,
        statement_id TYPE i,
        prefix_length TYPE i,
        token_count   TYPE i,

        token_1       TYPE string,
        token_2       TYPE string,
        token_3       TYPE string,
        token_4       TYPE string,

        segment_text  TYPE string,
        prefix_text   TYPE string,
      END OF ty_text_entry,

      tt_text_map TYPE HASHED TABLE OF ty_text_entry
        WITH UNIQUE KEY statement_id,

      ty_block_name TYPE c LENGTH 30,

      tt_block_stack TYPE STANDARD TABLE OF ty_block_name
        WITH EMPTY KEY.

ENDCLASS.

CLASS zcl_mig_stmt_normalizer IMPLEMENTATION.

  METHOD zif_mig_stmt_normalizer~normalize.

    DATA:
      lt_text_map    TYPE tt_text_map,
      lt_block_stack TYPE tt_block_stack,

      lv_chain_active  TYPE abap_bool,
      lv_chain_prefix  TYPE string,
      lv_chain_keyword TYPE string,

      lv_routine_name TYPE c LENGTH 120,
      lv_routine_type TYPE c LENGTH 20.

    rs_result = is_scan_result.

    "==========================================================
    " PASS 1
    " Tạo một text entry cho mỗi statement
    "==========================================================
    LOOP AT rs_result-statements
      ASSIGNING FIELD-SYMBOL(<statement_init>).

      INSERT VALUE #(
        statement_id  = <statement_init>-statement_id
        prefix_length = <statement_init>-prefix_length
      ) INTO TABLE lt_text_map.

    ENDLOOP.

    "==========================================================
    " PASS 2
    " Duyệt token đúng một lần để dựng text theo statement
    "==========================================================
    LOOP AT rs_result-tokens
      ASSIGNING FIELD-SYMBOL(<token>).

      IF <token>-statement_id <= 0.
        CONTINUE.
      ENDIF.

      READ TABLE lt_text_map
        WITH TABLE KEY
          statement_id = <token>-statement_id
        ASSIGNING FIELD-SYMBOL(<text_entry>).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      <text_entry>-token_count += 1.

      "--------------------------------------------------------
      " Giữ bốn token đầu để Context Builder sử dụng
      "--------------------------------------------------------
      CASE <text_entry>-token_count.

        WHEN 1.
          <text_entry>-token_1 = <token>-token_text.

        WHEN 2.
          <text_entry>-token_2 = <token>-token_text.

        WHEN 3.
          <text_entry>-token_3 = <token>-token_text.

        WHEN 4.
          <text_entry>-token_4 = <token>-token_text.

      ENDCASE.

      "--------------------------------------------------------
      " Dựng phần token riêng của statement
      "--------------------------------------------------------
      IF <text_entry>-segment_text IS INITIAL.

        <text_entry>-segment_text =
          <token>-token_text.

      ELSE.

        <text_entry>-segment_text =
          |{ <text_entry>-segment_text } {
             <token>-token_text }|.

      ENDIF.

      "--------------------------------------------------------
      " Với chained statement, lưu prefix trước dấu :
      " Ví dụ PARAMETERS: ...
      " PREFIXLEN = 1 → prefix là PARAMETERS
      "--------------------------------------------------------
      IF <text_entry>-prefix_length > 0
         AND <text_entry>-token_count
               <= <text_entry>-prefix_length.

        IF <text_entry>-prefix_text IS INITIAL.

          <text_entry>-prefix_text =
            <token>-token_text.

        ELSE.

          <text_entry>-prefix_text =
            |{ <text_entry>-prefix_text } {
               <token>-token_text }|.

        ENDIF.

      ENDIF.

    ENDLOOP.

    "==========================================================
    " PASS 3
    " Chuẩn hóa statement và xây routine/block context
    "==========================================================
    LOOP AT rs_result-statements
      ASSIGNING FIELD-SYMBOL(<statement>).

      READ TABLE lt_text_map
        WITH TABLE KEY
          statement_id = <statement>-statement_id
        ASSIGNING <text_entry>.

      IF sy-subrc <> 0.

        CLEAR:
          <statement>-statement_text,
          <statement>-parent_routine,
          <statement>-routine_type,
          <statement>-parent_block,
          <statement>-block_depth.

        CONTINUE.

      ENDIF.

      DATA:
        lv_statement_text TYPE string,
        lv_statement_type TYPE string,
        lv_token_1        TYPE string,
        lv_token_2        TYPE string,
        lv_token_3        TYPE string,
        lv_dummy          TYPE string.

      CLEAR:
        lv_statement_text,
        lv_statement_type,
        lv_token_1,
        lv_token_2,
        lv_token_3,
        lv_dummy.

      lv_token_1 =
        to_upper( <text_entry>-token_1 ).

      lv_token_2 =
        to_upper( <text_entry>-token_2 ).

      lv_token_3 =
        to_upper( <text_entry>-token_3 ).

      "========================================================
        " 3.1 Xử lý chained statement
        "
        " Scanner có thể trả continuation theo hai dạng:
        "
        " Dạng 1:
        "   P_TWO TYPE C
        "
        " Dạng 2:
        "   PARAMETERS P_TWO TYPE C
        "
        " Vì vậy chỉ prepend prefix khi segment chưa chứa keyword.
        "========================================================
        IF lv_chain_active = abap_true.

          "Continuation đã chứa keyword rồi thì không prepend lần nữa
          IF lv_token_1 = lv_chain_keyword.

            lv_statement_text =
              <text_entry>-segment_text.

          ELSE.

            lv_statement_text =
              |{ lv_chain_prefix } {
                 <text_entry>-segment_text }|.

          ENDIF.

          lv_statement_type =
            lv_chain_keyword.

          IF <statement>-terminator = ','.

            lv_chain_active = abap_true.

          ELSE.

            CLEAR:
              lv_chain_active,
              lv_chain_prefix,
              lv_chain_keyword.

          ENDIF.

        ELSEIF <statement>-prefix_length > 0.

          "Statement đầu tiên của chained statement
          lv_chain_prefix =
            <text_entry>-prefix_text.

          SPLIT lv_chain_prefix AT space
            INTO lv_chain_keyword lv_dummy.

          lv_chain_keyword =
            to_upper( lv_chain_keyword ).

          lv_statement_text =
            <text_entry>-segment_text.

          lv_statement_type =
            lv_chain_keyword.

          IF <statement>-terminator = ','.

            lv_chain_active = abap_true.

          ELSE.

            CLEAR:
              lv_chain_active,
              lv_chain_prefix,
              lv_chain_keyword.

          ENDIF.

        ELSE.

          "Statement thông thường
          CLEAR:
            lv_chain_active,
            lv_chain_prefix,
            lv_chain_keyword.

          lv_statement_text =
            <text_entry>-segment_text.

          lv_statement_type =
            lv_token_1.

        ENDIF.
      "--------------------------------------------------------
      " Thêm terminator logic
      "--------------------------------------------------------
      IF <statement>-terminator IS NOT INITIAL.

        lv_statement_text =
          |{ lv_statement_text }{
             <statement>-terminator }|.

      ENDIF.

      <statement>-statement_type =
        lv_statement_type.

      <statement>-statement_text =
        lv_statement_text.

      "========================================================
      " 3.2 Nhận diện processing block/routine bắt đầu
      "========================================================
      CASE <statement>-statement_type.

        WHEN 'FORM'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'FORM'.

          CLEAR lt_block_stack.

        WHEN 'METHOD'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'METHOD'.

          CLEAR lt_block_stack.

        WHEN 'FUNCTION'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'FUNCTION'.

          CLEAR lt_block_stack.

        WHEN 'MODULE'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'MODULE'.

          CLEAR lt_block_stack.

        WHEN 'INITIALIZATION'.

          lv_routine_name = 'INITIALIZATION'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'START-OF-SELECTION'.

          lv_routine_name = 'START-OF-SELECTION'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'END-OF-SELECTION'.

          lv_routine_name = 'END-OF-SELECTION'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'TOP-OF-PAGE'.

          lv_routine_name = 'TOP-OF-PAGE'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'END-OF-PAGE'.

          lv_routine_name = 'END-OF-PAGE'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'LOAD-OF-PROGRAM'.

          lv_routine_name = 'LOAD-OF-PROGRAM'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'AT'.

          CASE lv_token_2.

            WHEN 'SELECTION-SCREEN'.

              lv_routine_name =
                'AT SELECTION-SCREEN'.

              lv_routine_type = 'EVENT'.

              CLEAR lt_block_stack.

            WHEN 'LINE-SELECTION'.

              lv_routine_name =
                'AT LINE-SELECTION'.

              lv_routine_type = 'EVENT'.

              CLEAR lt_block_stack.

            WHEN 'USER-COMMAND'.

              lv_routine_name =
                'AT USER-COMMAND'.

              lv_routine_type = 'EVENT'.

              CLEAR lt_block_stack.

            WHEN OTHERS.

              "AT NEW / AT END OF trong LOOP không phải
              "processing event mới.

          ENDCASE.

      ENDCASE.

      "========================================================
      " 3.3 Gán routine context cho statement hiện tại
      "========================================================
      <statement>-parent_routine =
        lv_routine_name.

      <statement>-routine_type =
        lv_routine_type.

      "========================================================
      " 3.4 Gán block context trước khi push/pop
      "========================================================
      <statement>-block_depth =
        lines( lt_block_stack ).

      CLEAR <statement>-parent_block.

      IF lt_block_stack IS NOT INITIAL.

        READ TABLE lt_block_stack
          INDEX lines( lt_block_stack )
          INTO <statement>-parent_block.

      ENDIF.

      "========================================================
      " 3.5 Mở block
      "========================================================
      CASE <statement>-statement_type.

        WHEN 'IF'
          OR 'CASE'
          OR 'LOOP'
          OR 'DO'
          OR 'WHILE'
          OR 'TRY'.

          APPEND
            <statement>-statement_type
            TO lt_block_stack.

      ENDCASE.

      "========================================================
      " 3.6 Đóng block
      "
      "ENDLOOP vẫn có parent_block = LOOP.
      "Sau đó mới pop LOOP khỏi stack.
      "========================================================
      CASE <statement>-statement_type.

        WHEN 'ENDIF'
          OR 'ENDCASE'
          OR 'ENDLOOP'
          OR 'ENDDO'
          OR 'ENDWHILE'
          OR 'ENDTRY'.

          IF lt_block_stack IS NOT INITIAL.

            DELETE lt_block_stack
              INDEX lines( lt_block_stack ).

          ENDIF.

      ENDCASE.

      "========================================================
      " 3.7 Kết thúc routine
      "========================================================
      CASE <statement>-statement_type.

        WHEN 'ENDFORM'
          OR 'ENDMETHOD'
          OR 'ENDFUNCTION'
          OR 'ENDMODULE'.

          CLEAR:
            lv_routine_name,
            lv_routine_type,
            lt_block_stack.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
