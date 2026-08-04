CLASS zcl_mig_svc_map DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_svc_map.

  PRIVATE SECTION.

    TYPES:
      ty_norm_name TYPE c LENGTH 40.


    METHODS map_inputs
      IMPORTING
        is_bp
          TYPE zif_mig_types=>ty_service_blueprint_result

        is_sig
          TYPE zif_mig_types=>ty_sig_result

      CHANGING
        cs_map
          TYPE zif_mig_types=>ty_svc_map_result.


    METHODS add_req_missing
      IMPORTING
        is_sig
          TYPE zif_mig_types=>ty_sig_result

      CHANGING
        cs_map
          TYPE zif_mig_types=>ty_svc_map_result.


    METHODS map_outputs
      IMPORTING
        is_bp
          TYPE zif_mig_types=>ty_service_blueprint_result

        is_sig
          TYPE zif_mig_types=>ty_sig_result

      CHANGING
        cs_map
          TYPE zif_mig_types=>ty_svc_map_result.


    METHODS mark_output
      IMPORTING
        VALUE(iv_name) TYPE string

        is_sig
          TYPE zif_mig_types=>ty_sig_result

      CHANGING
        cs_map
          TYPE zif_mig_types=>ty_svc_map_result.


    METHODS norm_name
      IMPORTING
        VALUE(iv_name) TYPE string

      RETURNING
        VALUE(rv_name) TYPE ty_norm_name.


    METHODS type_ok
      IMPORTING
        is_svc
          TYPE zif_mig_types=>ty_service_parameter

        is_prv
          TYPE zif_mig_types=>ty_sig_par

      RETURNING
        VALUE(rv_ok) TYPE abap_bool.


    METHODS set_status
      IMPORTING
        is_bp
          TYPE zif_mig_types=>ty_service_blueprint_result

      CHANGING
        cs_map
          TYPE zif_mig_types=>ty_svc_map_result.

ENDCLASS.

