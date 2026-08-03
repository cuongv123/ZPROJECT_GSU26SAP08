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
      gc_excel_name   TYPE string VALUE 'migration_report.xlsx',
      gc_csv_name     TYPE string VALUE 'migration_report.csv',
      gc_pdf_name     TYPE string VALUE 'migration_report.pdf'.

    TYPES: BEGIN OF ty_section_registry,
             section_code TYPE zif_mig_export_provider=>ty_export_section,
             view_name    TYPE tabname,
             sheet_title  TYPE string,
           END OF ty_section_registry,
           tt_section_registry TYPE STANDARD TABLE OF ty_section_registry WITH NON-UNIQUE DEFAULT KEY.

    TYPES: BEGIN OF ty_evidence_map,
             evidence_id   TYPE sysuuid_x16,
             readable_text TYPE string,
           END OF ty_evidence_map,
           tt_evidence_map TYPE HASHED TABLE OF ty_evidence_map WITH UNIQUE KEY evidence_id.

    METHODS get_section_registry
      RETURNING VALUE(rt_registry) TYPE tt_section_registry.

    METHODS get_analysis_id
      IMPORTING
        iv_analysis_id        TYPE sysuuid_x16
        iv_report_type        TYPE zmig_mail_job-report_type
      RETURNING
        VALUE(rv_analysis_id) TYPE sysuuid_x16
      RAISING
        cx_root.

    METHODS load_evidence_lookup
      IMPORTING
        iv_analysis_id  TYPE sysuuid_x16
      RETURNING
        VALUE(rt_lookup) TYPE tt_evidence_map.

    METHODS format_cell_value
      IMPORTING
        iv_fieldname    TYPE string
        iv_raw_value    TYPE any
        it_evidence_map TYPE tt_evidence_map
      RETURNING
        VALUE(rv_text)  TYPE string.

    METHODS is_technical_key_field
      IMPORTING
        iv_fieldname    TYPE string
      RETURNING
        VALUE(rv_is_key) TYPE abap_bool.

    METHODS escape_csv_value
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS export_excel
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_analysis_id    TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    METHODS export_csv
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_analysis_id    TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    METHODS export_pdf
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_analysis_id    TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    METHODS escape_pdf_text
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS build_pdf_document
      IMPORTING
        it_lines          TYPE string_table
      RETURNING
        VALUE(rv_content) TYPE xstring
      RAISING
        cx_root.

ENDCLASS.


