CLASS lhc_ReportHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ReportHeader RESULT result.

    METHODS analyzeAndSave FOR MODIFY
      IMPORTING keys FOR ACTION ReportHeader~analyzeAndSave RESULT result.

    METHODS exportToExcel FOR MODIFY
      IMPORTING keys FOR ACTION ReportHeader~exportToExcel RESULT result.

ENDCLASS.

CLASS lhc_ReportHeader IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  " XỬ LÝ CHO INSTANCE ACTION
  METHOD exportToExcel.
    " Chuẩn hóa việc trả về tham số %param cho Action $self
    READ ENTITIES OF zi_mig_report_hd IN LOCAL MODE
      ENTITY ReportHeader
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    LOOP AT lt_headers INTO DATA(ls_header).
      APPEND VALUE #( %tky   = ls_header-%tky
                      %param = ls_header ) TO result.
    ENDLOOP.
  ENDMETHOD.

 METHOD analyzeAndSave.

  DATA(lo_analysis_service) =
    NEW zcl_mig_analysis_service( ).

  LOOP AT keys INTO DATA(ls_key).

    TRY.

        DATA(ls_analysis) =
          lo_analysis_service->zif_mig_analysis_service~analyze(
            iv_program = ls_key-%param-iv_program_name
          ).

      CATCH zcx_mig_analysis INTO DATA(lx_analysis).

        APPEND VALUE #(
          %cid        = ls_key-%cid
          %fail-cause = if_abap_behv=>cause-unspecific
        ) TO failed-reportheader.

        APPEND VALUE #(
          %cid = ls_key-%cid
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = lx_analysis->error_text
          )
        ) TO reported-reportheader.

    ENDTRY.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