CLASS zcl_mig_svc_map IMPLEMENTATION.

  METHOD zif_mig_svc_map~build.

    IF is_bp-blueprint-analysis_id IS INITIAL
       OR is_sig-analysis_id IS INITIAL
       OR is_bp-blueprint-analysis_id
            <> is_sig-analysis_id.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_bp-blueprint-source_program
      ).

    ENDIF.


    rs_map-analysis_id =
      is_bp-blueprint-analysis_id.


    IF is_bp-blueprint-strategy =
         zif_mig_types=>gc_svc_manual.

      rs_map-status =
        zif_mig_types=>gc_smap_review.

      rs_map-manual_review =
        abap_true.

      rs_map-decision_reason =
        'Service blueprint requires manual review.'.

      RETURN.

    ENDIF.


    IF is_sig-status <>
         zif_mig_types=>gc_sig_ready.

      rs_map-status =
        zif_mig_types=>gc_smap_review.

      rs_map-manual_review =
        abap_true.

      rs_map-decision_reason =
        'Provider signature is not ready.'.

      RETURN.

    ENDIF.


    map_inputs(
      EXPORTING
        is_bp  = is_bp
        is_sig = is_sig

      CHANGING
        cs_map = rs_map
    ).


    add_req_missing(
      EXPORTING
        is_sig = is_sig

      CHANGING
        cs_map = rs_map
    ).


    map_outputs(
      EXPORTING
        is_bp  = is_bp
        is_sig = is_sig

      CHANGING
        cs_map = rs_map
    ).


    set_status(
      EXPORTING
        is_bp = is_bp

      CHANGING
        cs_map = rs_map
    ).

  ENDMETHOD.


  METHOD map_inputs.

    LOOP AT is_bp-parameters
      INTO DATA(ls_svc).

      DATA:
        lv_hits TYPE i,
        ls_hit  TYPE zif_mig_types=>ty_sig_par,
        ls_map  TYPE zif_mig_types=>ty_svc_in_map.

      CLEAR:
        lv_hits,
        ls_hit,
        ls_map.


      DATA(lv_svc_norm) =
        norm_name(
          iv_name =
            CONV string( ls_svc-parameter_name )
        ).


      LOOP AT is_sig-input_params
        INTO DATA(ls_prv).

        DATA(lv_prv_norm) =
          norm_name(
            iv_name =
              CONV string( ls_prv-par_name )
          ).

        IF lv_svc_norm <> lv_prv_norm.
          CONTINUE.
        ENDIF.


        lv_hits += 1.

        ls_hit =
          ls_prv.

      ENDLOOP.


      ls_map-svc_item_id =
        ls_svc-source_item_id.

      ls_map-svc_name =
        ls_svc-parameter_name.

      ls_map-svc_kind =
        ls_svc-odata_kind.

      ls_map-svc_edm =
        ls_svc-edm_type.

      ls_map-mandatory =
        ls_svc-mandatory.


      CASE lv_hits.

        WHEN 0.

          ls_map-map_state =
            zif_mig_types=>gc_smap_missing.

          ls_map-reason =
            'No provider input parameter matches the service parameter.'.


        WHEN 1.

          ls_map-prv_name =
            ls_hit-par_name.

          ls_map-prv_edm =
            ls_hit-edm_type.

          ls_map-prv_optional =
            ls_hit-optional.


          DATA:
            lv_svc_up TYPE string,
            lv_prv_up TYPE string.

          lv_svc_up =
            to_upper(
              CONV string(
                ls_svc-parameter_name
              )
            ).

          lv_prv_up =
            to_upper(
              CONV string(
                ls_hit-par_name
              )
            ).

          ls_map-exact_name =
            xsdbool(
              lv_svc_up = lv_prv_up
            ).


          DATA(lv_used) =
            abap_false.

          LOOP AT cs_map-input_maps
            TRANSPORTING NO FIELDS
            WHERE prv_name = ls_hit-par_name
              AND map_state =
                zif_mig_types=>gc_smap_auto.

            lv_used =
              abap_true.

            EXIT.

          ENDLOOP.


          IF lv_used = abap_true.

            ls_map-map_state =
              zif_mig_types=>gc_smap_ambig.

            ls_map-reason =
              'Provider parameter is matched by more than one service parameter.'.

            LOOP AT cs_map-input_maps
              ASSIGNING FIELD-SYMBOL(<old_map>)
              WHERE prv_name = ls_hit-par_name.

              <old_map>-map_state =
                zif_mig_types=>gc_smap_ambig.

              <old_map>-reason =
                'Provider parameter is matched by more than one service parameter.'.

            ENDLOOP.


          ELSE.

            ls_map-type_match =
              type_ok(
                is_svc = ls_svc
                is_prv = ls_hit
              ).


            IF ls_map-type_match =
                 abap_true.

              ls_map-map_state =
                zif_mig_types=>gc_smap_auto.

              IF ls_svc-odata_kind = 'RANGE'.

                ls_map-reason =
                  'Selection range matches a provider table parameter.'.

              ELSEIF ls_map-exact_name =
                       abap_true.

                ls_map-reason =
                  'Exact parameter name and type match.'.

              ELSE.

                ls_map-reason =
                  'Normalized parameter name and type match.'.

              ENDIF.


            ELSE.

              ls_map-map_state =
                zif_mig_types=>gc_smap_type.

              ls_map-reason =
                'Service and provider parameter types are incompatible.'.

            ENDIF.

          ENDIF.


        WHEN OTHERS.

          ls_map-map_state =
            zif_mig_types=>gc_smap_ambig.

          ls_map-reason =
            'Multiple provider parameters have the same normalized name.'.

      ENDCASE.


      APPEND ls_map
        TO cs_map-input_maps.

    ENDLOOP.

  ENDMETHOD.


  METHOD add_req_missing.

    LOOP AT is_sig-input_params
      INTO DATA(ls_prv)
      WHERE optional = abap_false.

      DATA(lv_found) =
        abap_false.


      LOOP AT cs_map-input_maps
        TRANSPORTING NO FIELDS
        WHERE prv_name = ls_prv-par_name.

        lv_found =
          abap_true.

        EXIT.

      ENDLOOP.


      IF lv_found = abap_true.
        CONTINUE.
      ENDIF.


      APPEND VALUE #(
        prv_name =
          ls_prv-par_name

        prv_edm =
          ls_prv-edm_type

        prv_optional =
          ls_prv-optional

        mandatory =
          abap_true

        map_state =
          zif_mig_types=>gc_smap_missing

        reason =
          'Mandatory provider input has no service parameter.'
      ) TO cs_map-input_maps.

    ENDLOOP.

  ENDMETHOD.


  METHOD map_outputs.

    CLEAR cs_map-selected_out.


    LOOP AT is_sig-output_params
      INTO DATA(ls_prv)
      WHERE is_table = abap_true.

      APPEND VALUE #(
        prv_name =
          ls_prv-par_name

        type_name =
          ls_prv-type_name

        edm_type =
          ls_prv-edm_type

        is_table =
          ls_prv-is_table

        selected =
          abap_false

        name_match =
          abap_false

        map_state =
          zif_mig_types=>gc_smap_unused

        reason =
          'Output parameter was not selected.'
      ) TO cs_map-output_maps.

    ENDLOOP.


    DATA(lv_count) =
      lines( cs_map-output_maps ).


    IF lv_count = 0.
      RETURN.
    ENDIF.


    IF lv_count = 1.

      READ TABLE cs_map-output_maps
        INDEX 1
        INTO DATA(ls_only).

      mark_output(
        EXPORTING
          iv_name =
            CONV string( ls_only-prv_name )

          is_sig =
            is_sig

        CHANGING
          cs_map =
            cs_map
      ).

      RETURN.

    ENDIF.


    DATA(lv_src_norm) =
      norm_name(
        iv_name =
          CONV string(
            is_bp-blueprint-source_table
          )
      ).


    DATA:
      lv_hits     TYPE i,
      lv_out_name TYPE string.

    CLEAR:
      lv_hits,
      lv_out_name.


    LOOP AT cs_map-output_maps
      ASSIGNING FIELD-SYMBOL(<out_map>).

      DATA(lv_out_norm) =
        norm_name(
          iv_name =
            CONV string( <out_map>-prv_name )
        ).


      IF lv_out_norm <> lv_src_norm.
        CONTINUE.
      ENDIF.


      <out_map>-name_match =
        abap_true.

      lv_hits += 1.

      lv_out_name =
        <out_map>-prv_name.

    ENDLOOP.


    IF lv_hits = 1.

      mark_output(
        EXPORTING
          iv_name =
            lv_out_name

          is_sig =
            is_sig

        CHANGING
          cs_map =
            cs_map
      ).

      RETURN.

    ENDIF.


    LOOP AT cs_map-output_maps
      ASSIGNING <out_map>.

      <out_map>-map_state =
        zif_mig_types=>gc_smap_ambig.

      <out_map>-reason =
        'Multiple table outputs require explicit selection.'.

    ENDLOOP.

  ENDMETHOD.


  METHOD mark_output.

    LOOP AT cs_map-output_maps
      ASSIGNING FIELD-SYMBOL(<out_map>).

      IF <out_map>-prv_name = iv_name.

        <out_map>-selected =
          abap_true.

        <out_map>-map_state =
          zif_mig_types=>gc_smap_auto.

        <out_map>-reason =
          'Provider table output selected.'.

      ELSE.

        <out_map>-selected =
          abap_false.

        <out_map>-map_state =
          zif_mig_types=>gc_smap_unused.

        <out_map>-reason =
          'Provider table output was not selected.'.

      ENDIF.

    ENDLOOP.


    READ TABLE is_sig-output_params
      WITH KEY par_name = iv_name
      INTO cs_map-selected_out.

  ENDMETHOD.


  METHOD norm_name.

  DATA lv_name
    TYPE string.


  lv_name =
    to_upper(
      iv_name
    ).

  CONDENSE lv_name NO-GAPS.


  "============================================================
  " Bỏ prefix kỹ thuật của ABAP parameter
  " Ví dụ:
  " IV_VALID_ON -> VALID_ON
  " IT_MATERIAL -> MATERIAL
  "============================================================
  DO 3 TIMES.

    IF lv_name CP 'IV_*'
       OR lv_name CP 'IS_*'
       OR lv_name CP 'IT_*'
       OR lv_name CP 'EV_*'
       OR lv_name CP 'ES_*'
       OR lv_name CP 'ET_*'
       OR lv_name CP 'CV_*'
       OR lv_name CP 'CS_*'
       OR lv_name CP 'CT_*'
       OR lv_name CP 'RV_*'
       OR lv_name CP 'RS_*'
       OR lv_name CP 'RT_*'
       OR lv_name CP 'GT_*'
       OR lv_name CP 'GS_*'.

      lv_name =
        substring(
          val = lv_name
          off = 3
        ).


    ELSEIF lv_name CP 'I_*'
       OR lv_name CP 'E_*'
       OR lv_name CP 'C_*'
       OR lv_name CP 'R_*'
       OR lv_name CP 'P_*'
       OR lv_name CP 'S_*'
       OR lv_name CP 'T_*'.

      lv_name =
        substring(
          val = lv_name
          off = 2
        ).


    ELSE.

      EXIT.

    ENDIF.

  ENDDO.


  "============================================================
  " Chuẩn hóa CamelCase và ABAP snake_case về cùng dạng
  "
  " ValidOn  -> VALIDON
  " VALID_ON -> VALIDON
  "============================================================
  REPLACE ALL OCCURRENCES OF '_'
    IN lv_name
    WITH ''.


  CONDENSE lv_name NO-GAPS.


  rv_name =
    lv_name.

