CLASS zcl_mig_include_resolver DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_include_resolver.

    METHODS constructor
      IMPORTING
        io_source_repo TYPE REF TO zif_mig_source_repo OPTIONAL
        io_scanner     TYPE REF TO zif_mig_abap_scanner OPTIONAL.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_queue_entry,
        object_name   TYPE progname,
        parent_object TYPE progname,
        include_depth TYPE i,
        optional      TYPE abap_bool,
      END OF ty_queue_entry,

      tt_queue TYPE STANDARD TABLE OF ty_queue_entry
        WITH EMPTY KEY,

      tt_visited TYPE HASHED TABLE OF progname
        WITH UNIQUE KEY table_line.

    DATA:
      mo_source_repo TYPE REF TO zif_mig_source_repo,
      mo_scanner     TYPE REF TO zif_mig_abap_scanner.

    METHODS enqueue_includes
      IMPORTING
        is_scan_result  TYPE zif_mig_types=>ty_scan_result
        iv_parent_name  TYPE progname
        iv_parent_depth TYPE i
      CHANGING
        ct_queue        TYPE tt_queue.

ENDCLASS.

CLASS zcl_mig_include_resolver IMPLEMENTATION.

  METHOD constructor.

    IF io_source_repo IS BOUND.
      mo_source_repo = io_source_repo.
    ELSE.
      mo_source_repo = NEW zcl_mig_source_repo( ).
    ENDIF.

    IF io_scanner IS BOUND.
      mo_scanner = io_scanner.
    ELSE.
      mo_scanner = NEW zcl_mig_abap_scanner( ).
    ENDIF.

  ENDMETHOD.

    METHOD zif_mig_include_resolver~resolve.

    DATA:
      lv_root_program TYPE progname,
      lt_queue        TYPE tt_queue,
      lt_visited      TYPE tt_visited,
      lv_queue_index  TYPE i VALUE 1.

    "----------------------------------------------------------
    " 1. Chuẩn hóa root program
    "----------------------------------------------------------
    lv_root_program = iv_root_program.
    TRANSLATE lv_root_program TO UPPER CASE.

    IF lv_root_program IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>source_not_found
        program_name = lv_root_program
      ).

    ENDIF.

    "----------------------------------------------------------
    " 2. Khởi tạo processing queue
    "----------------------------------------------------------
    APPEND VALUE #(
      object_name   = lv_root_program
      parent_object = ''
      include_depth = 0
      optional      = abap_false
    ) TO lt_queue.

    "----------------------------------------------------------
    " 3. Xử lý queue
    "
    "Không DELETE dòng đầu queue vì DELETE INDEX 1 liên tục
    "sẽ làm dịch chuyển toàn bộ internal table.
    "----------------------------------------------------------
    WHILE lv_queue_index <= lines( lt_queue ).

      READ TABLE lt_queue
        INDEX lv_queue_index
        INTO DATA(ls_queue_entry).

      lv_queue_index += 1.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      "--------------------------------------------------------
      " Source đã xử lý thì bỏ qua
      "--------------------------------------------------------
      READ TABLE lt_visited
        WITH TABLE KEY
          table_line = ls_queue_entry-object_name
        TRANSPORTING NO FIELDS.

      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      "--------------------------------------------------------
      " 4. Đọc source
      "--------------------------------------------------------
      TRY.

          DATA(lt_source) =
            mo_source_repo->read_program(
              iv_program_name = ls_queue_entry-object_name
            ).

        CATCH zcx_mig_analysis INTO DATA(lx_analysis).

          DATA(lv_message_number) =
            lx_analysis->if_t100_message~t100key-msgno.

          "INCLUDE ... IF FOUND:
          "Không tồn tại vẫn được phép bỏ qua.
          IF ls_queue_entry-optional = abap_true
             AND lv_message_number = '001'.

            CONTINUE.

          ENDIF.

          "Root program không tồn tại giữ message 001.
          "Include bắt buộc không tồn tại chuyển thành message 004.
          IF ls_queue_entry-include_depth > 0
             AND lv_message_number = '001'.

            RAISE EXCEPTION NEW zcx_mig_analysis(
              textid       = zcx_mig_analysis=>include_not_found
              previous     = lx_analysis
              program_name = ls_queue_entry-object_name
            ).

          ENDIF.

          RAISE EXCEPTION lx_analysis.

      ENDTRY.

      "--------------------------------------------------------
      " 5. Scan source đúng một lần
      "--------------------------------------------------------
      DATA(ls_scan_result) =
        mo_scanner->scan(
          iv_source_object = ls_queue_entry-object_name
          it_source        = lt_source
        ).

      "Chỉ đánh dấu visited sau khi đọc và scan thành công.
      INSERT ls_queue_entry-object_name
        INTO TABLE lt_visited.

      "--------------------------------------------------------
      " 6. Thêm source unit vào kết quả
      "--------------------------------------------------------
      APPEND VALUE #(
        source_object = VALUE #(
          object_name   = ls_queue_entry-object_name
          object_type   = COND #(
            WHEN ls_queue_entry-include_depth = 0
            THEN 'PROGRAM'
            ELSE 'INCLUDE'
          )
          parent_object = ls_queue_entry-parent_object
          include_depth = ls_queue_entry-include_depth
          source_lines  = lt_source
        )
        scan_result = ls_scan_result
      ) TO rt_source_units.

      "--------------------------------------------------------
      " 7. Tìm include trong source vừa scan và thêm vào queue
      "--------------------------------------------------------
      enqueue_includes(
        EXPORTING
          is_scan_result  = ls_scan_result
          iv_parent_name  = ls_queue_entry-object_name
          iv_parent_depth = ls_queue_entry-include_depth
        CHANGING
          ct_queue        = lt_queue
      ).

    ENDWHILE.

  ENDMETHOD.

    METHOD enqueue_includes.

    DATA:
      ls_first_token TYPE zif_mig_types=>ty_token,
      ls_name_token  TYPE zif_mig_types=>ty_token,
      ls_if_token    TYPE zif_mig_types=>ty_token,
      ls_found_token TYPE zif_mig_types=>ty_token,

      lv_first_text   TYPE string,
      lv_include_name TYPE progname,
      lv_name_index   TYPE i,
      lv_if_index     TYPE i,
      lv_found_index  TYPE i,
      lv_optional     TYPE abap_bool.

    LOOP AT is_scan_result-statements
      ASSIGNING FIELD-SYMBOL(<statement>)
      WHERE statement_type = 'INCLUDE'.

      CLEAR:
        ls_first_token,
        ls_name_token,
        ls_if_token,
        ls_found_token,
        lv_first_text,
        lv_include_name,
        lv_name_index,
        lv_if_index,
        lv_found_index,
        lv_optional.

      "--------------------------------------------------------
      " Token đầu của statement
      "--------------------------------------------------------
      READ TABLE is_scan_result-tokens
        INDEX <statement>-token_from
        INTO ls_first_token.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_first_text =
        to_upper( ls_first_token-token_text ).

      "Thông thường token đầu là INCLUDE.
      IF lv_first_text = 'INCLUDE'.

        lv_name_index =
          <statement>-token_from + 1.

      ELSEIF <statement>-native_type = 'I'
          OR <statement>-native_type = 'J'.

        "Fallback cho khác biệt cách SCAN trả token
        "giữa các release.
        lv_name_index =
          <statement>-token_from.

      ELSE.

        CONTINUE.

      ENDIF.

      "--------------------------------------------------------
      " Đọc tên include
      "--------------------------------------------------------
      READ TABLE is_scan_result-tokens
        INDEX lv_name_index
        INTO ls_name_token.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_name_text) =
        to_upper( ls_name_token-token_text ).

      "Không nhầm INCLUDE TYPE/STRUCTURE với source include
      IF lv_name_text = 'TYPE'
         OR lv_name_text = 'STRUCTURE'.

        CONTINUE.

      ENDIF.

      lv_include_name =
        CONV progname( lv_name_text ).

      IF lv_include_name IS INITIAL.
        CONTINUE.
      ENDIF.

      "--------------------------------------------------------
      " Phát hiện addition IF FOUND
      "--------------------------------------------------------
      lv_if_index    = lv_name_index + 1.
      lv_found_index = lv_name_index + 2.

      READ TABLE is_scan_result-tokens
        INDEX lv_if_index
        INTO ls_if_token.

      READ TABLE is_scan_result-tokens
        INDEX lv_found_index
        INTO ls_found_token.

      IF to_upper( ls_if_token-token_text ) = 'IF'
         AND to_upper( ls_found_token-token_text ) = 'FOUND'.

        lv_optional = abap_true.

      ENDIF.

      "--------------------------------------------------------
      " Đưa include vào processing queue
      "--------------------------------------------------------
      APPEND VALUE #(
        object_name   = lv_include_name
        parent_object = iv_parent_name
        include_depth = iv_parent_depth + 1
        optional      = lv_optional
      ) TO ct_queue.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
