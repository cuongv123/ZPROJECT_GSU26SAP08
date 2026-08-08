CLASS zcl_mig_cmp_store DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

  METHODS save
  IMPORTING
    iv_analysis_id     TYPE sysuuid_x16
    iv_program_name    TYPE programm
    iv_target_strategy TYPE zif_mig_types=>ty_service_strategy
    it_items           TYPE zif_mig_cmp_types=>ty_t_cmp_item
  RETURNING
    VALUE(rv_cmp_run_id) TYPE sysuuid_x16
  RAISING
    zcx_mig_comparison.

  PRIVATE SECTION.

    METHODS determine_overall_status
  IMPORTING
    iv_compatibility_rate TYPE zmig_cmp_run-compatibility_rate
  RETURNING
    VALUE(rv_overall_status) TYPE zmig_cmp_run-overall_status.

ENDCLASS.


CLASS zcl_mig_cmp_store IMPLEMENTATION.

  METHOD save.

    DATA:
      lv_created_at        TYPE timestampl,
      lv_mapped_count      TYPE i,
      lv_refactor_count    TYPE i,
      lv_manual_count      TYPE i,
      lv_unsupported_count TYPE i,
      lv_total_items       TYPE i.

    TRY.

        rv_cmp_run_id =
          cl_system_uuid=>create_uuid_x16_static( ).

        GET TIME STAMP FIELD lv_created_at.

        lv_total_items = lines( it_items ).

        LOOP AT it_items
          INTO DATA(ls_item).

          CASE ls_item-status.

            WHEN zif_mig_cmp_types=>gc_status_mapped.
              lv_mapped_count += 1.

            WHEN zif_mig_cmp_types=>gc_status_refactor.
              lv_refactor_count += 1.

            WHEN zif_mig_cmp_types=>gc_status_manual.
              lv_manual_count += 1.

            WHEN zif_mig_cmp_types=>gc_status_unsupported.
              lv_unsupported_count += 1.

          ENDCASE.

        ENDLOOP.

        DATA lv_compatibility_rate
          TYPE zmig_cmp_run-compatibility_rate.

        IF lv_total_items > 0.

          lv_compatibility_rate =
            CONV decfloat34( lv_mapped_count )
            * 100
            / CONV decfloat34( lv_total_items ).

        ENDIF.

        DATA(lv_overall_status) =
          determine_overall_status(
            iv_compatibility_rate = lv_compatibility_rate
          ).

        DATA(ls_run) =
          VALUE zmig_cmp_run(
            client              = sy-mandt
            cmp_run_id          = rv_cmp_run_id
            analysis_id         = iv_analysis_id
            program_name        = iv_program_name
            target_strategy     = iv_target_strategy
            total_items         = lv_total_items
            mapped_count        = lv_mapped_count
            refactor_count      = lv_refactor_count
            manual_count        = lv_manual_count
            unsupported_count   = lv_unsupported_count
            compatibility_rate  = lv_compatibility_rate
            overall_status      = lv_overall_status
            run_status          = zif_mig_cmp_types=>gc_run_success
            created_by          = sy-uname
            created_at          = lv_created_at
            last_changed_by     = sy-uname
            last_changed_at     = lv_created_at
          ).

        INSERT zmig_cmp_run
          FROM @ls_run.

        IF sy-subrc <> 0.

          RAISE EXCEPTION TYPE zcx_mig_comparison
            EXPORTING
              iv_message =
                'Migration comparison run could not be saved'.

        ENDIF.

        DATA lt_db_items
          TYPE STANDARD TABLE OF zmig_cmp_item
          WITH EMPTY KEY.

        LOOP AT it_items
          INTO ls_item.

          DATA(lv_item_id) =
            cl_system_uuid=>create_uuid_x16_static( ).

          APPEND VALUE #(
            client          = sy-mandt
            cmp_run_id      = rv_cmp_run_id
            item_id         = lv_item_id
            item_no         = ls_item-item_no
            category        = ls_item-category
            source_element  = ls_item-source_element
            source_type     = ls_item-source_type
            source_value    = ls_item-source_value
            target_element  = ls_item-target_element
            target_type     = ls_item-target_type
            target_value    = ls_item-target_value
            mapping_rule    = ls_item-mapping_rule
            status          = ls_item-status
            severity        = ls_item-severity
            message         = ls_item-message
            recommendation  = ls_item-recommendation
            created_at      = lv_created_at
          ) TO lt_db_items.

        ENDLOOP.

        IF lt_db_items IS NOT INITIAL.

          INSERT zmig_cmp_item
            FROM TABLE @lt_db_items.

          IF sy-subrc <> 0.

            RAISE EXCEPTION TYPE zcx_mig_comparison
              EXPORTING
                iv_message =
                  'Migration comparison result items could not be saved'.

          ENDIF.

        ENDIF.

      CATCH cx_uuid_error INTO DATA(lx_uuid).

        RAISE EXCEPTION TYPE zcx_mig_comparison
          EXPORTING
            iv_message =
              |UUID generation failed: { lx_uuid->get_text( ) }|
            previous = lx_uuid.

      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

        RAISE EXCEPTION TYPE zcx_mig_comparison
          EXPORTING
            iv_message =
              |Comparison persistence failed: { lx_sql->get_text( ) }|
            previous = lx_sql.

    ENDTRY.

  ENDMETHOD.


  METHOD determine_overall_status.

    IF iv_compatibility_rate >= 80.

      rv_overall_status =
        zif_mig_cmp_types=>gc_overall_high.

    ELSEIF iv_compatibility_rate >= 60.

      rv_overall_status =
        zif_mig_cmp_types=>gc_overall_partial.

    ELSE.

      rv_overall_status =
        zif_mig_cmp_types=>gc_overall_manual.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
