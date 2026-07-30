CLASS zcl_mig_source_repo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_source_repo.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_cache_entry,
        program_name TYPE progname,
        source       TYPE zif_mig_types=>tt_source_line,
      END OF ty_cache_entry,

      tt_cache TYPE HASHED TABLE OF ty_cache_entry
        WITH UNIQUE KEY program_name.

    DATA mt_cache TYPE tt_cache.

ENDCLASS.

CLASS zcl_mig_source_repo IMPLEMENTATION.

  METHOD zif_mig_source_repo~read_program.

    DATA:
      lv_program_name TYPE progname,
      lt_raw_source   TYPE STANDARD TABLE OF string
        WITH EMPTY KEY.

    "----------------------------------------------------------
    " 1. Chuẩn hóa tên chương trình
    "----------------------------------------------------------
    lv_program_name = iv_program_name.
    TRANSLATE lv_program_name TO UPPER CASE.

    IF lv_program_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>source_not_found
        program_name = lv_program_name
      ).

    ENDIF.

    "----------------------------------------------------------
    " 2. Kiểm tra source cache
    "----------------------------------------------------------
    READ TABLE mt_cache
      WITH TABLE KEY program_name = lv_program_name
      INTO DATA(ls_cache).

    IF sy-subrc = 0.
      rt_source = ls_cache-source.
      RETURN.
    ENDIF.

    "----------------------------------------------------------
    " 3. Đọc active source từ ABAP Repository
    "----------------------------------------------------------
    READ REPORT lv_program_name
      INTO lt_raw_source
      STATE 'A'.

    CASE sy-subrc.

      WHEN 0.
        "Đọc thành công

      WHEN 4.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid       = zcx_mig_analysis=>source_not_found
          program_name = lv_program_name
        ).

      WHEN OTHERS.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid       = zcx_mig_analysis=>source_read_failed
          program_name = lv_program_name
        ).

    ENDCASE.

    "----------------------------------------------------------
    " 4. Chuyển raw source thành Source Contract
    "----------------------------------------------------------
    LOOP AT lt_raw_source INTO DATA(lv_source_text).

      DATA(lv_line_number) = sy-tabix.

      APPEND VALUE #(
        source_object = lv_program_name
        line_number   = lv_line_number
        source_text   = lv_source_text
      ) TO rt_source.

    ENDLOOP.

    "----------------------------------------------------------
    " 5. Cache source trong vòng đời của repository instance
    "----------------------------------------------------------
    INSERT VALUE #(
      program_name = lv_program_name
      source       = rt_source
    ) INTO TABLE mt_cache.

  ENDMETHOD.

ENDCLASS.
