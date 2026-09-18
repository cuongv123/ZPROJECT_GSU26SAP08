CLASS zcl_mig_row_rslv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_row_rslv.

    METHODS constructor
      IMPORTING
        io_repo TYPE REF TO zif_mig_row_repo.

  PRIVATE SECTION.

    TYPES:
      ty_norm_name TYPE c LENGTH 40.


    DATA mo_repo
      TYPE REF TO zif_mig_row_repo.


    METHODS map_fields
      IMPORTING
        is_bp  TYPE zif_mig_types=>ty_service_blueprint_result
        is_row TYPE zif_mig_types=>ty_row_def
      CHANGING
        cs_result TYPE zif_mig_types=>ty_row_result.


    METHODS add_unused
      IMPORTING
        is_row TYPE zif_mig_types=>ty_row_def
      CHANGING
        cs_result TYPE zif_mig_types=>ty_row_result.


    METHODS norm_name
      IMPORTING
        VALUE(iv_name) TYPE string
      RETURNING
        VALUE(rv_name) TYPE ty_norm_name.


    METHODS type_ok
      IMPORTING
        is_field TYPE zif_mig_types=>ty_service_field
        is_comp  TYPE zif_mig_types=>ty_row_comp
      RETURNING
        VALUE(rv_ok) TYPE abap_bool.


    METHODS set_status
      CHANGING
        cs_result TYPE zif_mig_types=>ty_row_result.

ENDCLASS.

