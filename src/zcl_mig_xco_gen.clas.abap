CLASS zcl_mig_xco_gen DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS validate_query_contract
      IMPORTING
        is_bp
          TYPE zif_mig_types=>ty_service_blueprint_result

        is_prv
          TYPE zif_mig_types=>ty_provider_contract

        is_sig
          TYPE zif_mig_types=>ty_sig_result

        is_smap
          TYPE zif_mig_types=>ty_svc_map_result

        is_row
          TYPE zif_mig_types=>ty_row_result

      RAISING
        zcx_mig_analysis.


    METHODS generate_query
      IMPORTING
        is_mfst
          TYPE zif_mig_types=>ty_art_mfst

        is_bp
          TYPE zif_mig_types=>ty_service_blueprint_result

        is_prv
          TYPE zif_mig_types=>ty_provider_contract

        is_sig
          TYPE zif_mig_types=>ty_sig_result

        is_smap
          TYPE zif_mig_types=>ty_svc_map_result

        is_row
          TYPE zif_mig_types=>ty_row_result

        it_shared_services
          TYPE zif_mig_types=>tt_shared_service
          OPTIONAL

        iv_request
          TYPE trkorr

        iv_execute
          TYPE abap_bool
          DEFAULT abap_false

        io_provider_gen
          TYPE REF TO zif_mig_prv_clas_gen OPTIONAL

      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.


  PRIVATE SECTION.

    TYPES:
      ty_boundary_kind TYPE c LENGTH 20,

      BEGIN OF ty_boundary_type,
        supported   TYPE abap_bool,
        kind        TYPE ty_boundary_kind,
        abap_decl   TYPE string,
        char_length TYPE i,
        reason      TYPE string,
      END OF ty_boundary_type.

    CONSTANTS:
      gc_boundary_char       TYPE ty_boundary_kind VALUE 'CHAR',
      gc_boundary_int4       TYPE ty_boundary_kind VALUE 'INT4',
      gc_boundary_int8       TYPE ty_boundary_kind VALUE 'INT8',
      gc_boundary_decfloat34 TYPE ty_boundary_kind VALUE 'DECFLOAT34',
      gc_boundary_date       TYPE ty_boundary_kind VALUE 'DATE',
      gc_boundary_time       TYPE ty_boundary_kind VALUE 'TIME',
      gc_boundary_utclong    TYPE ty_boundary_kind VALUE 'UTCLONG'.

    METHODS validate
      IMPORTING
        is_mfst
          TYPE zif_mig_types=>ty_art_mfst

        iv_request
          TYPE trkorr

      RAISING
        zcx_mig_analysis.


    METHODS add_clas
      IMPORTING
        io_put
          TYPE REF TO if_xco_cp_gen_d_o_put

        is_item
          TYPE zif_mig_types=>ty_art_item

        is_smap
         TYPE zif_mig_types=>ty_svc_map_result

        is_row
          TYPE zif_mig_types=>ty_row_result

        iv_package
          TYPE devclass

        it_fields
          TYPE zif_mig_types=>tt_service_field

        is_prv
          TYPE zif_mig_types=>ty_provider_contract

        is_sig
          TYPE zif_mig_types=>ty_sig_result

      RAISING
        zcx_mig_analysis.

    METHODS add_ddls
          IMPORTING
            io_put
              TYPE REF TO if_xco_cp_gen_d_o_put

            is_item
              TYPE zif_mig_types=>ty_art_item

            iv_class_name
              TYPE zif_mig_types=>ty_art_name

            iv_package
              TYPE devclass

            it_fields
              TYPE zif_mig_types=>tt_service_field

            is_smap
              TYPE zif_mig_types=>ty_svc_map_result

            is_row
              TYPE zif_mig_types=>ty_row_result

          RAISING
            zcx_mig_analysis.

      METHODS add_srvd
          IMPORTING
            io_put
              TYPE REF TO if_xco_cp_gen_d_o_put

            is_item
              TYPE zif_mig_types=>ty_art_item

            iv_package
              TYPE devclass

            iv_entity_name
              TYPE zif_mig_types=>ty_art_name

            iv_alias
              TYPE string

          RAISING
            zcx_mig_analysis.

      METHODS update_shared_srvb
        IMPORTING
          io_put
            TYPE REF TO if_xco_cp_gen_d_o_put

          iv_package
            TYPE devclass

          it_existing_services
            TYPE zif_mig_types=>tt_shared_service

          iv_service_name
            TYPE zif_mig_types=>ty_art_name

          iv_srvd_name
            TYPE zif_mig_types=>ty_art_name

        RAISING
          zcx_mig_analysis.

      METHODS build_select_src
          IMPORTING
            it_fields
              TYPE zif_mig_types=>tt_service_field

            is_prv
              TYPE zif_mig_types=>ty_provider_contract

            is_sig
              TYPE zif_mig_types=>ty_sig_result

            is_smap
              TYPE zif_mig_types=>ty_svc_map_result

            is_row
              TYPE zif_mig_types=>ty_row_result

          RETURNING
            VALUE(rt_source)
              TYPE string_table

          RAISING
            zcx_mig_analysis.

      METHODS norm_name
        IMPORTING
          VALUE(iv_name) TYPE string
        RETURNING
          VALUE(rv_name) TYPE string.

      METHODS resolve_boundary_type
        IMPORTING
          is_field TYPE zif_mig_types=>ty_service_field
        RETURNING
          VALUE(rs_type) TYPE ty_boundary_type.

ENDCLASS.

