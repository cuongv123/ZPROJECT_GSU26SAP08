CLASS zcl_abap_source_parser DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_code_parser.

  PRIVATE SECTION.
    " Khai báo các bảng chứa dữ liệu sau khi Scan
    DATA: mt_tokens     TYPE stokesx_tab,
          mt_statements TYPE sstmnt_tab.

    METHODS parse_statement
      IMPORTING is_statement TYPE sstmnt
      CHANGING  ct_db_table  TYPE zcl_parser_types=>tt_raw_db_table
                ct_ui_filter TYPE zcl_parser_types=>tt_raw_ui_filter
                ct_logic     TYPE zcl_parser_types=>tt_raw_logic.
ENDCLASS.

CLASS zcl_abap_source_parser IMPLEMENTATION.

  METHOD zif_code_parser~analyze_program.
    DATA: lv_message TYPE string,
          lv_line    TYPE i,
          lv_word    TYPE c LENGTH 72.


    SCAN ABAP-SOURCE it_source_code
         TOKENS     INTO mt_tokens
         STATEMENTS INTO mt_statements
         WITH ANALYSIS
         MESSAGE    INTO lv_message
         LINE       INTO lv_line
         WORD       INTO lv_word.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " 2. DUYỆT QUA TỪNG CÂU LỆNH (STATEMENTS) THAY VÌ TỪNG DÒNG (LINES)
    LOOP AT mt_statements INTO DATA(ls_statement).
      parse_statement(
        EXPORTING is_statement = ls_statement
        CHANGING  ct_db_table  = et_db_table
                  ct_ui_filter = et_ui_filter
                  ct_logic     = et_logic ).
    ENDLOOP.

    " (Phần Deduplicate giữ nguyên như cũ của bạn)

  ENDMETHOD.

  METHOD parse_statement.
    DATA: ls_db_table       TYPE zcl_parser_types=>ty_raw_db_table,
          ls_logic          TYPE zcl_parser_types=>ty_raw_logic,
          ls_ui_filter      TYPE zcl_parser_types=>ty_raw_ui_filter,
          lv_find_type      TYPE abap_bool,
          lv_in_from_clause TYPE abap_bool,
          lv_prev_token     TYPE string.

    " 1. Lấy Token đầu tiên để biết đây là lệnh gì
    READ TABLE mt_tokens INTO DATA(ls_first_token) INDEX is_statement-from.
    IF sy-subrc <> 0. RETURN. ENDIF.

    DATA(lv_keyword) = to_upper( ls_first_token-str ).

    " 2. Xử lý chuyên sâu cho từng loại lệnh
    CASE lv_keyword.
    " =================================================================
      " F. BÓC TÁCH GIAO DIỆN LỰA CHỌN (UI FILTERS)
      " =================================================================
      WHEN 'PARAMETERS' OR 'SELECT-OPTIONS'.
        " Token thứ 2 luôn là tên biến (ví dụ: p_matnr, s_vbeln)
        IF ( is_statement-to - is_statement-from ) >= 1.
          READ TABLE mt_tokens INTO DATA(ls_var_name) INDEX ( is_statement-from + 1 ).
          IF sy-subrc = 0.
            CLEAR ls_ui_filter.
            ls_ui_filter-field_name  = to_upper( ls_var_name-str ).
            ls_ui_filter-filter_type = lv_keyword. " Là PARAMETERS hay SELECT-OPTIONS

            " Duyệt các token còn lại để tìm thuộc tính OBLIGATORY và Data Element
            lv_find_type = abap_false.
            LOOP AT mt_tokens INTO DATA(ls_tok) FROM ( is_statement-from + 2 ) TO is_statement-to.
              DATA(lv_tok_str) = to_upper( ls_tok-str ).

              " 1. Bắt cờ bắt buộc nhập
              IF lv_tok_str = 'OBLIGATORY'.
                ls_ui_filter-mandatory_flag = abap_true.
              ENDIF.

              " 2. Bắt Data Element (từ khóa đứng ngay sau TYPE, LIKE, hoặc FOR)
              IF lv_find_type = abap_true.
                ls_ui_filter-data_element = lv_tok_str.
                lv_find_type = abap_false. " Reset cờ sau khi đã lấy được
              ENDIF.

              " Nếu gặp TYPE/LIKE/FOR, bật cờ để vòng lặp tiếp theo chộp lấy Data Element
              IF lv_tok_str = 'TYPE' OR lv_tok_str = 'LIKE' OR lv_tok_str = 'FOR'.
                lv_find_type = abap_true.
              ENDIF.
            ENDLOOP.

            " Đưa vào bảng kết quả (Deduplicate)
            READ TABLE ct_ui_filter WITH KEY field_name = ls_ui_filter-field_name TRANSPORTING NO FIELDS.
            IF sy-subrc <> 0.
              APPEND ls_ui_filter TO ct_ui_filter.
            ENDIF.
          ENDIF.
        ENDIF.
      " =================================================================
      " A. BÓC TÁCH LỆNH SELECT (BẮT CHÍNH XÁC JOIN & MULTIPLE TABLES)
      " =================================================================
      WHEN 'SELECT'.
        lv_in_from_clause = abap_false.
        lv_prev_token     = ``.

        " Duyệt qua tất cả các từ (Tokens) cấu thành nên câu lệnh SELECT này
        LOOP AT mt_tokens INTO DATA(ls_token) FROM is_statement-from TO is_statement-to.
          DATA(lv_token_str) = to_upper( ls_token-str ).

          " DẤU HIỆU THOÁT: Kết thúc mệnh đề FROM nếu gặp các từ khóa này
          IF lv_token_str = 'WHERE' OR lv_token_str = 'INTO' OR
             lv_token_str = 'ORDER' OR lv_token_str = 'GROUP' OR
             lv_token_str = 'HAVING' OR lv_token_str = 'UP'. " UP TO n ROWS
            lv_in_from_clause = abap_false.
          ENDIF.

          " NẾU ĐANG BÊN TRONG MỆNH ĐỀ FROM
          IF lv_in_from_clause = abap_true.
            " Nếu từ đứng ngay đằng trước là FROM, JOIN, hoặc dấu phẩy
            IF lv_prev_token = 'FROM' OR lv_prev_token = 'JOIN' OR lv_prev_token = ','.

              " Bỏ qua các keyword phụ của câu lệnh JOIN và biến động/host variable (có dấu ngoặc hoặc @)
              IF lv_token_str <> 'INNER' AND lv_token_str <> 'LEFT' AND
                 lv_token_str <> 'OUTER' AND lv_token_str <> 'RIGHT' AND
                 lv_token_str(1) <> '('  AND lv_token_str(1) <> '@'.

                " BÙM! ĐÂY CHÍNH XÁC LÀ TÊN BẢNG
                CLEAR ls_db_table.
                ls_db_table-table_name = lv_token_str.
                ls_db_table-operation  = 'SELECT'.

                " Kiểm tra tránh lưu trùng lặp (vd: self-join cùng 1 bảng 2 lần)
                READ TABLE ct_db_table WITH KEY table_name = ls_db_table-table_name operation = 'SELECT' TRANSPORTING NO FIELDS.
                IF sy-subrc <> 0.
                  APPEND ls_db_table TO ct_db_table.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

          " DẤU HIỆU BẮT ĐẦU: Bật cờ khi gặp mệnh đề FROM
          IF lv_token_str = 'FROM'.
            lv_in_from_clause = abap_true.
          ENDIF.

          " Lưu lại từ khóa hiện tại cho vòng lặp tiếp theo
          lv_prev_token = lv_token_str.
        ENDLOOP.

      " =================================================================
      " B. XỬ LÝ LỆNH UPDATE / INSERT / DELETE (Cực kỳ đơn giản)
      " =================================================================
      WHEN 'UPDATE' OR 'INSERT' OR 'DELETE' OR 'MODIFY'.
        " Đối với các lệnh DML, tên bảng thường nằm ngay vị trí token thứ 2 hoặc thứ 3
        READ TABLE mt_tokens INTO DATA(ls_target_token) INDEX ( is_statement-from + 1 ).
        IF sy-subrc = 0.
          DATA(lv_target) = to_upper( ls_target_token-str ).
          " Xử lý chữ FROM trong lệnh DELETE FROM ... hoặc INTO trong INSERT INTO ...
          IF lv_target = 'FROM' OR lv_target = 'INTO'.
             READ TABLE mt_tokens INTO ls_target_token INDEX ( is_statement-from + 2 ).
             lv_target = to_upper( ls_target_token-str ).
          ENDIF.

          IF lv_target(1) <> '(' AND lv_target(1) <> '@'.
             CLEAR ls_db_table.
             ls_db_table-table_name = lv_target.
             ls_db_table-operation  = lv_keyword.
             APPEND ls_db_table TO ct_db_table.
          ENDIF.
        ENDIF.
      " =================================================================
      " C. BÓC TÁCH CALL FUNCTION VÀ CALL SCREEN
      " =================================================================
      WHEN 'CALL'.
        " Đảm bảo câu lệnh CALL có ít nhất 3 từ (VD: CALL FUNCTION 'BAPI...')
        IF ( is_statement-to - is_statement-from ) >= 2.

          " Lấy Token thứ 2 (Nằm ngay sau chữ CALL)
          READ TABLE mt_tokens INTO DATA(ls_call_type) INDEX ( is_statement-from + 1 ).
          IF sy-subrc = 0.
            DATA(lv_call_type) = to_upper( ls_call_type-str ).

            " --- NHÁNH 1: CALL FUNCTION ---
            IF lv_call_type = 'FUNCTION'.
              " Lấy Token thứ 3 (Tên function)
              READ TABLE mt_tokens INTO DATA(ls_func_name) INDEX ( is_statement-from + 2 ).
              IF sy-subrc = 0.
                DATA(lv_func_name) = to_upper( ls_func_name-str ).

                " Xóa dấu nháy đơn bao quanh tên hàm (nếu gọi kiểu hardcode tĩnh)
                REPLACE ALL OCCURRENCES OF '''' IN lv_func_name WITH space.
                CONDENSE lv_func_name.

                IF lv_func_name IS NOT INITIAL.
                  CLEAR ls_logic.
                  ls_logic-object_name = lv_func_name.
                  ls_logic-object_type = 'FUNCTION MODULE'.

                  " Chống trùng lặp (Deduplicate)
                  READ TABLE ct_logic WITH KEY object_type = ls_logic-object_type
                                               object_name = ls_logic-object_name
                                      TRANSPORTING NO FIELDS.
                  IF sy-subrc <> 0.
                    APPEND ls_logic TO ct_logic.
                  ENDIF.
                ENDIF.
              ENDIF.

            " --- NHÁNH 2: CALL SCREEN ---
            ELSEIF lv_call_type = 'SCREEN'.
              " Lấy Token thứ 3 (Số dynpro screen)
              READ TABLE mt_tokens INTO DATA(ls_screen_num) INDEX ( is_statement-from + 2 ).
              IF sy-subrc = 0.
                DATA(lv_screen) = to_upper( ls_screen_num-str ).

                " Xóa dấu nháy đơn (nếu có)
                REPLACE ALL OCCURRENCES OF '''' IN lv_screen WITH space.
                CONDENSE lv_screen.

                IF lv_screen IS NOT INITIAL.
                  CLEAR ls_logic.
                  ls_logic-object_name = lv_screen.
                  ls_logic-object_type = 'CALL SCREEN'.

                  READ TABLE ct_logic WITH KEY object_type = ls_logic-object_type
                                               object_name = ls_logic-object_name
                                      TRANSPORTING NO FIELDS.
                  IF sy-subrc <> 0.
                    APPEND ls_logic TO ct_logic.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.

          ENDIF.
        ENDIF.

      " =================================================================
      " D. BÓC TÁCH PERFORM (Form Routines)
      " =================================================================
      WHEN 'PERFORM'.
        IF ( is_statement-to - is_statement-from ) >= 1.
          READ TABLE mt_tokens INTO DATA(ls_form_name) INDEX ( is_statement-from + 1 ).
          IF sy-subrc = 0.
            DATA(lv_form_name) = to_upper( ls_form_name-str ).
            IF lv_form_name IS NOT INITIAL.
              CLEAR ls_logic.
              ls_logic-object_name = lv_form_name.
              ls_logic-object_type = 'FORM'.

              READ TABLE ct_logic WITH KEY object_type = ls_logic-object_type
                                           object_name = ls_logic-object_name
                                  TRANSPORTING NO FIELDS.
              IF sy-subrc <> 0.
                APPEND ls_logic TO ct_logic.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

      " =================================================================
      " E. BÓC TÁCH SUBMIT (Gọi chương trình khác)
      " =================================================================
      WHEN 'SUBMIT'.
        IF ( is_statement-to - is_statement-from ) >= 1.
          READ TABLE mt_tokens INTO DATA(ls_submit_name) INDEX ( is_statement-from + 1 ).
          IF sy-subrc = 0.
            DATA(lv_program_name) = to_upper( ls_submit_name-str ).

            REPLACE ALL OCCURRENCES OF '''' IN lv_program_name WITH space.
            CONDENSE lv_program_name.

            IF lv_program_name IS NOT INITIAL.
              CLEAR ls_logic.
              ls_logic-object_name = lv_program_name.
              ls_logic-object_type = 'SUBMIT'.

              READ TABLE ct_logic WITH KEY object_type = ls_logic-object_type
                                           object_name = ls_logic-object_name
                                  TRANSPORTING NO FIELDS.
              IF sy-subrc <> 0.
                APPEND ls_logic TO ct_logic.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
