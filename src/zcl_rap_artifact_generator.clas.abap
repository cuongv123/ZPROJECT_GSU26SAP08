CLASS zcl_rap_artifact_generator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS generate_base_cds
      IMPORTING iv_table_name  TYPE string
      RETURNING VALUE(rt_code) TYPE string_table.

    METHODS generate_projection_cds
      IMPORTING iv_table_name TYPE string
                it_ui_filters TYPE zcl_parser_types=>tt_ui_filter
      RETURNING VALUE(rt_code) TYPE string_table.

    " Đã nâng cấp thêm Package và Transport Request
    METHODS publish_cds_view
      IMPORTING iv_view_name TYPE string
                it_source    TYPE string_table
                iv_package   TYPE devclass
                iv_transport TYPE trkorr
      EXPORTING ev_success   TYPE abap_bool
                et_messages  TYPE bapiret2_t.

    METHODS generate_custom_entity
      IMPORTING iv_entity_name    TYPE string
                iv_structure_name TYPE string
                it_ui_filters     TYPE zcl_parser_types=>tt_ui_filter
      RETURNING VALUE(rt_code)    TYPE string_table.

    METHODS generate_service_definition
      IMPORTING iv_service_name TYPE string
                it_entities     TYPE string_table
      RETURNING VALUE(rt_code)  TYPE string_table.

    " --- CÁC HÀM XCO MỚI ---
    METHODS generate_base_cds_xco
      IMPORTING iv_table_name TYPE string
                iv_package    TYPE devclass
                iv_transport  TYPE trkorr
      EXPORTING ev_success    TYPE abap_bool
                ev_message    TYPE string.

    METHODS generate_sd_via_xco
      IMPORTING iv_service_name TYPE sxco_srvd_object_name
                it_entities     TYPE string_table
                iv_package      TYPE sxco_package
                iv_transport    TYPE sxco_transport
      EXPORTING ev_success      TYPE abap_bool
                ev_message      TYPE string.

    METHODS generate_sb_via_xco
      IMPORTING iv_binding_name TYPE sxco_srvb_object_name
                iv_service_name TYPE sxco_srvd_object_name
                iv_package      TYPE sxco_package
                iv_transport    TYPE sxco_transport
      EXPORTING ev_success      TYPE abap_bool
                ev_message      TYPE string.

  PRIVATE SECTION.
    METHODS get_table_fields
      IMPORTING iv_table         TYPE string
      RETURNING VALUE(rt_fields) TYPE ddfields.
ENDCLASS.
CLASS zcl_rap_artifact_generator IMPLEMENTATION.

METHOD get_table_fields.
    DATA: lo_type   TYPE REF TO cl_abap_typedescr,
          lo_struct TYPE REF TO cl_abap_structdescr.

    CLEAR rt_fields.

    " 1. Tránh Dump do truyền vào tên rỗng
    IF iv_table IS INITIAL.
      RETURN.
    ENDIF.

    " 2. Dùng CALL METHOD chuẩn để bắt gọn Classic Exception của SAP
    CALL METHOD cl_abap_typedescr=>describe_by_name
      EXPORTING
        p_name         = iv_table
      RECEIVING
        p_descr_ref    = lo_type
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2.

    " 3. Chỉ xử lý tiếp nếu tìm thấy đối tượng trong hệ thống
    IF sy-subrc = 0.
      TRY.
          " Ép kiểu an toàn từ Type mô tả chung sang Type cấu trúc
          lo_struct ?= lo_type.
          rt_fields = lo_struct->get_ddic_field_list( ).
        CATCH cx_root.
          " Bỏ qua nếu đối tượng tìm thấy không phải là Bảng/Cấu trúc
          " (Ví dụ nó là Data Element hoặc Class)
      ENDTRY.
    ENDIF.
  ENDMETHOD.
