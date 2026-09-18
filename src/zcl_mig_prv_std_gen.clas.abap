CLASS zcl_mig_prv_std_gen DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_mig_prv_clas_gen.
  PRIVATE SECTION.
    METHODS inspect_language
      IMPORTING iv_code TYPE string
      RETURNING VALUE(rs_check) TYPE zif_mig_prv_clas_gen=>ty_check.
    METHODS read_standard_version
      IMPORTING iv_package TYPE zif_mig_prv_clas_gen=>ty_package
      EXPORTING
        eo_version TYPE REF TO cl_xco_abap_language_version
        es_check TYPE zif_mig_prv_clas_gen=>ty_check.
ENDCLASS.

CLASS zcl_mig_prv_std_gen IMPLEMENTATION.
  METHOD inspect_language.
    "Default XCO representation: space = Standard, 2 = Key Users, 5 = Cloud.
    IF iv_code <> space.
      rs_check-message = |Class language version "{ iv_code }"; Standard ABAP (space) is required.|.
      RETURN.
    ENDIF.
    rs_check-language_code = space.
    rs_check-allowed = abap_true.
  ENDMETHOD.

  METHOD read_standard_version.
    CLEAR: eo_version, es_check.
    IF iv_package IS INITIAL OR iv_package = '$TMP'.
      es_check-message = 'Standard generation requires a transportable provider package.'.
      RETURN.
    ENDIF.

    TRY.
        SELECT SINGLE devclass FROM tdevc
          WHERE devclass = @iv_package INTO @DATA(lv_package).
        IF sy-subrc <> 0.
          es_check-message = |Provider package { iv_package } does not exist.|.
          RETURN.
        ENDIF.

        eo_version = xco_abap_language_version=>object_type->clas->get_default_language_version(
          iv_package ).
        IF eo_version IS NOT BOUND.
          es_check-message = |No default class language version for package { iv_package }.|.
          RETURN.
        ENDIF.

        es_check = inspect_language( CONV string( eo_version->get_value( ) ) ).
        IF es_check-allowed <> abap_true.
          es_check-message = |Package { iv_package }: { es_check-message }|.
          CLEAR eo_version.
          RETURN.
        ENDIF.

        es_check-language_code = space.
        es_check-allowed = abap_true.
        es_check-message = |Provider package { iv_package }: Standard ABAP (space).|.
      CATCH cx_root INTO DATA(lx_check).
        CLEAR eo_version.
        es_check-message = |Provider package check failed: { lx_check->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_mig_prv_clas_gen~check_target.
    read_standard_version(
      EXPORTING iv_package = iv_package
      IMPORTING es_check = rs_check ).
  ENDMETHOD.

  METHOD zif_mig_prv_clas_gen~generate.
    IF iv_class_name IS INITIAL OR iv_transport IS INITIAL
       OR it_select_source IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_generation(
        iv_detail = 'Standard class generation requires a name, transport and SELECT source.' ).
    ENDIF.

    read_standard_version(
      EXPORTING iv_package = iv_package
      IMPORTING eo_version = DATA(lo_version) es_check = DATA(ls_check) ).
    IF ls_check-allowed <> abap_true OR lo_version IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_mig_generation( iv_detail = ls_check-message ).
    ENDIF.

    "Recheck immediately before PUT: the pipeline remains create-only.
    SELECT SINGLE devclass FROM tadir
      WHERE pgmid = 'R3TR' AND object = 'CLAS' AND obj_name = @iv_class_name
      INTO @DATA(lv_existing_package).
    IF sy-subrc = 0.
      RAISE EXCEPTION NEW zcx_mig_generation(
        iv_detail = |Class { iv_class_name } already exists in { lv_existing_package }; it will not be overwritten.| ).
    ENDIF.

    TRY.
        DATA(lo_env) = xco_generation=>environment->transported(
          iv_transport = iv_transport ).
        DATA(lo_put) = lo_env->for-clas->create_put_operation( ).
        DATA(lo_spec) = lo_put->add_object(
          iv_name = iv_class_name
        )->set_package( iv_package )->create_form_specification( ).

        lo_spec->set_abap_language_version( lo_version ).
        lo_spec->set_short_description( 'Generated MIG query provider' ).
        lo_spec->definition->add_interface( 'IF_RAP_QUERY_PROVIDER' ).
        lo_spec->implementation->add_method(
          'IF_RAP_QUERY_PROVIDER~SELECT'
        )->set_source( it_select_source ).

        DATA(lo_result) = lo_put->execute( ).
        IF lo_result IS NOT BOUND.
          RAISE EXCEPTION NEW zcx_mig_generation(
            iv_detail = 'XCO PUT returned no result; generation cannot continue.' ).
        ENDIF.
        IF lo_result->findings IS NOT BOUND.
          RAISE EXCEPTION NEW zcx_mig_generation(
            iv_detail = 'XCO PUT returned no findings; generation cannot continue.' ).
        ENDIF.

        IF lo_result->findings->contain_errors( ) = abap_true.
          DATA(lv_findings) = |XCO PUT reported errors for class { iv_class_name }.|.
          LOOP AT lo_result->findings->if_xco_news~get_messages( ) INTO DATA(lo_finding_message).
            lv_findings = lv_findings && cl_abap_char_utilities=>newline
              && lo_finding_message->get_text( ).
          ENDLOOP.
          RAISE EXCEPTION NEW zcx_mig_generation( iv_detail = lv_findings ).
        ENDIF.
      CATCH cx_xco_gen_put_exception INTO DATA(lx_put).
        DATA(lv_detail) =
          |Standard CLAS { iv_class_name } in { iv_package } failed: { lx_put->get_text( ) }|.
        LOOP AT lx_put->if_xco_news~get_messages( ) INTO DATA(lo_message).
          lv_detail = lv_detail && cl_abap_char_utilities=>newline && lo_message->get_text( ).
        ENDLOOP.
        RAISE EXCEPTION NEW zcx_mig_generation( iv_detail = lv_detail previous = lx_put ).
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION NEW zcx_mig_generation(
          iv_detail = |Standard CLAS { iv_class_name } in { iv_package } failed: { lx_error->get_text( ) }|
          previous = lx_error ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