ENDMETHOD.


  METHOD type_ok.

    rv_ok =
      abap_false.


    "SELECT-OPTIONS / RANGE phải map vào table parameter
    IF is_svc-odata_kind = 'RANGE'.

      rv_ok =
        xsdbool(
          is_prv-is_table = abap_true
        ).

      RETURN.

    ENDIF.


    "Scalar service parameter không map vào table parameter
    IF is_prv-is_table = abap_true.
      RETURN.
    ENDIF.


    DATA:
      lv_svc_edm TYPE string,
      lv_prv_edm TYPE string.

    lv_svc_edm =
      to_upper(
        CONV string( is_svc-edm_type )
      ).

    lv_prv_edm =
      to_upper(
        CONV string( is_prv-edm_type )
      ).


    rv_ok =
      xsdbool(
        lv_svc_edm = lv_prv_edm
      ).

  ENDMETHOD.


  METHOD set_status.

    DATA:
      lv_issues TYPE i,
      lv_mapped TYPE i.

    CLEAR:
      lv_issues,
      lv_mapped.


    LOOP AT cs_map-input_maps
      INTO DATA(ls_input).

      IF ls_input-map_state =
           zif_mig_types=>gc_smap_auto.

        lv_mapped += 1.

      ELSE.

        lv_issues += 1.

      ENDIF.

    ENDLOOP.


    LOOP AT cs_map-output_maps
      TRANSPORTING NO FIELDS
      WHERE map_state =
        zif_mig_types=>gc_smap_ambig.

      lv_issues += 1.

    ENDLOOP.


    IF is_bp-fields IS NOT INITIAL
       AND cs_map-selected_out-par_name
             IS INITIAL.

      lv_issues += 1.

    ENDIF.


    cs_map-mapped_inputs =
      lv_mapped.

    cs_map-issue_count =
      lv_issues.


    IF lv_issues = 0.

      cs_map-status =
        zif_mig_types=>gc_smap_ready.

      cs_map-manual_review =
        abap_false.

      cs_map-decision_reason =
        'Service and provider parameters were mapped.'.

    ELSE.

      cs_map-status =
        zif_mig_types=>gc_smap_review.

      cs_map-manual_review =
        abap_true.

      cs_map-decision_reason =
        'One or more parameter mappings require review.'.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
