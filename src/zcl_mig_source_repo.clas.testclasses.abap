CLASS ltc_source_repo DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_cut TYPE REF TO zif_mig_source_repo.

    METHODS:
      setup,

      read_existing_program
        FOR TESTING
        RAISING zcx_mig_analysis,

      preserve_line_numbers
        FOR TESTING
        RAISING zcx_mig_analysis,

      normalize_program_name
        FOR TESTING
        RAISING zcx_mig_analysis,

      reject_missing_program
        FOR TESTING.

ENDCLASS.

CLASS ltc_source_repo IMPLEMENTATION.

  METHOD setup.

    mo_cut = NEW zcl_mig_source_repo( ).

  ENDMETHOD.


  METHOD read_existing_program.

    DATA(lt_source) =
      mo_cut->read_program(
        iv_program_name = 'ZRMIG_SAMPLE_BASIC'
      ).

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_source
      msg = 'Source của report mẫu không được trả về'
    ).

    DATA(lv_report_statement_found) = abap_false.

    LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<source_line>).

      DATA(lv_upper_source) =
        to_upper( <source_line>-source_text ).

      IF lv_upper_source CS 'REPORT ZRMIG_SAMPLE_BASIC'.
        lv_report_statement_found = abap_true.
        EXIT.
      ENDIF.

    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
      act = lv_report_statement_found
      msg = 'Không tìm thấy REPORT statement trong source'
    ).

  ENDMETHOD.


  METHOD preserve_line_numbers.

    DATA(lt_source) =
      mo_cut->read_program(
        iv_program_name = 'ZRMIG_SAMPLE_BASIC'
      ).

    DATA(lv_expected_line) = 0.

    LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<source_line>).

      lv_expected_line += 1.

      cl_abap_unit_assert=>assert_equals(
        exp = lv_expected_line
        act = <source_line>-line_number
        msg = |Sai line number tại dòng { lv_expected_line }|
      ).

      cl_abap_unit_assert=>assert_equals(
        exp = 'ZRMIG_SAMPLE_BASIC'
        act = <source_line>-source_object
        msg = |Sai source object tại dòng { lv_expected_line }|
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD normalize_program_name.

    DATA(lt_source) =
      mo_cut->read_program(
        iv_program_name = 'zrmig_sample_basic'
      ).

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_source
      msg = 'Tên chương trình chữ thường không được xử lý'
    ).

    READ TABLE lt_source INDEX 1
      INTO DATA(ls_first_line).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không đọc được dòng source đầu tiên'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_BASIC'
      act = ls_first_line-source_object
      msg = 'Tên source object chưa được chuẩn hóa thành chữ hoa'
    ).

  ENDMETHOD.


  METHOD reject_missing_program.

    TRY.

        mo_cut->read_program(
          iv_program_name = 'ZRMIG_NOT_EXISTING'
        ).

        cl_abap_unit_assert=>fail(
          msg = 'Phải phát sinh exception khi program không tồn tại'
        ).

      CATCH zcx_mig_analysis INTO DATA(lx_analysis).

        cl_abap_unit_assert=>assert_equals(
          exp = 'ZRMIG_NOT_EXISTING'
          act = lx_analysis->program_name
          msg = 'Exception không chứa đúng program name'
        ).

        cl_abap_unit_assert=>assert_equals(
          exp = '001'
          act = lx_analysis->if_t100_message~t100key-msgno
          msg = 'Phải trả message SOURCE_NOT_FOUND'
        ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
