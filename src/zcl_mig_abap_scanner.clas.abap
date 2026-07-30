CLASS zcl_mig_abap_scanner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_abap_scanner.

ENDCLASS.

CLASS zcl_mig_abap_scanner IMPLEMENTATION.

  METHOD zif_mig_abap_scanner~scan.

    DATA:
      lv_source_object TYPE progname,

      lt_raw_source    TYPE STANDARD TABLE OF string
        WITH EMPTY KEY,

      lt_native_tokens TYPE STANDARD TABLE OF stokes
        WITH EMPTY KEY,

      lt_native_statements TYPE STANDARD TABLE OF sstmnt
        WITH EMPTY KEY.

    "----------------------------------------------------------
    " 1. Chuẩn hóa source object
    "----------------------------------------------------------
    lv_source_object = iv_source_object.
    TRANSLATE lv_source_object TO UPPER CASE.

    rs_result-source_object = lv_source_object.

    "----------------------------------------------------------
    " 2. Chuyển Source Contract về source table cho SCAN
    "----------------------------------------------------------
    LOOP AT it_source ASSIGNING FIELD-SYMBOL(<source_line>).

      APPEND <source_line>-source_text
        TO lt_raw_source.

    ENDLOOP.

    "Include rỗng vẫn là trường hợp hợp lệ
    IF lt_raw_source IS INITIAL.
      RETURN.
    ENDIF.

    "----------------------------------------------------------
    " 3. Gọi ABAP lexical scanner
    "----------------------------------------------------------
    SCAN ABAP-SOURCE lt_raw_source
      TOKENS INTO lt_native_tokens
      STATEMENTS INTO lt_native_statements.

    CASE sy-subrc.

      WHEN 0.
        "Scan thành công

      WHEN 2.
        "Source rỗng hoặc không có vùng source hợp lệ
        RETURN.

      WHEN OTHERS.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid       = zcx_mig_analysis=>scan_failed
          program_name = lv_source_object
        ).

    ENDCASE.

    "----------------------------------------------------------
    " 4. Chuẩn hóa native statements
    "----------------------------------------------------------
    LOOP AT lt_native_statements
      ASSIGNING FIELD-SYMBOL(<native_statement>).

      DATA(lv_statement_id) = sy-tabix.

      DATA:
        lv_start_line     TYPE i,
        lv_end_line       TYPE i,
        lv_statement_type TYPE string.

      CLEAR:
        lv_start_line,
        lv_end_line,
        lv_statement_type.

      "Dòng bắt đầu lấy từ token đầu tiên
      IF <native_statement>-from > 0.

        READ TABLE lt_native_tokens
          INDEX <native_statement>-from
          ASSIGNING FIELD-SYMBOL(<first_token>).

        IF sy-subrc = 0.

          lv_start_line =
            <first_token>-row.

          lv_statement_type =
            to_upper(
               <first_token>-str
            ).

        ENDIF.

      ENDIF.

      "Dòng kết thúc lấy từ token cuối cùng
      IF <native_statement>-to > 0.

        READ TABLE lt_native_tokens
          INDEX <native_statement>-to
          ASSIGNING FIELD-SYMBOL(<last_token>).

        IF sy-subrc = 0.
          lv_end_line = <last_token>-row.
        ENDIF.

      ENDIF.

      "Native type giúp nhận INCLUDE chắc chắn,
      "kể cả chained statement.
      CASE <native_statement>-type.

        WHEN 'I' OR 'J'.
          lv_statement_type = 'INCLUDE'.

        WHEN OTHERS.
          "Giữ keyword token đầu tiên đã xác định ở trên

      ENDCASE.

      APPEND VALUE #(
        statement_id   = lv_statement_id
        native_type    = <native_statement>-type
        statement_type = lv_statement_type

        token_from     = <native_statement>-from
        token_to       = <native_statement>-to
        prefix_length  = <native_statement>-prefixlen
        terminator     = <native_statement>-terminator

        source_object  = lv_source_object
        start_line     = lv_start_line
        end_line       = lv_end_line

        parent_routine = ''
        parent_block   = ''
        statement_text = ''
      ) TO rs_result-statements.

    ENDLOOP.

    "----------------------------------------------------------
    " 5. Map token → statement bằng con trỏ tăng dần
    "
    "Không LOOP statement × LOOP token.
    "Mỗi token và mỗi statement chỉ được đi qua một lần.
    "----------------------------------------------------------
    DATA:
      lv_current_statement_index TYPE i VALUE 1,
      lv_token_statement_id      TYPE i,
      ls_current_statement       TYPE sstmnt.

    READ TABLE lt_native_statements
      INDEX lv_current_statement_index
      INTO ls_current_statement.

    LOOP AT lt_native_tokens
      ASSIGNING FIELD-SYMBOL(<native_token>).

      DATA(lv_token_index) = sy-tabix.

      "Di chuyển con trỏ statement khi token đã vượt phạm vi
      WHILE sy-subrc = 0
        AND lv_token_index > ls_current_statement-to
        AND lv_current_statement_index
              < lines( lt_native_statements ).

        lv_current_statement_index += 1.

        READ TABLE lt_native_statements
          INDEX lv_current_statement_index
          INTO ls_current_statement.

      ENDWHILE.

      CLEAR lv_token_statement_id.

      IF sy-subrc = 0
         AND lv_token_index >= ls_current_statement-from
         AND lv_token_index <= ls_current_statement-to.

        lv_token_statement_id =
          lv_current_statement_index.

      ENDIF.

      APPEND VALUE #(
        statement_id  = lv_token_statement_id
        token_index   = lv_token_index
        token_type    = <native_token>-type
        token_text    = CONV string( <native_token>-str )
        source_object = lv_source_object
        source_line   = <native_token>-row
        source_column = <native_token>-col
      ) TO rs_result-tokens.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
