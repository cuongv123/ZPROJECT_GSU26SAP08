CLASS ltc_stmt_normalizer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA:
      mo_source_repo TYPE REF TO zif_mig_source_repo,
      mo_scanner     TYPE REF TO zif_mig_abap_scanner,
      mo_cut         TYPE REF TO zif_mig_stmt_normalizer.

    METHODS:
      setup,

      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_scan_result
        RAISING
          zcx_mig_analysis,

      rebuild_statement_text
        FOR TESTING
        RAISING zcx_mig_analysis,

      normalize_chained_parameters
        FOR TESTING
        RAISING zcx_mig_analysis,

      assign_form_context
        FOR TESTING
        RAISING zcx_mig_analysis,

      assign_nested_block_context
        FOR TESTING
        RAISING zcx_mig_analysis,

      clear_form_context
        FOR TESTING
        RAISING zcx_mig_analysis,
      avoid_duplicate_chain_prefix
          FOR TESTING
          RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_stmt_normalizer IMPLEMENTATION.

  METHOD setup.

    mo_source_repo =
      NEW zcl_mig_source_repo( ).

    mo_scanner =
      NEW zcl_mig_abap_scanner( ).

    mo_cut =
      NEW zcl_mig_stmt_normalizer( ).

  ENDMETHOD.


  METHOD get_result.

    DATA(lt_source) =
      mo_source_repo->read_program(
        iv_program_name = 'ZRMIG_SAMPLE_CONTEXT'
      ).

    DATA(ls_scan_result) =
      mo_scanner->scan(
        iv_source_object = 'ZRMIG_SAMPLE_CONTEXT'
        it_source        = lt_source
      ).

    rs_result =
      mo_cut->normalize(
        is_scan_result = ls_scan_result
      ).

  ENDMETHOD.


  METHOD rebuild_statement_text.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-statements
      WITH KEY statement_type = 'REPORT'
      INTO DATA(ls_report).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy REPORT statement'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_report-statement_text
      msg = 'REPORT statement chưa được dựng text'
    ).

    cl_abap_unit_assert=>assert_char_cp(
      act = to_upper( ls_report-statement_text )
      exp = '*ZRMIG_SAMPLE_CONTEXT*'
      msg = 'REPORT statement không chứa program name'
    ).

  ENDMETHOD.


  METHOD normalize_chained_parameters.

    DATA(ls_result) = get_result( ).

    DATA:
      lv_parameter_count TYPE i,
      lv_p_one_found     TYPE abap_bool,
      lv_p_two_found     TYPE abap_bool.

    LOOP AT ls_result-statements
      ASSIGNING FIELD-SYMBOL(<statement>)
      WHERE statement_type = 'PARAMETERS'.

      lv_parameter_count += 1.

      DATA(lv_statement_text) =
        to_upper( <statement>-statement_text ).

      IF lv_statement_text CS 'P_ONE'.
        lv_p_one_found = abap_true.
      ENDIF.

      IF lv_statement_text CS 'P_TWO'.
        lv_p_two_found = abap_true.
      ENDIF.

    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lv_parameter_count
      msg = 'Chained PARAMETERS phải tạo hai logical statements'
    ).

    cl_abap_unit_assert=>assert_true(
      act = lv_p_one_found
      msg = 'Không dựng được logical statement cho P_ONE'
    ).

    cl_abap_unit_assert=>assert_true(
      act = lv_p_two_found
      msg = 'Không dựng được logical statement cho P_TWO'
    ).

  ENDMETHOD.


  METHOD assign_form_context.

    DATA(ls_result) = get_result( ).

    DATA:
      lv_found   TYPE abap_bool,
      ls_target  TYPE zif_mig_types=>ty_statement.

    LOOP AT ls_result-statements
      INTO DATA(ls_statement)
      WHERE statement_type = 'WRITE'.

      IF to_upper( ls_statement-statement_text )
           CS 'LV_TEXT'.

        ls_target = ls_statement.
        lv_found  = abap_true.
        EXIT.

      ENDIF.

    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
      act = lv_found
      msg = 'Không tìm thấy WRITE trong FORM'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'READ_DATA'
      act = ls_target-parent_routine
      msg = 'WRITE không được gắn vào FORM READ_DATA'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'FORM'
      act = ls_target-routine_type
      msg = 'Routine type phải là FORM'
    ).

  ENDMETHOD.


  METHOD assign_nested_block_context.

    DATA(ls_result) = get_result( ).

    DATA:
      lv_found  TYPE abap_bool,
      ls_target TYPE zif_mig_types=>ty_statement.

    LOOP AT ls_result-statements
      INTO DATA(ls_statement)
      WHERE statement_type = 'WRITE'.

      IF to_upper( ls_statement-statement_text )
           CS 'LV_TEXT'.

        ls_target = ls_statement.
        lv_found  = abap_true.
        EXIT.

      ENDIF.

    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
      act = lv_found
      msg = 'Không tìm thấy WRITE trong nested block'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'LOOP'
      act = ls_target-parent_block
      msg = 'Block gần nhất của WRITE phải là LOOP'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = ls_target-block_depth
      msg = 'WRITE phải nằm trong IF và LOOP'
    ).

  ENDMETHOD.


  METHOD clear_form_context.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-statements
      WITH KEY statement_type = 'PERFORM'
      INTO DATA(ls_perform).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không tìm thấy PERFORM statement'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'START-OF-SELECTION'
      act = ls_perform-parent_routine
      msg = 'Context FORM chưa được clear sau ENDFORM'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'EVENT'
      act = ls_perform-routine_type
      msg = 'PERFORM phải thuộc START-OF-SELECTION event'
    ).

  ENDMETHOD.

  METHOD avoid_duplicate_chain_prefix.

  DATA(ls_result) = get_result( ).

  LOOP AT ls_result-statements
    ASSIGNING FIELD-SYMBOL(<statement>)
    WHERE statement_type = 'PARAMETERS'.

    DATA(lv_text) =
      to_upper( <statement>-statement_text ).

    cl_abap_unit_assert=>assert_false(
      act = xsdbool(
        lv_text CS 'PARAMETERS PARAMETERS'
      )
      msg = |Prefix PARAMETERS bị lặp: {
        <statement>-statement_text }|
    ).

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
