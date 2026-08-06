REPORT zrmig_test_xco_gen.

PARAMETERS:
  p_class TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZCL_MIG_Q_FM01',

  p_ddls TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZC_MIG_Q_FM01',

  p_srvd TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZUI_MIG_Q_FM01',

  p_pack TYPE devclass
    DEFAULT 'ZMIG_GEN_TEST',

  p_req TYPE trkorr
    DEFAULT 'S40K918252',

  p_exec AS CHECKBOX
    DEFAULT abap_false.


START-OF-SELECTION.

  CONSTANTS gc_anl_id
    TYPE zif_mig_types=>ty_analysis_id
    VALUE '00000000000000000000000000000088'.


  DATA:
    ls_prv  TYPE zif_mig_types=>ty_provider_contract,
    ls_sig  TYPE zif_mig_types=>ty_sig_result,
    ls_smap TYPE zif_mig_types=>ty_svc_map_result,
    ls_mfst TYPE zif_mig_types=>ty_art_mfst,
    ls_bp   TYPE zif_mig_types=>ty_service_blueprint_result.


  "============================================================
  " 1. Service Blueprint
  "============================================================
  ls_bp-blueprint-analysis_id =
    gc_anl_id.

  ls_bp-blueprint-strategy =
    zif_mig_types=>gc_svc_query.

  ls_bp-blueprint-manual_review =
    abap_false.

  ls_bp-blueprint-entity_name =
    'MigrationResult'.

  ls_bp-blueprint-supports_filter =
    abap_true.

  ls_bp-blueprint-source_program =
    sy-repid.


  "BAPIRET2_T output fields
  APPEND VALUE #(
    field_name = 'Type'
    label      = 'Message Type'
    edm_type   = 'Edm.String'
    position   = 10
    key_field  = abap_true
    visible    = abap_true
    filterable = abap_true
    sortable   = abap_true
  ) TO ls_bp-fields.


  APPEND VALUE #(
    field_name = 'Id'
    label      = 'Message Class'
    edm_type   = 'Edm.String'
    position   = 20
    key_field  = abap_true
    visible    = abap_true
    filterable = abap_false
    sortable   = abap_true
  ) TO ls_bp-fields.


  APPEND VALUE #(
    field_name = 'Message'
    label      = 'Message'
    edm_type   = 'Edm.String'
    position   = 30
    key_field  = abap_false
    visible    = abap_true
    filterable = abap_false
    sortable   = abap_true
  ) TO ls_bp-fields.


  "TYPE maps automatically to FM parameter IV_TYPE
  APPEND VALUE #(
    parameter_name     = 'Type'
    source_kind        = 'PARAMETERS'
    odata_kind         = 'SCALAR'
    edm_type           = 'Edm.String'
    mandatory          = abap_false
    multiple_selection = abap_false
    range_supported    = abap_false
  ) TO ls_bp-parameters.


  "============================================================
  " 2. Function Module Provider Contract
  "============================================================
  ls_prv-analysis_id =
    gc_anl_id.

  ls_prv-service_strategy =
    zif_mig_types=>gc_svc_query.

  ls_prv-provider_kind =
    zif_mig_types=>gc_provider_function.

  ls_prv-provider_status =
    zif_mig_types=>gc_provider_ready.

  CLEAR ls_prv-source_container_name.

  ls_prv-source_object_name =
    'Z_MIG_TEST_READ_MESSAGES'.

  ls_prv-manual_review =
    abap_false.


  "============================================================
  " 3. Artifact Manifest
  "============================================================
  ls_mfst-analysis_id =
    gc_anl_id.

  ls_mfst-strategy =
    zif_mig_types=>gc_svc_query.

  ls_mfst-source_program =
    sy-repid.

  ls_mfst-package =
    p_pack.

  ls_mfst-base_name =
    'FM01'.

  ls_mfst-status =
    zif_mig_types=>gc_art_ready.

  ls_mfst-manual_review =
    abap_false.


  APPEND VALUE #(
    seq         = 10
    art_type    = zif_mig_types=>gc_art_clas
    art_role    = zif_mig_types=>gc_art_query_prv
    object_name = p_class
    package     = p_pack
    description = 'Generated MIG FM query provider test'
    gen_order   = 10
    required    = abap_true
    cap_state   = zif_mig_types=>gc_art_cap_yes
    gen_state   = zif_mig_types=>gc_art_planned
  ) TO ls_mfst-items.


  APPEND VALUE #(
    seq         = 20
    art_type    = zif_mig_types=>gc_art_ddls
    art_role    = zif_mig_types=>gc_art_entity
    object_name = p_ddls
    package     = p_pack
    description = 'Generated MIG FM custom entity test'
    gen_order   = 20
    required    = abap_true
    cap_state   = zif_mig_types=>gc_art_cap_yes
    gen_state   = zif_mig_types=>gc_art_planned
  ) TO ls_mfst-items.


  APPEND VALUE #(
    seq         = 40
    art_type    = zif_mig_types=>gc_art_srvd
    art_role    = zif_mig_types=>gc_art_srv_def
    object_name = p_srvd
    package     = p_pack
    description = 'Generated MIG FM service definition test'
    gen_order   = 40
    required    = abap_true
    cap_state   = zif_mig_types=>gc_art_cap_yes
    gen_state   = zif_mig_types=>gc_art_planned
  ) TO ls_mfst-items.


  APPEND VALUE #(
    art_seq = 20
    req_seq = 10
  ) TO ls_mfst-dependencies.


  APPEND VALUE #(
    art_seq = 40
    req_seq = 20
  ) TO ls_mfst-dependencies.


  ls_mfst-item_count =
    lines( ls_mfst-items ).

  ls_mfst-dep_count =
    lines( ls_mfst-dependencies ).


  TRY.

      "==========================================================
      " 4. Read the real Function Module signature
      "==========================================================
      DATA(lo_sig_repo) =
        NEW zcl_mig_sig_repo( ).


      DATA(lo_sig_resolver) =
        NEW zcl_mig_sig_rslv(
          io_repo = lo_sig_repo
        ).


      ls_sig =
        lo_sig_resolver->zif_mig_sig_rslv~resolve(
          is_prv = ls_prv
        ).


      WRITE:
        / 'Signature status :', ls_sig-status,
        / 'Manual review    :', ls_sig-manual_review,
        / 'Reason           :', ls_sig-decision_reason,
        / 'Input count      :', lines( ls_sig-input_params ),
        / 'Output count     :', lines( ls_sig-output_params ).


      LOOP AT ls_sig-all_params
        INTO DATA(ls_sig_debug).

        WRITE:
          / 'Parameter        :', ls_sig_debug-par_name,
          / 'Direction        :', ls_sig_debug-direction,
          / 'ABAP type        :', ls_sig_debug-abap_type,
          / 'Type name        :', ls_sig_debug-type_name,
          / 'EDM type         :', ls_sig_debug-edm_type,
          / 'Optional         :', ls_sig_debug-optional,
          / 'Is table         :', ls_sig_debug-is_table,
          / '-------------------------------'.

      ENDLOOP.


      IF ls_sig-status <>
           zif_mig_types=>gc_sig_ready.

        WRITE:
          / 'Generator stopped because FM signature is not ready.'.

        RETURN.

      ENDIF.


      "==========================================================
      " 5. Read services already registered in shared binding
      "==========================================================
      DATA(lo_registry) =
        NEW zcl_mig_svc_registry( ).


      DATA(lt_shared_services) =
        lo_registry->read_all( ).


      WRITE:
        / 'Shared registry count:',
          lines( lt_shared_services ).


      LOOP AT lt_shared_services
        INTO DATA(ls_shared_debug).

        WRITE:
          / 'Registered service:',
            ls_shared_debug-service_name,
            ls_shared_debug-srvd_name,
            ls_shared_debug-version.

      ENDLOOP.


      "==========================================================
      " 6. Build Service Mapping
      "==========================================================
      ls_smap =
        NEW zcl_mig_svc_map(
          )->zif_mig_svc_map~build(
            is_bp  = ls_bp
            is_sig = ls_sig
          ).


      WRITE:
        / 'Service map status :', ls_smap-status,
        / 'Mapped inputs      :', ls_smap-mapped_inputs,
        / 'Mapping issues     :', ls_smap-issue_count.


      LOOP AT ls_smap-input_maps
        INTO DATA(ls_map_debug).

        WRITE:
          / 'Service parameter :', ls_map_debug-svc_name,
          / 'Provider parameter:', ls_map_debug-prv_name,
          / 'Service EDM       :', ls_map_debug-svc_edm,
          / 'Provider EDM      :', ls_map_debug-prv_edm,
          / 'Map state         :', ls_map_debug-map_state,
          / 'Reason            :', ls_map_debug-reason,
          / '-------------------------------'.

      ENDLOOP.


      IF ls_smap-status <>
           zif_mig_types=>gc_smap_ready.

        WRITE:
          / 'Generator stopped because service mapping is not ready.'.

        RETURN.

      ENDIF.


      "==========================================================
      " 7. Repository Preflight
      "==========================================================
      DATA(lo_pref) =
        NEW zcl_mig_art_pref(
          io_repo =
            NEW zcl_mig_art_repo( )
        ).


      DATA(ls_pref) =
        lo_pref->zif_mig_art_pref~apply(
          is_mfst = ls_mfst
        ).


      WRITE:
        / 'Manifest status :', ls_pref-status,
        / 'Create count    :', ls_pref-create_count,
        / 'Block count     :', ls_pref-block_count.


      LOOP AT ls_pref-items
        INTO DATA(ls_item).

        WRITE:
          / 'Object          :', ls_item-object_name,
          / 'Generation mode :', ls_item-gen_mode,
          / 'Generation state:', ls_item-gen_state,
          / 'Reason          :', ls_item-reason.

      ENDLOOP.


      IF ls_pref-status <>
           zif_mig_types=>gc_art_ready.

        WRITE:
          / 'Generator was not executed.'.

        RETURN.

      ENDIF.


      "==========================================================
      " 8. Generate CLAS + DDLS + SRVD and update shared SRVB
      "==========================================================
      DATA(lo_gen) =
        NEW zcl_mig_xco_gen( ).


      lo_gen->generate_query(
        is_mfst =
          ls_pref

        is_bp =
          ls_bp

        is_prv =
          ls_prv

        is_sig =
          ls_sig

        is_smap =
          ls_smap

        it_shared_services =
          lt_shared_services

        iv_request =
          p_req

        iv_execute =
          p_exec
      ).


      WRITE:
        / 'Generator call completed.'.


      IF p_exec = abap_true.

        lo_registry->upsert(
          iv_service_name = p_srvd
          iv_srvd_name    = p_srvd
          iv_version      = 1
        ).

        WRITE:
          / 'Service registry updated:',
            p_srvd.

      ELSE.

        WRITE:
          / 'Dry run completed. Select P_EXEC to create objects.'.

      ENDIF.


    CATCH zcx_mig_analysis INTO DATA(lx_mig).

      WRITE:
        / 'MIG error:',
          lx_mig->get_text( ).


    CATCH cx_xco_gen_put_exception INTO DATA(lx_xco).

      WRITE:
        / 'XCO generation error:',
          lx_xco->get_text( ).


      DATA(lt_messages) =
        lx_xco->if_xco_news~get_messages( ).


      IF lt_messages IS INITIAL.

        WRITE:
          / 'No detailed XCO message returned.'.

      ELSE.

        WRITE:
          / 'Detailed XCO messages:'.


        LOOP AT lt_messages
          INTO DATA(lo_message).

          WRITE:
            / lo_message->get_text( ).

        ENDLOOP.

      ENDIF.


    CATCH cx_root INTO DATA(lx_root).

      WRITE:
        / 'Unexpected error:',
          lx_root->get_text( ).

  ENDTRY.