METHOD generate_base_cds.
    DATA: lt_fields TYPE ddfields.

    lt_fields = get_table_fields( iv_table_name ).
    IF lt_fields IS INITIAL.
      APPEND |// Error: Table { iv_table_name } not found.| TO rt_code.
      RETURN.
    ENDIF.

    " 1. Ráp Header
    APPEND |@AccessControl.authorizationCheck: #NOT_REQUIRED| TO rt_code.
    APPEND |@EndUserText.label: 'Generated Base View for { iv_table_name }'| TO rt_code.
    APPEND |define root view entity ZI_GEN_{ iv_table_name }| TO rt_code.
    APPEND |  as select from { iv_table_name }| TO rt_code.
    APPEND |\{| TO rt_code.

    " 2. Ráp Fields (Đã bỏ alias để tránh lỗi cú pháp CDS View Entity)
    DATA(lv_total_fields) = lines( lt_fields ).
    DATA(lv_current_idx)  = 0.

    LOOP AT lt_fields INTO DATA(ls_field).
      IF ls_field-datatype = 'CLNT'.
        lv_total_fields = lv_total_fields - 1.
        CONTINUE.
      ENDIF.

      lv_current_idx += 1.
      DATA(lv_comma) = COND string( WHEN lv_current_idx < lv_total_fields THEN ',' ELSE '' ).

      IF ls_field-keyflag = 'X'.
        APPEND |  key { ls_field-fieldname }{ lv_comma }| TO rt_code.
      ELSE.
        APPEND |      { ls_field-fieldname }{ lv_comma }| TO rt_code.
      ENDIF.
    ENDLOOP.

    APPEND |\}| TO rt_code.
  ENDMETHOD.

  METHOD generate_projection_cds.
    DATA: lt_fields TYPE ddfields,
          lv_pos    TYPE i VALUE 10.

    lt_fields = get_table_fields( iv_table_name ).
    IF lt_fields IS INITIAL.
      RETURN.
    ENDIF.

    " 1. Ráp Header cho Fiori UI (Đã bỏ provider contract)
    APPEND |@EndUserText.label: 'Generated Projection for { iv_table_name }'| TO rt_code.
    APPEND |@AccessControl.authorizationCheck: #NOT_REQUIRED| TO rt_code.
    APPEND |@UI.headerInfo: \{ typeName: 'Item', typeNamePlural: 'Items' \}| TO rt_code.
    APPEND |define root view entity ZC_GEN_{ iv_table_name }| TO rt_code.
    APPEND |  as projection on ZI_GEN_{ iv_table_name }| TO rt_code.
    APPEND |\{| TO rt_code.

    " 2. Ráp Fields kèm Annotations (Đã bỏ alias)
    DATA(lv_total_fields) = lines( lt_fields ).
    DATA(lv_current_idx)  = 0.

    LOOP AT lt_fields INTO DATA(ls_field).
      IF ls_field-datatype = 'CLNT'.
        lv_total_fields -= 1.
        CONTINUE.
      ENDIF.

      lv_current_idx += 1.
      DATA(lv_comma) = COND string( WHEN lv_current_idx < lv_total_fields THEN ',' ELSE '' ).

      APPEND | | TO rt_code. " Dòng trắng phân cách

      READ TABLE it_ui_filters TRANSPORTING NO FIELDS WITH KEY data_element = ls_field-rollname.
      IF sy-subrc = 0.
        APPEND |      @UI.selectionField: [\{ position: { lv_pos } \}]| TO rt_code.
      ENDIF.

      APPEND |      @UI.lineItem: [\{ position: { lv_pos } \}]| TO rt_code.
      APPEND |      @EndUserText.label: '{ ls_field-scrtext_m }'| TO rt_code.

      IF ls_field-keyflag = 'X'.
        APPEND |  key { ls_field-fieldname }{ lv_comma }| TO rt_code.
      ELSE.
        APPEND |      { ls_field-fieldname }{ lv_comma }| TO rt_code.
      ENDIF.

      lv_pos += 10.
    ENDLOOP.

    APPEND |\}| TO rt_code.
  ENDMETHOD.
  METHOD publish_cds_view.
    " Trở về với RFC thần thánh để giải quyết bài toán chuỗi Text (Hybrid)
    DATA(lv_source_string) = concat_lines_of( table = it_source sep = cl_abap_char_utilities=>cr_lf ).

    ev_success = abap_false.
    CLEAR et_messages.

    " Gọi Function Module qua RFC với DESTINATION 'NONE' (Không lo Dump Commit)
    CALL FUNCTION 'Z_MIG_PUBLISH_CDS' DESTINATION 'NONE'
      EXPORTING
        iv_view_name = iv_view_name
        iv_source    = lv_source_string
        iv_package   = iv_package
        iv_transport = iv_transport
      IMPORTING
        ev_success   = ev_success
        et_messages  = et_messages.
  ENDMETHOD.

