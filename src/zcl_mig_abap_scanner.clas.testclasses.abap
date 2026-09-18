CLASS ltc_abap_scanner DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA:
      mo_source_repo TYPE REF TO zif_mig_source_repo,
      mo_cut         TYPE REF TO zif_mig_abap_scanner.

    METHODS:
      setup,

      scan_existing_program
        FOR TESTING
        RAISING zcx_mig_analysis,

      find_report_statement
        FOR TESTING
        RAISING zcx_mig_analysis,

      find_parameters_statement
        FOR TESTING
        RAISING zcx_mig_analysis,

      preserve_token_position
        FOR TESTING
        RAISING zcx_mig_analysis,

      accept_empty_source
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_abap_scanner IMPLEMENTATION.

  METHOD setup.

    mo_source_repo =
      NEW zcl_mig_source_repo( ).

    mo_cut =
      NEW zcl_mig_abap_scanner( ).

  ENDMETHOD.


  METHOD scan_existing_program.

    DATA(lt_source) =
      mo_source_repo->read_program(
        iv_program_name = 'ZRMIG_SAMPLE_BASIC'
      ).

    DATA(ls_scan_result) =
      mo_cut->scan(
        iv_source_object = 'ZRMIG_SAMPLE_BASIC'
        it_source        = lt_source
      ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_scan_result-tokens
      msg = 'Scanner không trả về token'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_scan_result-statements
      msg = 'Scanner không trả về statement'
    ).

  ENDMETHOD.


  METHOD find_report_statement.

    DATA(lt_source) =
      mo_source_repo->read_program(
        iv_program_name = 'ZRMIG_SAMPLE_BASIC'
      ).

    DATA(ls_scan_result) =
      mo_cut->scan(
        iv_source_object = 'ZRMIG_SAMPLE_BASIC'
        it_source        = lt_source
      ).

    READ TABLE ls_scan_result-statements
      WITH KEY statement_type = 'REPORT'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện REPORT statement'
    ).

  ENDMETHOD.


  METHOD find_parameters_statement.

    DATA(lt_source) =
      mo_source_repo->read_program(
        iv_program_name = 'ZRMIG_SAMPLE_BASIC'
      ).

    DATA(ls_scan_result) =
      mo_cut->scan(
        iv_source_object = 'ZRMIG_SAMPLE_BASIC'
        it_source        = lt_source
      ).

    READ TABLE ls_scan_result-statements
      WITH KEY statement_type = 'PARAMETERS'
      TRANSPORTING NO FIELDS.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện PARAMETERS statement'
    ).

  ENDMETHOD.


  METHOD preserve_token_position.

    DATA(lt_source) =
      mo_source_repo->read_program(
        iv_program_name = 'ZRMIG_SAMPLE_BASIC'
      ).

    DATA(ls_scan_result) =
      mo_cut->scan(
        iv_source_object = 'ZRMIG_SAMPLE_BASIC'
        it_source        = lt_source
      ).

    READ TABLE ls_scan_result-tokens
      WITH KEY token_text = 'REPORT'
      INTO DATA(ls_report_token).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy REPORT token'
    ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool(
        ls_report_token-source_line > 0
      )
      msg = 'Token không giữ source line'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_BASIC'
      act = ls_report_token-source_object
      msg = 'Token không giữ đúng source object'
    ).

  ENDMETHOD.


  METHOD accept_empty_source.

    DATA lt_empty_source
      TYPE zif_mig_types=>tt_source_line.

    DATA(ls_scan_result) =
      mo_cut->scan(
        iv_source_object = 'ZRMIG_EMPTY_INCLUDE'
        it_source        = lt_empty_source
      ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_scan_result-tokens
      msg = 'Empty source không được sinh token'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_scan_result-statements
      msg = 'Empty source không được sinh statement'
    ).

  ENDMETHOD.

ENDCLASS.
