CLASS zcl_mig_export_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mig_export_provider.

  PRIVATE SECTION.
    CONSTANTS:
      gc_format_excel TYPE zmig_e_file_format VALUE 'X',
      gc_format_csv   TYPE zmig_e_file_format VALUE 'C',
      gc_format_pdf   TYPE zmig_e_file_format VALUE 'P',
      gc_excel_name   TYPE string VALUE 'migration_report',
      gc_csv_name     TYPE string VALUE 'migration_report',
      gc_pdf_name     TYPE string VALUE 'migration_report'.

    TYPES: BEGIN OF ty_col,
             seq_no         TYPE ztb_exp_col-seq_no,
             fieldname      TYPE ztb_exp_col-fieldname,
             column_title   TYPE ztb_exp_col-column_title,
             odata_property TYPE ztb_exp_col-odata_property,
           END OF ty_col,
           tt_col TYPE STANDARD TABLE OF ty_col WITH EMPTY KEY.

    TYPES: BEGIN OF ty_section_registry,
             section_code TYPE zif_mig_export_provider=>ty_export_section,
             view_name    TYPE tabname,
             sheet_title  TYPE string,
             sort_spec    TYPE string,
           END OF ty_section_registry,
           tt_section_registry TYPE STANDARD TABLE OF ty_section_registry WITH NON-UNIQUE DEFAULT KEY.

    " Bản đồ field đã chọn theo TỪNG section - dùng khi ExportSection=ALL
    " để mỗi section lấy đúng field riêng đã được tick, không dùng chung
    " 1 danh sách phẳng cho tất cả section.
    TYPES: BEGIN OF ty_section_fields,
             section_code TYPE zif_mig_export_provider=>ty_export_section,
             fields       TYPE string_table,
           END OF ty_section_fields,
           tt_section_fields TYPE STANDARD TABLE OF ty_section_fields WITH NON-UNIQUE DEFAULT KEY.

    " ------------------------------------------------------------
    " Helpers dùng chung cho cả 3 định dạng
    " ------------------------------------------------------------
    METHODS get_section_registry
      RETURNING
        VALUE(rt_registry) TYPE tt_section_registry.

    " Sort động theo cấu hình sort_spec của section (VD: "TARGET_LAYER:D,SEVERITY:A")
    " - không hardcode tên section/field nào trong engine.
    METHODS apply_dynamic_sort
      IMPORTING
        iv_sort_spec TYPE string
      CHANGING
        ct_data      TYPE ANY TABLE.

    " Xây tên file động chứa ProgramName + ExportSection, đúng yêu cầu
    " spec mục 6 - hoạt động đúng cho cả 2 luồng gọi (GET theo report_type
    " và POST action chỉ có analysis_id, report_type rỗng).
    METHODS resolve_export_filename
      IMPORTING
        iv_analysis_id    TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
        iv_extension      TYPE string
      RETURNING
        VALUE(rv_filename) TYPE string.

    METHODS get_analysis_id
      IMPORTING
        iv_analysis_id        TYPE sysuuid_x16
        iv_report_type        TYPE zmig_mail_job-report_type
      RETURNING
        VALUE(rv_analysis_id) TYPE sysuuid_x16
      RAISING
        cx_root.

    " 1 SELECT duy nhất trên ZTB_EXP_COL cho 1 section, sau đó lọc/
    " sắp lại trong bộ nhớ theo it_selected_fields (nếu có) - KHÔNG
    " SELECT lần thứ 2 cho việc lọc.
    METHODS get_columns_for_section
      IMPORTING
        iv_section_code     TYPE zif_mig_export_provider=>ty_export_section
        it_selected_fields  TYPE string_table OPTIONAL
        io_struct           TYPE REF TO cl_abap_structdescr OPTIONAL
      RETURNING
        VALUE(rt_cols)      TYPE tt_col.

    " Tách chuỗi SelectedFields: trim, loại trùng, giữ thứ tự người dùng chọn.
    METHODS parse_selected_fields
      IMPORTING
        iv_selected_fields TYPE string
      RETURNING
        VALUE(rt_fields)   TYPE string_table.

    " Parse SelectedFields dạng nhiều section khi ExportSection=ALL:
    " "SECTION1:Field1,Field2;SECTION2:Field3" -> map section -> field list.
    " Định dạng phẳng cũ (không có dấu ':') vẫn hoạt động bình thường cho
    " trường hợp 1 section cụ thể (không đi qua method này).
    METHODS parse_section_field_map
      IMPORTING
        iv_selected_fields TYPE string
      RETURNING
        VALUE(rt_map)      TYPE tt_section_fields.

    " 1 SELECT duy nhất để đọc dữ liệu của 1 section theo analysis_id.
    METHODS read_section_data
      IMPORTING
        iv_view_name    TYPE tabname
        iv_analysis_id  TYPE sysuuid_x16
      RETURNING
        VALUE(rr_data)  TYPE REF TO data
      RAISING
        cx_root.

    METHODS escape_pdf_text
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS escape_csv_value
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    " Build 1 dòng text "|" - dùng chung cho CSV/PDF renderer.
    METHODS build_row_line
      IMPORTING
        it_cols          TYPE tt_col
        is_row           TYPE any
      RETURNING
        VALUE(rv_line)   TYPE string.

    METHODS build_pdf_document
      IMPORTING
        iv_title          TYPE string
        it_header_cols    TYPE tt_col
        it_lines          TYPE string_table
      RETURNING
        VALUE(rv_content) TYPE xstring
      RAISING
        cx_root.

    " Render các trang (dạng PDF content-stream text) cho 1 section -
    " chưa đóng gói thành file PDF hoàn chỉnh, dùng để gộp nhiều section
    " vào cùng 1 file khi ExportSection = ALL.
    METHODS render_section_pages
      IMPORTING
        iv_title        TYPE string
        it_header_cols  TYPE tt_col
        it_lines        TYPE string_table
      RETURNING
        VALUE(rt_pages) TYPE string_table.

    " Đóng gói danh sách trang (đã render) thành 1 file PDF nhị phân
    " hoàn chỉnh (xref/trailer) - dùng chung cho cả trường hợp 1 section
    " và nhiều section gộp lại.
    METHODS assemble_pdf_binary
      IMPORTING
        it_pages          TYPE string_table
      RETURNING
        VALUE(rv_content) TYPE xstring.

    METHODS build_csv_document
      IMPORTING
        it_cols           TYPE tt_col
        it_lines          TYPE string_table
      RETURNING
        VALUE(rv_content) TYPE xstring.

    METHODS export_excel
      IMPORTING
        iv_job_id          TYPE sysuuid_x16
        iv_analysis_id     TYPE sysuuid_x16
        iv_report_type     TYPE zmig_mail_job-report_type
        iv_export_section  TYPE zif_mig_export_provider=>ty_export_section
        iv_selected_fields TYPE string
      RETURNING
        VALUE(rs_result)   TYPE zif_mig_export_provider=>ty_export_result
      RAISING
        zcx_excel.

    METHODS export_csv
      IMPORTING
        iv_job_id          TYPE sysuuid_x16
        iv_analysis_id     TYPE sysuuid_x16
        iv_report_type     TYPE zmig_mail_job-report_type
        iv_export_section  TYPE zif_mig_export_provider=>ty_export_section
        iv_selected_fields TYPE string
      RETURNING
        VALUE(rs_result)   TYPE zif_mig_export_provider=>ty_export_result.

    METHODS export_pdf
      IMPORTING
        iv_job_id          TYPE sysuuid_x16
        iv_analysis_id     TYPE sysuuid_x16
        iv_report_type     TYPE zmig_mail_job-report_type
        iv_export_section  TYPE zif_mig_export_provider=>ty_export_section
        iv_selected_fields TYPE string
      RETURNING
        VALUE(rs_result)   TYPE zif_mig_export_provider=>ty_export_result.

