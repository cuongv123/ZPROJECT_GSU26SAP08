CLASS ltc_row_repo DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      read_table_type
        FOR TESTING
        RAISING zcx_mig_analysis,

      read_struct_type
        FOR TESTING
        RAISING zcx_mig_analysis,

      read_abs_type
        FOR TESTING
        RAISING zcx_mig_analysis,

      read_scalar_type
        FOR TESTING
        RAISING zcx_mig_analysis,

      missing_type
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_row_repo IMPLEMENTATION.

  METHOD read_table_type.

    DATA(ls_row) =
      NEW zcl_mig_row_repo(
        )->zif_mig_row_repo~read_type(
          iv_type = 'BAPIRET2_T'
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_row-exists
      msg = 'BAPIRET2_T must exist'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_row-structured
      msg = 'Table line must be structured'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_row-line_name
      msg = 'Line type name is empty'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_row-components
      msg = 'Row components are empty'
    ).


    READ TABLE ls_row-components
      WITH KEY comp_name = 'TYPE'
      INTO DATA(ls_type).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'TYPE component not found'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Edm.String'
      act = ls_type-edm_type
      msg = 'TYPE must map to Edm.String'
    ).

  ENDMETHOD.


  METHOD read_struct_type.

    DATA(ls_row) =
      NEW zcl_mig_row_repo(
        )->zif_mig_row_repo~read_type(
          iv_type = 'BAPIRET2'
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_row-exists
      msg = 'BAPIRET2 must exist'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_row-structured
      msg = 'BAPIRET2 must be structured'
    ).


    READ TABLE ls_row-components
      WITH KEY comp_name = 'MESSAGE'
      INTO DATA(ls_message).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'MESSAGE component not found'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Edm.String'
      act = ls_message-edm_type
      msg = 'MESSAGE must map to string'
    ).

  ENDMETHOD.


  METHOD read_abs_type.

    DATA(ls_row) =
      NEW zcl_mig_row_repo(
        )->zif_mig_row_repo~read_type(
          iv_type = '\TYPE=BAPIRET2_T'
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_row-exists
      msg = 'Absolute table type must resolve'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_row-structured
      msg = 'Absolute line type must be structured'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_row-components
      msg = 'Absolute type has no components'
    ).

  ENDMETHOD.


  METHOD read_scalar_type.

    DATA(ls_row) =
      NEW zcl_mig_row_repo(
        )->zif_mig_row_repo~read_type(
          iv_type = 'CHAR1'
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_row-exists
      msg = 'CHAR1 must exist'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_row-structured
      msg = 'CHAR1 must not be structured'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_row-components
      msg = 'Scalar type must have no components'
    ).

  ENDMETHOD.


  METHOD missing_type.

    DATA(ls_row) =
      NEW zcl_mig_row_repo(
        )->zif_mig_row_repo~read_type(
          iv_type = 'Z_MIG_TYPE_NOT_EXIST'
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_row-exists
      msg = 'Unknown type must not exist'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_row-components
      msg = 'Unknown type has components'
    ).

  ENDMETHOD.

ENDCLASS.
