CLASS ltc_include_resolver DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_cut TYPE REF TO zif_mig_include_resolver.

    METHODS:
      setup,

      resolve_complete_tree
        FOR TESTING
        RAISING zcx_mig_analysis,

      preserve_parent_and_depth
        FOR TESTING
        RAISING zcx_mig_analysis,

      scan_every_source_unit
        FOR TESTING
        RAISING zcx_mig_analysis,

      avoid_duplicate_objects
        FOR TESTING
        RAISING zcx_mig_analysis,

      normalize_root_name
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_include_resolver IMPLEMENTATION.

  METHOD setup.

    mo_cut =
      NEW zcl_mig_include_resolver( ).

  ENDMETHOD.


  METHOD resolve_complete_tree.

    DATA(lt_units) =
      mo_cut->resolve(
        iv_root_program = 'ZRMIG_SAMPLE_INC_ROOT'
      ).

    "Root + TOP + F01 + SUB
    "Optional missing include không được trả về
    cl_abap_unit_assert=>assert_equals(
      exp = 4
      act = lines( lt_units )
      msg = 'Include resolver không trả đúng source tree'
    ).

  ENDMETHOD.


  METHOD preserve_parent_and_depth.

    DATA(lt_units) =
      mo_cut->resolve(
        iv_root_program = 'ZRMIG_SAMPLE_INC_ROOT'
      ).

    DATA:
      lv_root_found TYPE abap_bool,
      lv_top_found  TYPE abap_bool,
      lv_f01_found  TYPE abap_bool,
      lv_sub_found  TYPE abap_bool.

    LOOP AT lt_units
      ASSIGNING FIELD-SYMBOL(<unit>).

      CASE <unit>-source_object-object_name.

        WHEN 'ZRMIG_SAMPLE_INC_ROOT'.

          lv_root_found = abap_true.

          cl_abap_unit_assert=>assert_equals(
            exp = 0
            act = <unit>-source_object-include_depth
            msg = 'Root program phải có depth 0'
          ).

          cl_abap_unit_assert=>assert_initial(
            act = <unit>-source_object-parent_object
            msg = 'Root program không được có parent'
          ).

        WHEN 'ZRMIG_SAMPLE_INC_TOP'.

          lv_top_found = abap_true.

          cl_abap_unit_assert=>assert_equals(
            exp = 1
            act = <unit>-source_object-include_depth
            msg = 'TOP include phải có depth 1'
          ).

          cl_abap_unit_assert=>assert_equals(
            exp = 'ZRMIG_SAMPLE_INC_ROOT'
            act = <unit>-source_object-parent_object
            msg = 'TOP include có sai parent'
          ).

        WHEN 'ZRMIG_SAMPLE_INC_F01'.

          lv_f01_found = abap_true.

          cl_abap_unit_assert=>assert_equals(
            exp = 1
            act = <unit>-source_object-include_depth
            msg = 'F01 include phải có depth 1'
          ).

          cl_abap_unit_assert=>assert_equals(
            exp = 'ZRMIG_SAMPLE_INC_ROOT'
            act = <unit>-source_object-parent_object
            msg = 'F01 include có sai parent'
          ).

        WHEN 'ZRMIG_SAMPLE_INC_SUB'.

          lv_sub_found = abap_true.

          cl_abap_unit_assert=>assert_equals(
            exp = 2
            act = <unit>-source_object-include_depth
            msg = 'SUB include phải có depth 2'
          ).

          cl_abap_unit_assert=>assert_equals(
            exp = 'ZRMIG_SAMPLE_INC_F01'
            act = <unit>-source_object-parent_object
            msg = 'SUB include có sai parent'
          ).

      ENDCASE.

    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
      act = lv_root_found
      msg = 'Không tìm thấy root program'
    ).

    cl_abap_unit_assert=>assert_true(
      act = lv_top_found
      msg = 'Không tìm thấy TOP include'
    ).

    cl_abap_unit_assert=>assert_true(
      act = lv_f01_found
      msg = 'Không tìm thấy F01 include'
    ).

    cl_abap_unit_assert=>assert_true(
      act = lv_sub_found
      msg = 'Không tìm thấy nested SUB include'
    ).

  ENDMETHOD.


  METHOD scan_every_source_unit.

    DATA(lt_units) =
      mo_cut->resolve(
        iv_root_program = 'ZRMIG_SAMPLE_INC_ROOT'
      ).

    LOOP AT lt_units
      ASSIGNING FIELD-SYMBOL(<unit>).

      cl_abap_unit_assert=>assert_not_initial(
        act = <unit>-source_object-source_lines
        msg = |Không có source: {
          <unit>-source_object-object_name }|
      ).

      cl_abap_unit_assert=>assert_not_initial(
        act = <unit>-scan_result-tokens
        msg = |Không có token: {
          <unit>-source_object-object_name }|
      ).

      cl_abap_unit_assert=>assert_not_initial(
        act = <unit>-scan_result-statements
        msg = |Không có statement: {
          <unit>-source_object-object_name }|
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD avoid_duplicate_objects.

    DATA(lt_units) =
      mo_cut->resolve(
        iv_root_program = 'ZRMIG_SAMPLE_INC_ROOT'
      ).

    DATA lt_names TYPE HASHED TABLE OF progname
      WITH UNIQUE KEY table_line.

    LOOP AT lt_units
      ASSIGNING FIELD-SYMBOL(<unit>).

      INSERT <unit>-source_object-object_name
        INTO TABLE lt_names.

      cl_abap_unit_assert=>assert_subrc(
        exp = 0
        msg = |Source object bị resolve trùng: {
          <unit>-source_object-object_name }|
      ).

    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      exp = lines( lt_units )
      act = lines( lt_names )
      msg = 'Source tree chứa object trùng'
    ).

  ENDMETHOD.


  METHOD normalize_root_name.

    DATA(lt_units) =
      mo_cut->resolve(
        iv_root_program = 'zrmig_sample_inc_root'
      ).

    READ TABLE lt_units
      INDEX 1
      INTO DATA(ls_root_unit).

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      msg = 'Không trả root source unit'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZRMIG_SAMPLE_INC_ROOT'
      act = ls_root_unit-source_object-object_name
      msg = 'Root program chưa được chuẩn hóa'
    ).

  ENDMETHOD.

ENDCLASS.
