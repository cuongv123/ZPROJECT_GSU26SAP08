CLASS zcl_mig_export_stub DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_export_provider.

  PRIVATE SECTION.

    CONSTANTS:
      gc_format_csv TYPE zmig_e_file_format VALUE 'C',
      gc_file_type  TYPE soodk-objtp VALUE 'CSV'.

ENDCLASS.


CLASS zcl_mig_export_stub IMPLEMENTATION.

  METHOD zif_mig_export_provider~generate.

    "Stub currently supports CSV only.
    IF iv_file_format <> gc_format_csv.

      rs_result-success = abap_false.
      rs_result-message =
        |Export format { iv_file_format } is not supported by the stub.|.

      RETURN.

    ENDIF.


    TRY.

        DATA(lv_csv_text) =
            |JobId,ReportType,Status|
            && cl_abap_char_utilities=>cr_lf
            && |{ iv_job_id },{ iv_report_type },Generated|
            && cl_abap_char_utilities=>cr_lf.

        rs_result-content =
          cl_abap_codepage=>convert_to(
            source = lv_csv_text
          ).

        rs_result-file_name   = 'migration_export.csv'.
        rs_result-file_type   = gc_file_type.
        rs_result-file_format = gc_format_csv.
        rs_result-mime_type   = 'text/csv'.
        rs_result-success     = abap_true.
        rs_result-message     = 'CSV export generated successfully.'.

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

ENDCLASS.
