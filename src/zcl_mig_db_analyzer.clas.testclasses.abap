CLASS ltc_db_analyzer DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      get_result
        RETURNING
          VALUE(rs_result)
            TYPE zif_mig_types=>ty_db_analysis_result
        RAISING
          zcx_mig_analysis,

      detect_all_operations
        FOR TESTING
        RAISING zcx_mig_analysis,

      parse_select
        FOR TESTING
        RAISING zcx_mig_analysis,

      parse_aggregation
        FOR TESTING
        RAISING zcx_mig_analysis,

      parse_update
        FOR TESTING
        RAISING zcx_mig_analysis,

      classify_paging
        FOR TESTING
        RAISING zcx_mig_analysis,

      create_evidence
        FOR TESTING
        RAISING zcx_mig_analysis.

        METHODS:
  get_mixed_operation_result
    RETURNING
      VALUE(rs_result)
        TYPE zif_mig_types=>ty_db_analysis_result
    RAISING
      zcx_mig_analysis,

  ignore_internal_table
    FOR TESTING
    RAISING
      zcx_mig_analysis.

ENDCLASS.

CLASS ltc_db_analyzer IMPLEMENTATION.

  METHOD get_result.

    DATA(lo_source_repo) =
      NEW zcl_mig_source_repo( ).

    DATA(lo_scanner) =
      NEW zcl_mig_abap_scanner( ).

    DATA(lo_normalizer) =
      NEW zcl_mig_stmt_normalizer( ).

    DATA(lo_analyzer) =
      NEW zcl_mig_db_analyzer( ).

    DATA(lt_source) =
      lo_source_repo->zif_mig_source_repo~read_program(
        iv_program_name =
          'ZRMIG_SAMPLE_DB'
      ).

    DATA(ls_scan_result) =
      lo_scanner->zif_mig_abap_scanner~scan(
        iv_source_object =
          'ZRMIG_SAMPLE_DB'
        it_source =
          lt_source
      ).

    DATA(ls_normalized) =
      lo_normalizer->zif_mig_stmt_normalizer~normalize(
        is_scan_result =
          ls_scan_result
      ).

    DATA lt_source_units
      TYPE zif_mig_types=>tt_source_unit.

    APPEND VALUE #(
      source_object = VALUE #(
        object_name  = 'ZRMIG_SAMPLE_DB'
        object_type  = 'PROGRAM'
        source_lines = lt_source
      )
      scan_result = ls_normalized
    ) TO lt_source_units.

    rs_result =
      lo_analyzer->zif_mig_db_analyzer~analyze(
        it_source_units =
          lt_source_units
      ).

  ENDMETHOD.

    METHOD detect_all_operations.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 6
      act = lines( ls_result-database_objects )
      msg = 'Phải phát hiện 6 database statements'
    ).

  ENDMETHOD.


  METHOD parse_select.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-database_objects
      WITH KEY
        operation   = 'SELECT'
        object_name = 'ZTMIG_SAMPLE_DB'
      INTO DATA(ls_select).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện SELECT ZTMIG_SAMPLE_DB'
    ).

    cl_abap_unit_assert=>assert_true(
      act = ls_select-read_only
    ).

    cl_abap_unit_assert=>assert_char_cp(
      act = to_upper( ls_select-selected_fields )
      exp = '*ITEM_ID*DESCRIPTION*STATUS*'
      msg = 'Không đọc đúng danh sách SELECT fields'
    ).

    cl_abap_unit_assert=>assert_char_cp(
      act = to_upper( ls_select-where_fields )
      exp = '*STATUS*P_STATUS*'
      msg = 'Không đọc đúng WHERE condition'
    ).

  ENDMETHOD.


  METHOD parse_aggregation.

    DATA(ls_result) = get_result( ).

    DATA lv_found TYPE abap_bool.

    LOOP AT ls_result-database_objects
      INTO DATA(ls_object)
      WHERE operation = 'SELECT'.

      IF ls_object-aggregation CS 'COUNT'.

        lv_found = abap_true.
        EXIT.

      ENDIF.

    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
      act = lv_found
      msg = 'Không phát hiện COUNT aggregation'
    ).

  ENDMETHOD.


  METHOD parse_update.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-database_objects
      WITH KEY operation = 'UPDATE'
      INTO DATA(ls_update).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không phát hiện UPDATE'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZTMIG_SAMPLE_DB'
      act = ls_update-object_name
    ).

    cl_abap_unit_assert=>assert_false(
      act = ls_update-read_only
    ).

  ENDMETHOD.


  METHOD classify_paging.

    DATA(ls_result) = get_result( ).

    READ TABLE ls_result-database_objects
      WITH KEY operation = 'SELECT'
      INTO DATA(ls_select).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'DB_PUSHDOWN'
      act = ls_select-paging_capability
      msg = 'Static SELECT phải hỗ trợ paging pushdown'
    ).

  ENDMETHOD.


  METHOD create_evidence.

    DATA(ls_result) = get_result( ).

    cl_abap_unit_assert=>assert_equals(
      exp = lines( ls_result-database_objects )
      act = lines( ls_result-evidences )
      msg = 'Mỗi database fact phải có evidence'
    ).

    LOOP AT ls_result-evidences
      ASSIGNING FIELD-SYMBOL(<evidence>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <evidence>-evidence_id
      ).

      cl_abap_unit_assert=>assert_equals(
        exp = 'ZRMIG_SAMPLE_DB'
        act = <evidence>-source_object
      ).

      cl_abap_unit_assert=>assert_true(
        act = xsdbool(
          <evidence>-start_line > 0
        )
      ).

    ENDLOOP.

  ENDMETHOD.

