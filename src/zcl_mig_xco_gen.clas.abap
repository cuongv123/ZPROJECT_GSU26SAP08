CLASS zcl_mig_xco_gen DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

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

        iv_request
          TYPE trkorr

        iv_execute
          TYPE abap_bool
          DEFAULT abap_false

      RAISING
        zcx_mig_analysis
        cx_xco_gen_put_exception.


  PRIVATE SECTION.

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

      METHODS add_srvb
          IMPORTING
            io_put
              TYPE REF TO if_xco_cp_gen_d_o_put

            is_item
              TYPE zif_mig_types=>ty_art_item

            iv_package
              TYPE devclass

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

          RETURNING
            VALUE(rt_source)
              TYPE string_table

          RAISING
            zcx_mig_analysis.

ENDCLASS.

CLASS zcl_mig_xco_gen IMPLEMENTATION.

  METHOD generate_query.

    validate(
      is_mfst    = is_mfst
      iv_request = iv_request
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

    READ TABLE is_mfst-items
      WITH KEY
        art_type = zif_mig_types=>gc_art_srvb
        art_role = zif_mig_types=>gc_art_srv_bind
      INTO DATA(ls_srvb).


    IF sy-subrc <> 0
       OR ls_srvb-object_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    IF strlen(
         CONV string(
           ls_srvb-object_name
         )
       ) > 26.

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

    IF is_bp-blueprint-strategy <>
         zif_mig_types=>gc_svc_query
       OR is_bp-blueprint-manual_review =
            abap_true
       OR is_bp-fields IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.

    IF is_prv-service_strategy <>
         zif_mig_types=>gc_svc_query
       OR is_prv-provider_kind <>
            zif_mig_types=>gc_provider_class_method
       OR is_prv-provider_status <>
            zif_mig_types=>gc_provider_ready
       OR is_prv-manual_review =
            abap_true
       OR is_prv-source_container_name IS INITIAL
       OR is_prv-source_object_name IS INITIAL.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    IF is_sig-status <>
         zif_mig_types=>gc_sig_ready
       OR is_sig-manual_review =
            abap_true
       OR is_sig-provider_kind <>
            zif_mig_types=>gc_provider_class_method.

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

    LOOP AT is_sig-input_params
      TRANSPORTING NO FIELDS
      WHERE optional = abap_false.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDLOOP.

    DATA lv_ret_count
      TYPE i.

    CLEAR lv_ret_count.


    LOOP AT is_sig-output_params
      TRANSPORTING NO FIELDS
      WHERE direction =
              zif_mig_types=>gc_sig_ret
        AND is_table =
              abap_true.

      lv_ret_count += 1.

    ENDLOOP.


    IF lv_ret_count <> 1.

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid =
          zcx_mig_analysis=>analysis_failed

        program_name =
          is_mfst-source_program
      ).

    ENDIF.


    DATA(lo_env) =
      xco_cp_generation=>environment->dev_system(
          iv_request
      ).


    DATA(lo_put) =
      lo_env->create_put_operation( ).

    DATA(lo_srvb_put) =
      lo_env->create_put_operation( ).

    add_clas(
      io_put =
        lo_put

      is_item =
        ls_clas

      iv_package =
        is_mfst-package

      it_fields =
        is_bp-fields

      is_prv =
        is_prv

      is_sig =
        is_sig

      is_smap =
        is_smap
    ).

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

    add_srvb(
      io_put =
        lo_srvb_put

      is_item =
        ls_srvb

      iv_package =
        is_mfst-package

      iv_service_name =
        ls_srvd-object_name

      iv_srvd_name =
        ls_srvd-object_name
    ).

    IF iv_execute = abap_true.

      "Tạo và activate CLAS, DDLS, SRVD trước
      lo_put->execute( ).

      "Sau khi SRVD đã active mới tạo SRVB
      lo_srvb_put->execute( ).

    ENDIF.

  ENDMETHOD.


  METHOD validate.

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

    DATA(lv_key_name) =
      VALUE zif_mig_types=>ty_art_name( ).

    READ TABLE lt_fields
      WITH KEY key_field = abap_true
      INTO DATA(ls_key).

    IF sy-subrc = 0.

      lv_key_name =
        ls_key-field_name.

    ELSE.

      READ TABLE lt_fields
        INDEX 1
        INTO ls_key.

      IF sy-subrc = 0.

        lv_key_name =
          ls_key-field_name.

      ENDIF.

    ENDIF.

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


      DATA(lv_edm_type) =
          to_upper(
            val = CONV string(
              ls_field-edm_type
            )
          ).


        CASE lv_edm_type.

          WHEN 'EDM.BOOLEAN'.

            "Không có Boolean riêng trong XCO API của release này
            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->char(
                1
              )
            ).


          WHEN 'EDM.INT32'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->int4
            ).


          WHEN 'EDM.INT64'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->int8
            ).


          WHEN 'EDM.DECIMAL'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->decfloat16
            ).


          WHEN 'EDM.DOUBLE'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->decfloat34
            ).


          WHEN 'EDM.DATE'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->dats
            ).


          WHEN 'EDM.TIMEOFDAY'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->tims
            ).


          WHEN 'EDM.DATETIMEOFFSET'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->utclong
            ).


          WHEN 'EDM.GUID'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->char(
                36
              )
            ).


          WHEN 'EDM.STRING'.

            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->char(
                120
              )
            ).


          WHEN OTHERS.

            "Fallback an toàn cho type chưa hỗ trợ
            lo_field->set_type(
              xco_cp_abap_dictionary=>built_in_type->char(
                120
              )
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

      IF ls_field-field_name =
         lv_key_name.

      lo_field->set_key( ).

    ENDIF.

    ENDLOOP.

    IF lv_has_key = abap_false.

      READ TABLE lt_fields
        INDEX 1
        INTO DATA(ls_first).

      IF sy-subrc <> 0.

        RAISE EXCEPTION NEW zcx_mig_analysis(
          textid =
            zcx_mig_analysis=>analysis_failed
        ).

      ENDIF.

    ENDIF.

ENDMETHOD.

METHOD add_srvb.

  IF is_item-object_name IS INITIAL
     OR iv_package IS INITIAL
     OR iv_service_name IS INITIAL
     OR iv_srvd_name IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  DATA(lo_spec) =
    io_put->for-srvb->add_object(
      CONV #( is_item-object_name )
    )->set_package(
      iv_package
    )->create_form_specification( ).


  lo_spec->set_short_description(
    'Generated MIG OData V4 binding'
  ).


  lo_spec->set_binding_type(
    xco_cp_service_binding=>binding_type->odata_v4_ui
  ).


  DATA(lo_service) =
    lo_spec->add_service(
      CONV #( iv_service_name )
    ).


  DATA(lo_version) =
    lo_service->add_version(
      0001
    ).


  lo_version->set_service_definition( iv_srvd_name ).

ENDMETHOD.

METHOD build_select_src.

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
" - không input, hoặc
" - đúng một scalar optional Edm.String
"============================================================
DATA:
  lv_has_filter TYPE abap_bool,
  ls_input_map  TYPE zif_mig_types=>ty_svc_in_map.


lv_has_filter =
  abap_false.


IF is_smap-input_maps IS NOT INITIAL.

  IF lines( is_smap-input_maps ) <> 1.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  READ TABLE is_smap-input_maps
    INDEX 1
    INTO ls_input_map.

  IF sy-subrc <> 0.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


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


  IF ls_input_map-map_state <>
       zif_mig_types=>gc_smap_auto
     OR lv_svc_kind = 'RANGE'
     OR lv_svc_edm <> 'EDM.STRING'
     OR lv_prv_edm <> 'EDM.STRING'
     OR ls_input_map-prv_optional <>
          abap_true
     OR ls_input_map-svc_name IS INITIAL
     OR ls_input_map-prv_name IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  "Filter phải tương ứng với một output field filterable
  DATA lv_filter_field_ok
    TYPE abap_bool.

  lv_filter_field_ok =
    abap_false.


  DATA(lv_svc_name_up) =
    to_upper(
      CONV string(
        ls_input_map-svc_name
      )
    ).

  CONDENSE lv_svc_name_up NO-GAPS.


  LOOP AT lt_fields
    INTO DATA(ls_filter_field)
    WHERE filterable = abap_true.

    DATA(lv_field_name_up) =
      to_upper(
        CONV string(
          ls_filter_field-field_name
        )
      ).

    CONDENSE lv_field_name_up NO-GAPS.


    IF lv_field_name_up =
         lv_svc_name_up.

      lv_filter_field_ok =
        abap_true.

      EXIT.

    ENDIF.

  ENDLOOP.


  IF lv_filter_field_ok =
       abap_false.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid =
        zcx_mig_analysis=>analysis_failed
    ).

  ENDIF.


  lv_has_filter =
    abap_true.

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


    DATA(lv_edm_type) =
      to_upper(
        val = CONV string(
          ls_field-edm_type
        )
      ).


    DATA lv_type_decl
      TYPE string.


    CASE lv_edm_type.

      WHEN 'EDM.BOOLEAN'.

        lv_type_decl =
          'TYPE abap_bool'.


      WHEN 'EDM.INT32'.

        lv_type_decl =
          'TYPE i'.


      WHEN 'EDM.INT64'.

        lv_type_decl =
          'TYPE int8'.


      WHEN 'EDM.DECIMAL'.

        lv_type_decl =
          'TYPE decfloat16'.


      WHEN 'EDM.DOUBLE'.

        lv_type_decl =
          'TYPE decfloat34'.


      WHEN 'EDM.DATE'.

        lv_type_decl =
          'TYPE d'.


      WHEN 'EDM.TIMEOFDAY'.

        lv_type_decl =
          'TYPE t'.


      WHEN 'EDM.DATETIMEOFFSET'.

        lv_type_decl =
          'TYPE utclong'.


      WHEN 'EDM.GUID'.

        lv_type_decl =
          'TYPE c LENGTH 36'.


      WHEN OTHERS.

        lv_type_decl =
          'TYPE c LENGTH 120'.

    ENDCASE.


    APPEND
      |    { lv_name } { lv_type_decl },|
      TO rt_source.

  ENDLOOP.


  APPEND
    |  END OF ty_result.|
    TO rt_source.


  APPEND
    |DATA lt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.|
    TO rt_source.


  "============================================================
  " Chuẩn hóa tên class và static method provider
  "============================================================
  DATA(lv_class_name) =
    to_upper(
      CONV string(
        is_prv-source_container_name
      )
    ).

  CONDENSE lv_class_name NO-GAPS.


  DATA(lv_method_name) =
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


  IF lv_has_filter =
     abap_true.

  DATA(lv_filter_name) =
    to_upper(
      CONV string(
        ls_input_map-svc_name
      )
    ).

  CONDENSE lv_filter_name NO-GAPS.


  DATA(lv_prv_param) =
    to_upper(
      CONV string(
        ls_input_map-prv_name
      )
    ).

  CONDENSE lv_prv_param NO-GAPS.


  "==========================================================
  " Đọc filter request
  "==========================================================
  APPEND
    |DATA lv_filter_value TYPE c LENGTH 120.|
    TO rt_source.


  APPEND
    |DATA(lv_filter_valid) = abap_true.|
    TO rt_source.


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


  "Checkpoint chỉ chấp nhận đúng filter được map
  APPEND
    |      IF lv_req_filter_name <> '{ lv_filter_name }'.|
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


  "Checkpoint chỉ chấp nhận một điều kiện
  APPEND
    |      IF lines( ls_filter_pair-range ) <> 1.|
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
    |      READ TABLE ls_filter_pair-range INDEX 1 INTO DATA(ls_filter_option).|
    TO rt_source.


  "Chỉ hỗ trợ Include + Equal
  APPEND
    |      IF sy-subrc <> 0|
    TO rt_source.

  APPEND
    |         OR ls_filter_option-sign <> 'I'|
    TO rt_source.

  APPEND
    |         OR ls_filter_option-option <> 'EQ'|
    TO rt_source.

  APPEND
    |         OR ls_filter_option-high IS NOT INITIAL.|
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
    |      lv_filter_value = ls_filter_option-low.|
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


  "Không được trả dữ liệu unfiltered khi filter không hỗ trợ
  APPEND
    |IF lv_filter_valid = abap_false.|
    TO rt_source.


  APPEND
    |  IF io_request->is_total_numb_of_rec_requested( ).|
    TO rt_source.


  APPEND
    |    io_response->set_total_number_of_records( 0 ).|
    TO rt_source.


  APPEND
    |  ENDIF.|
    TO rt_source.


  APPEND
    |  IF io_request->is_data_requested( ).|
    TO rt_source.


  APPEND
    |    io_response->set_data( lt_result ).|
    TO rt_source.


  APPEND
    |  ENDIF.|
    TO rt_source.


  APPEND
    |  RETURN.|
    TO rt_source.


  APPEND
    |ENDIF.|
    TO rt_source.


  "==========================================================
  " Gọi provider bằng named optional parameter
  "==========================================================
  APPEND
    |DATA(lt_provider) = { lv_class_name }=>{ lv_method_name }(|
    TO rt_source.


  APPEND
    |  { lv_prv_param } = lv_filter_value|
    TO rt_source.


  APPEND
    |).|
    TO rt_source.

ELSE.

  "Provider không có input
  APPEND
    |DATA(lt_provider) = { lv_class_name }=>{ lv_method_name }( ).|
    TO rt_source.

ENDIF.


APPEND
  |lt_result = CORRESPONDING #( lt_provider ).|
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
        val = lv_sort_field
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
    |  DATA(lo_paging) = io_request->get_paging( ).|
    TO rt_source.


  APPEND
    |  DATA(lv_offset) = lo_paging->get_offset( ).|
    TO rt_source.


  APPEND
    |  DATA(lv_page_size) = lo_paging->get_page_size( ).|
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

ENDCLASS.