CLASS zcl_mig_xco_gen IMPLEMENTATION.

  METHOD validate_query_contract.

    DATA(lv_program) =
      is_bp-blueprint-source_program.

    DATA(lv_is_class_provider) =
      xsdbool(
        is_prv-provider_kind =
          zif_mig_types=>gc_provider_class_method
      ).

    DATA(lv_is_fm_provider) =
      xsdbool(
        is_prv-provider_kind =
          zif_mig_types=>gc_provider_function
        OR is_prv-provider_kind =
          zif_mig_types=>gc_provider_bapi
      ).

    DATA(lv_is_bapi_provider) =
      xsdbool(
        is_prv-provider_kind =
          zif_mig_types=>gc_provider_bapi
      ).


    IF is_bp-blueprint-strategy <> zif_mig_types=>gc_svc_query
       OR is_bp-blueprint-manual_review = abap_true
       OR is_bp-blueprint-entity_name IS INITIAL
       OR strlen( is_bp-blueprint-entity_name ) > 30
       OR is_bp-fields IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDIF.


    IF is_prv-service_strategy <> zif_mig_types=>gc_svc_query
       OR (
            is_prv-provider_status <> zif_mig_types=>gc_provider_ready
            AND is_prv-provider_status <> zif_mig_types=>gc_provider_signature
          )
       OR is_prv-manual_review = abap_true
       OR is_prv-source_object_name IS INITIAL
       OR (
            lv_is_class_provider = abap_false
            AND lv_is_fm_provider = abap_false
          )
       OR (
            lv_is_class_provider = abap_true
            AND is_prv-source_container_name IS INITIAL
          ).

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDIF.


    IF is_sig-status <> zif_mig_types=>gc_sig_ready
       OR is_sig-manual_review = abap_true
       OR is_sig-provider_kind <> is_prv-provider_kind
       OR (
            lv_is_class_provider = abap_true
            AND is_sig-provider_static = abap_false
          ).

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDIF.


    IF is_row-status <> zif_mig_types=>gc_row_ready
       OR is_row-manual_review = abap_true
       OR is_row-analysis_id <> is_bp-blueprint-analysis_id
       OR is_row-field_maps IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDIF.


    DATA lv_key_count TYPE i.

    LOOP AT is_bp-fields
      INTO DATA(ls_bp_field)
      WHERE visible = abap_true.

      IF ls_bp_field-key_field = abap_true.
        lv_key_count += 1.
      ENDIF.

      DATA(ls_boundary_type) =
        resolve_boundary_type(
          is_field = ls_bp_field
        ).

      IF ls_boundary_type-supported = abap_false.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid       = zcx_mig_analysis=>analysis_failed
          program_name = lv_program
        ).

      ENDIF.

      READ TABLE is_row-field_maps
        WITH KEY svc_name = ls_bp_field-field_name
        INTO DATA(ls_row_map).

      IF sy-subrc <> 0
         OR ls_row_map-map_state <> zif_mig_types=>gc_row_auto
         OR ls_row_map-comp_name IS INITIAL.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid      = zcx_mig_analysis=>analysis_failed
          program_name = lv_program
        ).

      ENDIF.

    ENDLOOP.


    IF lv_key_count = 0.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDIF.


    LOOP AT is_sig-input_params
      INTO DATA(ls_input_param).

      IF ls_input_param-is_ref = abap_true
         OR ls_input_param-is_deep = abap_true
         OR (
              ls_input_param-direction <> zif_mig_types=>gc_sig_imp
              AND NOT (
                    lv_is_bapi_provider = abap_true
                    AND ls_input_param-direction = zif_mig_types=>gc_sig_tab
                  )
            ).

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid      = zcx_mig_analysis=>analysis_failed
          program_name = lv_program
        ).

      ENDIF.

    ENDLOOP.


    LOOP AT is_sig-all_params
      TRANSPORTING NO FIELDS
      WHERE direction = zif_mig_types=>gc_sig_chg.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDLOOP.


    IF lv_is_bapi_provider = abap_false.

      LOOP AT is_sig-all_params
        TRANSPORTING NO FIELDS
        WHERE direction = zif_mig_types=>gc_sig_tab.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid      = zcx_mig_analysis=>analysis_failed
          program_name = lv_program
        ).

      ENDLOOP.

    ENDIF.


    DATA lv_output_table_count TYPE i.

    LOOP AT is_sig-output_params
      INTO DATA(ls_output_param)
      WHERE is_table = abap_true.

      IF lv_is_class_provider = abap_true
         AND ls_output_param-direction = zif_mig_types=>gc_sig_ret.

        lv_output_table_count += 1.

      ELSEIF lv_is_fm_provider = abap_true
         AND ls_output_param-direction = zif_mig_types=>gc_sig_exp.

        lv_output_table_count += 1.

      ELSEIF lv_is_bapi_provider = abap_true
         AND ls_output_param-direction = zif_mig_types=>gc_sig_tab.

        lv_output_table_count += 1.

      ENDIF.

    ENDLOOP.


    IF lv_output_table_count <> 1
       OR is_smap-status <> zif_mig_types=>gc_smap_ready
       OR is_smap-manual_review = abap_true
       OR is_smap-selected_out-par_name IS INITIAL
       OR is_smap-selected_out-type_name IS INITIAL
       OR is_smap-selected_out-is_table <> abap_true
       OR (
            lv_is_class_provider = abap_true
            AND is_smap-selected_out-direction <> zif_mig_types=>gc_sig_ret
          )
       OR (
            lv_is_fm_provider = abap_true
            AND lv_is_bapi_provider = abap_false
            AND is_smap-selected_out-direction <> zif_mig_types=>gc_sig_exp
          )
       OR (
            lv_is_bapi_provider = abap_true
            AND is_smap-selected_out-direction <> zif_mig_types=>gc_sig_exp
            AND is_smap-selected_out-direction <> zif_mig_types=>gc_sig_tab
          ).

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDIF.


    DATA(lt_source) =
      build_select_src(
        it_fields = is_bp-fields
        is_prv    = is_prv
        is_sig    = is_sig
        is_smap   = is_smap
        is_row    = is_row
      ).


    IF lt_source IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid      = zcx_mig_analysis=>analysis_failed
        program_name = lv_program
      ).

    ENDIF.

  ENDMETHOD.

  METHOD generate_query.

    validate(
      is_mfst    = is_mfst
      iv_request = iv_request
    ).


    validate_query_contract(
      is_bp   = is_bp
      is_prv  = is_prv
      is_sig  = is_sig
      is_smap = is_smap
      is_row  = is_row
    ).


    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_clas
        art_role = zif_mig_types=>gc_art_query_prv
      INTO DATA(ls_clas).

    IF sy-subrc <> 0
       OR ls_clas-object_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_ddls
        art_role = zif_mig_types=>gc_art_entity
      INTO DATA(ls_ddls).

    IF sy-subrc <> 0
       OR ls_ddls-object_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_srvd
        art_role = zif_mig_types=>gc_art_srv_def
      INTO DATA(ls_srvd).


    IF sy-subrc <> 0
       OR ls_srvd-object_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.

    DATA(lv_srv_alias) =
      CONV string(
        is_bp-blueprint-entity_name
      ).

    CONDENSE lv_srv_alias NO-GAPS.


    IF lv_srv_alias IS INITIAL
       OR strlen( lv_srv_alias ) > 30.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.

    IF is_mfst-analysis_id IS NOT INITIAL
       AND is_bp-blueprint-analysis_id <>
             is_mfst-analysis_id.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.

    DATA(lv_standard) = xsdbool(
      is_mfst-provider_language = zif_mig_prv_clas_gen=>gc_standard ).
    DATA lt_standard_source TYPE string_table.
    IF lv_standard = abap_true.
      IF io_provider_gen IS NOT BOUND.
        RAISE EXCEPTION NEW zcx_mig_generation(
          iv_detail = 'Standard provider executor is not configured.' ).
      ENDIF.
      DATA(ls_target_check) = io_provider_gen->check_target( ls_clas-package ).
      IF ls_target_check-allowed <> abap_true OR ls_target_check-language_code <> space.
        RAISE EXCEPTION NEW zcx_mig_generation(
          iv_detail = |Standard provider target rejected: { ls_target_check-message }| ).
      ENDIF.
      lt_standard_source = build_select_src(
        it_fields = is_bp-fields is_prv = is_prv is_sig = is_sig
        is_smap = is_smap is_row = is_row ).
    ENDIF.

    TEST-SEAM prepare_odata.
    DATA(lo_env) =
      xco_cp_generation=>environment->dev_system(
          iv_request
      ).


    DATA(lo_put) =
      lo_env->create_put_operation( ).

    DATA(lo_srvb_put) =
      lo_env->create_put_operation( ).

    IF lv_standard = abap_false.
      add_clas(
        io_put = lo_put
        is_item = ls_clas
        iv_package = ls_clas-package
        it_fields = is_bp-fields
        is_prv = is_prv
        is_sig = is_sig
        is_smap = is_smap
        is_row = is_row ).
    ENDIF.

    add_ddls(
      io_put =
        lo_put

      is_item =
        ls_ddls

      iv_class_name =
        ls_clas-object_name

      iv_package =
        is_mfst-package

      it_fields =
        is_bp-fields

      is_smap =
        is_smap

      is_row =
        is_row
    ).


    add_srvd(
      io_put =
        lo_put

      is_item =
        ls_srvd

      iv_package =
        is_mfst-package

      iv_entity_name =
        ls_ddls-object_name

      iv_alias =
        lv_srv_alias
    ).

    update_shared_srvb(
      io_put              = lo_srvb_put
      iv_package          = is_mfst-package
      it_existing_services = it_shared_services
      iv_service_name     = ls_srvd-object_name
      iv_srvd_name        = ls_srvd-object_name
    ).
    END-TEST-SEAM.

    IF iv_execute = abap_true.

      DATA(lv_stage) = VALUE string( ).
      DATA(lv_completed) = `No completed PUT has been confirmed.`.
      TRY.
          IF lv_standard = abap_true.
            lv_stage = |Standard CLAS { ls_clas-object_name } in { ls_clas-package }|.
            io_provider_gen->generate(
              iv_class_name = ls_clas-object_name
              iv_package = ls_clas-package
              iv_transport = iv_request
              it_select_source = lt_standard_source ).
            lv_completed = |Activated CLAS { ls_clas-object_name } in { ls_clas-package }.|.
          ENDIF.

          lv_stage = |OData PUT for { ls_ddls-object_name }, { ls_srvd-object_name }|.
          TEST-SEAM execute_odata_put.
            lo_put->execute( ).
          END-TEST-SEAM.
          lv_completed = |Activated CLAS { ls_clas-object_name }, DDLS { ls_ddls-object_name }, SRVD { ls_srvd-object_name }.|.

          lv_stage = |Shared binding { zcl_mig_svc_registry=>gc_shared_binding }|.
          TEST-SEAM execute_binding_put.
            lo_srvb_put->execute( ).
          END-TEST-SEAM.
        CATCH cx_xco_gen_put_exception INTO DATA(lx_put).
          DATA(lv_detail) = |{ lv_stage } failed. { lv_completed } { lx_put->get_text( ) }|.
          LOOP AT lx_put->if_xco_news~get_messages( ) INTO DATA(lo_message).
            lv_detail = lv_detail && cl_abap_char_utilities=>newline && lo_message->get_text( ).
          ENDLOOP.
          RAISE EXCEPTION NEW zcx_mig_generation(
            iv_detail = lv_detail && ` Review active/inactive objects before retrying; generation is create-only.`
            previous = lx_put ).
        CATCH cx_root INTO DATA(lx_stage).
          RAISE EXCEPTION NEW zcx_mig_generation(
            iv_detail = |{ lv_stage } failed. { lv_completed } { lx_stage->get_text( ) } Review active/inactive objects before retrying; generation is create-only.|
            previous = lx_stage ).
      ENDTRY.

    ENDIF.

  ENDMETHOD.


  METHOD validate.

    IF is_mfst-provider_language IS NOT INITIAL
       AND is_mfst-provider_language <> zif_mig_prv_clas_gen=>gc_cloud
       AND is_mfst-provider_language <> zif_mig_prv_clas_gen=>gc_standard.
      RAISE EXCEPTION NEW zcx_mig_generation(
        iv_detail = |Unsupported provider language: { is_mfst-provider_language }.| ).
    ENDIF.
    IF is_mfst-provider_language = zif_mig_prv_clas_gen=>gc_standard
       AND is_mfst-provider_package IS INITIAL.
      RAISE EXCEPTION NEW zcx_mig_generation(
        iv_detail = 'STANDARD requires an explicit provider package in the manifest.' ).
    ENDIF.

    LOOP AT is_mfst-items INTO DATA(ls_target_item)
      WHERE art_type = zif_mig_types=>gc_art_clas
        AND art_role = zif_mig_types=>gc_art_query_prv.
      IF ls_target_item-package IS INITIAL
         OR ( is_mfst-provider_package IS NOT INITIAL
              AND ls_target_item-package <> is_mfst-provider_package ).
        RAISE EXCEPTION NEW zcx_mig_generation(
          iv_detail = 'Query provider package does not match the manifest target.' ).
      ENDIF.
    ENDLOOP.

    IF is_mfst-status <>
         zif_mig_types=>gc_art_ready.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    IF is_mfst-strategy <>
         zif_mig_types=>gc_svc_query.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    IF is_mfst-package IS INITIAL
       OR iv_request IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    IF is_mfst-create_count <= 0
       OR is_mfst-block_count > 0.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    LOOP AT is_mfst-items
      INTO DATA(ls_item)
      WHERE required = abap_true.

      IF ls_item-gen_state <>
           zif_mig_types=>gc_art_planned
         OR ls_item-gen_mode <>
              zif_mig_types=>gc_art_create.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed

          program_name =
            is_mfst-source_program
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD add_clas.

  DATA(lo_spec) =
    io_put->for-clas->add_object(
      is_item-object_name
    )->set_package(
      iv_package
    )->create_form_specification( ).


  lo_spec->set_short_description(
    'Generated MIG query provider'
  ).


  lo_spec->definition->set_create_visibility(
    xco_cp_abap_objects=>visibility->public
  ).


  lo_spec->definition->add_interface(
    'IF_RAP_QUERY_PROVIDER'
  ).


  DATA(lt_select_source) =
      build_select_src(
        it_fields =
          it_fields

        is_prv =
          is_prv

        is_sig =
          is_sig

        is_smap =
          is_smap

        is_row =
          is_row
      ).


  lo_spec->implementation->add_method(
    'IF_RAP_QUERY_PROVIDER~SELECT'
  )->set_source(
    lt_select_source
  ).

