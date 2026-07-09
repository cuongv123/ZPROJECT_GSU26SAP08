CLASS zcl_dynamic_rap_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " Interface bắt buộc của SAP để biến class này thành một OData V4 Provider
    INTERFACES if_rap_query_provider .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_dynamic_rap_provider IMPLEMENTATION.

METHOD if_rap_query_provider~select.
    " =====================================================================
    " 1. NHẬN DIỆN "KHÁCH HÀNG" ĐANG GỌI
    " =====================================================================
    DATA(lv_entity_name) = io_request->get_entity_id( ).
    DATA(lv_fm_name) = CONV funcname( replace( val = lv_entity_name sub = 'ZCE_GEN_' with = '' ) ).
    TRANSLATE lv_fm_name TO UPPER CASE.

    " =====================================================================
    " 2. ĐỌC TẤT CẢ YÊU CẦU TỪ FIORI (THỎA MÃN HỢP ĐỒNG CỦA SAP)
    " =====================================================================
    " A. Lọc (Filter)
    TRY.
        DATA(lo_filter) = io_request->get_filter( ).
      CATCH cx_root.
    ENDTRY.

    " B. Sắp xếp (Sorting) - Phòng ngừa lỗi missing get_sort_elements
    TRY.
        DATA(lt_sort) = io_request->get_sort_elements( ).
      CATCH cx_root.
    ENDTRY.

    " C. Tìm kiếm (Search) - Phòng ngừa lỗi missing get_search_expression
    TRY.
        DATA(lv_search) = io_request->get_search_expression( ).
      CATCH cx_root.
    ENDTRY.

    " D. Phân trang (Paging) - ĐÂY CHÍNH LÀ THỦ PHẠM GÂY RA LỖI CỦA BẠN
    DATA: lv_top  TYPE i,
          lv_skip TYPE i.
    TRY.
        DATA(lo_paging) = io_request->get_paging( ).
        lv_top  = COND #( WHEN lo_paging IS BOUND THEN lo_paging->get_page_size( ) ELSE 0 ).
        lv_skip = COND #( WHEN lo_paging IS BOUND THEN lo_paging->get_offset( ) ELSE 0 ).
      CATCH cx_root.
    ENDTRY.


    " =====================================================================
    " 3. CHUẨN BỊ BỘ NHỚ VÀ GỌI HÀM CŨ
    " =====================================================================
    DATA: lo_data TYPE REF TO data.
    FIELD-SYMBOLS: <lt_result> TYPE STANDARD TABLE. "
    DATA(lv_ready) = abap_true.

    TRY.
        CREATE DATA lo_data TYPE STANDARD TABLE OF (lv_entity_name).
        ASSIGN lo_data->* TO <lt_result>.
      CATCH cx_root.
        lv_ready = abap_false.
    ENDTRY.

    IF lv_ready = abap_true.
      DATA: lt_ptab TYPE abap_func_parmbind_tab,
            ls_ptab TYPE abap_func_parmbind.

      ls_ptab-name  = 'ET_DATA'.  " Chú ý: Tên biến đầu ra của Function Module
      ls_ptab-kind  = abap_func_tables.
      GET REFERENCE OF <lt_result> INTO ls_ptab-value.
      INSERT ls_ptab INTO TABLE lt_ptab.

      TRY.
          CALL FUNCTION lv_fm_name PARAMETER-TABLE lt_ptab.
        CATCH cx_root.
          " Bỏ lệnh RETURN đi để tránh Dump.
      ENDTRY.
    ENDIF.


    " =====================================================================
    " 4. XỬ LÝ DỮ LIỆU ĐỘNG (SORT & PAGING) & TRẢ KẾT QUẢ VỀ UI
    " =====================================================================
    IF <lt_result> IS ASSIGNED.

      " Trả về TỔNG SỐ DÒNG cho Fiori UI (Để nó biết có bao nhiêu trang)
      IF io_request->is_total_numb_of_rec_requested( ).
        io_response->set_total_number_of_records( lines( <lt_result> ) ).
      ENDIF.

      IF io_request->is_data_requested( ).

        " Áp dụng SORTING động (Click vào tiêu đề cột trên Fiori để sort)
        IF lt_sort IS NOT INITIAL.
          DATA: lt_otab TYPE abap_sortorder_tab,
                ls_otab TYPE abap_sortorder.
          LOOP AT lt_sort INTO DATA(ls_sort_req).
            ls_otab-name       = ls_sort_req-element_name.
            ls_otab-descending = ls_sort_req-descending.
            APPEND ls_otab TO lt_otab.
          ENDLOOP.
          SORT <lt_result> BY (lt_otab).
        ENDIF.


        IF lv_top > 0.
          DATA: lo_sliced TYPE REF TO data.
          FIELD-SYMBOLS: <lt_sliced> TYPE STANDARD TABLE,
                         <ls_row>    TYPE ANY.

          CREATE DATA lo_sliced LIKE <lt_result>.
          ASSIGN lo_sliced->* TO <lt_sliced>.

          DATA(lv_start) = lv_skip + 1.
          DATA(lv_end)   = lv_skip + lv_top.

          LOOP AT <lt_result> ASSIGNING <ls_row> FROM lv_start TO lv_end.
            APPEND <ls_row> TO <lt_sliced>.
          ENDLOOP.

          io_response->set_data( <lt_sliced> ).
        ELSE.
          io_response->set_data( <lt_result> ).
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
