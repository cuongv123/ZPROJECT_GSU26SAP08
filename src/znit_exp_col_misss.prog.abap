REPORT zfix_exp_col_paging.

UPDATE ztb_exp_col
   SET fieldname      = 'PAGING_CAPABILITY'
       odata_property  = 'PagingCapability'
 WHERE section_code = 'DB_OBJ'
   AND seq_no       = 70.

IF sy-subrc = 0.
  WRITE: / '✅ Đã sửa DB_OBJ/0070: PAGING -> PAGING_CAPABILITY'.
ELSE.
  WRITE: / '❌ Không tìm thấy record để sửa (kiểm tra lại section_code/seq_no).'.
ENDIF.