ENDMETHOD.

METHOD add_ddls.

  DATA(lo_spec) =
    io_put->for-ddls->add_object(
      is_item-object_name
    )->set_package(
      iv_package
    )->create_form_specification( ).


  lo_spec->set_short_description(
    'Generated MIG custom entity'
  ).


  DATA(lo_entity) =
    lo_spec->add_custom_entity( ).


  lo_entity->add_annotation(
    'EndUserText.label'
  )->value->build(
  )->add_string(
    'Generated MIG query entity'
  ).


  DATA(lv_provider) =
    |ABAP:{ iv_class_name }|.


  lo_entity->add_annotation(
    'ObjectModel.query.implementedBy'
  )->value->build(
  )->add_string(
    lv_provider
  ).


  DATA lt_fields
      TYPE zif_mig_types=>tt_service_field.

    lt_fields =
      it_fields.

    DELETE lt_fields
      WHERE visible = abap_false.

    SORT lt_fields
      BY position
         field_name.


    IF lt_fields IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    DATA lv_has_key
      TYPE abap_bool.

    lv_has_key =
      abap_false.

    LOOP AT lt_fields
      INTO DATA(ls_field).

      DATA(lv_name) =
        ls_field-field_name.

      CONDENSE lv_name NO-GAPS.

      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.


      DATA(lo_field) =
      lo_entity->add_field(
        xco_cp_ddl=>field(
          CONV #( lv_name )
        )
      ).


      "Do not expose legacy DDIC data elements in the custom entity.
      "The same boundary policy is used by DDLS and query source.
      DATA(ls_ddls_type) =
        resolve_boundary_type(
          is_field = ls_field
        ).

      IF ls_ddls_type-supported = abap_false.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid = zcx_mig_analysis=>analysis_failed
        ).

      ENDIF.

      CASE ls_ddls_type-kind.

        WHEN gc_boundary_char.

          lo_field->set_type(
             xco_cp_abap_dictionary=>built_in_type->char(
              CONV #( ls_ddls_type-char_length ) )
            ).


        WHEN gc_boundary_int4.

          lo_field->set_type(
            xco_cp_abap_dictionary=>built_in_type->int4
          ).


        WHEN gc_boundary_int8.

          lo_field->set_type(
            xco_cp_abap_dictionary=>built_in_type->int8
          ).


        WHEN gc_boundary_decfloat34.

          lo_field->set_type(
            xco_cp_abap_dictionary=>built_in_type->decfloat34
          ).


        WHEN gc_boundary_date.

          lo_field->set_type(
            xco_cp_abap_dictionary=>built_in_type->dats
          ).


        WHEN gc_boundary_time.

          lo_field->set_type(
            xco_cp_abap_dictionary=>built_in_type->tims
          ).


        WHEN gc_boundary_utclong.

          lo_field->set_type(
            xco_cp_abap_dictionary=>built_in_type->utclong
          ).


        WHEN OTHERS.

          RAISE EXCEPTION NEW zcx_mig_analysis(
            textid = zcx_mig_analysis=>analysis_failed
          ).

      ENDCASE.

      IF ls_field-key_field = abap_true.

        lo_field->set_key( ).

        lv_has_key =
          abap_true.

      ENDIF.


      DATA(lv_label) =
        COND string(
          WHEN ls_field-label IS NOT INITIAL
          THEN ls_field-label
          ELSE ls_field-field_name
        ).


      lo_field->add_annotation(
        'EndUserText.label'
      )->value->build(
      )->add_string(
        lv_label
      ).

      DATA(lv_position) =
          ls_field-position.


        IF lv_position <= 0.

          lv_position =
            sy-tabix * 10.

        ENDIF.


        lo_field->add_annotation(
          'UI.lineItem'
        )->value->build(
        )->begin_array(
        )->begin_record(
        )->add_member(
          'position'
        )->add_number(
          lv_position
        )->add_member(
          'label'
        )->add_string(
          lv_label
        )->end_record(
        )->end_array( ).

        lo_field->add_annotation(
          'UI.identification'
        )->value->build(
        )->begin_array(
        )->begin_record(
        )->add_member(
          'position'
        )->add_number(
          lv_position
        )->add_member(
          'label'
        )->add_string(
          lv_label
        )->end_record(
        )->end_array( ).

        IF ls_field-filterable =
             abap_true.

          DATA(lv_field_up) =
            to_upper(
              CONV string(
                ls_field-field_name
              )
            ).

          CONDENSE lv_field_up NO-GAPS.


          DATA lv_filter_mapped
            TYPE abap_bool.

          DATA lv_filter_mandatory
            TYPE abap_bool.

          lv_filter_mapped =
            abap_false.

          lv_filter_mandatory =
            abap_false.


          LOOP AT is_smap-input_maps
            INTO DATA(ls_input_map)
            WHERE map_state =
              zif_mig_types=>gc_smap_auto.

            DATA(lv_svc_up) =
              to_upper(
                CONV string(
                  ls_input_map-svc_name
                )
              ).

            CONDENSE lv_svc_up NO-GAPS.


    IF lv_svc_up =
         lv_field_up.

      lv_filter_mapped =
        abap_true.

      lv_filter_mandatory =
        xsdbool(
          ls_input_map-mandatory = abap_true
          OR ls_input_map-prv_optional = abap_false
        ).

      EXIT.

    ENDIF.

  ENDLOOP.


  IF lv_filter_mapped =
       abap_true.

    lo_field->add_annotation(
      'UI.selectionField'
    )->value->build(
    )->begin_array(
    )->begin_record(
    )->add_member(
      'position'
    )->add_number(
      lv_position
    )->end_record(
    )->end_array( ).

    IF lv_filter_mandatory = abap_true.

      lo_field->add_annotation(
        'Consumption.filter.mandatory'
      )->value->build(
      )->add_boolean(
        abap_true
      ).

    ENDIF.

  ENDIF.

ENDIF.

    ENDLOOP.

    IF lv_has_key = abap_false.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.

ENDMETHOD.


METHOD add_srvd.

  IF is_item-object_name IS INITIAL
     OR iv_entity_name IS INITIAL
     OR iv_alias IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  DATA(lo_spec) =
    io_put->for-srvd->add_object(
      is_item-object_name
    )->set_package(
      iv_package
    )->create_form_specification( ).


  lo_spec->set_short_description(
    'Generated MIG service definition'
  ).


  lo_spec->add_annotation(
    'EndUserText.label'
  )->value->build(
  )->add_string(
    'Generated MIG service definition'
  ).


  lo_spec->add_exposure(
    iv_entity_name
  )->set_alias(
    CONV #( iv_alias )
  ).

ENDMETHOD.

METHOD update_shared_srvb.

  CONSTANTS gc_shared_srvb
    TYPE zif_mig_types=>ty_art_name
    VALUE 'ZUI_MIG_SHARED_O4'.


  IF iv_package IS INITIAL
     OR iv_service_name IS INITIAL
     OR iv_srvd_name IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  DATA(lo_spec) =
    io_put->for-srvb->add_object(
      CONV #( gc_shared_srvb )
    )->set_package(
      iv_package
    )->create_form_specification( ).


  lo_spec->set_short_description(
    'MIG shared OData V4 binding'
  ).


  lo_spec->set_binding_type(
    xco_cp_service_binding=>binding_type->odata_v4_ui
  ).


  DATA(lv_new_service) =
    to_upper(
      CONV string(
        iv_service_name
      )
    ).

  CONDENSE lv_new_service NO-GAPS.


  DATA lt_services
    TYPE zif_mig_types=>tt_shared_service.

  lt_services =
    it_existing_services.


  "Remove duplicate of the service being generated.
  "The new definition will be appended once with version 0001.
  LOOP AT lt_services
    ASSIGNING FIELD-SYMBOL(<ls_service>).

    DATA(lv_existing_name) =
      to_upper(
        CONV string(
          <ls_service>-service_name
        )
      ).

    CONDENSE lv_existing_name NO-GAPS.


    IF lv_existing_name =
         lv_new_service.

      DELETE lt_services
        INDEX sy-tabix.

    ENDIF.

  ENDLOOP.


  SORT lt_services
    BY service_name
       version
       srvd_name.


  DELETE ADJACENT DUPLICATES FROM lt_services
    COMPARING
      service_name
      version
      srvd_name.


  LOOP AT lt_services
    INTO DATA(ls_service).

    IF ls_service-service_name IS INITIAL
       OR ls_service-srvd_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    DATA(lv_version) =
      ls_service-version.


    IF lv_version <= 0.
      lv_version = 1.
    ENDIF.


    DATA(lo_existing_service) =
      lo_spec->add_service(
        CONV #( ls_service-service_name )
      ).


    lo_existing_service->add_version(
      CONV #( lv_version )
    )->set_service_definition(
       ls_service-srvd_name
    ).

  ENDLOOP.


  DATA(lo_new_service) =
    lo_spec->add_service(
      CONV #( iv_service_name )
    ).


  lo_new_service->add_version(
    0001
  )->set_service_definition(
     iv_srvd_name
  ).

ENDMETHOD.

METHOD build_select_src.

  DATA lt_fields
    TYPE zif_mig_types=>tt_service_field.

  DATA(lv_is_fm_provider) =
    xsdbool(
      is_prv-provider_kind =
        zif_mig_types=>gc_provider_function
      OR is_prv-provider_kind =
        zif_mig_types=>gc_provider_bapi
    ).

  DATA(lv_is_bapi_provider) =
    xsdbool(
      is_prv-provider_kind =
        zif_mig_types=>gc_provider_bapi
    ).


  lt_fields =
    it_fields.


  DELETE lt_fields
    WHERE visible = abap_false.


  SORT lt_fields
    BY position
       field_name.


  IF lt_fields IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  "============================================================
  " Xác định field sort mặc định:
  " 1. Key
  " 2. Field sortable đầu tiên
  " 3. Field đầu tiên
  "============================================================
  DATA lv_def_sort
    TYPE string.


  READ TABLE lt_fields
    WITH KEY key_field = abap_true
    INTO DATA(ls_def_sort).


  IF sy-subrc <> 0.

    READ TABLE lt_fields
      WITH KEY sortable = abap_true
      INTO ls_def_sort.

  ENDIF.


  IF sy-subrc <> 0.

    READ TABLE lt_fields
      INDEX 1
      INTO ls_def_sort.

  ENDIF.


  lv_def_sort =
    CONV string(
      ls_def_sort-field_name
    ).

  CONDENSE lv_def_sort NO-GAPS.


  IF lv_def_sort IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  "============================================================
  " Checkpoint input:
  " - SCALAR optional or mandatory:
  "   String / Int32 / Int64 / Decimal / Double / Date
  " - RANGE optional or mandatory:
  "   Edm.String, provider named table type
  " - Service Mapping = AUTO
  "============================================================
  DATA lt_input_maps
    TYPE zif_mig_types=>tt_svc_in_map.


  lt_input_maps =
    is_smap-input_maps.


  SORT lt_input_maps
    BY svc_name
       prv_name.


  DATA lt_resolved_input_maps
    TYPE zif_mig_types=>tt_svc_in_map.


  LOOP AT lt_input_maps
    INTO DATA(ls_input_map).

    DATA(lv_svc_kind) =
      to_upper(
        CONV string(
          ls_input_map-svc_kind
        )
      ).

    DATA(lv_svc_edm) =
      to_upper(
        CONV string(
          ls_input_map-svc_edm
        )
      ).

    DATA(lv_prv_edm) =
      to_upper(
        CONV string(
          ls_input_map-prv_edm
        )
      ).


    READ TABLE is_sig-input_params
      WITH KEY par_name = ls_input_map-prv_name
      INTO DATA(ls_sig_input).

    IF sy-subrc <> 0
       OR ls_input_map-map_state <>
            zif_mig_types=>gc_smap_auto
       OR ls_input_map-svc_name IS INITIAL
       OR ls_input_map-prv_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    CASE lv_svc_kind.

      WHEN 'SCALAR'.

        IF ls_sig_input-is_table =
             abap_true
           OR lv_svc_edm <> lv_prv_edm.

          RAISE EXCEPTION NEW zcx_mig_analysis(
            textid =
              zcx_mig_analysis=>analysis_failed
          ).

        ENDIF.


        CASE lv_svc_edm.

          WHEN 'EDM.STRING'
            OR 'EDM.INT32'
            OR 'EDM.INT64'
            OR 'EDM.DECIMAL'
            OR 'EDM.DOUBLE'
            OR 'EDM.DATE'.

            "Supported scalar type


          WHEN OTHERS.

            RAISE EXCEPTION NEW zcx_mig_analysis(
              textid =
                zcx_mig_analysis=>analysis_failed
            ).

        ENDCASE.


      WHEN 'RANGE'.

        IF lv_svc_edm <> 'EDM.STRING'
           OR lv_prv_edm <> lv_svc_edm
           OR ls_sig_input-is_table <>
                abap_true
           OR ls_sig_input-type_name IS INITIAL.

          RAISE EXCEPTION NEW zcx_mig_analysis(
            textid =
              zcx_mig_analysis=>analysis_failed
          ).

        ENDIF.


      WHEN OTHERS.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
        ).

    ENDCASE.


    "Service parameter phải có output field filterable tương ứng
    DATA(lv_svc_name_up) =
      norm_name(
        iv_name = CONV string(
          ls_input_map-svc_name
        )
      ).


    DATA:
      lv_filter_field_hits TYPE i,
      lv_filter_field_name TYPE string.

    CLEAR:
      lv_filter_field_hits,
      lv_filter_field_name.


    LOOP AT lt_fields
      INTO DATA(ls_filter_field)
      WHERE filterable = abap_true.

      DATA(lv_field_name_up) =
        norm_name(
          iv_name = CONV string(
            ls_filter_field-field_name
          )
        ).


      IF lv_field_name_up =
           lv_svc_name_up.

        lv_filter_field_hits += 1.

        lv_filter_field_name =
          ls_filter_field-field_name.

      ENDIF.

    ENDLOOP.


    IF lv_filter_field_hits <> 1
       OR lv_filter_field_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    "Generated OData filters must use the actual entity field.
    "For example, P_BUKRS is resolved to BUKRS.
    ls_input_map-svc_name =
      lv_filter_field_name.

    APPEND ls_input_map
      TO lt_resolved_input_maps.

  ENDLOOP.


  lt_input_maps =
    lt_resolved_input_maps.


  "============================================================
  " Output table của provider dùng cho dynamic method call
  "============================================================
  DATA(lv_output_type) =
    CONV string(
      is_smap-selected_out-type_name
    ).

  CONDENSE lv_output_type NO-GAPS.


  IF lv_output_type CP '\CLASS=*\TYPE=*'.

    REPLACE FIRST OCCURRENCE OF '\CLASS='
      IN lv_output_type
      WITH ''.

    REPLACE FIRST OCCURRENCE OF '\TYPE='
      IN lv_output_type
      WITH '=>'.


  ELSEIF lv_output_type CP '\INTERFACE=*\TYPE=*'.

    REPLACE FIRST OCCURRENCE OF '\INTERFACE='
      IN lv_output_type
      WITH ''.

    REPLACE FIRST OCCURRENCE OF '\TYPE='
      IN lv_output_type
      WITH '=>'.


  ELSEIF lv_output_type CP '\TYPE=*'.

    REPLACE FIRST OCCURRENCE OF '\TYPE='
      IN lv_output_type
      WITH ''.

  ENDIF.


  DATA(lv_output_param) =
    to_upper(
      CONV string(
        is_smap-selected_out-par_name
      )
    ).

  CONDENSE lv_output_param NO-GAPS.


  IF lv_output_type IS INITIAL
     OR lv_output_type CS '\'
     OR lv_output_param IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  "============================================================
  " Optional BAPI RETURN/BAPIRET message parameter
  "============================================================
  DATA:
    lv_bapi_message_count TYPE i,
    ls_bapi_message       TYPE zif_mig_types=>ty_sig_par,
    lv_bapi_message_name  TYPE string,
    lv_bapi_message_type  TYPE string.


  IF lv_is_bapi_provider = abap_true.

    LOOP AT is_sig-all_params
      INTO DATA(ls_technical_param)
      WHERE odata_role = zif_mig_types=>gc_sig_tech.

      lv_bapi_message_count += 1.
      ls_bapi_message = ls_technical_param.

    ENDLOOP.


    IF lv_bapi_message_count > 1
       OR (
            lv_bapi_message_count = 1
            AND ls_bapi_message-direction <> zif_mig_types=>gc_sig_tab
            AND ls_bapi_message-direction <> zif_mig_types=>gc_sig_exp
          ).

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    IF lv_bapi_message_count = 1.

      lv_bapi_message_name =
        to_upper(
          CONV string( ls_bapi_message-par_name )
        ).

      lv_bapi_message_type =
        CONV string( ls_bapi_message-type_name ).

      CONDENSE lv_bapi_message_name NO-GAPS.
      CONDENSE lv_bapi_message_type NO-GAPS.


      IF lv_bapi_message_type CP '\TYPE=*'.

        REPLACE FIRST OCCURRENCE OF '\TYPE='
          IN lv_bapi_message_type
          WITH ''.

      ENDIF.


      IF lv_bapi_message_name IS INITIAL
         OR lv_bapi_message_type IS INITIAL
         OR lv_bapi_message_type CS '\'
         OR lv_bapi_message_type CP '%_*'.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid = zcx_mig_analysis=>analysis_failed
        ).

      ENDIF.

    ENDIF.

  ENDIF.


  "============================================================
  " Sinh local result type
  "============================================================
  APPEND
    |TYPES:|
    TO rt_source.

  APPEND
    |  BEGIN OF ty_result,|
    TO rt_source.


  LOOP AT lt_fields
    INTO DATA(ls_field).

    DATA(lv_name) =
      CONV string(
        ls_field-field_name
      ).

    CONDENSE lv_name NO-GAPS.

    IF lv_name IS INITIAL.
      CONTINUE.
    ENDIF.


    "The query class and DDLS must use exactly the same OData
    "boundary type. The provider table itself keeps its original
    "DDIC type; only the generated result structure is converted.
    DATA(ls_query_type) =
      resolve_boundary_type(
        is_field = ls_field
      ).

    IF ls_query_type-supported = abap_false.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    APPEND
      |    { lv_name } { ls_query_type-abap_decl },|
      TO rt_source.

  ENDLOOP.


  APPEND
    |  END OF ty_result.|
    TO rt_source.


  APPEND
    |DATA lt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.|
    TO rt_source.

  APPEND
      |DATA(lo_paging) = io_request->get_paging( ).|
      TO rt_source.


    APPEND
      |DATA(lv_offset) = lo_paging->get_offset( ).|
      TO rt_source.


    APPEND
      |DATA(lv_page_size) = lo_paging->get_page_size( ).|
      TO rt_source.

  "============================================================
  "============================================================
  " Chuẩn hóa tên provider
  "============================================================
  DATA:
    lv_class_name TYPE string,
    lv_method_name TYPE string,
    lv_fm_name TYPE string.


  IF lv_is_fm_provider = abap_true.

    lv_fm_name =
      to_upper(
        CONV string(
          is_prv-source_object_name
        )
      ).

    CONDENSE lv_fm_name NO-GAPS.


    IF lv_fm_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


  ELSE.

    lv_class_name =
      to_upper(
        CONV string(
          is_prv-source_container_name
        )
      ).

    CONDENSE lv_class_name NO-GAPS.


    lv_method_name =
      to_upper(
        CONV string(
          is_prv-source_object_name
        )
      ).

    CONDENSE lv_method_name NO-GAPS.


    IF lv_class_name IS INITIAL
       OR lv_method_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.

  ENDIF.


  "============================================================
  " Biến hỗ trợ sinh source cho scalar + range filters
  "============================================================
  DATA:
    lv_filter_idx   TYPE i,
    lv_filter_var   TYPE string,
    lv_filter_set   TYPE string,
    lv_filter_decl  TYPE string,
    lv_filter_edm   TYPE string,
    lv_filter_kind  TYPE string,
    lv_filter_name  TYPE string,
    lv_prv_param    TYPE string,
    lv_prv_type     TYPE string.


  APPEND
    |DATA(lv_filter_valid) = abap_true.|
    TO rt_source.


  APPEND
    |DATA(lv_mandatory_missing) = abap_false.|
    TO rt_source.


  "============================================================
  " Khai báo variable cho từng mapped input
  "
  " SCALAR -> LV_Fn TYPE elementary
  " RANGE  -> LT_Fn TYPE provider named range type
  "============================================================
  CLEAR lv_filter_idx.


  LOOP AT lt_input_maps
    INTO ls_input_map.

    lv_filter_idx += 1.

    lv_filter_set =
      |lv_f{ lv_filter_idx }_set|.

    lv_filter_kind =
      to_upper(
        CONV string(
          ls_input_map-svc_kind
        )
      ).

    lv_filter_edm =
      to_upper(
        CONV string(
          ls_input_map-svc_edm
        )
      ).


    READ TABLE is_sig-input_params
      WITH KEY par_name = ls_input_map-prv_name
      INTO ls_sig_input.

    IF sy-subrc <> 0.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    IF lv_filter_kind = 'RANGE'.

      lv_filter_var =
        |lt_f{ lv_filter_idx }|.

      lv_prv_type =
        CONV string(
          ls_sig_input-type_name
        ).

      CONDENSE lv_prv_type NO-GAPS.


      IF lv_prv_type IS INITIAL.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
        ).

      ENDIF.


      IF lv_is_bapi_provider = abap_true
         AND ls_sig_input-direction = zif_mig_types=>gc_sig_tab.

        APPEND
          |DATA { lv_filter_var } TYPE STANDARD TABLE OF { lv_prv_type } WITH DEFAULT KEY.|
          TO rt_source.

      ELSE.

        APPEND
          |DATA { lv_filter_var } TYPE { lv_prv_type }.|
          TO rt_source.

      ENDIF.


    ELSE.

  lv_filter_var =
    |lv_f{ lv_filter_idx }|.


  "Dynamic calls require a data reference with the provider's
  "actual declared parameter type for both FM and class methods.
  IF ls_sig_input-type_name IS NOT INITIAL.

    lv_prv_type =
      CONV string(
        ls_sig_input-type_name
      ).

    CONDENSE lv_prv_type NO-GAPS.


    IF lv_prv_type CP '\CLASS=*\TYPE=*'.

      REPLACE FIRST OCCURRENCE OF '\CLASS='
        IN lv_prv_type
        WITH ''.

      REPLACE FIRST OCCURRENCE OF '\TYPE='
        IN lv_prv_type
        WITH '=>'.


    ELSEIF lv_prv_type CP '\INTERFACE=*\TYPE=*'.

      REPLACE FIRST OCCURRENCE OF '\INTERFACE='
        IN lv_prv_type
        WITH ''.

      REPLACE FIRST OCCURRENCE OF '\TYPE='
        IN lv_prv_type
        WITH '=>'.


    ELSEIF lv_prv_type CP '\TYPE=*'.

      REPLACE FIRST OCCURRENCE OF '\TYPE='
        IN lv_prv_type
        WITH ''.

    ENDIF.


    IF lv_prv_type IS INITIAL
       OR lv_prv_type CS '\'.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    lv_filter_decl =
      |TYPE { lv_prv_type }|.


  ELSE.

    CASE lv_filter_edm.

      WHEN 'EDM.STRING'.

        lv_filter_decl =
          'TYPE c LENGTH 120'.


      WHEN 'EDM.INT32'.

        lv_filter_decl =
          'TYPE i'.


      WHEN 'EDM.INT64'.

        lv_filter_decl =
          'TYPE int8'.


      WHEN 'EDM.DECIMAL'.

        lv_filter_decl =
          'TYPE decfloat16'.


      WHEN 'EDM.DOUBLE'.

        lv_filter_decl =
          'TYPE decfloat34'.


      WHEN 'EDM.DATE'.

        lv_filter_decl =
          'TYPE d'.


      WHEN OTHERS.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
        ).

    ENDCASE.

  ENDIF.


  APPEND
    |DATA { lv_filter_var } { lv_filter_decl }.|
    TO rt_source.

