CLASS zcl_ce_mig_export DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS zcl_ce_mig_export IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    DATA:
      lv_report_type    TYPE zmig_mail_job-report_type,
      lv_file_format    TYPE zmig_e_file_format,
      lv_export_section TYPE zif_mig_export_provider=>ty_export_section.

    TRY.

        DATA(lt_parameters) = io_request->get_parameters( ).

        LOOP AT lt_parameters INTO DATA(ls_para).

          CASE to_upper( ls_para-parameter_name ).

            WHEN 'REPORTTYPE'.
              lv_report_type = ls_para-value.

            WHEN 'FILEFORMAT'.
              lv_file_format = ls_para-value.

            WHEN 'EXPORTSECTION'.
              lv_export_section = ls_para-value.

          ENDCASE.

        ENDLOOP.

        IF lv_report_type IS INITIAL
        OR lv_file_format IS INITIAL
        OR lv_export_section IS INITIAL.

          DATA(lo_filter) = io_request->get_filter( ).

          IF lo_filter IS BOUND.

            DATA(lt_ranges) = lo_filter->get_as_ranges( ).

            LOOP AT lt_ranges INTO DATA(ls_filter_line).

              CASE to_upper( ls_filter_line-name ).

                WHEN 'REPORTTYPE'.

                  IF lines( ls_filter_line-range ) >= 1.
                    lv_report_type = ls_filter_line-range[ 1 ]-low.
                  ENDIF.

                WHEN 'FILEFORMAT'.

                  IF lines( ls_filter_line-range ) >= 1.
                    lv_file_format = ls_filter_line-range[ 1 ]-low.
                  ENDIF.

                WHEN 'EXPORTSECTION'.

                  IF lines( ls_filter_line-range ) >= 1.
                    lv_export_section = ls_filter_line-range[ 1 ]-low.
                  ENDIF.

              ENDCASE.

            ENDLOOP.

          ENDIF.

        ENDIF.

      CATCH cx_root.
        CLEAR:
          lv_report_type,
          lv_file_format,
          lv_export_section.
    ENDTRY.

    IF lv_export_section IS INITIAL.
      lv_export_section = 'ALL'.
    ENDIF.

    DATA: ls_result TYPE zif_mig_export_provider=>ty_export_result.

    IF io_request->is_data_requested( )
       AND lv_report_type IS NOT INITIAL
       AND lv_file_format IS NOT INITIAL.

      DATA(lo_engine) = NEW zcl_mig_export_engine( ).

      ls_result = lo_engine->zif_mig_export_provider~generate(
          iv_job_id         = cl_system_uuid=>create_uuid_x16_static( )
          iv_analysis_id    = VALUE sysuuid_x16( )
          iv_report_type    = lv_report_type
          iv_file_format    = lv_file_format
          iv_export_section = lv_export_section ).

    ENDIF.

    DATA(lv_final_filename) = COND string(
      WHEN ls_result-success = abap_false
      THEN |ERROR__{ ls_result-message }.txt|
      ELSE CONV string( ls_result-file_name ) ).

    DATA(lv_final_mimetype) = COND string(
      WHEN ls_result-success = abap_false
      THEN 'text/plain'
      ELSE ls_result-mime_type ).

    DATA lt_export TYPE TABLE OF zce_mig_export.

    APPEND VALUE #(
      reporttype    = lv_report_type
      fileformat    = lv_file_format
      exportsection = lv_export_section
      content       = ls_result-content
      mimetype      = lv_final_mimetype
      filename      = lv_final_filename
    ) TO lt_export.

    DATA(lo_paging) = io_request->get_paging( ).

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_export ) ).
    ENDIF.

    IF io_request->is_data_requested( ).

      DATA(lv_offset) = lo_paging->get_offset( ).

      " lt_export luôn có tối đa 1 dòng (mỗi request sinh đúng 1 file),
      " nên chỉ cần: nếu offset đã vượt quá số dòng có thì trả rỗng,
      " ngược lại trả nguyên dòng đó. Không cần cắt trang phức tạp.
      IF lv_offset >= lines( lt_export ).
        CLEAR lt_export.
      ENDIF.

      io_response->set_data( lt_export ).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