METHOD get_mixed_operation_result.

  CONSTANTS gc_program TYPE progname
    VALUE 'ZRMIG_UT_DB_KIND'.

  DATA lt_source
    TYPE zif_mig_types=>tt_source_line.

  lt_source = VALUE #(
    (
      source_object = gc_program
      line_number   = 1
      source_text   = `REPORT zrmig_ut_db_kind.`
    )
    (
      source_object = gc_program
      line_number   = 2
      source_text   = `DATA lt_data TYPE STANDARD TABLE OF t001.`
    )
    (
      source_object = gc_program
      line_number   = 3
      source_text   = `DATA ls_data TYPE t001.`
    )
    (
      source_object = gc_program
      line_number   = 4
      source_text   = `INSERT ls_data INTO TABLE lt_data.`
    )
    (
      source_object = gc_program
      line_number   = 5
      source_text   = `MODIFY TABLE lt_data FROM ls_data.`
    )
    (
      source_object = gc_program
      line_number   = 6
      source_text   = `DELETE TABLE lt_data FROM ls_data.`
    )
    (
      source_object = gc_program
      line_number   = 7
      source_text   = `DELETE lt_data WHERE bukrs IS INITIAL.`
    )
    (
      source_object = gc_program
      line_number   = 8
      source_text   = `SELECT bukrs FROM t001 INTO TABLE @lt_data.`
    )
    (
      source_object = gc_program
      line_number   = 9
      source_text   = `UPDATE t001 SET butxt = @ls_data-butxt WHERE bukrs = @ls_data-bukrs.`
    )
    (
      source_object = gc_program
      line_number   = 10
      source_text   = `DELETE FROM t001 WHERE bukrs = @ls_data-bukrs.`
    )
  ).

  DATA(lo_scanner) =
    NEW zcl_mig_abap_scanner( ).

  DATA(ls_scan_result) =
    lo_scanner->zif_mig_abap_scanner~scan(
      iv_source_object = gc_program
      it_source        = lt_source
    ).

  DATA(lo_normalizer) =
    NEW zcl_mig_stmt_normalizer( ).

  DATA(ls_normalized) =
    lo_normalizer->zif_mig_stmt_normalizer~normalize(
      is_scan_result = ls_scan_result
    ).

  DATA lt_source_units
    TYPE zif_mig_types=>tt_source_unit.

  APPEND VALUE #(
    source_object = VALUE #(
      object_name  = gc_program
      object_type  = 'PROGRAM'
      source_lines = lt_source
    )
    scan_result = ls_normalized
  ) TO lt_source_units.

  DATA(lo_analyzer) =
    NEW zcl_mig_db_analyzer( ).

  rs_result =
    lo_analyzer->zif_mig_db_analyzer~analyze(
      it_source_units = lt_source_units
    ).

ENDMETHOD.

METHOD ignore_internal_table.

  DATA(ls_result) =
    get_mixed_operation_result( ).

  "Chỉ ba Open SQL statements
  cl_abap_unit_assert=>assert_equals(
    exp = 3
    act = lines( ls_result-database_objects )
    msg = 'Internal-table operations bị nhận nhầm thành DB access'
  ).

  READ TABLE ls_result-database_objects
    WITH KEY
      operation   = 'SELECT'
      object_name = 'T001'
    TRANSPORTING NO FIELDS.

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện SELECT T001'
  ).

  READ TABLE ls_result-database_objects
    WITH KEY
      operation   = 'UPDATE'
      object_name = 'T001'
    TRANSPORTING NO FIELDS.

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện UPDATE T001'
  ).

  READ TABLE ls_result-database_objects
    WITH KEY
      operation   = 'DELETE'
      object_name = 'T001'
    TRANSPORTING NO FIELDS.

  cl_abap_unit_assert=>assert_subrc(
    exp = 0
    msg = 'Không phát hiện DELETE FROM T001'
  ).

  LOOP AT ls_result-database_objects
    INTO DATA(ls_object).

    cl_abap_unit_assert=>assert_differs(
      exp = 'LT_DATA'
      act = ls_object-object_name
      msg = 'LT_DATA không được tạo thành Database Object'
    ).

    cl_abap_unit_assert=>assert_differs(
      exp = 'LS_DATA'
      act = ls_object-object_name
      msg = 'LS_DATA không được tạo thành Database Object'
    ).

  ENDLOOP.

ENDMETHOD.


ENDCLASS.
