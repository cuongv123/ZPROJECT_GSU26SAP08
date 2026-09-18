CLASS zcl_mig_export_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_export_provider.
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


    TYPES: BEGIN OF ty_col,
             seq_no          TYPE ztb_exp_col-seq_no,
             fieldname       TYPE ztb_exp_col-fieldname,
             column_title    TYPE ztb_exp_col-column_title,
             odata_property  TYPE ztb_exp_col-odata_property,
             is_multi_value  TYPE ztb_exp_col-is_multi_value,
             value_separator TYPE ztb_exp_col-value_separator,
           END OF ty_col,
           tt_col TYPE STANDARD TABLE OF ty_col WITH EMPTY KEY.
    TYPES tt_row_cells TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
    " Build 1 dong text "|" - dung chung cho CSV/PDF renderer.
    METHODS escape_pdf_text
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
    METHODS build_row_line
      IMPORTING
        it_cols         TYPE tt_col
        is_row          TYPE any
      RETURNING
        VALUE(rt_cells) TYPE string_table.
    TYPES: BEGIN OF ty_export_plan,
             sections TYPE tt_section_registry,
             fields   TYPE tt_section_fields,
           END OF ty_export_plan.

    METHODS resolve_export_plan
      IMPORTING
        iv_export_section  TYPE zif_mig_export_provider=>ty_export_section
        iv_selected_fields TYPE string
      RETURNING
        VALUE(rs_plan)     TYPE ty_export_plan
      RAISING
        zcx_mig_export_error.
    METHODS split_row_for_excel
      IMPORTING
        it_columns       TYPE tt_col
        is_row           TYPE any
        iv_split_enabled TYPE abap_bool
      RETURNING
        VALUE(rt_rows)   TYPE tt_row_cells.
    TYPES: BEGIN OF ty_pdf_layout,
             header_text TYPE string,
             footer_text TYPE string,
             paper_size  TYPE char10,   " 'A4' hoặc 'LETTER' (rỗng = mặc định LETTER)
             orientation TYPE char1,    " 'P' portrait / 'L' landscape (rỗng = mặc định L)
             font_size   TYPE i,        " cỡ chữ thân bảng, mặc định 7 khi = 0/rỗng
             fit_to_page TYPE abap_bool,
           END OF ty_pdf_layout.
    " --- Type mới cho kích thước trang, thêm ngay gần ty_pdf_layout ---
    TYPES: BEGIN OF ty_page_dim,
             width  TYPE i,
             height TYPE i,
           END OF ty_page_dim.

    " --- Ket qua fit-to-page: font tim duoc + co "tat ca cot deu fit vua" hay
    " khong (all_fit). LUU Y: export_pdf KHONG dung all_fit de quyet dinh co
    " chia khoi cot hay khong nua (xem comment trong export_pdf) - FitToPage=true
    " luon ep 1 khoi duy nhat theo dung spec da handoff cho FE, bat ke all_fit.
    " Truong all_fit chi de tham khao/debug (vd log canh bao khi khong the lam
    " vua het, ma khong doi hanh vi chia khoi).
    TYPES: BEGIN OF ty_fit_result,
             font_size TYPE i,
             all_fit   TYPE abap_bool,
           END OF ty_fit_result.

    METHODS fit_to_page_font_size
      IMPORTING
        it_header_cols    TYPE tt_col
        it_lines          TYPE tt_row_cells
        iv_table_width    TYPE i
        iv_requested_font TYPE i
      RETURNING
        VALUE(rs_fit)     TYPE ty_fit_result.

    METHODS render_section_pages
      IMPORTING
        iv_title        TYPE string
        it_header_cols  TYPE tt_col
        it_lines        TYPE tt_row_cells
        is_pdf_layout   TYPE ty_pdf_layout OPTIONAL
      RETURNING
        VALUE(rt_pages) TYPE string_table.
    METHODS get_page_dimensions
      IMPORTING
        iv_paper_size  TYPE char10 OPTIONAL
        iv_orientation TYPE char1  OPTIONAL
      RETURNING
        VALUE(rs_dim)  TYPE ty_page_dim.
  PRIVATE SECTION.
    CONSTANTS:
      gc_format_excel TYPE zmig_e_file_format VALUE 'X',
      gc_format_csv   TYPE zmig_e_file_format VALUE 'C',
      gc_format_pdf   TYPE zmig_e_file_format VALUE 'P',
      gc_excel_name   TYPE string VALUE 'migration_report',
      gc_csv_name     TYPE string VALUE 'migration_report',
      gc_pdf_name     TYPE string VALUE 'migration_report'.
    METHODS wrap_text_lines
      IMPORTING
        iv_text         TYPE string
        iv_max_char     TYPE i
      RETURNING
        VALUE(rt_lines) TYPE string_table.



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
        iv_analysis_id     TYPE sysuuid_x16
        iv_report_type     TYPE zmig_mail_job-report_type
        iv_export_section  TYPE zif_mig_export_provider=>ty_export_section
        iv_extension       TYPE string
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
        iv_section_code    TYPE zif_mig_export_provider=>ty_export_section
        it_selected_fields TYPE string_table OPTIONAL
        io_struct          TYPE REF TO cl_abap_structdescr OPTIONAL
      RETURNING
        VALUE(rt_cols)     TYPE tt_col.

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
        iv_view_name   TYPE tabname
        iv_analysis_id TYPE sysuuid_x16
      RETURNING
        VALUE(rr_data) TYPE REF TO data
      RAISING
        cx_root.



    METHODS escape_csv_value
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.








    " Đóng gói danh sách trang (đã render) thành 1 file PDF nhị phân
    " hoàn chỉnh (xref/trailer) - dùng chung cho cả trường hợp 1 section
    " và nhiều section gộp lại.
    METHODS assemble_pdf_binary
      IMPORTING
        it_pages          TYPE string_table
        is_pdf_layout     TYPE ty_pdf_layout OPTIONAL
      RETURNING
        VALUE(rv_content) TYPE xstring.


    METHODS export_excel
      IMPORTING
        iv_job_id            TYPE sysuuid_x16
        iv_analysis_id       TYPE sysuuid_x16
        iv_report_type       TYPE zmig_mail_job-report_type
        iv_export_section    TYPE zif_mig_export_provider=>ty_export_section
        iv_selected_fields   TYPE string
        iv_split_multi_value TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rs_result)     TYPE zif_mig_export_provider=>ty_export_result
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
        is_pdf_layout      TYPE ty_pdf_layout OPTIONAL
      RETURNING
        VALUE(rs_result)   TYPE zif_mig_export_provider=>ty_export_result.

ENDCLASS.

