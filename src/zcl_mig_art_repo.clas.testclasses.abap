CLASS ltc_art_repo DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      read_self_class
        FOR TESTING
        RAISING zcx_mig_analysis,

      read_missing_obj
        FOR TESTING
        RAISING zcx_mig_analysis,

      read_many_mix
        FOR TESTING
        RAISING zcx_mig_analysis,

      match_type_name
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.

CLASS ltc_art_repo IMPLEMENTATION.

  METHOD read_self_class.

    DATA(ls_info) =
      NEW zcl_mig_art_repo(
        )->zif_mig_art_repo~read_info(
          iv_type =
            zif_mig_types=>gc_art_clas

          iv_name =
            'ZCL_MIG_ART_REPO'
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_info-read_ok
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_info-exists
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_info-package
    ).

  ENDMETHOD.


  METHOD read_missing_obj.

    DATA(ls_info) =
      NEW zcl_mig_art_repo(
        )->zif_mig_art_repo~read_info(
          iv_type =
            zif_mig_types=>gc_art_clas

          iv_name =
            'ZCL_MIG_NO_SUCH_99'
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_info-read_ok
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_info-exists
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_info-package
    ).

  ENDMETHOD.


  METHOD read_many_mix.

    DATA lt_items
      TYPE zif_mig_types=>tt_art_item.


    APPEND VALUE #(
      art_type =
        zif_mig_types=>gc_art_clas

      object_name =
        'ZCL_MIG_ART_REPO'
    ) TO lt_items.


    APPEND VALUE #(
      art_type =
        zif_mig_types=>gc_art_ddls

      object_name =
        'Z_MIG_NO_DDLS_99'
    ) TO lt_items.


    DATA(lt_info) =
      NEW zcl_mig_art_repo(
        )->zif_mig_art_repo~read_many(
          it_items = lt_items
        ).


    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( lt_info )
    ).


    READ TABLE lt_info
      WITH KEY
        art_type =
          zif_mig_types=>gc_art_clas

        object_name =
          'ZCL_MIG_ART_REPO'

      INTO DATA(ls_class).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_class-exists
    ).


    READ TABLE lt_info
      WITH KEY
        art_type =
          zif_mig_types=>gc_art_ddls

        object_name =
          'Z_MIG_NO_DDLS_99'

      INTO DATA(ls_ddls).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_ddls-exists
    ).

  ENDMETHOD.


  METHOD match_type_name.

    DATA lt_items
      TYPE zif_mig_types=>tt_art_item.


    APPEND VALUE #(
      art_type =
        zif_mig_types=>gc_art_clas

      object_name =
        'ZCL_MIG_ART_REPO'
    ) TO lt_items.


    APPEND VALUE #(
      art_type =
        zif_mig_types=>gc_art_ddls

      object_name =
        'ZCL_MIG_ART_REPO'
    ) TO lt_items.


    DATA(lt_info) =
      NEW zcl_mig_art_repo(
        )->zif_mig_art_repo~read_many(
          it_items = lt_items
        ).


    READ TABLE lt_info
      WITH KEY
        art_type =
          zif_mig_types=>gc_art_clas

      INTO DATA(ls_class).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_class-exists
    ).


    READ TABLE lt_info
      WITH KEY
        art_type =
          zif_mig_types=>gc_art_ddls

      INTO DATA(ls_ddls).


    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_ddls-exists
    ).

  ENDMETHOD.

ENDCLASS.
