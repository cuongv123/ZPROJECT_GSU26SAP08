REPORT ztest_add_missing_cols_final.

" Bo sung 12 field dang thieu trong ZTB_EXP_COL, phat hien qua doi chieu
" voi cau truc bang goc (zmig_anl_ui/db/log/alv/rec) va man hinh View
" Settings that cua UI5 app. Dung seq_no cao (9010+) de chac chan khong
" trung voi cac dong hien co - cot moi se hien o cuoi danh sach cot cua
" tung section, khong anh huong thu tu cac cot dang co.

DATA: lt_new_cols TYPE STANDARD TABLE OF ztb_exp_col WITH EMPTY KEY.

lt_new_cols = VALUE #(
  ( mandt = sy-mandt section_code = 'UI_FILTER'  seq_no = '9010' fieldname = 'EVIDENCE_ID'         odata_property = 'EvidenceId'        column_title = 'Evidence ID' )

  ( mandt = sy-mandt section_code = 'DB_OBJ'     seq_no = '9010' fieldname = 'RESULT_TARGET'       odata_property = 'ResultTarget'      column_title = 'Result Target' )
  ( mandt = sy-mandt section_code = 'DB_OBJ'     seq_no = '9020' fieldname = 'EXECUTION_KIND'      odata_property = 'ExecutionKind'     column_title = 'Execution Kind' )
  ( mandt = sy-mandt section_code = 'DB_OBJ'     seq_no = '9030' fieldname = 'EXECUTION_CONTEXT'   odata_property = 'ExecutionContext'  column_title = 'Execution Context' )
  ( mandt = sy-mandt section_code = 'DB_OBJ'     seq_no = '9040' fieldname = 'EVIDENCE_ID'         odata_property = 'EvidenceId'        column_title = 'Evidence ID' )

  ( mandt = sy-mandt section_code = 'BUS_LOGIC'  seq_no = '9010' fieldname = 'EXECUTION_KIND'      odata_property = 'ExecutionKind'     column_title = 'Execution Kind' )
  ( mandt = sy-mandt section_code = 'BUS_LOGIC'  seq_no = '9020' fieldname = 'EXECUTION_CONTEXT'   odata_property = 'ExecutionContext'  column_title = 'Execution Context' )

  ( mandt = sy-mandt section_code = 'ALV_OUTPUT' seq_no = '9010' fieldname = 'CONTAINING_ROUTINE'  odata_property = 'ContainingRoutine' column_title = 'Containing Routine' )
  ( mandt = sy-mandt section_code = 'ALV_OUTPUT' seq_no = '9020' fieldname = 'EVIDENCE_ID'         odata_property = 'EvidenceId'        column_title = 'Evidence ID' )
  ( mandt = sy-mandt section_code = 'ALV_OUTPUT' seq_no = '9030' fieldname = 'LAYOUT_EVIDENCE_ID'  odata_property = 'LayoutEvidenceId'  column_title = 'Layout Evidence ID' )

  ( mandt = sy-mandt section_code = 'RECOMMEN'   seq_no = '9010' fieldname = 'EVIDENCE_ID'         odata_property = 'EvidenceId'        column_title = 'Evidence ID' )
  ( mandt = sy-mandt section_code = 'RECOMMEN'   seq_no = '9020' fieldname = 'SOURCE_ITEM_ID'      odata_property = 'SourceItemId'      column_title = 'Source Item ID' )
).

INSERT ztb_exp_col FROM TABLE @lt_new_cols.

IF sy-subrc = 0.
  COMMIT WORK AND WAIT.
  WRITE: / 'Da them', lines( lt_new_cols ), 'dong moi vao ZTB_EXP_COL thanh cong.'.
  SKIP.
  LOOP AT lt_new_cols INTO DATA(ls_row).
    WRITE: / ls_row-section_code, ls_row-fieldname, '->', ls_row-odata_property, '(', ls_row-column_title, ')'.
  ENDLOOP.
ELSE.
  ROLLBACK WORK.
  WRITE: / 'INSERT that bai, sy-subrc =', sy-subrc.
ENDIF.