CLASS zcl_mig_export_engine IMPLEMENTATION.
  METHOD fit_to_page_font_size.
    CONSTANTS: lc_min_col_chars TYPE i VALUE 6,
               lc_max_col_chars TYPE i VALUE 30,
               lc_font_floor    TYPE i VALUE 5.

    DATA(lv_num_cols) = lines( it_header_cols ).
    IF lv_num_cols = 0 OR it_lines IS INITIAL.
      rs_fit-font_size = iv_requested_font.
      rs_fit-all_fit   = abap_true.
      RETURN.
    ENDIF.
    DATA(lt_header_cells) = it_lines[ 1 ].

    DATA lt_col_weight       TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lt_longest_dataword TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lt_longest_hdrword  TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DO lv_num_cols TIMES.
      DATA(lv_ix) = sy-index.
      DATA(lv_hdr_text) = COND string( WHEN lv_ix <= lines( lt_header_cells )
                                        THEN condense( lt_header_cells[ lv_ix ] ) ELSE `` ).
      " tu dai nhat trong TIEU DE (tach theo khoang trang, giong wrap_text_lines)
      " - dung lam GIOI HAN AN TOAN TOI THIEU (khong bao gio bop cot hep hon
      " muc nay), khong dung truc tiep de tinh weight nua (xem ben duoi).
      DATA(lv_longest_hdr) = 0.
      SPLIT lv_hdr_text AT space INTO TABLE DATA(lt_hdr_words).
      LOOP AT lt_hdr_words INTO DATA(lv_hword).
        IF strlen( lv_hword ) > lv_longest_hdr.
          lv_longest_hdr = strlen( lv_hword ).
        ENDIF.
      ENDLOOP.
      " do dai CA CAU header (khong tach tu) - dung lam MUC TIEU MONG MUON cho
      " weight, de header co co hoi hien tron ven 1 dong (giong san pham tham
      " khao) thay vi luon bi xuong dong ngay ca khi con du cho.
      DATA(lv_hdr_full_len) = strlen( lv_hdr_text ).

      " tu dai nhat trong DU LIEU
      DATA(lv_longest_data) = 0.
      LOOP AT it_lines INTO DATA(lt_row) FROM 2.
        IF lv_ix <= lines( lt_row ).
          SPLIT condense( lt_row[ lv_ix ] ) AT space INTO TABLE DATA(lt_words).
          LOOP AT lt_words INTO DATA(lv_word).
            IF strlen( lv_word ) > lv_longest_data.
              lv_longest_data = strlen( lv_word ).
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDLOOP.

      " be rong cot (weight): UU TIEN theo DO DAI CA CAU HEADER (de header co
      " nhieu co hoi hien tron 1 dong hon, giong san pham tham khao), so voi
      " tu dai nhat trong du lieu - lay gia tri lon hon. Day CHI la "muc tieu
      " mong muon" dung de chia ty le; con cai bao dam khong vo chu giua tu
      " (ca header lan data) van la vong kiem tra lv_maxchar_data/lv_maxchar_hdr
      " voi lt_longest_dataword/lt_longest_hdrword o duoi - nen du khi khong
      " du weight cho tat ca cot (qua nhieu cot), header co the phai xuong
      " dong lai, nhung TU thi khong bao gio bi cat/vo giua chung.
      DATA(lv_w) = COND i( WHEN lv_hdr_full_len > lv_longest_data THEN lv_hdr_full_len ELSE lv_longest_data ).
      lv_w = nmax( val1 = lc_min_col_chars val2 = nmin( val1 = lv_w val2 = lc_max_col_chars ) ).
      APPEND lv_w TO lt_col_weight.
      APPEND lv_longest_data TO lt_longest_dataword.
      APPEND lv_longest_hdr  TO lt_longest_hdrword.
    ENDDO.

    DATA(lv_total_weight) = REDUCE i( INIT s = 0 FOR w IN lt_col_weight NEXT s = s + w ).
    IF lv_total_weight = 0.
      rs_fit-font_size = iv_requested_font.
      rs_fit-all_fit   = abap_true.
      RETURN.
    ENDIF.

    DATA(lv_candidate) = iv_requested_font.
    WHILE lv_candidate >= lc_font_floor.
      DATA(lv_ok) = abap_true.
      LOOP AT lt_col_weight INTO DATA(lv_wv) FROM 1.
        DATA(lv_cidx) = sy-tabix.
        DATA(lv_cw) = CONV i( iv_table_width * lv_wv / lv_total_weight ).

        " o du lieu: chu ve bang lv_candidate
        DATA(lv_maxchar_data) = CONV i( lv_cw * 10 / ( lv_candidate * 7 ) ) - 1.
        " o tieu de: chu ve lon hon 1pt (dung font_size + 1 nhu trong render_section_pages)
        DATA(lv_maxchar_hdr)  = CONV i( lv_cw * 10 / ( ( lv_candidate + 1 ) * 7 ) ) - 1.

        IF lv_maxchar_data < lt_longest_dataword[ lv_cidx ]
        OR lv_maxchar_hdr  < lt_longest_hdrword[ lv_cidx ].
          lv_ok = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_ok = abap_true.
        rs_fit-font_size = lv_candidate.
        rs_fit-all_fit   = abap_true.
        RETURN.
      ENDIF.
      lv_candidate = lv_candidate - 1.
    ENDWHILE.

    " Khong tim duoc font nao (ke ca san lc_font_floor) lam tat ca cot fit vua
    " tu dai nhat cua no - bao hieu cho export_pdf biet de chuyen sang chia khoi
    " (column block) thay vi ep het len 1 khoi/1 trang gay vo tu giua chung.
    rs_fit-font_size = lc_font_floor.
    rs_fit-all_fit   = abap_false.
  ENDMETHOD.
  METHOD split_row_for_excel.
    " Voi tung cot: neu duoc bat tach (iv_split_enabled = X) VA duoc
    " danh dau IS_MULTI_VALUE = X trong ZTB_EXP_COL, tach gia tri gom
    " thanh danh sach cac phan tu; cot khac (hoac khi tat tinh nang)
    " giu nguyen 1 gia tri - dam bao mac dinh (iv_split_enabled = ' ')
    " hanh vi y het hien tai, khong breaking change.
    "
    " LUU Y QUAN TRONG: VALUE_SEPARATOR la CHAR(3), ABAP tu dong dem
    " them khoang trang cho du 3 ky tu khi luu (vd ', ' se thanh
    " ',  ' - 2 dau cach o cuoi thay vi 1). Neu dung NGUYEN gia tri
    " nay de SPLIT thi se KHONG khop voi chuoi goc (chuoi goc chi co
    " dung 1 dau cach sau dau phay) -> tach that bai am tham. Vi vay
    " chi lay DUNG 1 KY TU "cot loi" cua separator (bo het khoang
    " trang bang CONDENSE NO-GAPS), roi condense() lai tung phan tu
    " sau khi tach - vua tranh duoc van de dem cua CHAR co do dai co
    " dinh, vua khong phu thuoc du lieu goc co 1 hay nhieu dau cach.
    DATA lt_col_parts TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
    DATA(lv_max_parts) = 1.

    LOOP AT it_columns INTO DATA(ls_col).
      ASSIGN COMPONENT ls_col-fieldname OF STRUCTURE is_row TO FIELD-SYMBOL(<lv_val>).
      DATA(lv_raw) = COND string( WHEN sy-subrc = 0 THEN CONV string( <lv_val> ) ELSE '' ).

      DATA lt_parts TYPE string_table.
      CLEAR lt_parts.

      IF iv_split_enabled = abap_true
         AND ls_col-is_multi_value = abap_true
         AND lv_raw IS NOT INITIAL.
        DATA(lv_sep_char) = CONV string( ls_col-value_separator ).
        CONDENSE lv_sep_char NO-GAPS.
        IF lv_sep_char IS INITIAL.
          " Separator toan khoang trang (vd SELECTED_FIELDS = ' ') ->
          " CONDENSE NO-GAPS xoa het, fallback ve dung 1 dau cach.
          lv_sep_char = ` `.
        ENDIF.

        SPLIT lv_raw AT lv_sep_char INTO TABLE lt_parts.
        LOOP AT lt_parts ASSIGNING FIELD-SYMBOL(<lv_part>).
          <lv_part> = condense( <lv_part> ).
        ENDLOOP.
        DELETE lt_parts WHERE table_line IS INITIAL.
        IF lt_parts IS INITIAL.
          " Truong hop hiem: sau khi loc rong het (vd gia tri goc chi
          " toan dau phan tach) -> giu lai nguyen gia tri goc, tranh
          " mat du lieu.
          APPEND lv_raw TO lt_parts.
        ENDIF.
      ELSE.
        APPEND lv_raw TO lt_parts.
      ENDIF.

      APPEND lt_parts TO lt_col_parts.
      IF lines( lt_parts ) > lv_max_parts.
        lv_max_parts = lines( lt_parts ).
      ENDIF.
    ENDLOOP.

    " Sinh lv_max_parts dong xuat, moi dong lay dung 1 phan tu tuong
    " ung tung cot (rong neu cot do it phan tu hon dong dang xet).
    DO lv_max_parts TIMES.
      DATA(lv_part_idx) = sy-index.
      DATA lt_out_row TYPE string_table.
      CLEAR lt_out_row.
      LOOP AT lt_col_parts INTO DATA(lt_this_col_parts).
        DATA(lv_out) = COND string(
          WHEN lines( lt_this_col_parts ) <= 1
            THEN lt_this_col_parts[ 1 ]
          WHEN lv_part_idx <= lines( lt_this_col_parts )
            THEN lt_this_col_parts[ lv_part_idx ]
          ELSE '' ).
        APPEND lv_out TO lt_out_row.
      ENDLOOP.
      APPEND lt_out_row TO rt_rows.
    ENDDO.
  ENDMETHOD.

  METHOD wrap_text_lines.
    DATA(lv_text) = condense( iv_text ).
    IF iv_max_char <= 0 OR lv_text IS INITIAL.
      APPEND lv_text TO rt_lines.
      RETURN.
    ENDIF.

    SPLIT lv_text AT space INTO TABLE DATA(lt_words).
    DATA lv_current TYPE string.

    LOOP AT lt_words INTO DATA(lv_word).
      WHILE strlen( lv_word ) > iv_max_char.        " tu qua dai hon 1 dong, cat cung
        IF lv_current IS NOT INITIAL.
          APPEND lv_current TO rt_lines.
          CLEAR lv_current.
        ENDIF.
        APPEND lv_word(iv_max_char) TO rt_lines.
        lv_word = lv_word+iv_max_char.
      ENDWHILE.

      DATA(lv_candidate) = COND string( WHEN lv_current IS INITIAL THEN lv_word ELSE |{ lv_current } { lv_word }| ).
      IF strlen( lv_candidate ) > iv_max_char.
        APPEND lv_current TO rt_lines.
        lv_current = lv_word.
      ELSE.
        lv_current = lv_candidate.
      ENDIF.
    ENDLOOP.

    IF lv_current IS NOT INITIAL.
      APPEND lv_current TO rt_lines.
    ENDIF.
    IF rt_lines IS INITIAL.
      APPEND `` TO rt_lines.
    ENDIF.
  ENDMETHOD.



    METHOD zif_mig_export_provider~generate.

    CLEAR rs_result.

    TRY.

        DATA(lv_format) =
          to_upper(
            condense( CONV string( iv_file_format ) )
          ).

        DATA(lv_section) =
          CONV zif_mig_export_provider=>ty_export_section(
            to_upper(
              condense( CONV string( iv_export_section ) )
            )
          ).

        CASE lv_format.

          WHEN gc_format_excel OR 'EXCEL' OR 'E' OR 'XLSX'.

            rs_result = export_excel(
              iv_job_id            = iv_job_id
              iv_analysis_id       = iv_analysis_id
              iv_report_type       = iv_report_type
              iv_export_section    = lv_section
              iv_selected_fields   = iv_selected_fields
              iv_split_multi_value = iv_split_multi_value ).

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
              iv_selected_fields = iv_selected_fields
              is_pdf_layout      = VALUE ty_pdf_layout(
                header_text = iv_pdf_header
                footer_text = iv_pdf_footer
                paper_size  = iv_paper_size
                orientation = iv_orientation
                font_size   = iv_font_size
                fit_to_page = iv_fit_to_page ) ).

          WHEN 'M'.

            " Technical documents require an explicit snapshot
            IF iv_analysis_id IS INITIAL.
              rs_result-message =
                'An Analysis ID is required for a technical document.'.
              RETURN.
            ENDIF.

            " Technical documents contain the complete document
            IF lv_section IS NOT INITIAL
               AND lv_section <> 'ALL'.

              rs_result-message =
                'Technical documents support export section ALL only.'.
              RETURN.

            ENDIF.

            IF iv_selected_fields IS NOT INITIAL.
              rs_result-message =
                'Field selection is not supported for technical documents.'.
              RETURN.
            ENDIF.

            " Reuse the existing technical document service
            DATA lo_document_service
              TYPE REF TO zif_mig_tech_doc_service.

            lo_document_service =
              NEW zcl_mig_tech_doc_service( ).

            DATA(ls_document) =
              lo_document_service->generate(
                iv_analysis_id = iv_analysis_id ).

            " Verify that the generated document matches the request
            IF ls_document-analysis_id <> iv_analysis_id.
              rs_result-message =
                'The generated document does not match the requested analysis.'.
              RETURN.
            ENDIF.

            IF ls_document-markdown IS INITIAL
               OR ls_document-file_name IS INITIAL.

              rs_result-message =
                'The technical document content or file name is empty.'.
              RETURN.

            ENDIF.

            " Encode the attachment as UTF-8
            rs_result-content =
              cl_abap_codepage=>convert_to(
                source   = ls_document-markdown
                codepage = 'UTF-8' ).

            rs_result-file_name =
              ls_document-file_name.

            " BCS binary attachment; the file name retains .md
            rs_result-file_type = 'BIN'.

            rs_result-file_format = 'M'.
            rs_result-mime_type =
              'text/markdown; charset=utf-8'.

            rs_result-success = abap_true.
            rs_result-message =
              'Technical document generated successfully.'.

          WHEN OTHERS.

            rs_result-success = abap_false.
            rs_result-message =
              |Unsupported export format { iv_file_format }.|.

        ENDCASE.

        IF rs_result-success = abap_true.
          rs_result-file_format = iv_file_format.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).

        CLEAR:
          rs_result-content,
          rs_result-file_name,
          rs_result-file_type,
          rs_result-file_format,
          rs_result-mime_type.

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
  METHOD resolve_export_plan.
    DATA(lv_section) = CONV zif_mig_export_provider=>ty_export_section(
      to_upper( condense( CONV string( iv_export_section ) ) ) ).

    DATA(lt_registry) = get_section_registry( ).

    IF lv_section = 'ALL'.
      rs_plan-sections = lt_registry.
      rs_plan-fields    = parse_section_field_map( iv_selected_fields ).
      RETURN.
    ENDIF.

    READ TABLE lt_registry INTO DATA(ls_section) WITH KEY section_code = lv_section.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_mig_export_error
        EXPORTING
          mv_message = |Unknown export section { lv_section }.|.
    ENDIF.

    APPEND ls_section TO rs_plan-sections.
    APPEND VALUE #(
      section_code = lv_section
      fields       = parse_selected_fields( iv_selected_fields )
    ) TO rs_plan-fields.
  ENDMETHOD.


  METHOD get_columns_for_section.
    " 1 SELECT duy nhất trên toàn bộ cột của section.
    SELECT seq_no, fieldname, column_title, odata_property,
           is_multi_value, value_separator
      FROM ztb_exp_col
      WHERE section_code = @iv_section_code
      ORDER BY seq_no ASCENDING
      INTO TABLE @DATA(lt_all_cols).

    IF lt_all_cols IS INITIAL AND io_struct IS BOUND.
      " Fallback: chưa maintain ZTB_EXP_COL cho section này -> lấy hết
      " component của structure làm cột mặc định (không SELECT thêm).
      " is_multi_value/value_separator để trống (mặc định = khong tach).
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
    CLEAR rt_cells.
    LOOP AT it_cols INTO DATA(ls_col).
      ASSIGN COMPONENT ls_col-fieldname OF STRUCTURE is_row TO FIELD-SYMBOL(<lv_val>).
      APPEND COND string( WHEN sy-subrc = 0 THEN CONV string( <lv_val> ) ELSE '' ) TO rt_cells.
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
    lv_escaped = replace( regex = '[^ -~]' val = lv_escaped with = ' ' occ = 0 ).
    rv_text = lv_escaped.
  ENDMETHOD.


  METHOD export_excel.
    TRY.
        DATA(ls_plan) = resolve_export_plan(
          iv_export_section  = iv_export_section
          iv_selected_fields = iv_selected_fields ).
      CATCH zcx_mig_export_error INTO DATA(lx_plan).
        rs_result-success = abap_false.
        rs_result-message = lx_plan->get_text( ).
        RETURN.
    ENDTRY.

    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root.
        lv_analysis_id = VALUE #( ).
    ENDTRY.

    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lv_sheet_count) = 0.

    " Cot rong toi da (don vi ky tu chuan Excel) - noi dung dai hon muc nay
    " (vd truong text tu do nhu Description/Where Fields) se KHONG lam cot
    " gian ra vo han nua, ma bi gioi han o day va tu xuong dong trong CHINH
    " o do (nho style wrap text ben duoi + Excel tu tang chieu cao hang).
    CONSTANTS lc_col_width_cap TYPE i VALUE 80.

    " Dem THEO TI LE PHAN TRAM (khong con la so co dinh +2 nua) - don vi
    " "do rong cot" cua Excel duoc chuan hoa theo be ngang ky tu "0", trong
    " khi du lieu o day toan CHU HOA + gach duoi (vd ZTEST_ABAP_PARSER_F01,
    " INSTANCE_METHOD) co be ngang thuc te LON HON ky tu "0" kha nhieu. Muc
    " chenh lech nay TI LE THEO DO DAI chuoi (chuoi cang dai, phan thieu
    " tuyet doi cang lon) - nen 1 so co dinh (vd +2) chi du cho chuoi ngan,
    " chuoi dai hon (nhung van ngan hon xa muc lc_col_width_cap) van bi
    " xuong dong oan uong du that ra du cho hien 1 dong. Doi sang +X% do
    " dai + vai ky tu co dinh de muc dem tu tang theo do dai chuoi.
    CONSTANTS lc_width_buffer_pct TYPE i VALUE 25.

    TRY.
        DATA(lo_style_bold) = lo_excel->add_new_style( ).
        lo_style_bold->font->bold = abap_true.

        DATA(lo_style_total) = lo_excel->add_new_style( ).
        lo_style_total->font->bold = abap_true.
        lo_style_total->fill->fgcolor-rgb = 'FFF2F2F2'.
        lo_style_total->fill->filltype = zcl_excel_style_fill=>c_fill_solid.

        " Style cho O DU LIEU: bat wrap text + can tren, de gia tri qua dai
        " (bi gioi han boi lc_col_width_cap khi set be rong cot) tu dong
        " xuong dong TRONG cung 1 o, thay vi bi Excel hien 1 dong roi cat/de
        " tran sang o ben canh (nhin nhu "chua du de thay het du lieu").
        DATA(lo_style_wrap) = lo_excel->add_new_style( ).
        lo_style_wrap->alignment->wraptext   = abap_true.
        lo_style_wrap->alignment->vertical   = zcl_excel_style_alignment=>c_vertical_top.
      CATCH cx_root INTO DATA(lx_style_error).
        rs_result-success = abap_false.
        rs_result-message = |Excel style init error: { lx_style_error->get_text( ) }.|.
        RETURN.
    ENDTRY.

    TRY.
        LOOP AT ls_plan-sections INTO DATA(ls_section).
          TRY.
              DATA(lo_struct) = CAST cl_abap_structdescr(
                cl_abap_typedescr=>describe_by_name( ls_section-view_name ) ).
            CATCH cx_root.
              CONTINUE.
          ENDTRY.

          " Field áp dụng cho section đang xử lý: nếu ALL, tra trong map
          " (section nào không có trong map -> dùng cột mặc định); nếu
          " không phải ALL, dùng danh sách phẳng của chính section đó.
          READ TABLE ls_plan-fields INTO DATA(ls_map) WITH KEY section_code = ls_section-section_code.
          DATA(lt_fields_for_section) = COND string_table( WHEN sy-subrc = 0 THEN ls_map-fields ).

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

          " --- Độ rộng cột: khởi tạo tối thiểu theo độ dài tiêu đề
          " (+2 ký tự đệm cho chữ đậm), sẽ cập nhật thêm theo dữ liệu
          " thực tế bên dưới. Reset về rỗng mỗi section (tránh lệch dữ
          " liệu cũ từ section trước). ---
          DATA lt_max_len TYPE STANDARD TABLE OF i WITH EMPTY KEY.
          CLEAR lt_max_len.
          LOOP AT lt_columns INTO ls_col.
            DATA(lv_hdr_len_calc) = strlen( CONV string( ls_col-column_title ) ).
            APPEND lv_hdr_len_calc + 3 + ( lv_hdr_len_calc * lc_width_buffer_pct ) DIV 100 TO lt_max_len.
          ENDLOOP.

          " --- Data rows (co the "no dong" cho tung record neu bat
          " Split multi-value cho cot nao do trong record) ---
          DATA(lv_row) = 2.
          DATA(lv_written_rows) = 0.
          LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
            DATA(lt_exploded) = split_row_for_excel(
              it_columns       = lt_columns
              is_row           = <ls_row>
              iv_split_enabled = iv_split_multi_value ).

            LOOP AT lt_exploded INTO DATA(lt_out_row).
              lv_col = 1.
              LOOP AT lt_out_row INTO DATA(lv_cell_val).
                lo_sheet->set_cell( ip_column = lv_col ip_row = lv_row ip_value = lv_cell_val ).
                lo_sheet->set_cell_style( ip_column = lv_col ip_row = lv_row
                  ip_style = lo_style_wrap->get_guid( ) ).
                " +2 ky tu dem, GIONG HET buffer da dung cho tieu de o tren -
                " truoc day cho nay lay dung strlen() khong dem gi ca, nen he
                " nao gia tri DU LIEU (khong phai tieu de) la gia tri dai nhat
                " trong cot thi cot do luon bi hut mat ~2 ky tu, nhin nhu chua
                " tu dan du de thay het noi dung (phai tu keo tay moi thay).
                DATA(lv_cell_len_raw) = strlen( lv_cell_val ).
                DATA(lv_cell_len) = lv_cell_len_raw + 3
                  + ( lv_cell_len_raw * lc_width_buffer_pct ) DIV 100.
                IF lv_cell_len > lt_max_len[ lv_col ].
                  lt_max_len[ lv_col ] = lv_cell_len.
                ENDIF.
                lv_col = lv_col + 1.
              ENDLOOP.
              lv_row = lv_row + 1.
              lv_written_rows = lv_written_rows + 1.
            ENDLOOP.
          ENDLOOP.

          " --- Total: dem dung so dong DA GHI THUC TE len sheet (sau
          " khi tach, neu co bat split) - KHONG dung lines( <lt_data> )
          " nua, vi so dong tren sheet co the nhieu hon so record goc
          " khi 1 record no ra nhieu dong. ---
          DATA(lv_total_row) = lv_row + 1.
          DATA(lv_total_text) = |TOTAL: { lv_written_rows } rows|.
          lo_sheet->set_cell( ip_column = 1 ip_row = lv_total_row
            ip_value = lv_total_text ).
          lo_sheet->set_cell_style( ip_column = 1 ip_row = lv_total_row
            ip_style = lo_style_total->get_guid( ) ).
          " Dong TOTAL cung chu dam (giong header) va nam o cot 1 - can tinh
          " luon vao be rong cot 1, khong thi neu du lieu cot 1 ngan hon dong
          " nay se bi cat mat.
          DATA(lv_total_len_raw) = strlen( lv_total_text ).
          DATA(lv_total_len_calc) = lv_total_len_raw + 3
            + ( lv_total_len_raw * lc_width_buffer_pct ) DIV 100.
          IF lv_total_len_calc > lt_max_len[ 1 ].
            lt_max_len[ 1 ] = lv_total_len_calc.
          ENDIF.

          " --- Ép độ rộng cột theo nội dung thực tế đã tính ở trên, nhưng
          " không vượt qua lc_col_width_cap - cột nào nội dung dài hơn muc
          " nay se duoc gioi han rong toi da, phan con lai tu xuong dong
          " trong o (nho style wrap text da gan cho tung o du lieu o tren). ---
          DO lines( lt_columns ) TIMES.
            DATA(lv_wcol) = sy-index.
            DATA(lv_final_width) = nmin( val1 = lt_max_len[ lv_wcol ] val2 = lc_col_width_cap ).
            lo_sheet->set_column_width(
              ip_column         = lv_wcol
              ip_width_fix      = lv_final_width
              ip_width_autosize = abap_false ).
          ENDDO.

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

    TRY.
        DATA(ls_plan) = resolve_export_plan(
          iv_export_section  = iv_export_section
          iv_selected_fields = iv_selected_fields ).
      CATCH zcx_mig_export_error INTO DATA(lx_plan).
        rs_result-success = abap_false.
        rs_result-message = lx_plan->get_text( ).
        RETURN.
    ENDTRY.

    DATA lv_csv_all TYPE string.
    DATA lv_any_section_ok TYPE abap_bool VALUE abap_false.

    LOOP AT ls_plan-sections INTO DATA(ls_section).

      TRY.
          DATA(lo_struct) = CAST cl_abap_structdescr(
            cl_abap_typedescr=>describe_by_name( ls_section-view_name ) ).
        CATCH cx_root.
          CONTINUE.
      ENDTRY.

      READ TABLE ls_plan-fields INTO DATA(ls_map) WITH KEY section_code = ls_section-section_code.
      DATA(lt_fields_for_section) = COND string_table( WHEN sy-subrc = 0 THEN ls_map-fields ).

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
        DATA(lt_vals) = build_row_line( it_cols = lt_columns is_row = <ls_row> ).
        DATA(lv_csv_line) = REDUCE string(
          INIT s = ``
          FOR lv_v IN lt_vals
          NEXT s = COND #( WHEN s IS INITIAL THEN escape_csv_value( lv_v )
                            ELSE s && ',' && escape_csv_value( lv_v ) ) ).
        lv_csv_all = lv_csv_all && lv_csv_line && cl_abap_char_utilities=>cr_lf.
      ENDLOOP.

      IF <lt_data> IS INITIAL.
        lv_csv_all = lv_csv_all && escape_csv_value( |(No data available for this section)| ) && cl_abap_char_utilities=>cr_lf.
      ENDIF.

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
    DATA(ls_dim_check) = get_page_dimensions(
       iv_paper_size  = is_pdf_layout-paper_size
       iv_orientation = is_pdf_layout-orientation ).
    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root INTO DATA(lx_no_analysis).
        rs_result-success = abap_false.
        rs_result-message = |Analysis not found: { lx_no_analysis->get_text( ) }.|.
        RETURN.
    ENDTRY.

    TRY.
        DATA(ls_plan) = resolve_export_plan(
          iv_export_section  = iv_export_section
          iv_selected_fields = iv_selected_fields ).
      CATCH zcx_mig_export_error INTO DATA(lx_plan).
        rs_result-success = abap_false.
        rs_result-message = lx_plan->get_text( ).
        RETURN.
    ENDTRY.

    DATA lt_all_pages TYPE string_table.
    CONSTANTS lc_max_cols_per_block TYPE i VALUE 6.  " 752pt / 6 cột ≈ 125pt/cột - đủ chỗ cho hầu hết nội dung, giống layout khối nhỏ của SAP Export As  " 752pt / ~60pt mỗi cột để còn đọc được - đồng bộ với lv_table_width trong render_section_pages
    LOOP AT ls_plan-sections INTO DATA(ls_section).

      TRY.
          DATA(lo_struct) = CAST cl_abap_structdescr(
            cl_abap_typedescr=>describe_by_name( ls_section-view_name ) ).
        CATCH cx_root.
          CONTINUE.
      ENDTRY.

      READ TABLE ls_plan-fields INTO DATA(ls_map) WITH KEY section_code = ls_section-section_code.
      DATA(lt_fields_for_section) = COND string_table( WHEN sy-subrc = 0 THEN ls_map-fields ).

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
        DATA lt_empty_lines TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
        CLEAR lt_empty_lines.
        APPEND VALUE string_table( ( `Note` ) ) TO lt_empty_lines.
        APPEND VALUE string_table( ( |No data available for section { ls_section-sheet_title }.| ) ) TO lt_empty_lines.

        TRY.
            DATA(lt_empty_pages) = render_section_pages(
              iv_title       = |{ ls_section-sheet_title } - { iv_report_type }|
              it_header_cols = VALUE tt_col( ( ) )
              it_lines       = lt_empty_lines
              is_pdf_layout  = is_pdf_layout ).
            APPEND LINES OF lt_empty_pages TO lt_all_pages.
          CATCH cx_root.
        ENDTRY.
        CONTINUE.
      ENDIF.

      DATA(lt_header_cells) = VALUE string_table(
  FOR ls_c IN lt_columns ( CONV string( ls_c-column_title ) ) ).

      DATA lt_lines TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
      CLEAR lt_lines.
      APPEND lt_header_cells TO lt_lines.
      LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
        APPEND build_row_line( it_cols = lt_columns is_row = <ls_row> ) TO lt_lines.
      ENDLOOP.

      DATA(lv_total_cols) = lines( lt_columns ).
      DATA(lv_requested_font) = COND i( WHEN is_pdf_layout-font_size > 0 THEN is_pdf_layout-font_size ELSE 7 ).

      DATA(ls_layout_effective) = is_pdf_layout.
      " DUNG THEO SPEC DA CHOT/HANDOFF CHO FE (export-pdf-header-footer-fe-handoff.md
      " muc 3.3): FitToPage=true LUON ep tat ca cot vao 1 khoi duy nhat, CHAP NHAN
      " cot bi thu hep/kho doc hon neu qua nhieu cot - khong tu y chuyen sang chia
      " khoi du khong tim duoc font "vua het" (vi du: cot chua 1 chuoi rat dai
      " khong co khoang trang nhu GUID/Evidence ID se khong bao gio "vua" duoc du
      " co ha font toi san). Truoc day co thu them co "all_fit" de tu dong chia
      " khoi trong truong hop nay, nhung nhu vay lam FitToPage=true mat tac dung
      " quan sat duoc (giong het ket qua FitToPage=false) moi khi gap cot kieu
      " nay - trai voi hanh vi da test/handoff, nen bo lai dung spec goc.
      DATA(lv_use_single_block) = xsdbool( lv_total_cols <= lc_max_cols_per_block
                                         OR is_pdf_layout-fit_to_page = abap_true ).

      IF is_pdf_layout-fit_to_page = abap_true.
        DATA(ls_fit) = fit_to_page_font_size(
          it_header_cols    = lt_columns
          it_lines          = lt_lines
          iv_table_width    = ls_dim_check-width - 40
          iv_requested_font = lv_requested_font ).
        ls_layout_effective-font_size = ls_fit-font_size.
      ENDIF.

      IF lv_use_single_block = abap_true.
        " So cot binh thuong - 1 khoi duy nhat, hanh vi giu nguyen nhu cu.
        TRY.
            DATA(lt_section_pages) = render_section_pages(
              iv_title       = |{ ls_section-sheet_title } - { iv_report_type }|
              it_header_cols = lt_columns
              it_lines       = lt_lines
              is_pdf_layout  = ls_layout_effective ).
            APPEND LINES OF lt_section_pages TO lt_all_pages.
          CATCH cx_root.
            CONTINUE.
        ENDTRY.
      ELSE.
        " Qua nhieu cot cho 1 bang - chia thanh nhieu khoi, moi khoi toi da
        " lc_max_cols_per_block cot. Tu khoi thu 2 tro di, luon lap lai cot
        " dau tien (cot 1) lam "cot khoa" de doi chieu dong giua cac khoi.
        DATA(lv_extra_cols)           = lv_total_cols - lc_max_cols_per_block.
        DATA(lv_cols_per_extra_block) = lc_max_cols_per_block - 1.
        DATA(lv_extra_blocks)         = ( lv_extra_cols + lv_cols_per_extra_block - 1 ) DIV lv_cols_per_extra_block.
        DATA(lv_num_blocks)           = 1 + lv_extra_blocks.

        DO lv_num_blocks TIMES.
          DATA(lv_block_no) = sy-index.
          DATA lt_idx TYPE STANDARD TABLE OF i WITH EMPTY KEY.
          CLEAR lt_idx.
          DATA(lv_new_from) = 0.
          DATA(lv_new_to)   = 0.

          IF lv_block_no = 1.
            lv_new_from = 1.
            lv_new_to   = nmin( val1 = lv_total_cols val2 = lc_max_cols_per_block ).
            DATA(lv_i1) = lv_new_from.
            WHILE lv_i1 <= lv_new_to.
              APPEND lv_i1 TO lt_idx.
              lv_i1 = lv_i1 + 1.
            ENDWHILE.
          ELSE.
            lv_new_from = lc_max_cols_per_block + 1 + ( lv_block_no - 2 ) * lv_cols_per_extra_block.
            lv_new_to   = nmin( val1 = lv_total_cols val2 = lc_max_cols_per_block + ( lv_block_no - 1 ) * lv_cols_per_extra_block ).
            APPEND 1 TO lt_idx.
            DATA(lv_i2) = lv_new_from.
            WHILE lv_i2 <= lv_new_to.
              APPEND lv_i2 TO lt_idx.
              lv_i2 = lv_i2 + 1.
            ENDWHILE.
          ENDIF.

          DATA(lt_columns_block) = VALUE tt_col( FOR lv_ix IN lt_idx ( lt_columns[ lv_ix ] ) ).

          DATA lt_lines_block TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
          CLEAR lt_lines_block.
          LOOP AT lt_lines INTO DATA(lt_full_row).
            DATA(lt_row_block) = VALUE string_table( FOR lv_ix2 IN lt_idx ( lt_full_row[ lv_ix2 ] ) ).
            APPEND lt_row_block TO lt_lines_block.
          ENDLOOP.

          DATA(lv_block_title) = |{ ls_section-sheet_title } - { iv_report_type } (Columns { lv_new_from }-{ lv_new_to } of { lv_total_cols })|.

          " Nhanh nay chi vao duoc khi fit_to_page=false (xem dieu kien
          " lv_use_single_block o tren: fit_to_page=true luon di nhanh
          " single-block) - nen dung thang ls_layout_effective (= is_pdf_layout,
          " khong bi doi font) cho tung khoi, dung nhu hanh vi truoc day.
          TRY.
              DATA(lt_block_pages) = render_section_pages(
                iv_title       = lv_block_title
                it_header_cols = lt_columns_block
                it_lines       = lt_lines_block
                is_pdf_layout  = ls_layout_effective ).
              APPEND LINES OF lt_block_pages TO lt_all_pages.
            CATCH cx_root.
              CONTINUE.
        ENDTRY.
        ENDDO.
      ENDIF.

    ENDLOOP.

    IF lt_all_pages IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'No data available for PDF generation.'.
      RETURN.
    ENDIF.

    rs_result-content     = assemble_pdf_binary( it_pages = lt_all_pages is_pdf_layout = is_pdf_layout ).
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






  METHOD get_page_dimensions.
    " Kich thuoc goc theo huong PORTRAIT (point), tu dao truc khi Landscape.
    " Mac dinh (paper_size/orientation rong) = LETTER Landscape 792x612,
    " dung y het hang vi cu truoc khi co tham so nay - khong breaking change.
    DATA(lv_size)   = to_upper( condense( CONV string( iv_paper_size ) ) ).
    DATA(lv_orient) = to_upper( condense( CONV string( iv_orientation ) ) ).

    DATA lv_w TYPE i.
    DATA lv_h TYPE i.
    CASE lv_size.
      WHEN 'A4'.
        lv_w = 595.
        lv_h = 842.
      WHEN OTHERS.  " 'LETTER' hoac rong/gia tri la -> mac dinh LETTER
        lv_w = 612.
        lv_h = 792.
    ENDCASE.

    IF lv_orient = 'P'.
      rs_dim-width  = lv_w.
      rs_dim-height = lv_h.
    ELSE.  " 'L' hoac rong -> Landscape (mac dinh, giu hanh vi cu)
      rs_dim-width  = lv_h.
      rs_dim-height = lv_w.
    ENDIF.
  ENDMETHOD.


  METHOD render_section_pages.
    " it_lines[1] = header text-only, từ dòng 2 trở đi mới là data row thật.
    CONSTANTS: lc_min_col_chars TYPE i VALUE 6,
               lc_max_col_chars TYPE i VALUE 30,
               lc_line_height   TYPE i VALUE 11,   " chieu cao 1 dong text trong 1 o (word-wrap)
               lc_row_padding   TYPE i VALUE 7,    " 1 dong -> 11+7=18, giu dung chieu cao hang cu
               lc_min_y_reserve TYPE i VALUE 45.   " tru cho phan footer, khong du thi sang trang moi

    DATA(ls_dim) = get_page_dimensions(
      iv_paper_size  = is_pdf_layout-paper_size
      iv_orientation = is_pdf_layout-orientation ).
    DATA(lv_page_width)  = ls_dim-width.
    DATA(lv_page_height) = ls_dim-height.
    DATA(lv_font_size)   = COND i( WHEN is_pdf_layout-font_size > 0 THEN is_pdf_layout-font_size ELSE 7 ).

    DATA(lv_left_margin) = 20.
    DATA(lv_table_width) = lv_page_width - ( 2 * lv_left_margin ).
    DATA(lv_num_cols)    = lines( it_header_cols ).
    IF lv_num_cols = 0.
      lv_num_cols = 1.
    ENDIF.

    IF it_lines IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lt_header_cells) = it_lines[ 1 ].
    DATA lt_data_lines TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
    LOOP AT it_lines INTO DATA(lv_l) FROM 2.
      APPEND lv_l TO lt_data_lines.
    ENDLOOP.

    " --- Tinh be rong rieng cho tung cot, theo TU DAI NHAT (header hoac data),
    " khong theo do dai ca chuoi - de FitToPage khong bao gio bop cot hep hon
    " muc can de hien du 1 tu. Doi lai: cot nhieu-tu-nhung-tung-tu-ngan se
    " khong duoc "thuong" rong hon nhu truoc, chi wrap nhieu dong hon (hang
    " cao hon) thay vi chiem rong hon. Unit test LTC_EXPORT_PDF_LAYOUT_FIX->
    " WIDE_COLUMN_NOT_TRUNCATED can duoc cap nhat lai theo huong nay. ---
    DATA lt_col_weight TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    CLEAR lt_col_weight.
    DO lv_num_cols TIMES.
      DATA(lv_col_ix) = sy-index.
      DATA(lv_hdr_txt2) = COND string( WHEN lv_col_ix <= lines( lt_header_cells )
                                        THEN condense( lt_header_cells[ lv_col_ix ] ) ELSE `` ).
      " Weight uu tien theo DO DAI CA CAU HEADER (de header co co hoi hien
      " tron ven 1 dong, dung format voi fit_to_page_font_size o tren) -
      " khong con chi lay tu dai nhat nua. Viec khong vo chu giua tu van
      " duoc dam bao rieng boi wrap_text_lines (luon ngat theo tu) khi ve
      " thuc te ben duoi, khong phu thuoc vao weight nay.
      DATA(lv_w) = strlen( lv_hdr_txt2 ).
      LOOP AT lt_data_lines INTO DATA(lt_row_w).
        IF lv_col_ix <= lines( lt_row_w ).
          SPLIT condense( lt_row_w[ lv_col_ix ] ) AT space INTO TABLE DATA(lt_dw).
          LOOP AT lt_dw INTO DATA(lv_dw).
            IF strlen( lv_dw ) > lv_w.
              lv_w = strlen( lv_dw ).
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDLOOP.
      IF lv_w < lc_min_col_chars.
        lv_w = lc_min_col_chars.
      ENDIF.
      IF lv_w > lc_max_col_chars.
        lv_w = lc_max_col_chars.
      ENDIF.
      APPEND lv_w TO lt_col_weight.
    ENDDO.

    DATA(lv_total_weight) = REDUCE i( INIT s = 0 FOR lv_wv IN lt_col_weight NEXT s = s + lv_wv ).
    IF lv_total_weight = 0.
      lv_total_weight = 1.
    ENDIF.

    DATA lt_col_widths TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    CLEAR lt_col_widths.
    LOOP AT lt_col_weight INTO DATA(lv_wv2).
      DATA(lv_cw) = CONV i( lv_table_width * lv_wv2 / lv_total_weight ).
      IF lv_cw < 1.
        lv_cw = 1.
      ENDIF.
      APPEND lv_cw TO lt_col_widths.
    ENDLOOP.
    " ---------------------------------------------------------------------

    " --- so ky tu toi da/dong cho tung cot cua phan DATA (dung de word-wrap) ---
    DATA lt_col_maxchar TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    CLEAR lt_col_maxchar.
    LOOP AT lt_col_widths INTO DATA(lv_cw2).
      DATA(lv_mc) = CONV i( lv_cw2 * 10 / ( lv_font_size * 7 ) ) - 1.
      IF lv_mc < 1.
        lv_mc = 1.
      ENDIF.
      APPEND lv_mc TO lt_col_maxchar.
    ENDLOOP.
    " ------------------------------------------------------------------------------------------

    DATA(lv_generated_at) = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
    DATA(lv_header_text) = COND string( WHEN is_pdf_layout-header_text IS NOT INITIAL
                                     THEN is_pdf_layout-header_text ELSE iv_title ).
    DATA(lv_footer_left_text) = COND string( WHEN is_pdf_layout-footer_text IS NOT INITIAL
                                              THEN is_pdf_layout-footer_text
                                              ELSE |Generated: { lv_generated_at }| ).
    DATA lt_col_maxchar_hdr TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    CLEAR lt_col_maxchar_hdr.
    LOOP AT lt_col_widths INTO DATA(lv_cw3).
      DATA(lv_mc_hdr) = CONV i( lv_cw3 * 10 / ( ( lv_font_size + 1 ) * 7 ) ) - 1.
      IF lv_mc_hdr < 1.
        lv_mc_hdr = 1.
      ENDIF.
      APPEND lv_mc_hdr TO lt_col_maxchar_hdr.
    ENDLOOP.

    DATA lt_header_wrapped TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
    CLEAR lt_header_wrapped.
    DATA(lv_header_lines) = 1.
    LOOP AT lt_header_cells INTO DATA(lv_hcell0).
      DATA(lv_hidx0) = sy-tabix.
      DATA(lv_hmc0) = COND i( WHEN lv_hidx0 <= lines( lt_col_maxchar_hdr ) THEN lt_col_maxchar_hdr[ lv_hidx0 ] ELSE 1 ).
      DATA(lt_hwl) = wrap_text_lines( iv_text = condense( lv_hcell0 ) iv_max_char = lv_hmc0 ).
      APPEND lt_hwl TO lt_header_wrapped.
      IF lines( lt_hwl ) > lv_header_lines.
        lv_header_lines = lines( lt_hwl ).
      ENDIF.
    ENDLOOP.
    DATA(lv_row_height_hdr) = ( lv_header_lines * lc_line_height ) + lc_row_padding.

    DATA lv_page_content  TYPE string.
    DATA lv_y             TYPE i.
    DATA lv_page_num      TYPE i VALUE 1.
    DATA lv_data_idx      TYPE i VALUE 0.
    DATA(lv_total_data_lines) = lines( lt_data_lines ).

    DO.
      " ===== bat dau 1 trang moi: ve tieu de + header cot =====
      CLEAR lv_page_content.
      lv_page_content = |BT\n/F1 { lv_font_size + 5 } Tf\n1 0 0 1 { lv_left_margin } { lv_page_height - 25 } Tm\n|
        && |({ escape_pdf_text( lv_header_text ) }) Tj\nET\n|.

      lv_y = lv_page_height - 50.

      " Khung nen header: DINH (top) LUON co dinh o "lv_y + 14" (dung nhu truong
      " hop header 1 dong truoc day: lv_y - 4 + row_height_hdr(=18) = lv_y + 14),
      " con DAY (bottom) moi la phan gian ra khi header wrap nhieu dong (row_height_hdr
      " lon hon). Truoc day code luon fix DAY = lv_y - 4 va cho DINH phinh len theo
      " so dong -> khi header wrap >= 2 dong, dong chu cuoi (vd "Name", "Routine",
      " "Access", "Kind"...) roi xuong duoi DAY cua khung, de ra ngoai/de len hang
      " du lieu dau tien. Doi lai cong thuc (fix DINH, gian DAY xuong) thi moi
      " dong chu header - du wrap bao nhieu dong - deu nam gon trong khung nen.
      DATA(lv_hdr_box_bottom) = lv_y + 14 - lv_row_height_hdr.
      lv_page_content = lv_page_content && |0.90 0.92 0.95 rg\n|
        && |{ lv_left_margin } { lv_hdr_box_bottom } { lv_table_width } { lv_row_height_hdr } re f\n0 g\n|.

      DATA(lv_x) = lv_left_margin.
      LOOP AT lt_header_wrapped INTO DATA(lt_hcell_wl).
        DATA(lv_hidx) = sy-tabix.
        DATA(lv_this_width) = COND i( WHEN lv_hidx <= lines( lt_col_widths ) THEN lt_col_widths[ lv_hidx ] ELSE lv_table_width / lv_num_cols ).
        DATA(lv_hline_no) = 0.
        LOOP AT lt_hcell_wl INTO DATA(lv_hline).
          lv_page_content = lv_page_content
            && |BT\n/F1 { lv_font_size + 1 } Tf\n1 0 0 1 { lv_x + 4 } { lv_y + 2 - ( lv_hline_no * lc_line_height ) } Tm\n({ escape_pdf_text( lv_hline ) }) Tj\nET\n|.
          lv_hline_no = lv_hline_no + 1.
        ENDLOOP.
        lv_x = lv_x + lv_this_width.
      ENDLOOP.
      lv_y = lv_y - lv_row_height_hdr.

      " ===== ve du lieu cho den khi het cho tren trang hoac het du lieu =====
      DATA(lv_rows_on_this_page) = 0.
      WHILE lv_data_idx < lv_total_data_lines.
        DATA(lv_next_idx) = lv_data_idx + 1.
        DATA(lt_cells) = lt_data_lines[ lv_next_idx ].

        DATA lt_wrapped TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
        CLEAR lt_wrapped.
        DATA(lv_row_lines) = 1.
        LOOP AT lt_cells INTO DATA(lv_cell_raw).
          DATA(lv_cidx0) = sy-tabix.
          DATA(lv_mc0) = COND i( WHEN lv_cidx0 <= lines( lt_col_maxchar ) THEN lt_col_maxchar[ lv_cidx0 ] ELSE 1 ).
          DATA(lt_wl) = wrap_text_lines( iv_text = condense( lv_cell_raw ) iv_max_char = lv_mc0 ).
          APPEND lt_wl TO lt_wrapped.
          IF lines( lt_wl ) > lv_row_lines.
            lv_row_lines = lines( lt_wl ).
          ENDIF.
        ENDLOOP.

        DATA(lv_this_row_height) = ( lv_row_lines * lc_line_height ) + lc_row_padding.

        IF lv_rows_on_this_page > 0 AND ( lv_y - lv_this_row_height ) < lc_min_y_reserve.
          EXIT.  " het cho tren trang nay -> chot trang, trang sau xu ly tiep tu dong nay
        ENDIF.

        DATA(lv_sep_y) = lv_y - lv_this_row_height + 14.
        lv_page_content = lv_page_content && |0.80 0.80 0.80 RG\n0.5 w\n|
          && |{ lv_left_margin } { lv_sep_y } m { lv_left_margin + lv_table_width } { lv_sep_y } l S\n|.

        lv_x = lv_left_margin.
        LOOP AT lt_wrapped INTO DATA(lt_cell_wl).
          DATA(lv_cidx) = sy-tabix.
          DATA(lv_this_width2) = COND i( WHEN lv_cidx <= lines( lt_col_widths ) THEN lt_col_widths[ lv_cidx ] ELSE lv_table_width / lv_num_cols ).
          DATA(lv_line_no) = 0.
          LOOP AT lt_cell_wl INTO DATA(lv_cell_line).
            lv_page_content = lv_page_content
              && |BT\n/F1 { lv_font_size } Tf\n1 0 0 1 { lv_x + 4 } { lv_y + 3 - ( lv_line_no * lc_line_height ) } Tm\n({ escape_pdf_text( lv_cell_line ) }) Tj\nET\n|.
            lv_line_no = lv_line_no + 1.
          ENDLOOP.
          lv_x = lv_x + lv_this_width2.
        ENDLOOP.

        lv_y = lv_y - lv_this_row_height.
        lv_data_idx = lv_next_idx.
        lv_rows_on_this_page = lv_rows_on_this_page + 1.
      ENDWHILE.
      DATA(lv_footer_right_text)  = |{ iv_title } - Page { lv_page_num } / __TOTAL_PAGES__|.
      DATA(lv_footer_right_width) = CONV i( strlen( lv_footer_right_text ) * lv_font_size * 7 / 10 ).
      DATA(lv_footer_right_x)     = lv_page_width - lv_left_margin - lv_footer_right_width.
      IF lv_footer_right_x < lv_left_margin.
        lv_footer_right_x = lv_left_margin.  " qua dai thi it nhat cho tran vao trong, khong mat chu
      ENDIF.

      lv_page_content = lv_page_content
       && |BT\n/F1 { lv_font_size } Tf\n1 0 0 1 { lv_left_margin } 15 Tm\n({ escape_pdf_text( lv_footer_left_text ) }) Tj\nET\n|
       && |BT\n/F1 { lv_font_size } Tf\n1 0 0 1 { lv_footer_right_x } 15 Tm\n({ escape_pdf_text( lv_footer_right_text ) }) Tj\nET\n|.
      APPEND lv_page_content TO rt_pages.
      lv_page_num = lv_page_num + 1.

      IF lv_data_idx >= lv_total_data_lines.
        EXIT.
      ENDIF.
    ENDDO.

    " ===== thay placeholder tong so trang bang gia tri that (chi biet duoc sau khi da render het) =====
    DATA(lv_total_pages_str) = |{ lines( rt_pages ) }|.
    LOOP AT rt_pages ASSIGNING FIELD-SYMBOL(<lv_page>).
      REPLACE ALL OCCURRENCES OF '__TOTAL_PAGES__' IN <lv_page> WITH lv_total_pages_str.
    ENDLOOP.
  ENDMETHOD.

  METHOD assemble_pdf_binary.
    DATA(ls_dim) = get_page_dimensions(
      iv_paper_size  = is_pdf_layout-paper_size
      iv_orientation = is_pdf_layout-orientation ).
    DATA(lv_page_width)  = ls_dim-width.
    DATA(lv_page_height) = ls_dim-height.

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
        && |/MediaBox [0 0 { lv_page_width } { lv_page_height }] /Contents { lv_this_cont_obj } 0 R >>\nendobj\n|.

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