ENDIF.


    APPEND
      |DATA { lv_filter_set } TYPE abap_bool.|
      TO rt_source.

  ENDLOOP.



  "============================================================
  " Đọc request filters
  "
  " SCALAR:
  " - đúng 1 row
  " - SIGN I
  " - OPTION EQ
  "
  " RANGE Edm.String:
  " - 1..N rows
  " - SIGN I
  " - OPTION EQ hoặc BT
  "============================================================
  APPEND
    |TRY.|
    TO rt_source.


  APPEND
    |    DATA(lt_filter_ranges) = io_request->get_filter( )->get_as_ranges( ).|
    TO rt_source.


  APPEND
    |    LOOP AT lt_filter_ranges INTO DATA(ls_filter_pair).|
    TO rt_source.


  APPEND
    |      DATA(lv_req_filter_name) = to_upper( ls_filter_pair-name ).|
    TO rt_source.


  "Khai báo work area đúng một lần, tránh inline declaration lặp
  APPEND
    |      READ TABLE ls_filter_pair-range INDEX 1 INTO DATA(ls_filter_option).|
    TO rt_source.


  APPEND
    |      IF sy-subrc <> 0.|
    TO rt_source.


  APPEND
    |        lv_filter_valid = abap_false.|
    TO rt_source.


  APPEND
    |        EXIT.|
    TO rt_source.


  APPEND
    |      ENDIF.|
    TO rt_source.


  APPEND
    |      CASE lv_req_filter_name.|
    TO rt_source.


  CLEAR lv_filter_idx.


  LOOP AT lt_input_maps
    INTO ls_input_map.

    lv_filter_idx += 1.

    lv_filter_set =
      |lv_f{ lv_filter_idx }_set|.

    lv_filter_kind =
      to_upper(
        CONV string(
          ls_input_map-svc_kind
        )
      ).

    lv_filter_edm =
      to_upper(
        CONV string(
          ls_input_map-svc_edm
        )
      ).

    lv_filter_name =
      to_upper(
        CONV string(
          ls_input_map-svc_name
        )
      ).

    CONDENSE lv_filter_name NO-GAPS.


    APPEND
      |        WHEN '{ lv_filter_name }'.|
      TO rt_source.


    IF lv_filter_kind = 'RANGE'.

      lv_filter_var =
        |lt_f{ lv_filter_idx }|.


      APPEND
        |          CLEAR { lv_filter_var }.|
        TO rt_source.


      APPEND
        |          LOOP AT ls_filter_pair-range INTO ls_filter_option.|
        TO rt_source.


      APPEND
        |            IF ls_filter_option-sign <> 'I'.|
        TO rt_source.


      APPEND
        |              lv_filter_valid = abap_false.|
        TO rt_source.


      APPEND
        |              EXIT.|
        TO rt_source.


      APPEND
        |            ENDIF.|
        TO rt_source.


      APPEND
        |            CASE ls_filter_option-option.|
        TO rt_source.


      APPEND
        |              WHEN 'EQ'.|
        TO rt_source.


      APPEND
        |                IF ls_filter_option-high IS NOT INITIAL.|
        TO rt_source.


      APPEND
        |                  lv_filter_valid = abap_false.|
        TO rt_source.


      APPEND
        |                ENDIF.|
        TO rt_source.


    APPEND
      |              WHEN 'BT'.|
      TO rt_source.


    APPEND
      |                IF ls_filter_option-low IS INITIAL|
      TO rt_source.


    APPEND
      |                   OR ls_filter_option-high IS INITIAL.|
      TO rt_source.


    APPEND
      |                  lv_filter_valid = abap_false.|
      TO rt_source.


    APPEND
      |                ENDIF.|
      TO rt_source.


      APPEND
        |              WHEN OTHERS.|
        TO rt_source.


      APPEND
        |                lv_filter_valid = abap_false.|
        TO rt_source.


      APPEND
        |            ENDCASE.|
        TO rt_source.


      APPEND
        |            IF lv_filter_valid = abap_false.|
        TO rt_source.


      APPEND
        |              EXIT.|
        TO rt_source.


      APPEND
        |            ENDIF.|
        TO rt_source.


      APPEND
        |            APPEND VALUE #(|
        TO rt_source.


      APPEND
        |              sign   = ls_filter_option-sign|
        TO rt_source.


      APPEND
        |              option = ls_filter_option-option|
        TO rt_source.


      APPEND
        |              low    = ls_filter_option-low|
        TO rt_source.


      APPEND
        |              high   = ls_filter_option-high|
        TO rt_source.


      APPEND
        |            ) TO { lv_filter_var }.|
        TO rt_source.


      APPEND
        |          ENDLOOP.|
        TO rt_source.


      APPEND
        |          IF lv_filter_valid = abap_true|
        TO rt_source.


      APPEND
        |             AND { lv_filter_var } IS NOT INITIAL.|
        TO rt_source.


      APPEND
        |            { lv_filter_set } = abap_true.|
        TO rt_source.


      APPEND
        |          ENDIF.|
        TO rt_source.


    ELSE.

      lv_filter_var =
        |lv_f{ lv_filter_idx }|.


      "Scalar chỉ chấp nhận đúng một I/EQ row
      APPEND
        |          IF lines( ls_filter_pair-range ) <> 1|
        TO rt_source.


      APPEND
        |             OR ls_filter_option-sign <> 'I'|
        TO rt_source.


      APPEND
        |             OR ls_filter_option-option <> 'EQ'|
        TO rt_source.


      APPEND
        |             OR ls_filter_option-high IS NOT INITIAL.|
        TO rt_source.


      APPEND
        |            lv_filter_valid = abap_false.|
        TO rt_source.


      APPEND
        |          ELSE.|
        TO rt_source.


      CASE lv_filter_edm.

        WHEN 'EDM.STRING'.

          APPEND
            |            { lv_filter_var } = ls_filter_option-low.|
            TO rt_source.


          APPEND
            |            { lv_filter_set } = abap_true.|
            TO rt_source.


        WHEN 'EDM.INT32'.

          APPEND
            |            TRY.|
            TO rt_source.


          APPEND
            |                { lv_filter_var } = CONV i( ls_filter_option-low ).|
            TO rt_source.


          APPEND
            |                { lv_filter_set } = abap_true.|
            TO rt_source.


          APPEND
            |              CATCH cx_sy_conversion_error.|
            TO rt_source.


          APPEND
            |                lv_filter_valid = abap_false.|
            TO rt_source.


          APPEND
            |            ENDTRY.|
            TO rt_source.


        WHEN 'EDM.INT64'.

          APPEND
            |            TRY.|
            TO rt_source.


          APPEND
            |                { lv_filter_var } = CONV int8( ls_filter_option-low ).|
            TO rt_source.


          APPEND
            |                { lv_filter_set } = abap_true.|
            TO rt_source.


          APPEND
            |              CATCH cx_sy_conversion_error.|
            TO rt_source.


          APPEND
            |                lv_filter_valid = abap_false.|
            TO rt_source.


          APPEND
            |            ENDTRY.|
            TO rt_source.


        WHEN 'EDM.DECIMAL'.

          APPEND
            |            TRY.|
            TO rt_source.


          APPEND
            |                { lv_filter_var } = CONV decfloat16( ls_filter_option-low ).|
            TO rt_source.


          APPEND
            |                { lv_filter_set } = abap_true.|
            TO rt_source.


          APPEND
            |              CATCH cx_sy_conversion_error.|
            TO rt_source.


          APPEND
            |                lv_filter_valid = abap_false.|
            TO rt_source.


          APPEND
            |            ENDTRY.|
            TO rt_source.


        WHEN 'EDM.DOUBLE'.

          APPEND
            |            TRY.|
            TO rt_source.


          APPEND
            |                { lv_filter_var } = CONV decfloat34( ls_filter_option-low ).|
            TO rt_source.


          APPEND
            |                { lv_filter_set } = abap_true.|
            TO rt_source.


          APPEND
            |              CATCH cx_sy_conversion_error.|
            TO rt_source.


          APPEND
            |                lv_filter_valid = abap_false.|
            TO rt_source.


          APPEND
            |            ENDTRY.|
            TO rt_source.


        WHEN 'EDM.DATE'.

          APPEND
            |            TRY.|
            TO rt_source.


          APPEND
            |                { lv_filter_var } = CONV d( replace( val = ls_filter_option-low sub = '-' with = '' occ = 0 ) ).|
            TO rt_source.


          APPEND
            |                { lv_filter_set } = abap_true.|
            TO rt_source.


          APPEND
            |              CATCH cx_sy_conversion_error.|
            TO rt_source.


          APPEND
            |                lv_filter_valid = abap_false.|
            TO rt_source.


          APPEND
            |            ENDTRY.|
            TO rt_source.

      ENDCASE.


      APPEND
        |          ENDIF.|
        TO rt_source.

    ENDIF.

  ENDLOOP.


  APPEND
    |        WHEN OTHERS.|
    TO rt_source.


  APPEND
    |          lv_filter_valid = abap_false.|
    TO rt_source.


  APPEND
    |      ENDCASE.|
    TO rt_source.


  APPEND
    |      IF lv_filter_valid = abap_false.|
    TO rt_source.


  APPEND
    |        EXIT.|
    TO rt_source.


  APPEND
    |      ENDIF.|
    TO rt_source.


  APPEND
    |    ENDLOOP.|
    TO rt_source.


  APPEND
    |  CATCH cx_rap_query_filter_no_range.|
    TO rt_source.


  APPEND
    |    lv_filter_valid = abap_false.|
    TO rt_source.


  APPEND
    |ENDTRY.|
    TO rt_source.


  "============================================================
  " Mandatory selection parameters must be present in the request.
  " A non-optional provider input is mandatory even when legacy
  " selection metadata did not mark it correctly.
  "============================================================
  CLEAR lv_filter_idx.


  LOOP AT lt_input_maps
    INTO ls_input_map.

    lv_filter_idx += 1.

    IF ls_input_map-mandatory = abap_false
       AND ls_input_map-prv_optional = abap_true.

      CONTINUE.

    ENDIF.


    lv_filter_set =
      |lv_f{ lv_filter_idx }_set|.


    APPEND
      |IF { lv_filter_set } = abap_false.|
      TO rt_source.


    APPEND
      |  lv_mandatory_missing = abap_true.|
      TO rt_source.


    APPEND
      |ENDIF.|
      TO rt_source.

  ENDLOOP.


  APPEND
    |IF lv_mandatory_missing = abap_true.|
    TO rt_source.


  APPEND
    |  RAISE EXCEPTION TYPE zcx_mig_query_error|
    TO rt_source.


  APPEND
    |    EXPORTING iv_message = 'A mandatory OData filter is missing'.|
    TO rt_source.


  APPEND
    |ENDIF.|
    TO rt_source.



  "============================================================
  " Không trả toàn bộ dữ liệu khi request filter không hỗ trợ
  "============================================================
  APPEND
    |IF lv_filter_valid = abap_false.|
    TO rt_source.


  APPEND
    |  RAISE EXCEPTION TYPE zcx_mig_query_error|
    TO rt_source.


  APPEND
    |    EXPORTING iv_message = 'Unsupported or invalid OData filter expression'.|
    TO rt_source.


  APPEND
    |ENDIF.|
    TO rt_source.


  "============================================================
  " Dynamic provider call:
  " - only bind parameters that are present in the request
  " - class method dùng ABAP_PARMBIND_TAB
  " - function module dùng ABAP_FUNC_PARMBIND_TAB
  "============================================================
  IF lv_is_bapi_provider = abap_true
     AND is_smap-selected_out-direction = zif_mig_types=>gc_sig_tab.

    APPEND
      |DATA lt_provider TYPE STANDARD TABLE OF { lv_output_type } WITH DEFAULT KEY.|
      TO rt_source.

  ELSE.

    APPEND
      |DATA lt_provider TYPE { lv_output_type }.|
      TO rt_source.

  ENDIF.


  IF lv_bapi_message_count = 1.

    IF ls_bapi_message-direction = zif_mig_types=>gc_sig_tab.

      APPEND
        |DATA lt_bapi_return TYPE STANDARD TABLE OF { lv_bapi_message_type } WITH DEFAULT KEY.|
        TO rt_source.

    ELSE.

      APPEND
        |DATA ls_bapi_return TYPE { lv_bapi_message_type }.|
        TO rt_source.

    ENDIF.

  ENDIF.


  IF lv_is_fm_provider = abap_true.

    APPEND
      |DATA lt_bind TYPE abap_func_parmbind_tab.|
      TO rt_source.

    APPEND
      |DATA lt_exceptions TYPE abap_func_excpbind_tab.|
      TO rt_source.

  ELSE.

    APPEND
      |DATA lt_bind TYPE abap_parmbind_tab.|
      TO rt_source.

  ENDIF.


  CLEAR lv_filter_idx.


  LOOP AT lt_input_maps
    INTO ls_input_map.

    lv_filter_idx += 1.

    lv_filter_set =
      |lv_f{ lv_filter_idx }_set|.

    lv_filter_kind =
      to_upper(
        CONV string(
          ls_input_map-svc_kind
        )
      ).


    IF lv_filter_kind = 'RANGE'.

      lv_filter_var =
        |lt_f{ lv_filter_idx }|.

    ELSE.

      lv_filter_var =
        |lv_f{ lv_filter_idx }|.

    ENDIF.


    lv_prv_param =
      to_upper(
        CONV string(
          ls_input_map-prv_name
        )
      ).

    CONDENSE lv_prv_param NO-GAPS.


    READ TABLE is_sig-input_params
      WITH KEY par_name = lv_prv_param
      INTO DATA(ls_bind_input).

    IF sy-subrc <> 0.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    APPEND
      |IF { lv_filter_set } = abap_true.|
      TO rt_source.


    APPEND
      |  INSERT VALUE #(|
      TO rt_source.


    APPEND
      |    name = '{ lv_prv_param }'|
      TO rt_source.


    IF lv_is_bapi_provider = abap_true
       AND ls_bind_input-direction = zif_mig_types=>gc_sig_tab.

      APPEND
        |    kind = abap_func_tables|
        TO rt_source.

    ELSEIF lv_is_fm_provider = abap_true.

      APPEND
        |    kind = abap_func_exporting|
        TO rt_source.

    ELSE.

      APPEND
        |    kind = cl_abap_objectdescr=>exporting|
        TO rt_source.

    ENDIF.


    APPEND
      |    value = REF #( { lv_filter_var } )|
      TO rt_source.


    APPEND
      |  ) INTO TABLE lt_bind.|
      TO rt_source.


    APPEND
      |ENDIF.|
      TO rt_source.

  ENDLOOP.


  APPEND
    |INSERT VALUE #(|
    TO rt_source.


  APPEND
    |  name = '{ lv_output_param }'|
    TO rt_source.


  IF lv_is_bapi_provider = abap_true
     AND is_smap-selected_out-direction = zif_mig_types=>gc_sig_tab.

    APPEND
      |  kind = abap_func_tables|
      TO rt_source.

  ELSEIF lv_is_fm_provider = abap_true.

    APPEND
      |  kind = abap_func_importing|
      TO rt_source.

  ELSE.

    APPEND
      |  kind = cl_abap_objectdescr=>receiving|
      TO rt_source.

  ENDIF.


  APPEND
    |  value = REF #( lt_provider )|
    TO rt_source.


  APPEND
    |) INTO TABLE lt_bind.|
    TO rt_source.


  IF lv_bapi_message_count = 1.

    APPEND
      |INSERT VALUE #(|
      TO rt_source.

    APPEND
      |  name = '{ lv_bapi_message_name }'|
      TO rt_source.


    IF ls_bapi_message-direction = zif_mig_types=>gc_sig_tab.

      APPEND
        |  kind = abap_func_tables|
        TO rt_source.

      APPEND
        |  value = REF #( lt_bapi_return )|
        TO rt_source.

    ELSE.

      APPEND
        |  kind = abap_func_importing|
        TO rt_source.

      APPEND
        |  value = REF #( ls_bapi_return )|
        TO rt_source.

    ENDIF.


    APPEND
      |) INTO TABLE lt_bind.|
      TO rt_source.

  ENDIF.


  IF lv_is_fm_provider = abap_true.

    APPEND
      |DATA(lv_provider_fm) = '{ lv_fm_name }'.|
      TO rt_source.


    APPEND
      |lt_exceptions = VALUE #( ( name = 'OTHERS' value = 1 ) ).|
      TO rt_source.


    APPEND
      |TRY.|
      TO rt_source.


    APPEND
      |    CALL FUNCTION lv_provider_fm|
      TO rt_source.


    APPEND
      |      PARAMETER-TABLE lt_bind|
      TO rt_source.


    APPEND
      |      EXCEPTION-TABLE lt_exceptions.|
      TO rt_source.


    APPEND
      |    DATA(lv_fm_subrc) = sy-subrc.|
      TO rt_source.


    APPEND
      |  CATCH cx_sy_dyn_call_error INTO DATA(lx_dyn_call).|
      TO rt_source.


    APPEND
      |    RAISE EXCEPTION TYPE zcx_mig_query_error|
      TO rt_source.


    APPEND
      |      EXPORTING previous = lx_dyn_call|
      TO rt_source.


    APPEND
      |                iv_message = 'Function module provider call failed'.|
      TO rt_source.


    APPEND
      |  CATCH cx_root INTO DATA(lx_provider).|
      TO rt_source.


    APPEND
      |    RAISE EXCEPTION TYPE zcx_mig_query_error|
      TO rt_source.


    APPEND
      |      EXPORTING previous = lx_provider|
      TO rt_source.


    APPEND
      |                iv_message = 'Function module provider raised an exception'.|
      TO rt_source.


    APPEND
      |ENDTRY.|
      TO rt_source.


    APPEND
      |IF lv_fm_subrc <> 0.|
      TO rt_source.


    APPEND
      |  RAISE EXCEPTION TYPE zcx_mig_query_error|
      TO rt_source.


    APPEND
      |    EXPORTING iv_message = 'Function module provider returned an exception'.|
      TO rt_source.


    APPEND
      |ENDIF.|
      TO rt_source.


    IF lv_bapi_message_count = 1.

      IF ls_bapi_message-direction = zif_mig_types=>gc_sig_tab.

        APPEND
          |LOOP AT lt_bapi_return ASSIGNING FIELD-SYMBOL(<bapi_return>).|
          TO rt_source.

        APPEND
          |  IF <bapi_return>-type CA 'AEX'.|
          TO rt_source.

        APPEND
          |    RAISE EXCEPTION TYPE zcx_mig_query_error|
          TO rt_source.

        APPEND
          |      EXPORTING iv_message = CONV string( <bapi_return>-message ).|
          TO rt_source.

        APPEND
          |  ENDIF.|
          TO rt_source.

        APPEND
          |ENDLOOP.|
          TO rt_source.

      ELSE.

        APPEND
          |IF ls_bapi_return-type CA 'AEX'.|
          TO rt_source.

        APPEND
          |  RAISE EXCEPTION TYPE zcx_mig_query_error|
          TO rt_source.

        APPEND
          |    EXPORTING iv_message = CONV string( ls_bapi_return-message ).|
          TO rt_source.

        APPEND
          |ENDIF.|
          TO rt_source.

      ENDIF.

    ENDIF.


  ELSE.

    APPEND
      |DATA(lv_provider_class) = '{ lv_class_name }'.|
      TO rt_source.


    APPEND
      |DATA(lv_provider_method) = '{ lv_method_name }'.|
      TO rt_source.


    APPEND
      |TRY.|
      TO rt_source.


    APPEND
      |    CALL METHOD (lv_provider_class)=>(lv_provider_method)|
      TO rt_source.


    APPEND
      |      PARAMETER-TABLE lt_bind.|
      TO rt_source.


    APPEND
      |  CATCH cx_sy_dyn_call_error INTO DATA(lx_dyn_call).|
      TO rt_source.


    APPEND
      |    RAISE EXCEPTION TYPE zcx_mig_query_error|
      TO rt_source.


    APPEND
      |      EXPORTING previous = lx_dyn_call|
      TO rt_source.


    APPEND
      |                iv_message = 'Static class provider call failed'.|
      TO rt_source.


    APPEND
      |  CATCH cx_root INTO DATA(lx_provider).|
      TO rt_source.


    APPEND
      |    RAISE EXCEPTION TYPE zcx_mig_query_error|
      TO rt_source.


    APPEND
      |      EXPORTING previous = lx_provider|
      TO rt_source.


    APPEND
      |                iv_message = 'Static class provider raised an exception'.|
      TO rt_source.


    APPEND
      |ENDTRY.|
      TO rt_source.

  ENDIF.


  "============================================================
  " Explicit provider-row -> service-row mapping
  "
  " Do not use CORRESPONDING here. Normalized service names can
  " legitimately differ from the provider component names.
  "============================================================
  APPEND
    |lt_result = VALUE #(|
    TO rt_source.


  APPEND
    |  FOR ls_provider IN lt_provider|
    TO rt_source.


  APPEND
    |  (|
    TO rt_source.


  LOOP AT lt_fields
    INTO DATA(ls_result_field).

    READ TABLE is_row-field_maps
      WITH KEY svc_name = ls_result_field-field_name
      INTO DATA(ls_result_map).

    IF sy-subrc <> 0
       OR ls_result_map-map_state <> zif_mig_types=>gc_row_auto
       OR ls_result_map-comp_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid = zcx_mig_analysis=>analysis_failed
      ).

    ENDIF.


    APPEND
      |    { ls_result_field-field_name } = ls_provider-{ ls_result_map-comp_name }|
      TO rt_source.

  ENDLOOP.


  APPEND
    |  )|
    TO rt_source.


  APPEND
    |).|
    TO rt_source.


  "============================================================
  " Count trước sorting và paging
  "============================================================
  APPEND
    |IF io_request->is_total_numb_of_rec_requested( ).|
    TO rt_source.


  APPEND
    |  io_response->set_total_number_of_records( lines( lt_result ) ).|
    TO rt_source.


  APPEND
    |ENDIF.|
    TO rt_source.


  "============================================================
  " Chỉ sort và paging khi request cần data
  "============================================================
  APPEND
    |IF io_request->is_data_requested( ).|
    TO rt_source.


  "============================================================
  " Default sort để paging ổn định
  "============================================================
  APPEND
    |  SORT lt_result STABLE BY { lv_def_sort } ASCENDING.|
    TO rt_source.


  "============================================================
  " Đọc $orderby từ RAP request
  "============================================================
  APPEND
    |  DATA(lt_sort) = io_request->get_sort_elements( ).|
    TO rt_source.


  APPEND
    |  DATA(lv_sort_idx) = lines( lt_sort ).|
    TO rt_source.


  "Duyệt ngược để giữ đúng độ ưu tiên của nhiều sort fields
  APPEND
    |  WHILE lv_sort_idx > 0.|
    TO rt_source.


  APPEND
    |    READ TABLE lt_sort INDEX lv_sort_idx INTO DATA(ls_sort).|
    TO rt_source.


  APPEND
    |    IF sy-subrc = 0.|
    TO rt_source.


  APPEND
    |      DATA(lv_sort_name) = to_upper( ls_sort-element_name ).|
    TO rt_source.


  APPEND
    |      CASE lv_sort_name.|
    TO rt_source.


  "============================================================
  " Sinh CASE branch cho từng field được phép sort
  "============================================================
  LOOP AT lt_fields
    INTO DATA(ls_sort_field)
    WHERE sortable = abap_true.

    DATA(lv_sort_field) =
      CONV string(
        ls_sort_field-field_name
      ).

    CONDENSE lv_sort_field NO-GAPS.

    IF lv_sort_field IS INITIAL.
      CONTINUE.
    ENDIF.


    DATA(lv_sort_key) =
      to_upper(
        lv_sort_field
      ).


    APPEND
      |        WHEN '{ lv_sort_key }'.|
      TO rt_source.


    APPEND
      |          IF ls_sort-descending = abap_true.|
      TO rt_source.


    APPEND
      |            SORT lt_result STABLE BY { lv_sort_field } DESCENDING.|
      TO rt_source.


    APPEND
      |          ELSE.|
      TO rt_source.


    APPEND
      |            SORT lt_result STABLE BY { lv_sort_field } ASCENDING.|
      TO rt_source.


    APPEND
      |          ENDIF.|
      TO rt_source.

  ENDLOOP.


  APPEND
    |        WHEN OTHERS.|
    TO rt_source.


  APPEND
    |          CLEAR lv_sort_name.|
    TO rt_source.


  APPEND
    |      ENDCASE.|
    TO rt_source.


  APPEND
    |    ENDIF.|
    TO rt_source.


  APPEND
    |    lv_sort_idx -= 1.|
    TO rt_source.


  APPEND
    |  ENDWHILE.|
    TO rt_source.


  "============================================================
  " Paging sau sorting
  "============================================================
  APPEND
    |  DATA lt_page TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.|
    TO rt_source.



  APPEND
    |  IF lv_page_size = if_rap_query_paging=>page_size_unlimited.|
    TO rt_source.


  APPEND
    |    lt_page = lt_result.|
    TO rt_source.


  APPEND
    |  ELSEIF lv_page_size > 0.|
    TO rt_source.


  APPEND
    |    DATA(lv_from) = CONV i( lv_offset + 1 ).|
    TO rt_source.


  APPEND
    |    DATA(lv_to) = CONV i( lv_offset + lv_page_size ).|
    TO rt_source.


  APPEND
    |    LOOP AT lt_result INTO DATA(ls_result) FROM lv_from TO lv_to.|
    TO rt_source.


  APPEND
    |      APPEND ls_result TO lt_page.|
    TO rt_source.


  APPEND
    |    ENDLOOP.|
    TO rt_source.


  APPEND
    |  ENDIF.|
    TO rt_source.


  "============================================================
  " Trả dữ liệu sau sort và paging
  "============================================================
  APPEND
    |  io_response->set_data( lt_page ).|
    TO rt_source.


  APPEND
    |ENDIF.|
    TO rt_source.

