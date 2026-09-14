CLASS ltc_analysis_reader DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA go_osql
      TYPE REF TO if_osql_test_environment.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS read_call_bindings
      FOR TESTING
      RAISING zcx_mig_analysis.

ENDCLASS.



CLASS ltc_analysis_reader IMPLEMENTATION.


  METHOD class_setup.

    go_osql =
      cl_osql_test_environment=>create(
        i_dependency_list =
          VALUE #(
            ( 'ZMIG_ANL_H'    )
            ( 'ZMIG_ANL_SRC'  )
            ( 'ZMIG_ANL_UI'   )
            ( 'ZMIG_ANL_DB'   )
            ( 'ZMIG_ANL_LOG'  )
            ( 'ZMIG_ANL_BIND' )
            ( 'ZMIG_ANL_ALV'  )
            ( 'ZMIG_ANL_COL'  )
            ( 'ZMIG_ANL_SRT'  )
            ( 'ZMIG_ANL_FLT'  )
            ( 'ZMIG_ANL_EVT'  )
            ( 'ZMIG_ANL_EVD'  )
            ( 'ZMIG_ANL_REC'  )
            ( 'ZMIG_ANL_ANN'  )
            ( 'ZMIG_ANL_MSG'  )
          )
      ).

  ENDMETHOD.


  METHOD class_teardown.

    go_osql->destroy( ).

  ENDMETHOD.



  METHOD read_call_bindings.

    DATA(lv_analysis_id) =
      cl_system_uuid=>create_uuid_x16_static( ).

    DATA(lv_logic_id) =
      cl_system_uuid=>create_uuid_x16_static( ).

    DATA(lv_binding_id) =
      cl_system_uuid=>create_uuid_x16_static( ).

    DATA(lv_evidence_id) =
      cl_system_uuid=>create_uuid_x16_static( ).


    "==========================================================
    " Header
    "==========================================================
    DATA lt_header
      TYPE STANDARD TABLE OF zmig_anl_h
      WITH EMPTY KEY.

    APPEND INITIAL LINE
      TO lt_header
      ASSIGNING FIELD-SYMBOL(<header>).

    <header>-analysis_id =
      lv_analysis_id.

    <header>-program_name =
      'ZRMIG_UT_READER_BIND'.


    go_osql->insert_test_data(
      lt_header
    ).


    "==========================================================
    " Business Logic parent
    "==========================================================
    DATA lt_logic
      TYPE STANDARD TABLE OF zmig_anl_log
      WITH EMPTY KEY.

    APPEND INITIAL LINE
      TO lt_logic
      ASSIGNING FIELD-SYMBOL(<logic>).

    <logic>-analysis_id =
      lv_analysis_id.

    <logic>-item_id =
      lv_logic_id.

    <logic>-evidence_id =
      lv_evidence_id.

    <logic>-object_type =
      'BAPI'.

    <logic>-object_name =
      'BAPI_USER_GET_DETAIL'.


    go_osql->insert_test_data(
      lt_logic
    ).


    "==========================================================
    " Binding child
    "==========================================================
    DATA lt_binding
      TYPE STANDARD TABLE OF zmig_anl_bind
      WITH EMPTY KEY.

    APPEND INITIAL LINE
      TO lt_binding
      ASSIGNING FIELD-SYMBOL(<binding>).

    <binding>-analysis_id =
      lv_analysis_id.

    <binding>-item_id =
      lv_binding_id.

    <binding>-call_item_id =
      lv_logic_id.

    <binding>-evidence_id =
      lv_evidence_id.

    <binding>-parameter_name =
      'USERNAME'.

    <binding>-direction =
      'EXPORTING'.

    <binding>-actual_expression =
      'SY-UNAME'.

    <binding>-binding_position =
      1.

    <binding>-confidence =
      zif_mig_types=>gc_conf_high.


    go_osql->insert_test_data(
      lt_binding
    ).


    "==========================================================
    " READ
    "==========================================================
    DATA(lo_reader) =
      NEW zcl_mig_analysis_reader( ).


    DATA(ls_result) =
      lo_reader->zif_mig_analysis_reader~read(
        iv_analysis_id =
          lv_analysis_id
      ).


    "==========================================================
    " Assertions
    "==========================================================
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines(
              ls_result-call_bindings
            )
      msg = 'Reader không trả Call Binding'
    ).


    READ TABLE ls_result-call_bindings
      INDEX 1
      INTO DATA(ls_actual_binding).


    cl_abap_unit_assert=>assert_subrc(
      exp = 0
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = lv_analysis_id
      act = ls_actual_binding-analysis_id
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = lv_logic_id
      act = ls_actual_binding-call_item_id
      msg = 'Reader mất CALL_ITEM_ID relation'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = lv_evidence_id
      act = ls_actual_binding-evidence_id
      msg = 'Reader mất EVIDENCE_ID relation'
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'USERNAME'
      act = ls_actual_binding-parameter_name
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'EXPORTING'
      act = ls_actual_binding-direction
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 'SY-UNAME'
      act = ls_actual_binding-actual_expression
    ).


    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = ls_actual_binding-position
      msg = 'BINDING_POSITION không map thành POSITION'
    ).

  ENDMETHOD.


ENDCLASS.