CLASS zcl_mig_row_rslv IMPLEMENTATION.

  METHOD constructor.

    mo_repo = io_repo.

  ENDMETHOD.


  METHOD zif_mig_row_rslv~resolve.

    IF is_bp-blueprint-analysis_id IS INITIAL
       OR is_smap-analysis_id IS INITIAL
       OR is_bp-blueprint-analysis_id
            <> is_smap-analysis_id.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_bp-blueprint-source_program
      ).

    ENDIF.


    rs_result-analysis_id =
      is_bp-blueprint-analysis_id.

    rs_result-output_name =
      is_smap-selected_out-par_name.

    rs_result-row_type =
      is_smap-selected_out-type_name.


    IF mo_repo IS NOT BOUND.

      rs_result-status =
        zif_mig_types=>gc_row_unsup.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Row type repository is not available.'.

      RETURN.

    ENDIF.


    IF is_smap-status <>
         zif_mig_types=>gc_smap_ready.

      rs_result-status =
        zif_mig_types=>gc_row_review.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Service mapping is not ready.'.

      RETURN.

    ENDIF.


    IF is_smap-selected_out-par_name IS INITIAL.

      rs_result-status =
        zif_mig_types=>gc_row_review.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'No provider output was selected.'.

      RETURN.

    ENDIF.


    IF is_smap-selected_out-type_name IS INITIAL.

      rs_result-status =
        zif_mig_types=>gc_row_review.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Selected output has no row type name.'.

      RETURN.

    ENDIF.


    DATA(lv_type) =
      CONV zif_mig_types=>ty_sig_name(
        is_smap-selected_out-type_name
      ).

    DATA(ls_row) =
      mo_repo->read_type(
        iv_type = lv_type
      ).

    IF ls_row-exists = abap_false.

      rs_result-status =
        zif_mig_types=>gc_row_not_found.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Provider row type was not found.'.

      RETURN.

    ENDIF.


    IF ls_row-structured = abap_false.

      rs_result-status =
        zif_mig_types=>gc_row_review.

      rs_result-manual_review =
        abap_true.

      rs_result-decision_reason =
        'Provider output line type is not a structure.'.

      RETURN.

    ENDIF.


    rs_result-row_type =
      ls_row-line_name.

    rs_result-components =
      ls_row-components.


    map_fields(
      EXPORTING
        is_bp  = is_bp
        is_row = ls_row

      CHANGING
        cs_result = rs_result
    ).


    add_unused(
      EXPORTING
        is_row = ls_row

      CHANGING
        cs_result = rs_result
    ).


    set_status(
      CHANGING
        cs_result = rs_result
    ).

  ENDMETHOD.


  METHOD map_fields.

    LOOP AT is_bp-fields
      INTO DATA(ls_field).

      DATA:
        lv_hits TYPE i,
        ls_hit  TYPE zif_mig_types=>ty_row_comp,
        ls_map  TYPE zif_mig_types=>ty_row_map.

      CLEAR:
        lv_hits,
        ls_hit,
        ls_map.


      DATA(lv_svc_name) =
        norm_name(
          iv_name =
            CONV string( ls_field-field_name )
        ).


      LOOP AT is_row-components
        INTO DATA(ls_comp).

        DATA(lv_comp_name) =
          norm_name(
            iv_name =
              CONV string( ls_comp-comp_name )
          ).


        IF lv_svc_name <> lv_comp_name.
          CONTINUE.
        ENDIF.


        lv_hits += 1.

        ls_hit =
          ls_comp.

      ENDLOOP.


      ls_map-svc_item_id =
        ls_field-source_item_id.

      ls_map-svc_name =
        ls_field-field_name.

      ls_map-svc_edm =
        ls_field-edm_type.

      ls_map-position =
        ls_field-position.


      CASE lv_hits.

        WHEN 0.

          ls_map-map_state =
            zif_mig_types=>gc_row_missing.

          ls_map-reason =
            'Service field has no provider row component.'.


        WHEN 1.

          ls_map-comp_name =
            ls_hit-comp_name.

          ls_map-comp_edm =
            ls_hit-edm_type.


          DATA:
            lv_svc_up  TYPE string,
            lv_comp_up TYPE string.

          lv_svc_up =
            to_upper(
              CONV string(
                ls_field-field_name
              )
            ).

          lv_comp_up =
            to_upper(
              CONV string(
                ls_hit-comp_name
              )
            ).

          ls_map-exact_name =
            xsdbool(
              lv_svc_up = lv_comp_up
            ).


          ls_map-type_match =
            type_ok(
              is_field = ls_field
              is_comp  = ls_hit
            ).


          IF ls_map-type_match =
               abap_true.

            ls_map-map_state =
              zif_mig_types=>gc_row_auto.

            ls_map-reason =
              'Service field matches provider row component.'.

          ELSE.

            ls_map-map_state =
              zif_mig_types=>gc_row_type.

            ls_map-reason =
              'Service field and row component types conflict.'.

          ENDIF.


        WHEN OTHERS.

          ls_map-map_state =
            zif_mig_types=>gc_row_ambig.

          ls_map-reason =
            'Multiple provider components match the service field.'.

      ENDCASE.


      APPEND ls_map
        TO cs_result-field_maps.

    ENDLOOP.


    SORT cs_result-field_maps
      BY position
         svc_name.

  ENDMETHOD.


  METHOD add_unused.

    LOOP AT is_row-components
      INTO DATA(ls_comp).

      DATA(lv_used) =
        abap_false.


      LOOP AT cs_result-field_maps
        TRANSPORTING NO FIELDS
        WHERE comp_name = ls_comp-comp_name
          AND map_state = zif_mig_types=>gc_row_auto.

        lv_used =
          abap_true.

        EXIT.

      ENDLOOP.


      IF lv_used = abap_false.

        APPEND ls_comp
          TO cs_result-unused_comps.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD norm_name.

    DATA lv_name TYPE string.

    lv_name =
      to_upper( iv_name ).

    CONDENSE lv_name NO-GAPS.

    rv_name =
      lv_name.

  ENDMETHOD.


  METHOD type_ok.

    rv_ok =
      abap_false.


    IF is_comp-is_table = abap_true
       OR is_comp-is_ref = abap_true
       OR is_comp-is_deep = abap_true.

      RETURN.

    ENDIF.


    IF is_field-edm_type IS INITIAL
       OR is_comp-edm_type IS INITIAL.

      RETURN.

    ENDIF.


    DATA:
      lv_svc_edm  TYPE string,
      lv_comp_edm TYPE string.

    lv_svc_edm =
      to_upper(
        CONV string( is_field-edm_type )
      ).

    lv_comp_edm =
      to_upper(
        CONV string( is_comp-edm_type )
      ).


    rv_ok =
      xsdbool(
        lv_svc_edm = lv_comp_edm
      ).

  ENDMETHOD.


  METHOD set_status.

    DATA:
      lv_mapped TYPE i,
      lv_issues TYPE i.

    CLEAR:
      lv_mapped,
      lv_issues.


    IF cs_result-field_maps IS INITIAL.

      cs_result-status =
        zif_mig_types=>gc_row_review.

      cs_result-manual_review =
        abap_true.

      cs_result-decision_reason =
        'Service output contains no fields.'.

      RETURN.

    ENDIF.


    LOOP AT cs_result-field_maps
      INTO DATA(ls_map).

      IF ls_map-map_state =
           zif_mig_types=>gc_row_auto.

        lv_mapped += 1.

      ELSE.

        lv_issues += 1.

      ENDIF.

    ENDLOOP.


    cs_result-mapped_fields =
      lv_mapped.

    cs_result-issue_count =
      lv_issues.


    IF lv_issues = 0.

      cs_result-status =
        zif_mig_types=>gc_row_ready.

      cs_result-manual_review =
        abap_false.

      cs_result-decision_reason =
        'Provider row type matches the service output.'.

    ELSE.

      cs_result-status =
        zif_mig_types=>gc_row_review.

      cs_result-manual_review =
        abap_true.

      cs_result-decision_reason =
        'One or more output fields require review.'.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