ENDMETHOD.


METHOD resolve_boundary_type.

  DATA(lv_edm_type) =
    to_upper(
      CONV string( is_field-edm_type )
    ).

  CONDENSE lv_edm_type NO-GAPS.

  CASE lv_edm_type.

    WHEN 'EDM.BOOLEAN'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_char.
      rs_type-char_length = 1.
      rs_type-abap_decl = 'TYPE abap_bool'.


    WHEN 'EDM.INT32'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_int4.
      rs_type-abap_decl = 'TYPE i'.


    WHEN 'EDM.INT64'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_int8.
      rs_type-abap_decl = 'TYPE int8'.


    WHEN 'EDM.DECIMAL'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_decfloat34.
      rs_type-abap_decl = 'TYPE decfloat34'.


    WHEN 'EDM.DOUBLE'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_decfloat34.
      rs_type-abap_decl = 'TYPE decfloat34'.


    WHEN 'EDM.DATE'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_date.
      rs_type-abap_decl = 'TYPE d'.


    WHEN 'EDM.TIMEOFDAY'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_time.
      rs_type-abap_decl = 'TYPE t'.


    WHEN 'EDM.DATETIMEOFFSET'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_utclong.
      rs_type-abap_decl = 'TYPE utclong'.


    WHEN 'EDM.GUID'.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_char.
      rs_type-char_length = 36.
      rs_type-abap_decl = 'TYPE c LENGTH 36'.


    WHEN 'EDM.STRING'.

      DATA(lv_length) = is_field-length.

      IF lv_length <= 0.

        rs_type-supported = abap_false.
        rs_type-reason =
          |Field { is_field-field_name } has no resolved character length.|.

        RETURN.

      ENDIF.

      IF lv_length > 1333.

        rs_type-supported = abap_false.
        rs_type-reason =
          |Field { is_field-field_name } exceeds the supported character length of 1333.|.

        RETURN.

      ENDIF.

      rs_type-supported = abap_true.
      rs_type-kind = gc_boundary_char.
      rs_type-char_length = lv_length.
      rs_type-abap_decl = |TYPE c LENGTH { lv_length }|.


    WHEN OTHERS.

      rs_type-supported = abap_false.
      rs_type-reason =
        |Field { is_field-field_name } has unsupported EDM type { is_field-edm_type }.|.

  ENDCASE.

