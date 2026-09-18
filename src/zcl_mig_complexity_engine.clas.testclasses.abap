CLASS ltc_complexity_engine DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      empty_result
        FOR TESTING,

      calculate_known_score
        FOR TESTING,

      cap_scores
        FOR TESTING,

      preserve_analysis_data
        FOR TESTING,

      deterministic_result
        FOR TESTING.

ENDCLASS.

CLASS ltc_complexity_engine IMPLEMENTATION.

  METHOD empty_result.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    DATA(lo_engine) =
      NEW zcl_mig_complexity_engine( ).

    lo_engine->zif_mig_complexity_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    CONSTANTS:
      lc_expected_complexity TYPE decfloat16 VALUE '0',
      lc_expected_readiness  TYPE decfloat16 VALUE '100'.

    cl_abap_unit_assert=>assert_equals(
      exp = lc_expected_complexity
      act = ls_result-overview-complexity_score
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lc_expected_readiness
      act = ls_result-overview-readiness_score
    ).

  ENDMETHOD.

    METHOD calculate_known_score.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.


    "========================================================
    " UI: 2 points
    "========================================================
    APPEND INITIAL LINE
      TO ls_result-ui_filters.

    APPEND INITIAL LINE
      TO ls_result-ui_filters.


    "========================================================
    " DB SELECT:
    " base 2 + dynamic 5 + join 3 + aggregation 2 = 12
    " readiness penalty = 10 + 2 = 12
    "========================================================
    APPEND VALUE #(
      operation       = 'SELECT'
      dynamic_access  = abap_true
      joined_objects  = 'VBAP'
      aggregation     = 'COUNT'
    ) TO ls_result-database_objects.


    "========================================================
    " DB UPDATE:
    " base 2 + write 4 = 6
    " readiness penalty = 5
    "========================================================
    APPEND VALUE #(
      operation = 'UPDATE'
    ) TO ls_result-database_objects.


    "========================================================
    " FORM:
    " base 2 + GUI 8 + transaction 5 + FORM 4 = 19
    " readiness penalty = 12 + 8 + 4 = 24
    "========================================================
    APPEND VALUE #(
      object_type            = 'FORM_DEFINITION'
      gui_dependency         = abap_true
      transaction_dependency = abap_true
    ) TO ls_result-business_logic.


    "========================================================
    " ALV output:
    " base 3 + editable 4 = 7
    " readiness penalty = 5
    "========================================================
    APPEND VALUE #(
      editable = abap_true
    ) TO ls_result-alv_outputs.


    "Six columns → ceil(6 / 5) = 2 points
    DO 6 TIMES.

      APPEND INITIAL LINE
        TO ls_result-alv_columns.

    ENDDO.


    "One sort → 1 point
    APPEND INITIAL LINE
      TO ls_result-alv_sorts.


    "One filter → 1 point
    APPEND INITIAL LINE
      TO ls_result-alv_filters.


    "Two events → 4 complexity and readiness penalty points
    APPEND INITIAL LINE
      TO ls_result-alv_events.

    APPEND INITIAL LINE
      TO ls_result-alv_events.


    DATA(lo_engine) =
      NEW zcl_mig_complexity_engine( ).

    lo_engine->zif_mig_complexity_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).


    CONSTANTS:
      lc_expected_complexity TYPE decfloat16 VALUE '54',
      lc_expected_readiness  TYPE decfloat16 VALUE '50'.

    cl_abap_unit_assert=>assert_equals(
      exp = lc_expected_complexity
      act = ls_result-overview-complexity_score
      msg = 'Complexity score không đúng theo rule'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lc_expected_readiness
      act = ls_result-overview-readiness_score
      msg = 'Readiness score không đúng theo rule'
    ).

  ENDMETHOD.

    METHOD cap_scores.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    "Tạo đủ GUI-dependent logic để vượt quá 100 điểm
    DO 30 TIMES.

      APPEND VALUE #(
        object_type            = 'FORM_DEFINITION'
        gui_dependency         = abap_true
        transaction_dependency = abap_true
      ) TO ls_result-business_logic.

    ENDDO.

    DATA(lo_engine) =
      NEW zcl_mig_complexity_engine( ).

    lo_engine->zif_mig_complexity_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    CONSTANTS:
      lc_max_score TYPE decfloat16 VALUE '100',
      lc_min_score TYPE decfloat16 VALUE '0'.

    cl_abap_unit_assert=>assert_equals(
      exp = lc_max_score
      act = ls_result-overview-complexity_score
      msg = 'Complexity phải được cap ở 100'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lc_min_score
      act = ls_result-overview-readiness_score
      msg = 'Readiness không được thấp hơn 0'
    ).

  ENDMETHOD.

    METHOD preserve_analysis_data.

    DATA ls_result
      TYPE zif_mig_types=>ty_analysis_result.

    APPEND INITIAL LINE
      TO ls_result-ui_filters.

    APPEND VALUE #(
      operation = 'SELECT'
    ) TO ls_result-database_objects.

    APPEND VALUE #(
      object_type = 'INSTANCE_METHOD'
    ) TO ls_result-business_logic.

    DATA(lv_ui_count_before) =
      lines( ls_result-ui_filters ).

    DATA(lv_db_count_before) =
      lines( ls_result-database_objects ).

    DATA(lv_logic_count_before) =
      lines( ls_result-business_logic ).

    DATA(lo_engine) =
      NEW zcl_mig_complexity_engine( ).

    lo_engine->zif_mig_complexity_engine~enrich(
      CHANGING
        cs_result = ls_result
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_ui_count_before
      act = lines( ls_result-ui_filters )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_db_count_before
      act = lines( ls_result-database_objects )
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = lv_logic_count_before
      act = lines( ls_result-business_logic )
    ).

  ENDMETHOD.

    METHOD deterministic_result.

    DATA:
      ls_result_1 TYPE zif_mig_types=>ty_analysis_result,
      ls_result_2 TYPE zif_mig_types=>ty_analysis_result.

    APPEND VALUE #(
      operation      = 'SELECT'
      dynamic_access = abap_true
    ) TO ls_result_1-database_objects.

    ls_result_2 =
      ls_result_1.

    DATA(lo_engine) =
      NEW zcl_mig_complexity_engine( ).

    lo_engine->zif_mig_complexity_engine~enrich(
      CHANGING
        cs_result = ls_result_1
    ).

    lo_engine->zif_mig_complexity_engine~enrich(
      CHANGING
        cs_result = ls_result_2
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_result_1-overview-complexity_score
      act = ls_result_2-overview-complexity_score
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_result_1-overview-readiness_score
      act = ls_result_2-overview-readiness_score
    ).

  ENDMETHOD.

ENDCLASS.