METHOD generate_custom_entity.
    DATA: lt_fields TYPE ddfields,
          lv_code   TYPE string,
          lv_pos    TYPE i VALUE 10.

    " BẢN VÁ: Tự động gọt tên tối đa 30 ký tự chuẩn SAP
    DATA(lv_exact_name) = |ZCE_GEN_{ iv_entity_name }|.
    IF strlen( lv_exact_name ) > 30.
      lv_exact_name = substring( val = lv_exact_name off = 0 len = 30 ).
    ENDIF.

    " 1. Ráp Header cho Custom Entity
    lv_code = |@EndUserText.label: 'Custom Entity for { iv_entity_name }'\r\n|.
    lv_code = lv_code && |@ObjectModel.query.implementedBy: 'ABAP:ZCL_DYNAMIC_RAP_PROVIDER'\r\n\r\n|.
    lv_code = lv_code && |@UI.headerInfo: \{\r\n|.
    lv_code = lv_code && |  typeName: 'Item',\r\n|.
    lv_code = lv_code && |  typeNamePlural: 'Items'\r\n|.
    lv_code = lv_code && |\}\r\n|.

    " Dùng tên đã gọt để định nghĩa mã nguồn
    lv_code = lv_code && |define root custom entity { lv_exact_name }\r\n|.
    lv_code = lv_code && |\{\r\n|.

    " 2. Đọc field từ Structure (Nếu có)
    lt_fields = get_table_fields( iv_structure_name ).

    IF lt_fields IS INITIAL.
      " Fallback an toàn: Nếu FM chưa có structure rõ ràng, tạo 1 dummy key
      lv_code = lv_code && |      @UI.lineItem: [\{ position: 10 \}]\r\n|.
      lv_code = lv_code && |  key dummy_id : abap.char( 32 );\r\n|. " <--- BẢN VÁ: Dùng chuẩn abap.char
    ELSE.
      " Ráp fields kèm Annotations (Giống Projection CDS)
      DATA(lv_total_fields) = lines( lt_fields ).
      DATA(lv_current_idx)  = 0.

      LOOP AT lt_fields INTO DATA(ls_field_count) WHERE datatype = 'CLNT'.
        lv_total_fields = lv_total_fields - 1.
      ENDLOOP.

      LOOP AT lt_fields INTO DATA(ls_field).
        IF ls_field-datatype = 'CLNT'.
          CONTINUE.
        ENDIF.

        lv_current_idx += 1.
        DATA(lv_comma) = COND string( WHEN lv_current_idx < lv_total_fields THEN ',' ELSE '' ).
        lv_code = lv_code && |\r\n|.

        " Mapping SmartFilterBar
        READ TABLE it_ui_filters TRANSPORTING NO FIELDS WITH KEY data_element = ls_field-rollname.
        IF sy-subrc = 0.
          lv_code = lv_code && |      @UI.selectionField: [\{ position: { lv_pos } \}]\r\n|.
        ENDIF.

        lv_code = lv_code && |      @UI.lineItem: [\{ position: { lv_pos } \}]\r\n|.
        lv_code = lv_code && |      @EndUserText.label: '{ ls_field-scrtext_m }'\r\n|.

        " Xác định kiểu dữ liệu chuẩn cho Custom Entity
        DATA(lv_type) = COND string(
          WHEN ls_field-datatype = 'CHAR' OR ls_field-datatype = 'CUKY' OR ls_field-datatype = 'UNIT' THEN |abap.char( { ls_field-leng } )|
          WHEN ls_field-datatype = 'NUMC' THEN |abap.numc( { ls_field-leng } )|
          WHEN ls_field-datatype = 'DATS' THEN |abap.dats|
          WHEN ls_field-datatype = 'TIMS' THEN |abap.tims|
          WHEN ls_field-datatype = 'INT4' THEN |abap.int4|
          WHEN ls_field-datatype = 'CURR' OR ls_field-datatype = 'QUAN' OR ls_field-datatype = 'DEC' THEN |abap.dec( { ls_field-leng },{ ls_field-decimals } )|
          ELSE |abap.char( 255 )| ).

        IF ls_field-keyflag = 'X'.
          lv_code = lv_code && |  key { to_lower( ls_field-fieldname ) } : { lv_type }{ lv_comma }\r\n|.
        ELSE.
          lv_code = lv_code && |      { to_lower( ls_field-fieldname ) } : { lv_type }{ lv_comma }\r\n|.
        ENDIF.

        lv_pos += 10.
      ENDLOOP.
    ENDIF.

    lv_code = lv_code && |\}\r\n|.
    APPEND lv_code TO rt_code.
  ENDMETHOD.

  METHOD generate_service_definition.
    DATA(lv_code) = |@EndUserText.label: 'Generated Service for { iv_service_name }'\r\n|.
    lv_code = lv_code && |define service ZUI_GEN_{ iv_service_name } \{\r\n|.

    LOOP AT it_entities INTO DATA(lv_entity).
      lv_code = lv_code && |  expose { lv_entity };\r\n|.
    ENDLOOP.

    lv_code = lv_code && |\}\r\n|.
    APPEND lv_code TO rt_code.
  ENDMETHOD.

