CLASS zcl_mig_export_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_export_provider.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_section_registry,
             section_code TYPE zif_mig_export_provider=>ty_export_section,
             view_name    TYPE tabname,
             sheet_title  TYPE string,
           END OF ty_section_registry,
           tt_section_registry TYPE STANDARD TABLE OF ty_section_registry
             WITH NON-UNIQUE DEFAULT KEY.

    METHODS get_section_registry
      RETURNING VALUE(rt_registry) TYPE tt_section_registry.

    METHODS get_analysis_id
      IMPORTING
        iv_report_type        TYPE zmig_mail_job-report_type
      RETURNING
        VALUE(rv_analysis_id) TYPE sysuuid_x16
      RAISING
        cx_root.

    METHODS export_excel
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    METHODS export_csv
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    METHODS escape_csv_value
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS export_pdf
      IMPORTING
        iv_job_id         TYPE sysuuid_x16
        iv_report_type    TYPE zmig_mail_job-report_type
        iv_export_section TYPE zif_mig_export_provider=>ty_export_section
      RETURNING
        VALUE(rs_result)  TYPE zif_mig_export_provider=>ty_export_result.

    CONSTANTS:
      gc_format_excel TYPE zmig_e_file_format VALUE 'X',
      gc_format_csv   TYPE zmig_e_file_format VALUE 'C',
      gc_format_pdf   TYPE zmig_e_file_format VALUE 'P'.

    CONSTANTS:
      gc_excel_name TYPE zmig_mail_log-file_name VALUE 'migration_report.xlsx',
      gc_csv_name   TYPE zmig_mail_log-file_name VALUE 'migration_report.csv',
      gc_pdf_name   TYPE zmig_mail_log-file_name VALUE 'migration_report.pdf'.

ENDCLASS.



