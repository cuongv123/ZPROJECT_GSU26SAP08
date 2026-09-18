CLASS zcl_mig_svc_registry DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS gc_shared_binding
      TYPE zif_mig_types=>ty_art_name
      VALUE 'ZUI_MIG_SHARED_O4'.


    METHODS read_all
      IMPORTING
        iv_binding_name
          TYPE zif_mig_types=>ty_art_name
          DEFAULT gc_shared_binding

      RETURNING
        VALUE(rt_services)
          TYPE zif_mig_types=>tt_shared_service

      RAISING
        zcx_mig_analysis.


    METHODS upsert
      IMPORTING
        iv_binding_name
          TYPE zif_mig_types=>ty_art_name
          DEFAULT gc_shared_binding

        iv_service_name
          TYPE zif_mig_types=>ty_art_name

        iv_srvd_name
          TYPE zif_mig_types=>ty_art_name

        iv_version
          TYPE i
          DEFAULT 1

      RAISING
        zcx_mig_analysis.

ENDCLASS.


CLASS zcl_mig_svc_registry IMPLEMENTATION.

  METHOD read_all.

    DATA(lv_binding_name) =
      to_upper(
        CONV string(
          iv_binding_name
        )
      ).

    CONDENSE lv_binding_name NO-GAPS.


    IF lv_binding_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    TRY.

        SELECT
          FROM zmig_svc_reg
          FIELDS
            service_name,
            srvd_name,
            service_version AS version
          WHERE binding_name = @lv_binding_name
          ORDER BY
            service_name,
            service_version
          INTO CORRESPONDING FIELDS OF TABLE @rt_services.


      CATCH cx_sy_open_sql_db.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
        ).

    ENDTRY.

  ENDMETHOD.


  METHOD upsert.

    DATA(lv_binding_name) =
      to_upper(
        CONV string(
          iv_binding_name
        )
      ).

    CONDENSE lv_binding_name NO-GAPS.


    DATA(lv_service_name) =
      to_upper(
        CONV string(
          iv_service_name
        )
      ).

    CONDENSE lv_service_name NO-GAPS.


    DATA(lv_srvd_name) =
      to_upper(
        CONV string(
          iv_srvd_name
        )
      ).

    CONDENSE lv_srvd_name NO-GAPS.


    DATA(lv_version) =
      iv_version.


    IF lv_version <= 0.
      lv_version = 1.
    ENDIF.


    IF lv_binding_name IS INITIAL
       OR lv_service_name IS INITIAL
       OR lv_srvd_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    TRY.

        MODIFY zmig_svc_reg
          FROM @(
            VALUE #(
              client          = sy-mandt
              binding_name    = lv_binding_name
              service_name    = lv_service_name
              srvd_name       = lv_srvd_name
              service_version = lv_version
            )
          ).


        IF sy-subrc <> 0.

          RAISE EXCEPTION NEW zcx_mig_analysis(
            textid =
              zcx_mig_analysis=>analysis_failed
          ).

        ENDIF.


      CATCH cx_sy_open_sql_db.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
        ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
