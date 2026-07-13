CLASS zcl_abap_source_parser DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_code_parser.

  PRIVATE SECTION.

    METHODS extract_select_option
      IMPORTING
        iv_line         TYPE string
      EXPORTING
        ev_field        TYPE string
        ev_data_element TYPE string.

    METHODS extract_parameter
      IMPORTING
        iv_line         TYPE string
      EXPORTING
        ev_field        TYPE string
        ev_data_element TYPE string.

    METHODS extract_function_name
      IMPORTING iv_line            TYPE string
      RETURNING VALUE(rv_function) TYPE string.

    METHODS extract_table_name
      IMPORTING iv_line         TYPE string
      RETURNING VALUE(rv_table) TYPE string.

    METHODS extract_form_name
      IMPORTING iv_line        TYPE string
      RETURNING VALUE(rv_form) TYPE string.

    METHODS extract_method_name
      IMPORTING iv_line          TYPE string
      RETURNING VALUE(rv_method) TYPE string.

    METHODS extract_submit_name
      IMPORTING iv_line           TYPE string
      RETURNING VALUE(rv_program) TYPE string.

    METHODS extract_class_name
      IMPORTING iv_line         TYPE string
      RETURNING VALUE(rv_class) TYPE string.

    METHODS extract_static_method_name
      IMPORTING iv_line          TYPE string
      RETURNING VALUE(rv_method) TYPE string.

    METHODS extract_screen_number
      IMPORTING iv_line          TYPE string
      RETURNING VALUE(rv_screen) TYPE string.

    METHODS extract_join_tables
      IMPORTING iv_line          TYPE string
      RETURNING VALUE(rt_tables)
                  TYPE zcl_parser_types=>tt_source_code.

    METHODS extract_new_class_name
      IMPORTING iv_line         TYPE string
      RETURNING VALUE(rv_class) TYPE string.

    METHODS build_statements
      IMPORTING
                it_source_code       TYPE zcl_parser_types=>tt_source_code
      RETURNING VALUE(rt_statements)
                  TYPE zcl_parser_types=>tt_source_code.

    METHODS parse_selection_screen
      IMPORTING it_source_code TYPE zcl_parser_types=>tt_source_code
      CHANGING  ct_ui_filter   TYPE zcl_parser_types=>tt_raw_ui_filter.

    METHODS parse_alv_grid
      IMPORTING it_source_code TYPE zcl_parser_types=>tt_source_code
      CHANGING  ct_logic       TYPE zcl_parser_types=>tt_raw_logic.

    METHODS extract_alv_variable
      IMPORTING iv_statement TYPE string
                iv_alv_type  TYPE string
      RETURNING VALUE(rv_variable) TYPE string.

    METHODS extract_select_fields
      IMPORTING iv_line TYPE string
      RETURNING VALUE(rv_fields) TYPE string.
ENDCLASS.


