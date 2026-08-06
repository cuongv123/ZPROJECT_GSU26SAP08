REPORT zinit_exp_col.

DATA lt_col TYPE TABLE OF ztb_exp_col.

" Nạp danh sách cột mẫu đã chuẩn hóa tên Technical Field
lt_col = VALUE #(
  " Sheet Overview
  ( section_code = 'OVERVIEW'   seq_no = 10 fieldname = 'ANALYSIS_ID'   column_title = 'Analysis ID' )
  ( section_code = 'OVERVIEW'   seq_no = 20 fieldname = 'PROGRAM_NAME'  column_title = 'Program Name' )

  " Sheet Database Objects (Đã sửa OBJECT -> DB_OBJECT_NAME)
  ( section_code = 'DB_OBJ'     seq_no = 10 fieldname = 'DB_OBJECT_NAME' column_title = 'Object Name' )
  ( section_code = 'DB_OBJ'     seq_no = 20 fieldname = 'OBJECT_TYPE'    column_title = 'Object Type' )

  " Sheet Source Evidences (Đã sửa STATEMENT -> STATEMENT_TEXT)
  ( section_code = 'SRC_EVIDEN' seq_no = 10 fieldname = 'STATEMENT_TEXT' column_title = 'SQL Statement' )
  ( section_code = 'SRC_EVIDEN' seq_no = 20 fieldname = 'LINE_NO'        column_title = 'Line Number' )

  " Sheet Recommendations (Đã sửa RECOMMENDATION -> RECOMMENDATION_TEXT)
  ( section_code = 'RECOMMEN'   seq_no = 10 fieldname = 'RECOMMENDATION_TEXT' column_title = 'Recommendation' )
).

MODIFY ztb_exp_col FROM TABLE @lt_col.

IF sy-subrc = 0.
  WRITE: / '✅ Đã chuẩn hóa bảng ZTB_EXP_COL thành công!'.
ENDIF.
