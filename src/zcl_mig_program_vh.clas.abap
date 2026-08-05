CLASS zcl_mig_program_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS zcl_mig_program_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    TYPES:
      BEGIN OF ty_program,
        programname TYPE progname,
      END OF ty_program.

    DATA lt_programs
      TYPE STANDARD TABLE OF ty_program
      WITH EMPTY KEY.


    "Search text từ Fiori Value Help
    DATA(lv_search) =
      io_request->get_search_expression( ).

    lv_search =
      to_upper( lv_search ).

    REPLACE ALL OCCURRENCES OF '"'
      IN lv_search
      WITH ''.

    REPLACE ALL OCCURRENCES OF '*'
      IN lv_search
      WITH '%'.


    DATA lv_pattern
      TYPE string.

    IF lv_search IS INITIAL.
      lv_pattern = '%'.
    ELSE.
      lv_pattern = |%{ lv_search }%|.
    ENDIF.


    "Chỉ executable programs: TRDIR-SUBC = '1'
    "Giới hạn tuyệt đối dưới 4000 record
    SELECT FROM trdir
      FIELDS
        name AS programname
      WHERE subc = '1'
        AND name LIKE @lv_pattern
      ORDER BY name
      INTO TABLE @lt_programs
      UP TO 3999 ROWS.

        "==========================================================
    " Sorting bắt buộc khi Fiori gửi paging
    "==========================================================
    DATA(lt_sort_elements) =
      io_request->get_sort_elements( ).


    IF lt_sort_elements IS INITIAL.

      SORT lt_programs
        BY programname ASCENDING.

    ELSE.

      READ TABLE lt_sort_elements
        INDEX 1
        INTO DATA(ls_sort_element).

      IF sy-subrc = 0
         AND to_upper( ls_sort_element-element_name )
               = 'PROGRAMNAME'.

        IF ls_sort_element-descending = abap_true.

          SORT lt_programs
            BY programname DESCENDING.

        ELSE.

          SORT lt_programs
            BY programname ASCENDING.

        ENDIF.

      ELSE.

        "Fallback ổn định cho paging
        SORT lt_programs
          BY programname ASCENDING.

      ENDIF.

    ENDIF.


    IF io_request->is_total_numb_of_rec_requested( ).

      io_response->set_total_number_of_records(
        lines( lt_programs )
      ).

    ENDIF.


    IF io_request->is_data_requested( ) = abap_false.
      RETURN.
    ENDIF.


    DATA(lo_paging) =
      io_request->get_paging( ).

    DATA(lv_offset) =
      lo_paging->get_offset( ).

    DATA(lv_page_size) =
      lo_paging->get_page_size( ).


    DATA lt_page
      TYPE STANDARD TABLE OF ty_program
      WITH EMPTY KEY.


    IF lv_page_size =
         if_rap_query_paging=>page_size_unlimited.

      lt_page =
        lt_programs.

    ELSEIF lv_page_size > 0.

      DATA(lv_from) =
        CONV i( lv_offset + 1 ).

      DATA(lv_to) =
        CONV i( lv_offset + lv_page_size ).


      LOOP AT lt_programs
        INTO DATA(ls_program)
        FROM lv_from
        TO lv_to.

        APPEND ls_program
          TO lt_page.

      ENDLOOP.

    ENDIF.


    io_response->set_data(
      lt_page
    ).

  ENDMETHOD.

ENDCLASS.