CLASS zcl_mig_export_engine IMPLEMENTATION.

  METHOD zif_mig_export_provider~generate.

    TRY.

        CASE iv_file_format.

          WHEN gc_format_excel.

            rs_result = export_excel(
              iv_job_id         = iv_job_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN gc_format_csv.

            rs_result = export_csv(
              iv_job_id         = iv_job_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN gc_format_pdf.

            rs_result = export_pdf(
              iv_job_id         = iv_job_id
              iv_report_type    = iv_report_type
              iv_export_section = iv_export_section ).

          WHEN OTHERS.

            rs_result-success = abap_false.
            rs_result-message =
              |Unsupported export format { iv_file_format }.|.

        ENDCASE.

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

    rt_registry = VALUE #(
      ( section_code = 'OVERVIEW'        view_name = 'ZMIG_ANL_H'   sheet_title = 'Overview' )
      ( section_code = 'UI_FILTER'       view_name = 'ZMIG_ANL_UI'  sheet_title = 'UI Filters' )
      ( section_code = 'DB_OBJECT'       view_name = 'ZMIG_ANL_DB'  sheet_title = 'Database Objects' )
      ( section_code = 'BUSINESS_LOGIC'  view_name = 'ZMIG_ANL_LOG' sheet_title = 'Business Logic' )
      ( section_code = 'ALV_OUTPUT'      view_name = 'ZMIG_ANL_ALV' sheet_title = 'ALV Outputs' )
      ( section_code = 'SOURCE_EVIDENCE' view_name = 'ZMIG_ANL_EVD' sheet_title = 'Source Evidences' )
      ( section_code = 'RECOMMENDATION'  view_name = 'ZMIG_ANL_REC' sheet_title = 'Recommendations' )
      ( section_code = 'MESSAGE'         view_name = 'ZMIG_ANL_MSG' sheet_title = 'Messages' )
    ).

  ENDMETHOD.


  METHOD get_analysis_id.

    SELECT SINGLE analysis_id
      FROM zmig_anl_h
      WHERE program_name = @iv_report_type
      INTO @rv_analysis_id.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.

  ENDMETHOD.


  METHOD export_excel.

    DATA(lt_registry) = get_section_registry( ).

    TRY.
        DATA(lv_analysis_id) = get_analysis_id( iv_report_type ).
      CATCH cx_root.
        rs_result-success = abap_false.
        rs_result-message = |No analysis found for program { iv_report_type }.|.
        RETURN.
    ENDTRY.

    DATA(lo_excel) = NEW zcl_excel( ).
    DATA(lv_sheet_count) = 0.
    DATA(lv_any_data) = abap_false.

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

          SELECT * FROM (ls_section-view_name)
            WHERE analysis_id = @lv_analysis_id
            INTO TABLE @<lt_data>.

          IF sy-subrc <> 0 OR lines( <lt_data> ) = 0.
            CONTINUE.
          ENDIF.

          lv_any_data = abap_true.

          DATA(lo_sheet) = COND #(
            WHEN lv_sheet_count = 0
            THEN lo_excel->get_active_worksheet( )
            ELSE lo_excel->add_new_worksheet( ) ).

          lo_sheet->set_title( ip_title = CONV #( ls_section-sheet_title ) ).
          lo_sheet->bind_table(
            ip_table           = <lt_data>
            is_table_settings  = VALUE #( top_left_column = 1 top_left_row = 1 ) ).

          lv_sheet_count = lv_sheet_count + 1.

        ENDLOOP.

      CATCH zcx_excel INTO DATA(lx_excel_build).
        rs_result-success = abap_false.
        rs_result-message = |Excel build error: { lx_excel_build->get_text( ) }.|.
        RETURN.

    ENDTRY.

    IF lv_any_data = abap_false.
      rs_result-success = abap_false.
      rs_result-message = |No data found for section { iv_export_section } and analysis { lv_analysis_id }.|.
      RETURN.
    ENDIF.

    DATA(lo_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ).

    TRY.
        DATA(lv_content) = lo_writer->write_file( io_excel = lo_excel ).
      CATCH zcx_excel INTO DATA(lx_excel).
        rs_result-success = abap_false.
        rs_result-message = |Excel writer error: { lx_excel->get_text( ) }.|.
        RETURN.
    ENDTRY.

    IF lv_content IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'Generated Excel content is empty.'.
      RETURN.
    ENDIF.

    rs_result-success     = abap_true.
    rs_result-content     = lv_content.
    rs_result-file_name   = gc_excel_name.
    rs_result-file_type   = 'BIN'.
    rs_result-file_format = gc_format_excel.
    rs_result-mime_type   =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
    rs_result-message     = 'Excel export generated successfully.'.

  ENDMETHOD.

  METHOD escape_csv_value.

    DATA(lv_escaped) = replace(
      val  = iv_value
      sub  = '"'
      with = '""'
      occ  = 0 ).

    rv_value = |"{ lv_escaped }"|.

  ENDMETHOD.

  METHOD export_csv.

    DATA(lt_registry) = get_section_registry( ).

    TRY.
        DATA(lv_analysis_id) = get_analysis_id( iv_report_type ).
      CATCH cx_root.
        rs_result-success = abap_false.
        rs_result-message = |No analysis found for program { iv_report_type }.|.
        RETURN.
    ENDTRY.

    DATA lv_csv_text TYPE string.
    DATA(lv_any_data) = abap_false.

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

      SELECT * FROM (ls_section-view_name)
        WHERE analysis_id = @lv_analysis_id
        INTO TABLE @<lt_data>.

      IF sy-subrc <> 0 OR lines( <lt_data> ) = 0.
        CONTINUE.
      ENDIF.

      lv_any_data = abap_true.

      lv_csv_text = lv_csv_text && |=== { ls_section-sheet_title } ===| && cl_abap_char_utilities=>cr_lf.

      DATA(lt_fields) = lo_struct->get_components( ).
      DATA lv_header_line TYPE string.
      CLEAR lv_header_line.
      LOOP AT lt_fields INTO DATA(ls_field).
        DATA(lv_header_cell) = escape_csv_value( ls_field-name ).
        lv_header_line = COND #(
          WHEN lv_header_line IS INITIAL THEN lv_header_cell
          ELSE lv_header_line && ',' && lv_header_cell ).
      ENDLOOP.
      lv_csv_text = lv_csv_text && lv_header_line && cl_abap_char_utilities=>cr_lf.

      LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
        DATA lv_row_line TYPE string.
        CLEAR lv_row_line.
        DO lines( lt_fields ) TIMES.
          DATA(lv_idx) = sy-index.
          ASSIGN COMPONENT lv_idx OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_cell>).
          IF sy-subrc = 0.
            DATA(lv_escaped_cell) = escape_csv_value( |{ <lv_cell> }| ).
            lv_row_line = COND #(
              WHEN lv_row_line IS INITIAL THEN lv_escaped_cell
              ELSE lv_row_line && ',' && lv_escaped_cell ).
          ENDIF.
        ENDDO.
        lv_csv_text = lv_csv_text && lv_row_line && cl_abap_char_utilities=>cr_lf.
      ENDLOOP.

      lv_csv_text = lv_csv_text && cl_abap_char_utilities=>cr_lf.

    ENDLOOP.

    IF lv_any_data = abap_false.
      rs_result-success = abap_false.
      rs_result-message = |No data found for section { iv_export_section } and analysis { lv_analysis_id }.|.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_xstring) = cl_bcs_convert=>string_to_xstring(
          iv_string   = lv_csv_text
          iv_codepage = '4110' ).  " UTF-8
      CATCH cx_bcs INTO DATA(lx_bcs).
        rs_result-success = abap_false.
        rs_result-message = |CSV conversion error: { lx_bcs->get_text( ) }.|.
        RETURN.
    ENDTRY.

    IF lv_xstring IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'Generated CSV content is empty.'.
      RETURN.
    ENDIF.

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
        DATA(lv_analysis_id) = get_analysis_id( iv_report_type ).
      CATCH cx_root.
        rs_result-success = abap_false.
        rs_result-message = |No analysis found for program { iv_report_type }.|.
        RETURN.
    ENDTRY.

    TYPES: BEGIN OF ty_section_data,
             sheet_title TYPE string,
             fields      TYPE REF TO cl_abap_structdescr,
             data_ref    TYPE REF TO data,
           END OF ty_section_data.
    DATA lt_section_data TYPE STANDARD TABLE OF ty_section_data.
    DATA(lv_any_data) = abap_false.

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

      SELECT * FROM (ls_section-view_name)
        WHERE analysis_id = @lv_analysis_id
        INTO TABLE @<lt_data>.

      IF sy-subrc <> 0 OR lines( <lt_data> ) = 0.
        CONTINUE.
      ENDIF.

      lv_any_data = abap_true.

      APPEND VALUE #(
        sheet_title = ls_section-sheet_title
        fields      = lo_struct
        data_ref    = lr_data
      ) TO lt_section_data.

    ENDLOOP.

    IF lv_any_data = abap_false.
      rs_result-success = abap_false.
      rs_result-message = |No data found for section { iv_export_section } and analysis { lv_analysis_id }.|.
      RETURN.
    ENDIF.

    NEW-PAGE PRINT ON
      NO DIALOG
      DESTINATION 'LOCL'
      IMMEDIATELY ' '
      KEEP IN SPOOL 'X'
      LIST NAME 'MIG_EXPORT'.

    WRITE: / 'Migration Analysis Report'   COLOR COL_HEADING.
    WRITE: / 'Program:', iv_report_type.
    WRITE: / 'Generated:', sy-datum, sy-uzeit.
    ULINE.

    LOOP AT lt_section_data INTO DATA(ls_sec_data).

      ASSIGN ls_sec_data-data_ref->* TO FIELD-SYMBOL(<lt_sec_table>).
      DATA(lt_sec_fields) = ls_sec_data-fields->get_components( ).

      SKIP.
      WRITE: / ls_sec_data-sheet_title COLOR COL_GROUP.
      ULINE.

      LOOP AT <lt_sec_table> ASSIGNING FIELD-SYMBOL(<ls_sec_row>).
        DATA lv_line TYPE string.
        CLEAR lv_line.
        DO lines( lt_sec_fields ) TIMES.
          DATA(lv_col_idx) = sy-index.
          ASSIGN COMPONENT lv_col_idx OF STRUCTURE <ls_sec_row> TO FIELD-SYMBOL(<lv_sec_cell>).
          IF sy-subrc = 0.
            lv_line = COND #(
              WHEN lv_line IS INITIAL THEN |{ <lv_sec_cell> }|
              ELSE lv_line && ` | ` && |{ <lv_sec_cell> }| ).
          ENDIF.
        ENDDO.
        WRITE: / lv_line.
      ENDLOOP.

    ENDLOOP.

    SKIP.
    ULINE.
    WRITE: / 'End of report - generated automatically, do not reply.'.

    NEW-PAGE PRINT OFF.

    DATA(lv_spool_id) = sy-spono.

    IF lv_spool_id IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'Could not create spool job for PDF conversion.'.
      RETURN.
    ENDIF.

    DATA lv_pdf_bytecount TYPE i.
    DATA lt_pdf_lines TYPE STANDARD TABLE OF tline.

    CALL FUNCTION 'CONVERT_ABAPSPOOLJOB_2_PDF'
      EXPORTING
        src_spoolid              = lv_spool_id
        no_dialog                = abap_true
      IMPORTING
        pdf_bytecount            = lv_pdf_bytecount
      TABLES
        pdf                      = lt_pdf_lines
      EXCEPTIONS
        err_no_abap_spooljob     = 1
        err_no_spooljob          = 2
        err_no_permission        = 3
        err_conv_not_possible    = 4
        err_bad_dstdevice        = 5
        user_cancelled           = 6
        err_spoolerror           = 7
        err_temseerror           = 8
        err_btcjob_open_failed   = 9
        err_btcjob_submit_failed = 10
        err_btcjob_close_failed  = 11
        OTHERS                   = 12.

    IF sy-subrc <> 0 OR lv_pdf_bytecount = 0.
      rs_result-success = abap_false.
      rs_result-message = |PDF conversion failed, subrc = { sy-subrc }.|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_pdf_bytecount
      IMPORTING
        buffer       = rs_result-content
      TABLES
        binary_tab   = lt_pdf_lines
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.

    IF sy-subrc <> 0 OR rs_result-content IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'Generated PDF content is empty.'.
      RETURN.
    ENDIF.

    rs_result-success     = abap_true.
    rs_result-file_name   = gc_pdf_name.
    rs_result-file_type   = 'PDF'.
    rs_result-file_format = gc_format_pdf.
    rs_result-mime_type   = 'application/pdf'.
    rs_result-message     = 'PDF export generated successfully.'.

  ENDMETHOD.

ENDCLASS.