ENDMETHOD.


METHOD norm_name.

  DATA:
    lv_prefix  TYPE string,
    lv_changed TYPE abap_bool.

  rv_name = to_upper( iv_name ).
  CONDENSE rv_name NO-GAPS.

  DO 3 TIMES.

    lv_changed = abap_false.

    IF strlen( rv_name ) >= 3.

      lv_prefix = substring(
        val = rv_name
        len = 3
      ).

      CASE lv_prefix.
        WHEN 'IV_' OR 'IS_' OR 'IT_'
          OR 'EV_' OR 'ES_' OR 'ET_'
          OR 'CV_' OR 'CS_' OR 'CT_'
          OR 'RV_' OR 'RS_' OR 'RT_'
          OR 'GT_' OR 'GS_'.

          rv_name = substring(
            val = rv_name
            off = 3
          ).

          lv_changed = abap_true.

      ENDCASE.

    ENDIF.

    IF lv_changed = abap_false
       AND strlen( rv_name ) >= 2.

      lv_prefix = substring(
        val = rv_name
        len = 2
      ).

      CASE lv_prefix.
        WHEN 'I_' OR 'E_' OR 'C_' OR 'R_'
          OR 'P_' OR 'S_' OR 'T_'.

          rv_name = substring(
            val = rv_name
            off = 2
          ).

          lv_changed = abap_true.

      ENDCASE.

    ENDIF.

    IF lv_changed = abap_false.
      EXIT.
    ENDIF.

  ENDDO.

  REPLACE ALL OCCURRENCES OF '_'
    IN rv_name
    WITH ''.

  CONDENSE rv_name NO-GAPS.

ENDMETHOD.

ENDCLASS.