METHOD generate_base_cds_xco.
    ev_success = abap_true.
    CLEAR ev_message.

    DATA: lt_fields TYPE ddfields.
    lt_fields = get_table_fields( iv_table_name ).

    IF lt_fields IS INITIAL.
      ev_success = abap_false.
      ev_message = |Lỗi: Bảng { iv_table_name } không tồn tại hoặc không có trường dữ liệu.|.
      RETURN.
    ENDIF.

    DATA(lv_view_name) = CONV sxco_cds_object_name( |ZI_GEN_{ to_upper( iv_table_name ) }| ).

    TRY.
        DATA(lo_environment) = xco_cp_generation=>environment->dev_system( iv_transport ).
        DATA(lo_put_operation) = lo_environment->create_put_operation( ).

        DATA(lo_specification) = lo_put_operation->for-ddls->add_object( lv_view_name
          )->set_package( iv_package
          )->create_form_specification( ).

        DATA(lo_view_entity) = lo_specification->set_short_description( |Auto Base View for { iv_table_name }|
          )->add_view_entity( ).

        " BẢN VÁ 1: Đổi thành set_view_entity()
        lo_view_entity->data_source->set_view_entity( CONV #( iv_table_name ) ).

        LOOP AT lt_fields INTO DATA(ls_field).
          IF ls_field-datatype = 'CLNT'.
            CONTINUE.
          ENDIF.

          " BẢN VÁ 2: Tháo bỏ CONV #() thừa thãi ở trường name
          DATA(lo_field) = lo_view_entity->add_field( xco_cp_ddl=>field( ls_field-fieldname ) ).

          IF ls_field-keyflag = 'X'.
            lo_field->set_key( ).
          ENDIF.
        ENDLOOP.

        DATA(lo_result) = lo_put_operation->execute( ).

        " BẢN VÁ 3: Đổi get_errors() thành get()
        DATA(lt_findings) = lo_result->findings->get( ).
        IF lt_findings IS NOT INITIAL.
          ev_success = abap_false.
          ev_message = |Lỗi/Cảnh báo khi XCO biên dịch CDS { lv_view_name }|.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).
        ev_success = abap_false.
        ev_message = lx_error->get_text( ).
    ENDTRY.
  ENDMETHOD.

  METHOD generate_sd_via_xco.
    ev_success = abap_true.
    CLEAR ev_message.

    TRY.
        DATA(lo_environment) = xco_cp_generation=>environment->dev_system( iv_transport ).
        DATA(lo_put_operation) = lo_environment->create_put_operation( ).

        DATA(lo_specification) = lo_put_operation->for-srvd->add_object( iv_service_name
          )->set_package( iv_package
          )->create_form_specification( ).

        lo_specification->set_short_description( 'Auto-generated by RAP Generator' ).

        LOOP AT it_entities INTO DATA(lv_entity).
          DATA(lv_xco_entity) = CONV sxco_cds_object_name( lv_entity ).
          lo_specification->add_exposure( lv_xco_entity ).
        ENDLOOP.

        DATA(lo_result) = lo_put_operation->execute( ).

        " BẢN VÁ QUAN TRỌNG: Lấy chính xác câu lỗi từ lõi XCO
        DATA(lt_findings) = lo_result->findings->get( ).
        IF lt_findings IS NOT INITIAL.
          ev_success = abap_false.
          ev_message = lt_findings[ 1 ]->message->get_text( ). " <--- Trích xuất text gốc
        ENDIF.

     CATCH cx_root INTO DATA(lx_error).
        ev_success = abap_false.
        ev_message = lx_error->get_text( ).

        " 1. Lột mặt nạ các lớp Exception ẩn bên trong
        DATA(lx_prev) = lx_error->previous.
        WHILE lx_prev IS BOUND.
          ev_message = ev_message && | -> | && lx_prev->get_text( ).
          lx_prev = lx_prev->previous.
        ENDWHILE.

        " 2. Trích xuất trực tiếp báo cáo lỗi từ lõi XCO Put Exception
        TRY.
            DATA(lx_xco) = CAST cx_xco_gen_put_exception( lx_error ).
            LOOP AT lx_xco->findings->get( ) INTO DATA(lo_finding).
              ev_message = ev_message && | [| && lo_finding->message->get_text( ) && |]|.
            ENDLOOP.
          CATCH cx_root.
        ENDTRY.
    ENDTRY.
  ENDMETHOD.


  METHOD generate_sb_via_xco.
    ev_success = abap_true.
    CLEAR ev_message.

    TRY.
        DATA(lo_environment) = xco_cp_generation=>environment->dev_system( iv_transport ).
        DATA(lo_put_operation) = lo_environment->create_put_operation( ).

        DATA(lo_specification) = lo_put_operation->for-srvb->add_object( iv_binding_name
          )->set_package( iv_package
          )->create_form_specification( ).

        lo_specification->set_short_description( 'Auto-generated Service Binding' ).
        " Đặt chuẩn OData V4 UI để có thể test ngay trên Fiori Elements Preview
        lo_specification->set_binding_type( xco_cp_service_binding=>binding_type->odata_v4_ui ).
        " Link với Service Definition vừa tạo
        lo_specification->add_service( CONV #( iv_service_name ) )->add_version( '0001' )->set_service_definition( iv_service_name ).

        DATA(lo_result) = lo_put_operation->execute( ).

        DATA(lt_findings) = lo_result->findings->get( ).
        IF lt_findings IS NOT INITIAL.
          ev_success = abap_false.
          LOOP AT lt_findings INTO DATA(lo_finding).
            ev_message = ev_message && | [| && lo_finding->message->get_text( ) && |]|.
          ENDLOOP.
        ENDIF.

     CATCH cx_root INTO DATA(lx_error).
        ev_success = abap_false.
        ev_message = lx_error->get_text( ).

        " 1. Lột mặt nạ các lớp Exception ẩn bên trong
        DATA(lx_prev) = lx_error->previous.
        WHILE lx_prev IS BOUND.
          ev_message = ev_message && | -> | && lx_prev->get_text( ).
          lx_prev = lx_prev->previous.
        ENDWHILE.

        " 2. Trích xuất trực tiếp báo cáo lỗi từ lõi XCO Put Exception
        TRY.
            DATA(lx_xco) = CAST cx_xco_gen_put_exception( lx_error ).

            " BẢN VÁ: Đổi tên biến thành LO_XCO_FINDING để không bị trùng
            LOOP AT lx_xco->findings->get( ) INTO DATA(lo_xco_finding).
              ev_message = ev_message && | [| && lo_xco_finding->message->get_text( ) && |]|.
            ENDLOOP.

          CATCH cx_root.
        ENDTRY.
    ENDTRY.
  ENDMETHOD.

 ENDCLASS.
