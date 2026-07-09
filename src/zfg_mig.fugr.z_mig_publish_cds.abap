FUNCTION z_mig_publish_cds.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VIEW_NAME) TYPE  STRING
*"     VALUE(IV_SOURCE) TYPE  STRING
*"     VALUE(IV_PACKAGE) TYPE  DEVCLASS
*"     VALUE(IV_TRANSPORT) TYPE  TRKORR
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  BOOLE_D
*"     VALUE(ET_MESSAGES) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------

  DATA: ls_dddlsrcv TYPE ddddlsrcv,
        lt_e071     TYPE TABLE OF e071,
        ls_e071     TYPE e071,
        lt_e071k    TYPE TABLE OF e071k. " <-- BẢN VÁ: Khai báo thêm bảng E071K

  " Khai báo các biến mang chuẩn type của bảng TADIR
  DATA: lv_pgmid    TYPE tadir-pgmid VALUE 'R3TR',
        lv_object   TYPE tadir-object VALUE 'DDLS',
        lv_obj_name TYPE tadir-obj_name,
        lv_devclass TYPE tadir-devclass.

  " Gán giá trị vào biến chuẩn
  lv_obj_name = iv_view_name.
  lv_devclass = iv_package.

  ls_dddlsrcv-ddlname = iv_view_name.
  ls_dddlsrcv-source  = iv_source.

  ev_success = abap_false.
  CLEAR et_messages.

  TRY.
      " =================================================================
      " BƯỚC 1: ĐĂNG KÝ PACKAGE VÀ TRANSPORT REQUEST
      " =================================================================
      IF iv_package IS NOT INITIAL AND iv_package <> '$TMP'.

        CALL FUNCTION 'TR_TADIR_INTERFACE'
          EXPORTING
            wi_tadir_pgmid    = lv_pgmid
            wi_tadir_object   = lv_object
            wi_tadir_obj_name = lv_obj_name
            wi_tadir_devclass = lv_devclass
            wi_test_modus     = abap_false.

        IF iv_transport IS NOT INITIAL.
          ls_e071-trkorr   = iv_transport.
          ls_e071-pgmid    = lv_pgmid.
          ls_e071-object   = lv_object.
          ls_e071-obj_name = lv_obj_name.
          APPEND ls_e071 TO lt_e071.

          CALL FUNCTION 'TR_APPEND_TO_COMM_OBJS_KEYS'
            EXPORTING
              wi_trkorr = iv_transport
            TABLES
              wt_e071   = lt_e071
              wt_e071k  = lt_e071k      " <-- BẢN VÁ: Truyền bảng rỗng vào tham số bắt buộc
            EXCEPTIONS
              OTHERS    = 1.
        ENDIF.
      ENDIF.

      " =================================================================
      " BƯỚC 2: LƯU VÀ KÍCH HOẠT MÃ NGUỒN
      " =================================================================
      DATA(lo_ddl_handler) = cl_dd_ddl_handler_factory=>create( ).

      lo_ddl_handler->save(
        EXPORTING
          name         = CONV #( iv_view_name )
          put_state    = 'N'
          ddddlsrcv_wa = ls_dddlsrcv ).

      lo_ddl_handler->activate(
        EXPORTING
          name = CONV #( iv_view_name ) ).

      ev_success = abap_true.

    CATCH cx_root INTO DATA(lx_error).
      APPEND VALUE #( type = 'E' id = 'SY' number = '530' message = lx_error->get_text( ) ) TO et_messages.
  ENDTRY.

ENDFUNCTION.