ENDCLASS.

CLASS zcl_mig_export_engine IMPLEMENTATION.

  METHOD zif_mig_export_provider~generate.

    TRY.
        DATA(lv_format) = to_upper( condense( CONV string( iv_file_format ) ) ).
        DATA(lv_section) = CONV zif_mig_export_provider=>ty_export_section(
          to_upper( condense( CONV string( iv_export_section ) ) ) ).

        " ExportSection=ALL + SelectedFields: giờ được hỗ trợ qua định dạng
        " "SECTION1:Field1,Field2;SECTION2:Field3" - mỗi section tự lấy
        " đúng field đã tick, không còn bị chặn như trước.

        CASE lv_format.
          WHEN gc_format_excel OR 'EXCEL' OR 'E' OR 'XLSX'.
            rs_result = export_excel(
              iv_job_id          = iv_job_id
              iv_analysis_id     = iv_analysis_id
              iv_report_type     = iv_report_type
              iv_export_section  = lv_section
              iv_selected_fields = iv_selected_fields ).

          WHEN gc_format_csv OR 'CSV'.
            rs_result = export_csv(
              iv_job_id          = iv_job_id
              iv_analysis_id     = iv_analysis_id
              iv_report_type     = iv_report_type
              iv_export_section  = lv_section
              iv_selected_fields = iv_selected_fields ).

          WHEN gc_format_pdf OR 'PDF'.
            rs_result = export_pdf(
              iv_job_id          = iv_job_id
              iv_analysis_id     = iv_analysis_id
              iv_report_type     = iv_report_type
              iv_export_section  = lv_section
              iv_selected_fields = iv_selected_fields ).

          WHEN OTHERS.
            rs_result-success = abap_false.
            rs_result-message = |Unsupported export format { iv_file_format }.|.
        ENDCASE.

        IF rs_result-success = abap_true.
          rs_result-file_format = iv_file_format.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).
        CLEAR: rs_result-content, rs_result-file_name, rs_result-file_type,
               rs_result-file_format, rs_result-mime_type.
        rs_result-success = abap_false.
        rs_result-message = lx_error->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD get_section_registry.
    CLEAR rt_registry.

    " 1 SELECT duy nhất, không nằm trong loop. Không còn fallback hardcode
    " - registry hoàn toàn phụ thuộc dữ liệu thật trong ZTB_EXP_SECTION.
    SELECT section_code, view_name, sheet_title, sort_spec
      FROM ztb_exp_section
      WHERE is_active = 'X'
      ORDER BY sort_order ASCENDING
      INTO CORRESPONDING FIELDS OF TABLE @rt_registry.
  ENDMETHOD.


  METHOD apply_dynamic_sort.
    " iv_sort_spec dạng: "FIELD1:D,FIELD2:A" (D=Descending, A=Ascending)
    " Parse hoàn toàn động, không hardcode tên field/section nào ở đây.
    DATA lt_sort_order TYPE abap_sortorder_tab.

    SPLIT iv_sort_spec AT ',' INTO TABLE DATA(lt_parts).
    LOOP AT lt_parts INTO DATA(lv_part).
      SPLIT lv_part AT ':' INTO DATA(lv_field) DATA(lv_dir).
      lv_field = to_upper( condense( lv_field ) ).
      IF lv_field IS INITIAL.
        CONTINUE.
      ENDIF.
      APPEND VALUE #(
        name       = lv_field
        descending = xsdbool( to_upper( condense( lv_dir ) ) = 'D' )
      ) TO lt_sort_order.
    ENDLOOP.

    IF lt_sort_order IS NOT INITIAL.
      TRY.
          SORT ct_data BY (lt_sort_order).
        CATCH cx_root.
          " sort_spec cấu hình sai field name -> bỏ qua sort, không chặn export.
      ENDTRY.
    ENDIF.
  ENDMETHOD.


  METHOD resolve_export_filename.
    DATA(lv_prefix) = CONV string( iv_report_type ).

    IF lv_prefix IS INITIAL AND iv_analysis_id IS NOT INITIAL.
      " Luồng POST action chỉ có analysis_id, report_type rỗng ->
      " lấy ProgramName trực tiếp từ bảng để tên file luôn đúng yêu cầu.
      SELECT SINGLE program_name
        FROM zmig_anl_h
        WHERE analysis_id = @iv_analysis_id
        INTO @lv_prefix.
    ENDIF.

    IF lv_prefix IS INITIAL.
      lv_prefix = 'migration_report'.
    ENDIF.

    " Loại ký tự không hợp lệ trong tên file (khoảng trắng, / \ : * ? " < > |)
    lv_prefix = replace( regex = '[^A-Za-z0-9_\-]' val = lv_prefix with = '_' occ = 0 ).

    rv_filename = |{ lv_prefix }_{ iv_export_section }.{ iv_extension }|.
  ENDMETHOD.


  METHOD get_analysis_id.
    IF iv_analysis_id IS NOT INITIAL.
      rv_analysis_id = iv_analysis_id.
      RETURN.
    ENDIF.

    SELECT SINGLE analysis_id
      FROM zmig_anl_h
      WHERE program_name = @iv_report_type
      INTO @rv_analysis_id.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
  ENDMETHOD.


  METHOD parse_selected_fields.
    CLEAR rt_fields.
    IF iv_selected_fields IS INITIAL.
      RETURN.
    ENDIF.

    SPLIT iv_selected_fields AT ',' INTO TABLE DATA(lt_raw).

    LOOP AT lt_raw INTO DATA(lv_raw).
      DATA(lv_trimmed) = condense( lv_raw ).
      IF lv_trimmed IS INITIAL.
        CONTINUE.
      ENDIF.
      " Loại trùng, giữ nguyên thứ tự xuất hiện đầu tiên.
      READ TABLE rt_fields WITH KEY table_line = lv_trimmed TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND lv_trimmed TO rt_fields.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD parse_section_field_map.
    CLEAR rt_map.
    IF iv_selected_fields IS INITIAL.
      RETURN.
    ENDIF.

    " Định dạng: "SECTION1:Field1,Field2;SECTION2:Field3"
    SPLIT iv_selected_fields AT ';' INTO TABLE DATA(lt_parts).

    LOOP AT lt_parts INTO DATA(lv_part).
      lv_part = condense( lv_part ).
      IF lv_part IS INITIAL.
        CONTINUE.
      ENDIF.

      FIND FIRST OCCURRENCE OF ':' IN lv_part MATCH OFFSET DATA(lv_colon_pos).
      IF sy-subrc <> 0.
        CONTINUE. " thiếu dấu ':' -> định dạng sai, bỏ qua phần này
      ENDIF.

      DATA(lv_section_code) = to_upper( condense( lv_part(lv_colon_pos) ) ).
      DATA(lv_field_start)  = lv_colon_pos + 1.
      DATA(lv_fields_str)   = lv_part+lv_field_start.

      IF lv_section_code IS INITIAL.
        CONTINUE.
      ENDIF.

      READ TABLE rt_map WITH KEY section_code = lv_section_code TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE. " section khai báo trùng -> chỉ giữ lần đầu tiên
      ENDIF.

      APPEND VALUE #(
        section_code = lv_section_code
        fields       = parse_selected_fields( lv_fields_str )
      ) TO rt_map.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_columns_for_section.
    " 1 SELECT duy nhất trên toàn bộ cột của section.
    SELECT seq_no, fieldname, column_title, odata_property
      FROM ztb_exp_col
      WHERE section_code = @iv_section_code
      ORDER BY seq_no ASCENDING
      INTO TABLE @DATA(lt_all_cols).

    IF lt_all_cols IS INITIAL AND io_struct IS BOUND.
      " Fallback: chưa maintain ZTB_EXP_COL cho section này -> lấy hết
      " component của structure làm cột mặc định (không SELECT thêm).
      LOOP AT io_struct->get_components( ) INTO DATA(ls_comp).
        APPEND VALUE #( fieldname      = ls_comp-name
                         column_title   = ls_comp-name
                         odata_property = ls_comp-name ) TO lt_all_cols.
      ENDLOOP.
    ENDIF.

    IF it_selected_fields IS INITIAL.
      rt_cols = lt_all_cols.
      RETURN.
    ENDIF.

    " Lọc + sắp lại theo đúng thứ tự it_selected_fields (so khớp theo
    " odata_property, không phân biệt hoa/thường) - xử lý trong bộ nhớ,
    " không SELECT lại.
    LOOP AT it_selected_fields INTO DATA(lv_field).
      READ TABLE lt_all_cols INTO DATA(ls_found)
        WITH KEY odata_property = lv_field.
      IF sy-subrc = 0.
        APPEND ls_found TO rt_cols.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_section_data.
    DATA(lo_struct) = CAST cl_abap_structdescr(
      cl_abap_typedescr=>describe_by_name( iv_view_name ) ).

    DATA(lo_table_type) = cl_abap_tabledescr=>create( lo_struct ).
    CREATE DATA rr_data TYPE HANDLE lo_table_type.
    ASSIGN rr_data->* TO FIELD-SYMBOL(<lt_data>).

    " 1 SELECT duy nhất cho section này.
    SELECT * FROM (iv_view_name)
      WHERE analysis_id = @iv_analysis_id
      INTO TABLE @<lt_data>.

  ENDMETHOD.


  METHOD build_row_line.
    CLEAR rv_line.
    LOOP AT it_cols INTO DATA(ls_col).
      ASSIGN COMPONENT ls_col-fieldname OF STRUCTURE is_row TO FIELD-SYMBOL(<lv_val>).
      DATA(lv_val_str) = COND string( WHEN sy-subrc = 0 THEN CONV string( <lv_val> ) ELSE '' ).
      rv_line = COND #( WHEN rv_line IS INITIAL THEN lv_val_str
                         ELSE rv_line && '|' && lv_val_str ).
    ENDLOOP.
  ENDMETHOD.


  METHOD escape_csv_value.
    DATA(lv_escaped) = replace( val = iv_value sub = '"' with = '""' occ = 0 ).
    rv_value = |"{ lv_escaped }"|.
  ENDMETHOD.


  METHOD escape_pdf_text.
    DATA(lv_escaped) = iv_text.
    lv_escaped = replace( val = lv_escaped sub = '\' with = '\\' occ = 0 ).
    lv_escaped = replace( val = lv_escaped sub = '(' with = '\(' occ = 0 ).
    lv_escaped = replace( val = lv_escaped sub = ')' with = '\)' occ = 0 ).
    lv_escaped = replace( regex = '[^\x20-\x7E]' val = lv_escaped with = ' ' occ = 0 ).
    rv_text = lv_escaped.
  ENDMETHOD.


  METHOD export_excel.
    DATA(lt_registry) = get_section_registry( ).
    DATA(lv_is_all) = xsdbool( to_upper( condense( CONV string( iv_export_section ) ) ) = 'ALL' ).

    " ALL: field theo từng section (định dạng "SEC:f1,f2;SEC2:f3").
    " Khác ALL: field phẳng áp dụng cho đúng 1 section được chọn.
    DATA(lt_sel_fields) = COND string_table(
      WHEN lv_is_all = abap_false THEN parse_selected_fields( iv_selected_fields ) ).
    DATA(lt_section_map) = COND #(
      WHEN lv_is_all = abap_true THEN parse_section_field_map( iv_selected_fields ) ).

    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root.
        lv_analysis_id = VALUE #( ).
    ENDTRY.

    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lv_sheet_count) = 0.

    TRY.
        DATA(lo_style_bold) = lo_excel->add_new_style( ).
        lo_style_bold->font->bold = abap_true.

        DATA(lo_style_total) = lo_excel->add_new_style( ).
        lo_style_total->font->bold = abap_true.
        lo_style_total->fill->fgcolor-rgb = 'FFF2F2F2'.
        lo_style_total->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
      CATCH cx_root INTO DATA(lx_style_error).
        rs_result-success = abap_false.
        rs_result-message = |Excel style init error: { lx_style_error->get_text( ) }.|.
        RETURN.
    ENDTRY.

    TRY.
        LOOP AT lt_registry INTO DATA(ls_section).
          IF iv_export_section <> 'ALL' AND ls_section-section_code <> iv_export_section.
            CONTINUE.
          ENDIF.

          TRY.
              DATA(lo_struct) = CAST cl_abap_structdescr(
                cl_abap_typedescr=>describe_by_name( ls_section-view_name ) ).
            CATCH cx_root.
              CONTINUE.
          ENDTRY.

          " Field áp dụng cho section đang xử lý: nếu ALL, tra trong map
          " (section nào không có trong map -> dùng cột mặc định); nếu
          " không phải ALL, dùng danh sách phẳng của chính section đó.
          DATA lt_fields_for_section TYPE string_table.
          CLEAR lt_fields_for_section.
          IF lv_is_all = abap_true.
            READ TABLE lt_section_map INTO DATA(ls_section_map)
              WITH KEY section_code = ls_section-section_code.
            IF sy-subrc = 0.
              lt_fields_for_section = ls_section_map-fields.
            ENDIF.
          ELSE.
            lt_fields_for_section = lt_sel_fields.
          ENDIF.

          " 1 SELECT cho cột + 1 SELECT cho dữ liệu, cả hai nằm ngoài
          " mọi loop dòng dữ liệu (chỉ lặp theo số section, tối đa ~9).
          DATA(lt_columns) = get_columns_for_section(
            iv_section_code    = ls_section-section_code
            it_selected_fields = lt_fields_for_section
            io_struct          = lo_struct ).

          DATA(lo_sheet) = COND #(
            WHEN lv_sheet_count = 0
            THEN lo_excel->get_active_worksheet( )
            ELSE lo_excel->add_new_worksheet( ) ).
          lo_sheet->set_title( ip_title = CONV #( ls_section-sheet_title ) ).

          IF lv_analysis_id IS INITIAL OR lt_columns IS INITIAL.
            lo_sheet->set_cell( ip_column = 1 ip_row = 1
              ip_value = |No data available for section { ls_section-sheet_title }.| ).
            lv_sheet_count = lv_sheet_count + 1.
            CONTINUE.
          ENDIF.

          TRY.
              DATA(lr_data) = read_section_data(
                iv_view_name   = ls_section-view_name
                iv_analysis_id = lv_analysis_id ).
            CATCH cx_root.
              lo_sheet->set_cell( ip_column = 1 ip_row = 1
                ip_value = |Error reading data for section { ls_section-sheet_title }.| ).
              lv_sheet_count = lv_sheet_count + 1.
              CONTINUE.
          ENDTRY.
          ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

          IF ls_section-sort_spec IS NOT INITIAL AND <lt_data> IS NOT INITIAL.
            TRY.
                apply_dynamic_sort(
                  EXPORTING iv_sort_spec = ls_section-sort_spec
                  CHANGING  ct_data      = <lt_data> ).
              CATCH cx_root.
                " sort lỗi -> bỏ qua sort, vẫn xuất dữ liệu chưa sort.
            ENDTRY.
          ENDIF.

          IF <lt_data> IS INITIAL.
            lo_sheet->set_cell( ip_column = 1 ip_row = 1
              ip_value = |No data available for section { ls_section-sheet_title }.| ).
            lv_sheet_count = lv_sheet_count + 1.
            CONTINUE.
          ENDIF.

          " --- Header row ---
          DATA(lv_col) = 1.
          LOOP AT lt_columns INTO DATA(ls_col).
            lo_sheet->set_cell( ip_column = lv_col ip_row = 1
              ip_value = CONV string( ls_col-column_title ) ).
            lo_sheet->set_cell_style( ip_column = lv_col ip_row = 1
              ip_style = lo_style_bold->get_guid( ) ).
            lv_col = lv_col + 1.
          ENDLOOP.

          " --- Data rows + gom tổng cho cột số (1 lượt duyệt dữ liệu) ---
          DATA lt_is_numeric TYPE STANDARD TABLE OF abap_bool WITH EMPTY KEY.
          DATA lt_totals     TYPE STANDARD TABLE OF decfloat34 WITH EMPTY KEY.
          DATA(lt_struct_components) = lo_struct->get_components( ).
          LOOP AT lt_columns INTO ls_col.
            DATA(lv_is_num) = abap_false.
            READ TABLE lt_struct_components INTO DATA(ls_struct_comp)
              WITH KEY name = CONV abap_compname( ls_col-fieldname ).
            IF sy-subrc = 0 AND ls_struct_comp-type IS BOUND
               AND ls_struct_comp-type->kind = cl_abap_typedescr=>kind_elem.
              DATA(lv_type_kind) = CAST cl_abap_elemdescr( ls_struct_comp-type )->type_kind.
              IF lv_type_kind CA 'ibsI8PaFe'.  " int/packed/float/decfloat kinds
                lv_is_num = abap_true.
              ENDIF.
            ENDIF.
            APPEND lv_is_num TO lt_is_numeric.
            APPEND 0 TO lt_totals.
          ENDLOOP.

          DATA(lv_row) = 2.
          LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
            lv_col = 1.
            LOOP AT lt_columns INTO ls_col.
              ASSIGN COMPONENT ls_col-fieldname OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_val>).
              IF sy-subrc = 0.
                lo_sheet->set_cell( ip_column = lv_col ip_row = lv_row ip_value = <lv_val> ).
                IF lt_is_numeric[ lv_col ] = abap_true.
                  TRY.
                      lt_totals[ lv_col ] = lt_totals[ lv_col ] + CONV decfloat34( <lv_val> ).
                    CATCH cx_root.
                  ENDTRY.
                ENDIF.
              ENDIF.
              lv_col = lv_col + 1.
            ENDLOOP.
            lv_row = lv_row + 1.
          ENDLOOP.

          " --- Total row: chỉ điền cho cột numeric, cột đầu ghi nhãn ---
          DATA(lv_total_row) = lv_row + 1.
          lo_sheet->set_cell( ip_column = 1 ip_row = lv_total_row ip_value = 'TOTAL' ).
          lo_sheet->set_cell_style( ip_column = 1 ip_row = lv_total_row
            ip_style = lo_style_total->get_guid( ) ).

          DO lines( lt_columns ) TIMES.
            DATA(lv_c) = sy-index.
            IF lt_is_numeric[ lv_c ] = abap_true.
              lo_sheet->set_cell( ip_column = lv_c ip_row = lv_total_row ip_value = lt_totals[ lv_c ] ).
              lo_sheet->set_cell_style( ip_column = lv_c ip_row = lv_total_row
                ip_style = lo_style_total->get_guid( ) ).
            ENDIF.
          ENDDO.

          lo_sheet->set_cell( ip_column = 1 ip_row = lv_total_row + 1
            ip_value = |Rows: { lines( <lt_data> ) }| ).

          lo_sheet->calculate_column_widths( ).
          lv_sheet_count = lv_sheet_count + 1.

        ENDLOOP.

      CATCH zcx_excel INTO DATA(lx_excel_build).
        rs_result-success = abap_false.
        rs_result-message = |Excel build error: { lx_excel_build->get_text( ) }.|.
        RETURN.
      CATCH cx_root INTO DATA(lx_unexpected).
        rs_result-success = abap_false.
        rs_result-message = |Unexpected error: { lx_unexpected->get_text( ) }.|.
        RETURN.
    ENDTRY.

    IF lv_sheet_count = 0.
      DATA(lo_empty_sheet) = lo_excel->get_active_worksheet( ).
      lo_empty_sheet->set_title( ip_title = 'Report' ).
      lo_empty_sheet->set_cell( ip_column = 1 ip_row = 1
        ip_value = |No data available for program { iv_report_type }.| ).
    ENDIF.

    DATA(lo_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ).
    TRY.
        DATA(lv_content) = lo_writer->write_file( io_excel = lo_excel ).
      CATCH zcx_excel INTO DATA(lx_excel).
        rs_result-success = abap_false.
        rs_result-message = |Excel writer error: { lx_excel->get_text( ) }.|.
        RETURN.
    ENDTRY.

    rs_result-success     = abap_true.
    rs_result-content     = lv_content.
    rs_result-file_name   = resolve_export_filename(
                               iv_analysis_id    = lv_analysis_id
                               iv_report_type    = iv_report_type
                               iv_export_section = iv_export_section
                               iv_extension      = 'xlsx' ).
    rs_result-file_type   = 'BIN'.
    rs_result-file_format = gc_format_excel.
    rs_result-mime_type   = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
    rs_result-message     = 'Excel export generated successfully.'.
  ENDMETHOD.


  METHOD export_csv.
    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root INTO DATA(lx_no_analysis).
        rs_result-success = abap_false.
        rs_result-message = |Analysis not found: { lx_no_analysis->get_text( ) }.|.
        RETURN.
    ENDTRY.

    DATA(lt_registry) = get_section_registry( ).
    DATA(lv_is_all) = xsdbool( to_upper( condense( CONV string( iv_export_section ) ) ) = 'ALL' ).
    DATA(lt_sel_fields) = COND string_table(
      WHEN lv_is_all = abap_false THEN parse_selected_fields( iv_selected_fields ) ).
    DATA(lt_section_map) = COND #(
      WHEN lv_is_all = abap_true THEN parse_section_field_map( iv_selected_fields ) ).

    " Danh sách section cần xuất: ALL -> toàn bộ registry (~9, không phụ
    " thuộc số dòng dữ liệu), khác ALL -> đúng 1 section được chọn.
    DATA lt_target_sections LIKE lt_registry.
    IF lv_is_all = abap_true.
      lt_target_sections = lt_registry.
    ELSE.
      READ TABLE lt_registry INTO DATA(ls_only) WITH KEY section_code = iv_export_section.
      IF sy-subrc <> 0.
        rs_result-success = abap_false.
        rs_result-message = |Unknown export section { iv_export_section }.|.
        RETURN.
      ENDIF.
      APPEND ls_only TO lt_target_sections.
    ENDIF.

    DATA lv_csv_all TYPE string.
    DATA lv_any_section_ok TYPE abap_bool VALUE abap_false.

    LOOP AT lt_target_sections INTO DATA(ls_section).

      TRY.
          DATA(lo_struct) = CAST cl_abap_structdescr(
            cl_abap_typedescr=>describe_by_name( ls_section-view_name ) ).
        CATCH cx_root.
          CONTINUE.
      ENDTRY.

      DATA lt_fields_for_section TYPE string_table.
      CLEAR lt_fields_for_section.
      IF lv_is_all = abap_true.
        READ TABLE lt_section_map INTO DATA(ls_section_map)
          WITH KEY section_code = ls_section-section_code.
        IF sy-subrc = 0.
          lt_fields_for_section = ls_section_map-fields.
        ENDIF.
      ELSE.
        lt_fields_for_section = lt_sel_fields.
      ENDIF.

      DATA(lt_columns) = get_columns_for_section(
        iv_section_code    = ls_section-section_code
        it_selected_fields = lt_fields_for_section
        io_struct          = lo_struct ).
      IF lt_columns IS INITIAL.
        CONTINUE.
      ENDIF.

      TRY.
          DATA(lr_data) = read_section_data(
            iv_view_name   = ls_section-view_name
            iv_analysis_id = lv_analysis_id ).
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
      ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

      lv_any_section_ok = abap_true.

      " Header phân biệt section (chỉ có ý nghĩa khi ALL, vô hại khi 1 section)
      lv_csv_all = lv_csv_all && | { ls_section-sheet_title } | && cl_abap_char_utilities=>cr_lf.

      DATA(lv_col_header) = REDUCE string(
        INIT s = ``
        FOR ls_c IN lt_columns
        NEXT s = COND #( WHEN s IS INITIAL THEN escape_csv_value( CONV string( ls_c-column_title ) )
                          ELSE s && ',' && escape_csv_value( CONV string( ls_c-column_title ) ) ) ).
      lv_csv_all = lv_csv_all && lv_col_header && cl_abap_char_utilities=>cr_lf.

      LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
        DATA(lv_line) = build_row_line( it_cols = lt_columns is_row = <ls_row> ).
        SPLIT lv_line AT '|' INTO TABLE DATA(lt_vals).
        DATA(lv_csv_line) = REDUCE string(
          INIT s = ``
          FOR lv_v IN lt_vals
          NEXT s = COND #( WHEN s IS INITIAL THEN escape_csv_value( lv_v )
                            ELSE s && ',' && escape_csv_value( lv_v ) ) ).
        lv_csv_all = lv_csv_all && lv_csv_line && cl_abap_char_utilities=>cr_lf.
      ENDLOOP.

      lv_csv_all = lv_csv_all && cl_abap_char_utilities=>cr_lf.

    ENDLOOP.

    IF lv_any_section_ok = abap_false.
      rs_result-success = abap_false.
      rs_result-message = 'No data available for the requested export.'.
      RETURN.
    ENDIF.

    rs_result-success     = abap_true.
    rs_result-content     = cl_abap_codepage=>convert_to( source = lv_csv_all codepage = 'UTF-8' ).
    rs_result-file_name   = resolve_export_filename(
                               iv_analysis_id    = lv_analysis_id
                               iv_report_type    = iv_report_type
                               iv_export_section = iv_export_section
                               iv_extension      = 'csv' ).
    rs_result-file_type   = 'CSV'.
    rs_result-file_format = gc_format_csv.
    rs_result-mime_type   = 'text/csv'.
    rs_result-message     = 'CSV export generated successfully.'.
  ENDMETHOD.


  METHOD export_pdf.
    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root INTO DATA(lx_no_analysis).
        rs_result-success = abap_false.
        rs_result-message = |Analysis not found: { lx_no_analysis->get_text( ) }.|.
        RETURN.
    ENDTRY.

    DATA(lt_registry) = get_section_registry( ).
    DATA(lv_is_all) = xsdbool( to_upper( condense( CONV string( iv_export_section ) ) ) = 'ALL' ).
    DATA(lt_sel_fields) = COND string_table(
      WHEN lv_is_all = abap_false THEN parse_selected_fields( iv_selected_fields ) ).
    DATA(lt_section_map) = COND #(
      WHEN lv_is_all = abap_true THEN parse_section_field_map( iv_selected_fields ) ).

    DATA lt_target_sections LIKE lt_registry.
    IF lv_is_all = abap_true.
      lt_target_sections = lt_registry.
    ELSE.
      READ TABLE lt_registry INTO DATA(ls_only) WITH KEY section_code = iv_export_section.
      IF sy-subrc <> 0.
        rs_result-success = abap_false.
        rs_result-message = |Unknown export section { iv_export_section }.|.
        RETURN.
      ENDIF.
      APPEND ls_only TO lt_target_sections.
    ENDIF.

    DATA lt_all_pages TYPE string_table.

    LOOP AT lt_target_sections INTO DATA(ls_section).

      TRY.
          DATA(lo_struct) = CAST cl_abap_structdescr(
            cl_abap_typedescr=>describe_by_name( ls_section-view_name ) ).
        CATCH cx_root.
          CONTINUE.
      ENDTRY.

      DATA lt_fields_for_section TYPE string_table.
      CLEAR lt_fields_for_section.
      IF lv_is_all = abap_true.
        READ TABLE lt_section_map INTO DATA(ls_section_map)
          WITH KEY section_code = ls_section-section_code.
        IF sy-subrc = 0.
          lt_fields_for_section = ls_section_map-fields.
        ENDIF.
      ELSE.
        lt_fields_for_section = lt_sel_fields.
      ENDIF.

      DATA(lt_columns) = get_columns_for_section(
        iv_section_code    = ls_section-section_code
        it_selected_fields = lt_fields_for_section
        io_struct          = lo_struct ).
      IF lt_columns IS INITIAL.
        CONTINUE.
      ENDIF.

      TRY.
          DATA(lr_data) = read_section_data(
            iv_view_name   = ls_section-view_name
            iv_analysis_id = lv_analysis_id ).
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
      ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

      IF <lt_data> IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_header) = REDUCE string(
        INIT s = ``
        FOR ls_c IN lt_columns
        NEXT s = COND #( WHEN s IS INITIAL THEN CONV string( ls_c-column_title )
                          ELSE s && '|' && ls_c-column_title ) ).

      DATA lt_lines TYPE string_table.
      CLEAR lt_lines.
      APPEND lv_header TO lt_lines.
      LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
        APPEND build_row_line( it_cols = lt_columns is_row = <ls_row> ) TO lt_lines.
      ENDLOOP.

      TRY.
          DATA(lt_section_pages) = render_section_pages(
            iv_title       = |{ ls_section-sheet_title } - { iv_report_type }|
            it_header_cols = lt_columns
            it_lines       = lt_lines ).
          APPEND LINES OF lt_section_pages TO lt_all_pages.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.

    ENDLOOP.

    IF lt_all_pages IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'No data available for PDF generation.'.
      RETURN.
    ENDIF.

    rs_result-content     = assemble_pdf_binary( it_pages = lt_all_pages ).
    rs_result-success     = abap_true.
    rs_result-file_name   = resolve_export_filename(
                               iv_analysis_id    = lv_analysis_id
                               iv_report_type    = iv_report_type
                               iv_export_section = iv_export_section
                               iv_extension      = 'pdf' ).
    rs_result-file_type   = 'PDF'.
    rs_result-file_format = gc_format_pdf.
    rs_result-mime_type   = 'application/pdf'.
    rs_result-message     = 'PDF generated successfully.'.
  ENDMETHOD.


  METHOD build_csv_document.
    DATA lv_csv_string TYPE string.

    " Header - áp escape_csv_value đúng chuẩn CSV (dấu ngoặc kép/xuống dòng).
    DATA(lv_header_line) = REDUCE string(
      INIT s = ``
      FOR ls_c IN it_cols
      NEXT s = COND #( WHEN s IS INITIAL THEN escape_csv_value( CONV string( ls_c-column_title ) )
                        ELSE s && ',' && escape_csv_value( CONV string( ls_c-column_title ) ) ) ).
    lv_csv_string = lv_header_line && cl_abap_char_utilities=>cr_lf.

    LOOP AT it_lines INTO DATA(lv_line) FROM 2. " dòng 1 là header text-only, đã build riêng ở trên
      SPLIT lv_line AT '|' INTO TABLE DATA(lt_vals).
      DATA(lv_csv_line) = REDUCE string(
        INIT s = ``
        FOR lv_v IN lt_vals
        NEXT s = COND #( WHEN s IS INITIAL THEN escape_csv_value( lv_v )
                          ELSE s && ',' && escape_csv_value( lv_v ) ) ).
      lv_csv_string = lv_csv_string && lv_csv_line && cl_abap_char_utilities=>cr_lf.
    ENDLOOP.

    rv_content = cl_abap_codepage=>convert_to( source = lv_csv_string codepage = 'UTF-8' ).
  ENDMETHOD.


  METHOD build_pdf_document.
    DATA(lt_pages) = render_section_pages(
      iv_title       = iv_title
      it_header_cols = it_header_cols
      it_lines       = it_lines ).
    rv_content = assemble_pdf_binary( it_pages = lt_pages ).
  ENDMETHOD.


  METHOD render_section_pages.
    " it_lines[1] = header text-only, từ dòng 2 trở đi mới là data row thật.
    CONSTANTS: lc_lines_per_page TYPE i VALUE 20,
               lc_page_width     TYPE i VALUE 792,
               lc_page_height    TYPE i VALUE 612.

    DATA(lv_left_margin)  = 20.
    DATA(lv_table_width)  = 752.
    DATA(lv_num_cols)     = lines( it_header_cols ).
    IF lv_num_cols = 0.
      lv_num_cols = 1.
    ENDIF.
    DATA(lv_col_width) = lv_table_width / lv_num_cols.

    IF it_lines IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_header_line) = it_lines[ 1 ].
    DATA lt_data_lines TYPE string_table.
    LOOP AT it_lines INTO DATA(lv_l) FROM 2.
      APPEND lv_l TO lt_data_lines.
    ENDLOOP.

    DATA(lv_total_data_lines) = lines( lt_data_lines ).
    DATA(lv_total_pages) = COND i(
      WHEN lv_total_data_lines = 0 THEN 1
      ELSE ( ( lv_total_data_lines - 1 ) DIV lc_lines_per_page ) + 1 ).

    DATA(lv_idx) = 0.
    DATA(lv_page_num) = 1.
    DATA(lv_generated_at) = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|.

    DO lv_total_pages TIMES.
      DATA(lv_from) = lv_idx + 1.
      DATA(lv_to)   = nmin( val1 = lv_total_data_lines val2 = lv_idx + lc_lines_per_page ).

      DATA(lv_page_content) = |BT\n/F1 12 Tf\n1 0 0 1 { lv_left_margin } { lc_page_height - 25 } Tm\n|
        && |({ escape_pdf_text( iv_title ) }) Tj\nET\n|.

      DATA(lv_y) = lc_page_height - 50.
      DATA(lv_row_height) = 18.

      lv_page_content = lv_page_content && |0.90 0.92 0.95 rg\n|
        && |{ lv_left_margin } { lv_y - 4 } { lv_table_width } { lv_row_height } re f\n0 g\n|.

      SPLIT lv_header_line AT '|' INTO TABLE DATA(lt_header_cells).
      DATA(lv_x) = lv_left_margin.
      LOOP AT lt_header_cells INTO DATA(lv_hcell).
        lv_page_content = lv_page_content
          && |BT\n/F1 8 Tf\n1 0 0 1 { lv_x + 4 } { lv_y + 2 } Tm\n({ escape_pdf_text( condense( lv_hcell ) ) }) Tj\nET\n|.
        lv_x = lv_x + lv_col_width.
      ENDLOOP.
      lv_y = lv_y - lv_row_height.

      IF lv_from <= lv_to.
        DATA(lv_line_counter) = lv_from.
        WHILE lv_line_counter <= lv_to.
          DATA(lv_curr_str) = lt_data_lines[ lv_line_counter ].
          SPLIT lv_curr_str AT '|' INTO TABLE DATA(lt_cells).

          lv_page_content = lv_page_content && |0.80 0.80 0.80 RG\n0.5 w\n|
            && |{ lv_left_margin } { lv_y - 4 } m { lv_left_margin + lv_table_width } { lv_y - 4 } l S\n|.

          lv_x = lv_left_margin.
          LOOP AT lt_cells INTO DATA(lv_cell).
            DATA(lv_cell_txt) = condense( lv_cell ).
            DATA(lv_max_char) = CONV i( lv_col_width / 5 ) - 1.
            IF lv_max_char > 0 AND strlen( lv_cell_txt ) > lv_max_char.
              lv_cell_txt = lv_cell_txt(lv_max_char) && '..'.
            ENDIF.

            lv_page_content = lv_page_content
              && |BT\n/F1 7 Tf\n1 0 0 1 { lv_x + 4 } { lv_y + 3 } Tm\n({ escape_pdf_text( lv_cell_txt ) }) Tj\nET\n|.
            lv_x = lv_x + lv_col_width.
          ENDLOOP.

          lv_y = lv_y - lv_row_height.
          lv_line_counter = lv_line_counter + 1.
        ENDWHILE.
      ENDIF.

      lv_page_content = lv_page_content
        && |BT\n/F1 7 Tf\n1 0 0 1 { lv_left_margin } 15 Tm\n({ escape_pdf_text( |Generated: { lv_generated_at }| ) }) Tj\nET\n|
        && |BT\n/F1 7 Tf\n1 0 0 1 { lc_page_width - 80 } 15 Tm\n({ escape_pdf_text( |{ iv_title } - Page { lv_page_num } / { lv_total_pages }| ) }) Tj\nET\n|.

      APPEND lv_page_content TO rt_pages.
      lv_idx = lv_idx + lc_lines_per_page.
      lv_page_num = lv_page_num + 1.
    ENDDO.
  ENDMETHOD.


  METHOD assemble_pdf_binary.
    CONSTANTS: lc_page_width  TYPE i VALUE 792,
               lc_page_height TYPE i VALUE 612.

    DATA lv_pdf TYPE string.
    DATA lt_offsets TYPE STANDARD TABLE OF i.

    lv_pdf = |%PDF-1.4\n|.
    DATA(lv_pdf_xstring) = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
    APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
    lv_pdf = lv_pdf && |1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n|.

    DATA lv_kids TYPE string.
    DATA(lv_num_pages) = lines( it_pages ).
    DO lv_num_pages TIMES.
      DATA(lv_page_obj_num) = 4 + ( sy-index - 1 ) * 2.
      lv_kids = lv_kids && |{ lv_page_obj_num } 0 R |.
    ENDDO.

    lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
    APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
    lv_pdf = lv_pdf && |2 0 obj\n<< /Type /Pages /Kids [ { lv_kids }] /Count { lv_num_pages } >>\nendobj\n|.

    lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
    APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
    lv_pdf = lv_pdf && |3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n|.

    LOOP AT it_pages INTO DATA(lv_page_text).
      DATA(lv_this_page_obj) = 4 + ( sy-tabix - 1 ) * 2.
      DATA(lv_this_cont_obj) = lv_this_page_obj + 1.

      lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
      APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
      lv_pdf = lv_pdf && |{ lv_this_page_obj } 0 obj\n|
        && |<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 3 0 R >> >> |
        && |/MediaBox [0 0 { lc_page_width } { lc_page_height }] /Contents { lv_this_cont_obj } 0 R >>\nendobj\n|.

      DATA(lv_page_xstr) = cl_abap_codepage=>convert_to( source = lv_page_text codepage = 'UTF-8' ).
      DATA(lv_stream_len) = xstrlen( lv_page_xstr ).

      lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
      APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
      lv_pdf = lv_pdf && |{ lv_this_cont_obj } 0 obj\n<< /Length { lv_stream_len } >>\nstream\n|
        && lv_page_text && |endstream\nendobj\n|.
    ENDLOOP.

    lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
    DATA(lv_xref_offset) = xstrlen( lv_pdf_xstring ).
    DATA(lv_total_objects) = lines( lt_offsets ) + 1.

    lv_pdf = lv_pdf && |xref\n0 { lv_total_objects }\n0000000000 65535 f \n|.
    LOOP AT lt_offsets INTO DATA(lv_offset).
      DATA(lv_offset_str) = |{ lv_offset }|.
      WHILE strlen( lv_offset_str ) < 10.
        lv_offset_str = |0{ lv_offset_str }|.
      ENDWHILE.
      lv_pdf = lv_pdf && |{ lv_offset_str } 00000 n \n|.
    ENDLOOP.

    lv_pdf = lv_pdf && |trailer\n<< /Size { lv_total_objects } /Root 1 0 R >>\nstartxref\n{ lv_xref_offset }\n%%EOF|.

    rv_content = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
  ENDMETHOD.

ENDCLASS.



