REPORT zmig_test_prepare_pdf_hf.

SELECT SINGLE analysis_id FROM zmig_anl_h INTO @DATA(lv_analysis_id).

IF sy-subrc <> 0.
  WRITE: / 'Khong tim thay Analysis nao trong zmig_anl_h de test.'.
  RETURN.
ENDIF.

MODIFY ENTITIES OF zi_mig_analysis
  ENTITY Analysis
  EXECUTE PrepareSelectedExport
  FROM VALUE #( ( AnalysisId = lv_analysis_id
                   %param = VALUE #( FileFormat     = 'PDF'
                                      ExportSection  = 'ALL'
                                      SelectedFields = ''
                                      PdfHeaderText  = 'TIEU DE TUY CHINH'
                                      PdfFooterText  = 'FOOTER TUY CHINH' ) ) )
  RESULT DATA(lt_result)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).

COMMIT ENTITIES.

IF ls_failed-analysis IS NOT INITIAL.
  WRITE: / '❌ Action FAILED.'.
  LOOP AT ls_reported-analysis INTO DATA(ls_msg).
        WRITE: / ls_msg-%msg->if_message~get_text( ).
  ENDLOOP.
ELSE.
  WRITE: / '✅ Action thanh cong cho AnalysisId:', lv_analysis_id.
ENDIF.

SELECT file_name, content, message, created_at
  FROM zmig_exp_job
  WHERE analysis_id = @lv_analysis_id
  ORDER BY created_at DESCENDING
  INTO TABLE @DATA(lt_jobs)
  UP TO 1 ROWS.

LOOP AT lt_jobs INTO DATA(ls_job).
  DATA(lv_len) = xstrlen( ls_job-content ).
  WRITE: / 'File:', ls_job-file_name, '| Size:', lv_len, 'bytes | Msg:', ls_job-message.
ENDLOOP.