CLASS zcl_mig_export_engine IMPLEMENTATION.

  METHOD zif_mig_export_provider~generate.

    TRY.
        DATA(lv_format) = to_upper( condense( CONV string( iv_file_format ) ) ).

        CASE lv_format.
          WHEN gc_format_excel OR 'EXCEL' OR 'E' OR 'XLSX' OR 'X'.
            rs_result = export_excel(
              iv_job_id         = iv_job_id
              iv_analysis_id    = iv_analysis_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN gc_format_csv OR 'CSV' OR 'C'.
            rs_result = export_csv(
              iv_job_id         = iv_job_id
              iv_analysis_id    = iv_analysis_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN gc_format_pdf OR 'PDF' OR 'P'.
            rs_result = export_pdf(
              iv_job_id         = iv_job_id
              iv_analysis_id    = iv_analysis_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN OTHERS.
            rs_result-success = abap_false.
            rs_result-message = |Unsupported export format { iv_file_format }.|.
        ENDCASE.

        IF rs_result-success = abap_true.
          rs_result-file_format = iv_file_format.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).
        CLEAR: rs_result-content, rs_result-file_name, rs_result-file_type, rs_result-file_format, rs_result-mime_type.
        rs_result-success = abap_false.
        rs_result-message = lx_error->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD get_section_registry.
    rt_registry = VALUE #(
      ( section_code = 'OVERVIEW'    view_name = 'ZMIG_ANL_H'   sheet_title = 'Overview' )
      ( section_code = 'UI_FILTER'   view_name = 'ZMIG_ANL_UI'  sheet_title = 'UI Filters' )
      ( section_code = 'DB_OBJ'      view_name = 'ZMIG_ANL_DB'  sheet_title = 'Database Objects' )
      ( section_code = 'BUS_LOGIC'   view_name = 'ZMIG_ANL_LOG' sheet_title = 'Business Logic' )
      ( section_code = 'ALV_OUTPUT'  view_name = 'ZMIG_ANL_ALV' sheet_title = 'ALV Outputs' )
      ( section_code = 'SRC_EVIDEN'  view_name = 'ZMIG_ANL_EVD' sheet_title = 'Source Evidences' )
      ( section_code = 'RECOMMEN'    view_name = 'ZMIG_ANL_REC' sheet_title = 'Recommendations' )
      ( section_code = 'MESSAGE'     view_name = 'ZMIG_ANL_MSG' sheet_title = 'Messages' )
    ).
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


  METHOD is_technical_key_field.
    IF iv_fieldname = 'CLIENT' OR iv_fieldname = 'MANDT'
       OR iv_fieldname = 'ANALYSIS_ID' OR iv_fieldname = 'ITEM_ID'.
      rv_is_key = abap_true.
    ELSE.
      rv_is_key = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD load_evidence_lookup.
    IF iv_analysis_id IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_struct) = CAST cl_abap_structdescr(
          cl_abap_typedescr=>describe_by_name( 'ZMIG_ANL_EVD' ) ).
        DATA(lo_table) = cl_abap_tabledescr=>create( lo_struct ).

        DATA lr_data TYPE REF TO data.
        CREATE DATA lr_data TYPE HANDLE lo_table.
        ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_evd>).

        SELECT * FROM zmig_anl_evd
          WHERE analysis_id = @iv_analysis_id
          INTO TABLE @<lt_evd>.

        LOOP AT <lt_evd> ASSIGNING FIELD-SYMBOL(<ls_evd>).
          DATA lv_evd_id TYPE sysuuid_x16.
          DATA lv_text   TYPE string.

          ASSIGN COMPONENT 'EVIDENCE_ID' OF STRUCTURE <ls_evd> TO FIELD-SYMBOL(<lv_id>).
          IF sy-subrc = 0.
            lv_evd_id = <lv_id>.
          ELSE.
            CONTINUE.
          ENDIF.

          ASSIGN COMPONENT 'PROGRAM_NAME' OF STRUCTURE <ls_evd> TO FIELD-SYMBOL(<lv_prog>).
          ASSIGN COMPONENT 'LINE_NUMBER' OF STRUCTURE <ls_evd> TO FIELD-SYMBOL(<lv_line>).
          ASSIGN COMPONENT 'CODE_SNIPPET' OF STRUCTURE <ls_evd> TO FIELD-SYMBOL(<lv_code>).

          IF <lv_prog> IS ASSIGNED AND <lv_prog> IS NOT INITIAL.
            lv_text = |{ <lv_prog> }|.
          ENDIF.

          IF <lv_line> IS ASSIGNED AND <lv_line> IS NOT INITIAL.
            lv_text = COND #( WHEN lv_text IS INITIAL THEN |Line { <lv_line> }| ELSE |{ lv_text } (Line { <lv_line> })| ).
          ENDIF.

          IF <lv_code> IS ASSIGNED AND <lv_code> IS NOT INITIAL.
            lv_text = COND #( WHEN lv_text IS INITIAL THEN |{ <lv_code> }| ELSE |{ lv_text }: { <lv_code> }| ).
          ENDIF.

          IF lv_text IS INITIAL.
            lv_text = CONV string( lv_evd_id ).
          ENDIF.

          INSERT VALUE #( evidence_id = lv_evd_id readable_text = lv_text ) INTO TABLE rt_lookup.
        ENDLOOP.

      CATCH cx_root.
        CLEAR rt_lookup.
    ENDTRY.
  ENDMETHOD.


  METHOD format_cell_value.
    IF iv_fieldname = 'EVIDENCE_ID'.
      DATA(lv_guid) = CONV sysuuid_x16( iv_raw_value ).
      READ TABLE it_evidence_map INTO DATA(ls_map) WITH KEY evidence_id = lv_guid.
      IF sy-subrc = 0.
        rv_text = ls_map-readable_text.
        RETURN.
      ENDIF.
    ENDIF.

    rv_text = CONV string( iv_raw_value ).
  ENDMETHOD.


  METHOD escape_csv_value.
    DATA(lv_escaped) = replace( val = iv_value sub = '"' with = '""' occ = 0 ).
    rv_value = |"{ lv_escaped }"|.
  ENDMETHOD.


  METHOD export_excel.
    DATA(lt_registry) = get_section_registry( ).

    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root.
        lv_analysis_id = VALUE #( ).
    ENDTRY.

    DATA(lt_evidence_map) = load_evidence_lookup( lv_analysis_id ).

    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lv_sheet_count) = 0.

    DATA(lo_style_bold) = lo_excel->add_new_style( ).
    lo_style_bold->font->bold = abap_true.

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

          DATA(lo_table_type) = cl_abap_tabledescr=>create( lo_struct ).
          DATA lr_data TYPE REF TO data.
          CREATE DATA lr_data TYPE HANDLE lo_table_type.
          ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

          IF lv_analysis_id IS NOT INITIAL.
            SELECT * FROM (ls_section-view_name)
              WHERE analysis_id = @lv_analysis_id
              INTO TABLE @<lt_data>.
          ENDIF.

          DATA(lo_sheet) = COND #(
            WHEN lv_sheet_count = 0
            THEN lo_excel->get_active_worksheet( )
            ELSE lo_excel->add_new_worksheet( ) ).

          lo_sheet->set_title( ip_title = CONV #( ls_section-sheet_title ) ).

          IF <lt_data> IS INITIAL.
            lo_sheet->set_cell( ip_column = 1 ip_row = 1 ip_value = |No data available for section { ls_section-sheet_title }.| ).
          ELSE.
            DATA lt_dfies TYPE STANDARD TABLE OF dfies.
            CLEAR lt_dfies.
            CALL FUNCTION 'DDIF_FIELDINFO_GET'
              EXPORTING
                tabname   = ls_section-view_name
              TABLES
                dfies_tab = lt_dfies
              EXCEPTIONS
                OTHERS    = 1.

            DATA lt_export_components TYPE cl_abap_structdescr=>component_table.
            CLEAR lt_export_components.

            LOOP AT lo_struct->get_components( ) INTO DATA(ls_comp_chk).
              IF is_technical_key_field( CONV string( ls_comp_chk-name ) ) = abap_true.
                CONTINUE.
              ENDIF.
              APPEND ls_comp_chk TO lt_export_components.
            ENDLOOP.

            " Header
            DATA(lv_col) = 1.
            LOOP AT lt_export_components INTO DATA(ls_comp).
              DATA(lv_header_text) = COND string( WHEN ls_comp-name = 'EVIDENCE_ID' THEN 'SOURCE LOCATION / EVIDENCE' ELSE CONV string( ls_comp-name ) ).

              READ TABLE lt_dfies INTO DATA(ls_dfie) WITH KEY fieldname = ls_comp-name.
              IF sy-subrc = 0 AND ls_comp-name <> 'EVIDENCE_ID'.
                DATA(lv_ddic_text) = COND string(
                  WHEN ls_dfie-fieldtext IS NOT INITIAL THEN CONV string( ls_dfie-fieldtext )
                  WHEN ls_dfie-scrtext_l IS NOT INITIAL THEN CONV string( ls_dfie-scrtext_l )
                  WHEN ls_dfie-scrtext_m IS NOT INITIAL THEN CONV string( ls_dfie-scrtext_m )
                  WHEN ls_dfie-scrtext_s IS NOT INITIAL THEN CONV string( ls_dfie-scrtext_s )
                  ELSE CONV string( ls_dfie-fieldname ) ).

                IF lv_ddic_text NS '16 Byte UUID' AND lv_ddic_text NS 'UUID in 16 B'.
                  lv_header_text = lv_ddic_text.
                ENDIF.
              ENDIF.

              lo_sheet->set_cell( ip_column = lv_col ip_row = 1 ip_value = lv_header_text ).
              lo_sheet->set_cell_style( ip_column = lv_col ip_row = 1 ip_style = lo_style_bold->get_guid( ) ).

              DATA(lo_col_obj) = lo_sheet->get_column( ip_column = lv_col ).
              IF lo_col_obj IS BOUND.
                " FIX: Dùng kiểu float (f) chuẩn của ABAP
                DATA lv_hdr_width TYPE f.
                lv_hdr_width = strlen( lv_header_text ) + 4.
                lo_col_obj->set_width( ip_width = lv_hdr_width ).
              ENDIF.

              lv_col = lv_col + 1.
            ENDLOOP.

            " Data Row
            DATA(lv_row) = 2.
            LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
              lv_col = 1.
              LOOP AT lt_export_components INTO ls_comp.
                ASSIGN COMPONENT ls_comp-name OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_val>).
                IF sy-subrc = 0.
                  DATA(lv_display_val) = format_cell_value(
                    iv_fieldname    = CONV string( ls_comp-name )
                    iv_raw_value    = <lv_val>
                    it_evidence_map = lt_evidence_map ).

                  lo_sheet->set_cell( ip_column = lv_col ip_row = lv_row ip_value = lv_display_val ).

                  DATA(lv_val_len) = strlen( lv_display_val ) + 3.
                  DATA(lo_column)  = lo_sheet->get_column( ip_column = lv_col ).
                  IF lo_column IS BOUND AND lv_val_len > lo_column->get_width( ).
                    " FIX: Dùng kiểu float (f) chuẩn của ABAP
                    DATA lv_cell_width TYPE f.
                    lv_cell_width = COND i( WHEN lv_val_len > 60 THEN 60 ELSE lv_val_len ).
                    lo_column->set_width( ip_width = lv_cell_width ).
                  ENDIF.

                ENDIF.
                lv_col = lv_col + 1.
              ENDLOOP.
              lv_row = lv_row + 1.
            ENDLOOP.

            lo_sheet->set_cell( ip_column = 1 ip_row = lv_row + 1 ip_value = 'TOTAL ROWS' ).
            lo_sheet->set_cell( ip_column = 2 ip_row = lv_row + 1 ip_value = lines( <lt_data> ) ).
            lo_sheet->calculate_column_widths( ).

          ENDIF.

          lv_sheet_count = lv_sheet_count + 1.

        ENDLOOP.

      CATCH zcx_excel INTO DATA(lx_excel_build).
        rs_result-success = abap_false.
        rs_result-message = |Excel build error: { lx_excel_build->get_text( ) }.|.
        RETURN.
    ENDTRY.

    IF lv_sheet_count = 0.
      DATA(lo_empty_sheet) = lo_excel->get_active_worksheet( ).
      lo_empty_sheet->set_title( ip_title = 'Report' ).
      lo_empty_sheet->set_cell( ip_column = 1 ip_row = 1 ip_value = |No data available for program { iv_report_type }.| ).
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
    rs_result-file_name   = gc_excel_name.
    rs_result-file_type   = 'BIN'.
    rs_result-file_format = gc_format_excel.
    rs_result-mime_type   = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
    rs_result-message     = 'Excel export generated successfully.'.

  ENDMETHOD.


  METHOD export_csv.
    DATA(lt_registry) = get_section_registry( ).

    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root.
        lv_analysis_id = VALUE #( ).
    ENDTRY.

    DATA(lt_evidence_map) = load_evidence_lookup( lv_analysis_id ).
    DATA lv_csv_text TYPE string.
    DATA(lv_processed_count) = 0.

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

      DATA(lo_table_type) = cl_abap_tabledescr=>create( lo_struct ).
      DATA lr_data TYPE REF TO data.
      CREATE DATA lr_data TYPE HANDLE lo_table_type.
      ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

      IF lv_analysis_id IS NOT INITIAL.
        SELECT * FROM (ls_section-view_name)
          WHERE analysis_id = @lv_analysis_id
          INTO TABLE @<lt_data>.
      ENDIF.

      lv_processed_count = lv_processed_count + 1.
      lv_csv_text = lv_csv_text && |=== { ls_section-sheet_title } ===| && cl_abap_char_utilities=>cr_lf.

      IF <lt_data> IS INITIAL.
        lv_csv_text = lv_csv_text && |"No data available for section { ls_section-sheet_title }."| && cl_abap_char_utilities=>cr_lf.
      ELSE.
        DATA lt_export_fields TYPE cl_abap_structdescr=>component_table.
        CLEAR lt_export_fields.
        LOOP AT lo_struct->get_components( ) INTO DATA(ls_f_comp).
          IF is_technical_key_field( CONV string( ls_f_comp-name ) ) = abap_true.
            CONTINUE.
          ENDIF.
          APPEND ls_f_comp TO lt_export_fields.
        ENDLOOP.

        " Header Line
        DATA lv_header_line TYPE string.
        CLEAR lv_header_line.
        LOOP AT lt_export_fields INTO DATA(ls_field).
          DATA(lv_h_name) = COND string( WHEN ls_field-name = 'EVIDENCE_ID' THEN 'SOURCE_LOCATION' ELSE CONV string( ls_field-name ) ).
          DATA(lv_header_cell) = escape_csv_value( lv_h_name ).
          lv_header_line = COND #( WHEN lv_header_line IS INITIAL THEN lv_header_cell ELSE lv_header_line && ',' && lv_header_cell ).
        ENDLOOP.
        lv_csv_text = lv_csv_text && lv_header_line && cl_abap_char_utilities=>cr_lf.

        " Data Rows
        LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
          DATA lv_row_line TYPE string.
          CLEAR lv_row_line.
          LOOP AT lt_export_fields INTO ls_field.
            ASSIGN COMPONENT ls_field-name OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_cell>).
            IF sy-subrc = 0.
              DATA(lv_display) = format_cell_value(
                iv_fieldname    = CONV string( ls_field-name )
                iv_raw_value    = <lv_cell>
                it_evidence_map = lt_evidence_map ).

              DATA(lv_escaped_cell) = escape_csv_value( lv_display ).
              lv_row_line = COND #( WHEN lv_row_line IS INITIAL THEN lv_escaped_cell ELSE lv_row_line && ',' && lv_escaped_cell ).
            ENDIF.
          ENDLOOP.
          lv_csv_text = lv_csv_text && lv_row_line && cl_abap_char_utilities=>cr_lf.
        ENDLOOP.
      ENDIF.

      lv_csv_text = lv_csv_text && cl_abap_char_utilities=>cr_lf.

    ENDLOOP.

    IF lv_processed_count = 0.
      lv_csv_text = |"No data available for program { iv_report_type }."|.
    ENDIF.

    TRY.
        DATA(lv_xstring) = cl_bcs_convert=>string_to_xstring(
          iv_string   = lv_csv_text
          iv_codepage = '4110' ).
      CATCH cx_bcs INTO DATA(lx_bcs).
        rs_result-success = abap_false.
        rs_result-message = |CSV conversion error: { lx_bcs->get_text( ) }.|.
        RETURN.
    ENDTRY.

    rs_result-success     = abap_true.
    rs_result-content     = lv_xstring.
    rs_result-file_name   = gc_csv_name.
    rs_result-file_type   = 'CSV'.
    rs_result-file_format = gc_format_csv.
    rs_result-mime_type   = 'text/csv'.
    rs_result-message     = 'CSV export generated successfully.'.

  ENDMETHOD.


  METHOD export_pdf.
    DATA(lt_registry) = get_section_registry( ).

    TRY.
        DATA(lv_analysis_id) = get_analysis_id(
          iv_analysis_id = iv_analysis_id
          iv_report_type = iv_report_type ).
      CATCH cx_root.
        lv_analysis_id = VALUE #( ).
    ENDTRY.

    DATA(lt_evidence_map) = load_evidence_lookup( lv_analysis_id ).
    DATA lt_lines TYPE string_table.

    APPEND |Migration Analysis Report| TO lt_lines.
    APPEND |Program: { iv_report_type }| TO lt_lines.
    APPEND |Generated: { sy-datum } { sy-uzeit }| TO lt_lines.
    APPEND `` TO lt_lines.

    DATA(lv_processed_count) = 0.

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

      DATA(lo_table_type) = cl_abap_tabledescr=>create( lo_struct ).
      DATA lr_data TYPE REF TO data.
      CREATE DATA lr_data TYPE HANDLE lo_table_type.
      ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

      IF lv_analysis_id IS NOT INITIAL.
        SELECT * FROM (ls_section-view_name)
          WHERE analysis_id = @lv_analysis_id
          INTO TABLE @<lt_data>.
      ENDIF.

      lv_processed_count = lv_processed_count + 1.
      APPEND |=== { ls_section-sheet_title } ===| TO lt_lines.

      IF <lt_data> IS INITIAL.
        APPEND |No data available for section { ls_section-sheet_title }. | TO lt_lines.
      ELSE.
        DATA lt_export_fields TYPE cl_abap_structdescr=>component_table.
        CLEAR lt_export_fields.
        LOOP AT lo_struct->get_components( ) INTO DATA(ls_f_comp).
          IF is_technical_key_field( CONV string( ls_f_comp-name ) ) = abap_true.
            CONTINUE.
          ENDIF.
          APPEND ls_f_comp TO lt_export_fields.
        ENDLOOP.

        " Ghi Header cho PDF
        DATA lv_pdf_header TYPE string.
        CLEAR lv_pdf_header.
        LOOP AT lt_export_fields INTO DATA(ls_hdr_field).
          DATA(lv_hdr_name) = COND string( WHEN ls_hdr_field-name = 'EVIDENCE_ID' THEN 'EVIDENCE' ELSE CONV string( ls_hdr_field-name ) ).
          lv_pdf_header = COND #( WHEN lv_pdf_header IS INITIAL THEN lv_hdr_name ELSE lv_pdf_header && ` | ` && lv_hdr_name ).
        ENDLOOP.
        APPEND lv_pdf_header TO lt_lines.
        APPEND |---------------------------------------------------------------------------------------------------| TO lt_lines.

        " Ghi Data dòng PDF
        LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
          DATA lv_line TYPE string.
          CLEAR lv_line.
          LOOP AT lt_export_fields INTO DATA(ls_field).
            ASSIGN COMPONENT ls_field-name OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_cell>).
            IF sy-subrc = 0.
              DATA(lv_display_val) = format_cell_value(
                iv_fieldname    = CONV string( ls_field-name )
                iv_raw_value    = <lv_cell>
                it_evidence_map = lt_evidence_map ).

              lv_line = COND #( WHEN lv_line IS INITIAL THEN lv_display_val ELSE lv_line && ` | ` && lv_display_val ).
            ENDIF.
          ENDLOOP.

          IF strlen( lv_line ) > 110.
            lv_line = substring( val = lv_line off = 0 len = 107 ) && '...'.
          ENDIF.

          APPEND lv_line TO lt_lines.
        ENDLOOP.
      ENDIF.

      APPEND `` TO lt_lines.

    ENDLOOP.

    IF lv_processed_count = 0.
      APPEND |No data available for program { iv_report_type }.| TO lt_lines.
    ENDIF.

    TRY.
        rs_result-content = build_pdf_document( lt_lines ).
      CATCH cx_root INTO DATA(lx_pdf).
        rs_result-success = abap_false.
        rs_result-message = |PDF_BUILD_ERROR: { lx_pdf->get_text( ) }|.
        RETURN.
    ENDTRY.

    rs_result-success     = abap_true.
    rs_result-file_name   = gc_pdf_name.
    rs_result-file_type   = 'PDF'.
    rs_result-file_format = gc_format_pdf.
    rs_result-mime_type   = 'application/pdf'.
    rs_result-message     = 'PDF export generated successfully.'.

  ENDMETHOD.


  METHOD escape_pdf_text.
    DATA(lv_escaped) = replace( val = iv_text sub = '\' with = '\\' occ = 0 ).
    lv_escaped = replace( val = lv_escaped sub = '(' with = '\(' occ = 0 ).
    lv_escaped = replace( val = lv_escaped sub = ')' with = '\)' occ = 0 ).

    lv_escaped = replace(
      regex = '[^\x20-\x7E]'
      val   = lv_escaped
      with  = '?'
      occ   = 0 ).

    rv_text = lv_escaped.
  ENDMETHOD.


  METHOD build_pdf_document.
    CONSTANTS: lc_lines_per_page TYPE i VALUE 50,
               lc_page_width     TYPE i VALUE 612,
               lc_page_height    TYPE i VALUE 792.

    DATA lt_pages TYPE string_table.
    DATA(lv_total_lines) = lines( it_lines ).
    DATA(lv_total_pages) = COND i(
      WHEN lv_total_lines = 0 THEN 1
      ELSE ( ( lv_total_lines - 1 ) DIV lc_lines_per_page ) + 1 ).

    DATA lv_idx TYPE i VALUE 0.
    DATA lv_page_num TYPE i VALUE 1.

    DO lv_total_pages TIMES.
      DATA(lv_from) = lv_idx + 1.
      DATA(lv_to)   = nmin( val1 = lv_total_lines val2 = lv_idx + lc_lines_per_page ).

      DATA lv_page_content TYPE string.
      lv_page_content = |BT\n/F1 8 Tf\n|.
      lv_page_content = lv_page_content && |1 0 0 1 40 { lc_page_height - 30 } Tm\n|.
      lv_page_content = lv_page_content &&
        |({ escape_pdf_text( |Migration Analysis Report - Page { lv_page_num }/{ lv_total_pages }| ) }) Tj\n|.

      DATA(lv_y) = lc_page_height - 55.

      IF lv_from <= lv_to.
        LOOP AT it_lines FROM lv_from TO lv_to INTO DATA(lv_text_line).
          lv_page_content = lv_page_content && |1 0 0 1 40 { lv_y } Tm\n|.
          lv_page_content = lv_page_content && |({ escape_pdf_text( lv_text_line ) }) Tj\n|.
          lv_y = lv_y - 11.
        ENDLOOP.
      ENDIF.

      lv_page_content = lv_page_content && |1 0 0 1 40 30 Tm\n|.
      lv_page_content = lv_page_content &&
        |({ escape_pdf_text( |Generated automatically - { sy-datum } { sy-uzeit }| ) }) Tj\n|.
      lv_page_content = lv_page_content && |ET\n|.

      APPEND lv_page_content TO lt_pages.

      lv_idx = lv_idx + lc_lines_per_page.
      lv_page_num = lv_page_num + 1.
    ENDDO.

    DATA lv_pdf TYPE string.
    DATA lt_offsets TYPE STANDARD TABLE OF i.

    lv_pdf = |%PDF-1.4\n|.
    DATA(lv_pdf_xstring) = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).

    APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
    lv_pdf = lv_pdf && |1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n|.

    DATA lv_kids TYPE string.
    DATA(lv_num_pages) = lines( lt_pages ).
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

    LOOP AT lt_pages INTO DATA(lv_page_text).
      DATA(lv_this_page_obj) = 4 + ( sy-tabix - 1 ) * 2.
      DATA(lv_this_cont_obj) = lv_this_page_obj + 1.

      lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
      APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
      lv_pdf = lv_pdf && |{ lv_this_page_obj } 0 obj\n|
        && |<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 3 0 R >> >> |
        && |/MediaBox [0 0 { lc_page_width } { lc_page_height }] /Contents { lv_this_cont_obj } 0 R >>\nendobj\n|.

      lv_pdf_xstring = cl_abap_codepage=>convert_to( source = lv_pdf codepage = 'UTF-8' ).
      APPEND xstrlen( lv_pdf_xstring ) TO lt_offsets.
      DATA(lv_stream_len) = strlen( lv_page_text ).
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