CLASS zcl_abap_source_parser IMPLEMENTATION.
  METHOD extract_select_option.
    DATA: lt_parts TYPE STANDARD TABLE OF string.
    DATA(lv_line) = to_upper( iv_line ).
    REPLACE ALL OCCURRENCES OF ':' IN lv_line WITH space.
    REPLACE ALL OCCURRENCES OF '.' IN lv_line WITH space.
    CONDENSE lv_line.
    SPLIT lv_line AT space INTO TABLE lt_parts.

    " SELECT-OPTIONS S_VBELN FOR VBAK-VBELN
    IF lv_line CS 'SELECT-OPTIONS'.
      READ TABLE lt_parts INDEX 2 INTO ev_field.
    ELSE.
      READ TABLE lt_parts INDEX 1 INTO ev_field.
    ENDIF.
    CONDENSE ev_field.
    READ TABLE lt_parts TRANSPORTING NO FIELDS WITH KEY table_line = 'FOR'.

    IF sy-subrc = 0.
      DATA(lv_idx) = sy-tabix + 1.
      READ TABLE lt_parts INDEX lv_idx INTO ev_data_element.

      " VBAK-VBELN -> VBELN
      IF ev_data_element CS '-'.
        SPLIT ev_data_element AT '-' INTO DATA(lv_dummy) ev_data_element.
      ENDIF.
      CONDENSE ev_data_element.
    ENDIF.
  ENDMETHOD.

  METHOD extract_parameter.
    DATA: lt_parts TYPE STANDARD TABLE OF string.
    DATA(lv_line) = to_upper( iv_line ).
    REPLACE ALL OCCURRENCES OF ':' IN lv_line WITH space.
    REPLACE ALL OCCURRENCES OF '.' IN lv_line WITH space.
    CONDENSE lv_line.
    SPLIT lv_line AT space INTO TABLE lt_parts.

    " PARAMETERS P_BUKRS TYPE BUKRS
    IF lv_line CS 'PARAMETERS'.
      READ TABLE lt_parts INDEX 2 INTO ev_field.
    ELSE.
      READ TABLE lt_parts INDEX 1 INTO ev_field.
    ENDIF.
    CONDENSE ev_field.

    " TYPE
    READ TABLE lt_parts TRANSPORTING NO FIELDS WITH KEY table_line = 'TYPE'.

    " Nếu không có TYPE thì check LIKE
    IF sy-subrc <> 0.
      READ TABLE lt_parts TRANSPORTING NO FIELDS WITH KEY table_line = 'LIKE'.
    ENDIF.

    IF sy-subrc = 0.
      DATA(lv_idx) = sy-tabix + 1.
      READ TABLE lt_parts INDEX lv_idx INTO ev_data_element.

      " MARA-MATNR -> MATNR
      IF ev_data_element CS '-'.
        SPLIT ev_data_element AT '-' INTO DATA(lv_dummy) ev_data_element.
      ENDIF.
      CONDENSE ev_data_element.
    ENDIF.
  ENDMETHOD.

  METHOD extract_function_name.
    SPLIT iv_line AT ''''
      INTO DATA(lv_dummy) rv_function DATA(lv_ignore).
    CONDENSE rv_function.
  ENDMETHOD.

  METHOD extract_table_name.
    DATA: lt_parts TYPE STANDARD TABLE OF string.
    DATA(lv_line) = to_upper( iv_line ).
    REPLACE ALL OCCURRENCES OF '.' IN lv_line WITH space.
    CONDENSE lv_line.


    CLEAR rv_table.

    SPLIT lv_line AT space INTO TABLE lt_parts.

    " SELECT ... FROM
    READ TABLE lt_parts TRANSPORTING NO FIELDS WITH KEY table_line = 'FROM'.

    IF sy-subrc = 0.
      DATA(lv_idx) = sy-tabix + 1.
      READ TABLE lt_parts INDEX lv_idx INTO rv_table.

    ELSEIF lv_line CS 'UPDATE '.
      READ TABLE lt_parts INDEX 2 INTO rv_table.

    ELSEIF lv_line CS 'INSERT INTO '.
      READ TABLE lt_parts INDEX 3 INTO rv_table.

    ELSEIF lv_line CS 'DELETE FROM '.
      READ TABLE lt_parts INDEX 3 INTO rv_table.
    ENDIF.

    IF rv_table CS '(*'
        OR rv_table CS '('
        OR rv_table CS ')'.
      CLEAR rv_table.
    ENDIF.

    CONDENSE rv_table.

  ENDMETHOD.

  METHOD extract_form_name.
    DATA lt_parts TYPE STANDARD TABLE OF string.
    DATA(lv_line) = to_upper( iv_line ).
    SPLIT lv_line AT space INTO TABLE lt_parts.
    READ TABLE lt_parts INDEX 2 INTO rv_form.
  ENDMETHOD.

  METHOD extract_method_name.
    SPLIT iv_line AT '->'
      INTO DATA(lv_obj)
           DATA(lv_method).
    SPLIT lv_method AT '('
      INTO rv_method
           DATA(lv_dummy).
    REPLACE ALL OCCURRENCES OF '.' IN rv_method WITH ''.
    CONDENSE rv_method.
  ENDMETHOD.

  METHOD extract_submit_name.
    DATA lt_parts TYPE STANDARD TABLE OF string.
    DATA(lv_line) = to_upper( iv_line ).
    REPLACE ALL OCCURRENCES OF '.' IN lv_line WITH space.
    SPLIT lv_line AT space INTO TABLE lt_parts.
    READ TABLE lt_parts INDEX 2 INTO rv_program.
  ENDMETHOD.

  METHOD extract_class_name.
    DATA lt_parts TYPE STANDARD TABLE OF string.
    DATA(lv_line) = to_upper( iv_line ).
    REPLACE ALL OCCURRENCES OF '.' IN lv_line WITH space.
    SPLIT lv_line AT space INTO TABLE lt_parts.
    READ TABLE lt_parts
      TRANSPORTING NO FIELDS
      WITH KEY table_line = 'TYPE'.
    IF sy-subrc = 0.
      DATA(lv_idx) = sy-tabix + 1.
      READ TABLE lt_parts INDEX lv_idx INTO rv_class.
    ENDIF.
  ENDMETHOD.

  METHOD extract_static_method_name.
    SPLIT iv_line AT '=>'
      INTO DATA(lv_class)
           DATA(lv_method).
    SPLIT lv_method AT '('
      INTO rv_method
           DATA(lv_dummy).
    REPLACE ALL OCCURRENCES OF '.' IN rv_method WITH ''.
    CONDENSE rv_method.
  ENDMETHOD.

  METHOD extract_screen_number.
    DATA lt_parts TYPE STANDARD TABLE OF string.
    DATA(lv_line) = to_upper( iv_line ).
    REPLACE ALL OCCURRENCES OF '.' IN lv_line WITH space.
    CONDENSE lv_line.
    SPLIT lv_line AT space INTO TABLE lt_parts.
    READ TABLE lt_parts INDEX 3 INTO rv_screen.
    CONDENSE rv_screen.
  ENDMETHOD.

  METHOD extract_join_tables.
    DATA:
      lt_parts TYPE STANDARD TABLE OF string,
      lv_word  TYPE string,
      lv_take  TYPE abap_bool.
    DATA(lv_line) = to_upper( iv_line ).
    REPLACE ALL OCCURRENCES OF ',' IN lv_line WITH space.
    REPLACE ALL OCCURRENCES OF '.' IN lv_line WITH space.
    CONDENSE lv_line.
    SPLIT lv_line AT space INTO TABLE lt_parts.
    LOOP AT lt_parts INTO lv_word.
      IF lv_word = 'FROM' OR lv_word = 'JOIN'.
        lv_take = abap_true.
        CONTINUE.
      ENDIF.
      IF lv_take = abap_true.
        lv_take = abap_false.
        IF lv_word IS INITIAL.
          CONTINUE.
        ENDIF.
        " Dynamic table
        IF lv_word CS '('.
          CONTINUE.
        ENDIF.
        IF lv_word CS ')'.
          CONTINUE.
        ENDIF.
        IF lv_word CP '@*'.
          CONTINUE.
        ENDIF.
        APPEND lv_word TO rt_tables.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD extract_new_class_name.
    DATA:
      lv_upper_line TYPE string,
      lv_after_new  TYPE string.
    CLEAR rv_class.
    lv_upper_line = to_upper( iv_line ).
    FIND FIRST OCCURRENCE OF 'NEW '
         IN lv_upper_line
         MATCH OFFSET DATA(lv_offset).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DATA(lv_start) = lv_offset + 4.
    " Prevent substring overflow
    IF lv_start >= strlen( lv_upper_line ).
      RETURN.
    ENDIF.
    lv_after_new =
        substring(
          val = lv_upper_line
          off = lv_start ).
    CONDENSE lv_after_new.
    IF lv_after_new IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT lv_after_new
      AT '('
      INTO rv_class
           DATA(lv_dummy).
    CONDENSE rv_class.
    " Ignore NEW #( )
    IF rv_class = '#'.
      CLEAR rv_class.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD build_statements.
    DATA: lv_statement TYPE string.

    LOOP AT it_source_code INTO DATA(lv_line).
      SPLIT lv_line AT '"' INTO lv_line DATA(lv_comment).
      DATA(lv_work) = lv_line.
      SHIFT lv_work LEFT DELETING LEADING space.

      IF lv_work IS INITIAL.
        CONTINUE.
      ENDIF.

      CONCATENATE
        lv_statement
        lv_work
        INTO lv_statement
        SEPARATED BY space.

      " Statement kết thúc bằng dấu .
      WHILE lv_statement CS '.'.
        SPLIT lv_statement
          AT '.'
          INTO DATA(lv_single_stmt)
               lv_statement.
        CONDENSE lv_single_stmt.
        IF lv_single_stmt IS NOT INITIAL.
          APPEND lv_single_stmt TO rt_statements.
        ENDIF.
      ENDWHILE.
    ENDLOOP.
    IF lv_statement IS NOT INITIAL.
      APPEND lv_statement TO rt_statements.
    ENDIF.
  ENDMETHOD.

  METHOD zif_code_parser~analyze_program.

    DATA:
      ls_filter TYPE zcl_parser_types=>ty_raw_ui_filter,
      ls_logic  TYPE zcl_parser_types=>ty_raw_logic,
      ls_table  TYPE zcl_parser_types=>ty_raw_db_table.

    DATA:
      lt_items TYPE STANDARD TABLE OF string,
      lv_item  TYPE string.

    DATA(lt_statements) = build_statements( it_source_code ).
    LOOP AT lt_statements INTO DATA(lv_line).
      CONDENSE lv_line.

      DATA(lv_upper) = to_upper( lv_line ).

      " Skip empty/comment
      IF lv_upper IS INITIAL
         OR lv_upper+0(1) = '*'
         OR lv_upper+0(1) = '"'.
        CONTINUE.
      ENDIF.

    "=====================================
      " Detect SELECT
      "=====================================
      IF lv_upper CS 'SELECT' AND lv_upper CS 'FROM'.
        CLEAR lt_items.
        lt_items = extract_join_tables( lv_line ).

        DATA: lv_extracted_fields TYPE string,
              lv_sel_table        TYPE string.

        " Gọi hàm bóc tách trường
        lv_extracted_fields = me->extract_select_fields( lv_line ).

        LOOP AT lt_items INTO lv_sel_table.
          CLEAR ls_table.
          ls_table-table_name = lv_sel_table.
          ls_table-operation  = 'SELECT'.
          ls_table-fields     = lv_extracted_fields. " <--- LƯU VÀO ls_table
          APPEND ls_table TO et_db_table.
        ENDLOOP.
      ENDIF.

      "=====================================
      " Detect PARAMETERS & SELECT-OPTIONS (Smart Scan)
      "=====================================
      IF lv_upper CS 'PARAMETERS' OR lv_upper CS 'SELECT-OPTIONS'.
        CLEAR ls_filter.

        " 1. Xác định loại Filter
        IF lv_upper CS 'PARAMETERS'.
          ls_filter-filter_type = 'Single Value'.
        ELSE.
          ls_filter-filter_type = 'Multiple Range'.
        ENDIF.

        " 2. Lấy Tên Biến bằng Regex
        FIND PCRE `(?:PARAMETERS|SELECT-OPTIONS)\s*:?\s*([\w\-]+)` IN lv_upper SUBMATCHES ls_filter-field_name.

        " 3. Lấy Data Element (TYPE, LIKE, FOR)
        FIND PCRE `(?:TYPE|LIKE|FOR)\s+([\w\-]+)` IN lv_upper SUBMATCHES ls_filter-data_element.
        " Xóa tiền tố bảng nếu có (VD: VBAK-VBELN -> VBELN)
        IF ls_filter-data_element CS '-'.
          SPLIT ls_filter-data_element AT '-' INTO DATA(lv_dummy_tab) ls_filter-data_element.
        ENDIF.

        " 4. Nhận diện OBLIGATORY (Bắt buộc nhập)
        IF lv_upper CS 'OBLIGATORY'.
          ls_filter-mandatory_flag = abap_true.
        ELSE.
          ls_filter-mandatory_flag = abap_false.
        ENDIF.

        " 5. Nhận diện MATCHCODE OBJECT (Search Help)
        FIND PCRE `MATCHCODE\s+OBJECT\s+([\w]+)` IN lv_upper SUBMATCHES ls_filter-matchcode_object.

        IF ls_filter-field_name IS NOT INITIAL.
          APPEND ls_filter TO et_ui_filter.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect AUTHORITY-CHECK (Security Scan)
      "=====================================
      IF lv_upper CS 'AUTHORITY-CHECK OBJECT'.
        CLEAR ls_logic.
        " Bắt tên Object phân quyền nằm trong dấu nháy đơn
        FIND PCRE `AUTHORITY-CHECK\s+OBJECT\s+'([^']+)'` IN lv_upper SUBMATCHES ls_logic-object_name.

        IF ls_logic-object_name IS INITIAL.
          " Fallback nếu lập trình viên truyền bằng biến thay vì nháy đơn
          FIND PCRE `AUTHORITY-CHECK\s+OBJECT\s+([\w]+)` IN lv_upper SUBMATCHES ls_logic-object_name.
        ENDIF.

        IF ls_logic-object_name IS NOT INITIAL.
          ls_logic-object_type = 'AUTHORITY-CHECK'.
          APPEND ls_logic TO et_logic.
        ENDIF.
      ENDIF.
      "=====================================
      " Detect PERFORM
      "=====================================
      IF lv_upper CS 'PERFORM '.
        CLEAR ls_logic.
        ls_logic-object_name = extract_form_name( lv_line ).
        ls_logic-object_type = 'FORM'.
        APPEND ls_logic TO et_logic.
      ENDIF.

      "=====================================
      " Detect CALL FUNCTION
      "=====================================
      IF lv_upper CS 'CALL FUNCTION'.
        CLEAR ls_logic.
        ls_logic-object_name = extract_function_name( lv_line ).
        ls_logic-object_type = 'FUNCTION MODULE'.
        IF ls_logic-object_name IS NOT INITIAL.
          APPEND ls_logic TO et_logic.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect CALL SCREEN
      "=====================================
      IF lv_upper CS 'CALL SCREEN'.
        CLEAR ls_logic.
        ls_logic-object_name = extract_screen_number( lv_line ).
        ls_logic-object_type = 'CALL SCREEN'.
        IF ls_logic-object_name IS NOT INITIAL.
          APPEND ls_logic TO et_logic.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect SUBMIT
      "=====================================
      IF lv_upper CS 'SUBMIT '.
        CLEAR ls_logic.
        ls_logic-object_name = extract_submit_name( lv_line ).
        ls_logic-object_type = 'SUBMIT'.
        APPEND ls_logic TO et_logic.
      ENDIF.

      "=====================================
      " Detect CREATE OBJECT
      "=====================================
      IF lv_upper CS 'CREATE OBJECT'.
        CLEAR ls_logic.
        ls_logic-object_name =
          extract_class_name( lv_line ).
        ls_logic-object_type = 'CLASS'.
        IF ls_logic-object_name IS NOT INITIAL.
          APPEND ls_logic TO et_logic.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect NEW Operator
      "=====================================
      IF lv_upper CP '*NEW *(*'.
        CLEAR ls_logic.
        ls_logic-object_name = extract_new_class_name( lv_line ).
        ls_logic-object_type = 'CLASS'.
        IF ls_logic-object_name IS NOT INITIAL.
*           AND ls_logic-object_name <> '#'.
          APPEND ls_logic TO et_logic.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect METHOD
      "=====================================
      IF lv_upper CP '*->*(*'.
        CLEAR ls_logic.
        ls_logic-object_name = extract_method_name( lv_line ).
        ls_logic-object_type = 'METHOD'.
        IF ls_logic-object_name IS NOT INITIAL.
          APPEND ls_logic TO et_logic.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect Static METHOD
      "=====================================
      IF lv_upper CP '*=>*(*'.
        CLEAR ls_logic.
        ls_logic-object_name =
          extract_static_method_name( lv_line ).
        ls_logic-object_type = 'STATIC METHOD'.
        IF ls_logic-object_name IS NOT INITIAL.
          APPEND ls_logic TO et_logic.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect SELECT
      "=====================================
      IF lv_upper CS 'SELECT' AND lv_upper CS 'FROM'.
        CLEAR lt_items.
        lt_items = extract_join_tables( lv_line ).
        LOOP AT lt_items INTO DATA(lv_table_name).
          CLEAR ls_table.
          ls_table-table_name = lv_table_name.
          ls_table-operation  = 'SELECT'.
          APPEND ls_table TO et_db_table.
        ENDLOOP.
      ENDIF.

      "=====================================
      " Detect INSERT
      "=====================================
      IF lv_upper CS 'INSERT INTO'.
        CLEAR ls_table.
        ls_table-table_name = extract_table_name( lv_line ).
        ls_table-operation = 'INSERT'.
        IF ls_table-table_name IS NOT INITIAL.
          APPEND ls_table TO et_db_table.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect UPDATE
      "=====================================
      IF lv_upper CP 'UPDATE *'
       AND lv_upper NS 'UPDATE SCREEN'
       AND lv_upper NS 'UPDATE TASK'.
        CLEAR ls_table.
        ls_table-table_name = extract_table_name( lv_line ).
        ls_table-operation = 'UPDATE'.
        IF ls_table-table_name IS NOT INITIAL.
          APPEND ls_table TO et_db_table.
        ENDIF.
      ENDIF.

      "=====================================
      " Detect DELETE
      "=====================================
      IF lv_upper CS 'DELETE FROM'.
        CLEAR ls_table.
        ls_table-table_name = extract_table_name( lv_line ).
        ls_table-operation = 'DELETE'.
        IF ls_table-table_name IS NOT INITIAL.
          APPEND ls_table TO et_db_table.
        ENDIF.
      ENDIF.
      "=====================================
      " Detect SELECT
      "=====================================
      IF lv_upper CS 'SELECT' AND lv_upper CS 'FROM'.
        CLEAR lt_items.
        lt_items = extract_join_tables( lv_line ).

        " 1. Đổi sang tên biến hoàn toàn mới (lv_sql_fields) để né code cũ
        DATA(lv_sql_fields) = me->extract_select_fields( lv_line ).

        " 2. Dùng FIELD-SYMBOL để lặp, tuyệt đối miễn nhiễm với lỗi "already declared"
        LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<fs_table_name>).
          CLEAR ls_table.
          ls_table-table_name = <fs_table_name>.
          ls_table-operation  = 'SELECT'.
          ls_table-fields     = lv_sql_fields. " <--- LƯU FIELDS VÀO ĐÂY
          APPEND ls_table TO et_db_table.
        ENDLOOP.
      ENDIF.
      "===================================================================
      " THE CORE: DETECT ALV -> EXTRACT VARIABLE -> RESOLVE DATA TYPE
      "===================================================================
      DATA: lv_alv_type TYPE string.
      CLEAR lv_alv_type.

      " 1. Nhận diện các loại ALV trên toàn bộ 1 Statement hoàn chỉnh
      IF lv_upper CS 'REUSE_ALV_GRID_DISPLAY' OR lv_upper CS 'REUSE_ALV_LIST_DISPLAY'.
        lv_alv_type = 'ALV_CLASSIC'.
        ls_logic-object_name = 'REUSE_ALV_DISPLAY'.
      ELSEIF lv_upper CS 'SET_TABLE_FOR_FIRST_DISPLAY'.
        lv_alv_type = 'ALV_OO'.
        ls_logic-object_name = 'CL_GUI_ALV_GRID'.
      ELSEIF lv_upper CS 'CL_SALV_TABLE=>FACTORY'.
        lv_alv_type = 'ALV_SALV'.
        ls_logic-object_name = 'CL_SALV_TABLE'.
      ENDIF.

      " 2. Nếu tìm thấy ALV, bắt đầu quy trình TRUY HỒI ĐỘNG (Dynamic Resolution)
      IF lv_alv_type IS NOT INITIAL.
        ls_logic-object_type = lv_alv_type.

        " A. Bóc tách tên biến (Ví dụ: Lấy ra chữ 'GT_DATA')
        DATA(lv_var_name) = extract_alv_variable(
                              iv_statement = lv_upper
                              iv_alv_type  = lv_alv_type ).

        " B. Kích hoạt cỗ máy Resolver quét ngược toàn bộ Source Code để tìm gốc
        IF lv_var_name IS NOT INITIAL.
          DATA(lo_resolver) = NEW zcl_abap_type_resolver( ).
          ls_logic-target_structure = lo_resolver->resolve_type(
                                        iv_variable_name = lv_var_name
                                        it_source_code   = it_source_code ).
        ENDIF.

    " C. GHI NHẬN THÀNH QUẢ VÀ LÀM SẠCH DỮ LIỆU TRƯỚC KHI LƯU DB
        IF ls_logic-target_structure IS INITIAL OR ls_logic-target_structure = 'NO_STRUCTURE_FOUND'.
          " Cứu vớt: Bắt tham số I_STRUCTURE_NAME nếu nó nằm cùng 1 dòng
          FIND PCRE `I_STRUCTURE_NAME\s*=\s*'([^']+)'` IN lv_upper SUBMATCHES ls_logic-target_structure.
        ENDIF.

        " TẨY RỬA RÁC: Xóa ngay chữ TABLE OF nếu bộ type_resolver bắt nhầm
        IF ls_logic-target_structure CS 'TABLE OF'.
           REPLACE ALL OCCURRENCES OF 'STANDARD TABLE OF' IN ls_logic-target_structure WITH ''.
           REPLACE ALL OCCURRENCES OF 'TABLE OF' IN ls_logic-target_structure WITH ''.
           CONDENSE ls_logic-target_structure.
        ENDIF.

        IF ls_logic-target_structure IS INITIAL.
          ls_logic-target_structure = 'NO_STRUCTURE_FOUND'.
        ENDIF.

        APPEND ls_logic TO et_logic.
        CLEAR ls_logic.
      ENDIF.
    ENDLOOP.

    "=====================================
    " DEDUPLICATE RESULTS
    "=====================================
    SORT et_logic BY object_type object_name.
    DELETE ADJACENT DUPLICATES FROM et_logic
      COMPARING object_type object_name.

    SORT et_db_table BY operation table_name.
    DELETE ADJACENT DUPLICATES FROM et_db_table
      COMPARING operation table_name.

    SORT et_ui_filter BY filter_type field_name.
    DELETE ADJACENT DUPLICATES FROM et_ui_filter
      COMPARING filter_type field_name.

  ENDMETHOD.

  METHOD parse_selection_screen.
    DATA: ls_filter TYPE zcl_parser_types=>ty_raw_ui_filter,
          lv_field  TYPE string,
          lv_type   TYPE string.

    LOOP AT it_source_code INTO DATA(lv_line).
      DATA(lv_upper) = to_upper( condense( lv_line ) ).

      " 1. Bóc tách PARAMETERS
      IF find( val = lv_upper pcre = `PARAMETERS\s*:?\s*(\w+)\s+TYPE\s+(\w+)` ) >= 0.
        FIND PCRE `PARAMETERS\s*:?\s*(\w+)\s+TYPE\s+(\w+)` IN lv_upper SUBMATCHES lv_field lv_type.
        IF sy-subrc = 0.
          ls_filter-field_name   = lv_field.
          ls_filter-filter_type  = 'Single Value'.
          ls_filter-data_element = lv_type.

          " ========================================================
          " BẮT ĐẦU CHÈN THÊM LOGIC MỚI VÀO ĐÂY (CHO PARAMETERS)
          IF lv_upper CS 'OBLIGATORY'.
            ls_filter-mandatory_flag = abap_true.
          ELSE.
            ls_filter-mandatory_flag = abap_false.
          ENDIF.
          FIND PCRE `MATCHCODE\s+OBJECT\s+([\w]+)` IN lv_upper SUBMATCHES ls_filter-matchcode_object.
          " ========================================================

          APPEND ls_filter TO ct_ui_filter.
          CLEAR ls_filter.
        ENDIF.
      ENDIF.

      " 2. Bóc tách SELECT-OPTIONS
      IF find( val = lv_upper pcre = `SELECT-OPTIONS\s*:?\s*(\w+)\s+FOR\s+([\w-]+)` ) >= 0.
        FIND PCRE `SELECT-OPTIONS\s*:?\s*(\w+)\s+FOR\s+([\w-]+)` IN lv_upper SUBMATCHES lv_field lv_type.
        IF sy-subrc = 0.
          ls_filter-field_name   = lv_field.
          ls_filter-filter_type  = 'Multiple Range'.
          ls_filter-data_element = lv_type.

          " ========================================================
          " BẮT ĐẦU CHÈN THÊM LOGIC MỚI VÀO ĐÂY (CHO SELECT-OPTIONS)
          IF lv_upper CS 'OBLIGATORY'.
            ls_filter-mandatory_flag = abap_true.
          ELSE.
            ls_filter-mandatory_flag = abap_false.
          ENDIF.
          FIND PCRE `MATCHCODE\s+OBJECT\s+([\w]+)` IN lv_upper SUBMATCHES ls_filter-matchcode_object.
          " ========================================================

          APPEND ls_filter TO ct_ui_filter.
          CLEAR ls_filter.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD parse_alv_grid.
    DATA: ls_logic TYPE zcl_parser_types=>ty_raw_logic.

    LOOP AT it_source_code INTO DATA(lv_line).
      DATA(lv_upper) = to_upper( condense( lv_line ) ).

      " 1. Nhận diện Classic ALV (Dùng chuẩn PCRE)
      IF find( val = lv_upper pcre = `REUSE_ALV_GRID_DISPLAY|REUSE_ALV_LIST_DISPLAY|REUSE_ALV_HIERSEQ_LIST_DISPLAY` ) >= 0.
        ls_logic-object_name = 'REUSE_ALV_DISPLAY'.
        ls_logic-object_type = 'ALV_CLASSIC'.
        APPEND ls_logic TO ct_logic.
        CLEAR ls_logic.
      ENDIF.

      " 2. Nhận diện Object-Oriented ALV (OO ALV)
      IF find( val = lv_upper pcre = `CL_GUI_ALV_GRID` ) >= 0 OR find( val = lv_upper pcre = `SET_TABLE_FOR_FIRST_DISPLAY` ) >= 0.
        READ TABLE ct_logic WITH KEY object_type = 'ALV_OO' TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          ls_logic-object_name = 'CL_GUI_ALV_GRID'.
          ls_logic-object_type = 'ALV_OO'.
          APPEND ls_logic TO ct_logic.
          CLEAR ls_logic.
        ENDIF.
      ENDIF.

      " 3. Nhận diện SALV Table
      IF find( val = lv_upper pcre = `CL_SALV_TABLE=>FACTORY` ) >= 0.
         ls_logic-object_name = 'CL_SALV_TABLE'.
         ls_logic-object_type = 'ALV_SALV'.
         APPEND ls_logic TO ct_logic.
         CLEAR ls_logic.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

 METHOD extract_alv_variable.
    DATA: lv_pattern TYPE string,
          lv_match   TYPE string.

    " Tùy thuộc vào loại kiến trúc ALV, tham số chứa dữ liệu sẽ khác nhau
    CASE iv_alv_type.
      WHEN 'ALV_CLASSIC'.
        " Bắt biến sau chữ T_OUTTAB = (Ví dụ: T_OUTTAB = gt_sales)
        lv_pattern = `T_OUTTAB\s*=\s*([\w\-]+)`.
      WHEN 'ALV_OO'.
        " Bắt biến sau chữ IT_OUTTAB =
        lv_pattern = `IT_OUTTAB\s*=\s*([\w\-]+)`.
      WHEN 'ALV_SALV'.
        " Bắt biến sau chữ T_TABLE =
        lv_pattern = `T_TABLE\s*=\s*([\w\-]+)`.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    " Dùng PCRE quét trên toàn bộ câu lệnh (statement) đã được gộp dòng
    FIND PCRE lv_pattern IN to_upper( iv_statement ) SUBMATCHES lv_match.
    IF sy-subrc = 0.
      " Xóa khoảng trắng thừa
      rv_variable = condense( lv_match ).
    ENDIF.
  ENDMETHOD.

    METHOD extract_select_fields.
    DATA: lv_pattern TYPE string.
    DATA(lv_upper) = to_upper( condense( iv_line ) ).

    " Regex: Lấy tất cả mọi thứ nằm giữa SELECT (có thể kèm SINGLE/DISTINCT) và FROM
    lv_pattern = `SELECT\s+(?:SINGLE\s+)?(?:DISTINCT\s+)?(.*?)\s+FROM`.

    FIND PCRE lv_pattern IN lv_upper SUBMATCHES DATA(lv_raw_fields).

    IF sy-subrc = 0.
      " Nếu lập trình viên dùng SELECT *
      IF lv_raw_fields CS '*'.
        rv_fields = '*'.
      ELSE.
        " Xóa dấu phẩy và dọn dẹp khoảng trắng dư thừa
        REPLACE ALL OCCURRENCES OF ',' IN lv_raw_fields WITH space.
        rv_fields = condense( lv_raw_fields ).
        " Kết quả sẽ có dạng: 'VBELN ERDAT MATNR'
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

