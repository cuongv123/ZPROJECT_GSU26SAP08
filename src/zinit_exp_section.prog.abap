REPORT zinit_exp_section.

DATA lt_sec TYPE TABLE OF ztb_exp_section.

lt_sec = VALUE #(
  ( section_code = 'OVERVIEW'   view_name = 'ZMIG_ANL_H'   sheet_title = 'Overview'         sort_order = 10 is_active = 'X' )
  ( section_code = 'SRC_STRUCT' view_name = 'ZMIG_ANL_SRC' sheet_title = 'Source Structure' sort_order = 20 is_active = 'X' )
  ( section_code = 'UI_FILTER'  view_name = 'ZMIG_ANL_UI'  sheet_title = 'UI Filters'       sort_order = 30 is_active = 'X' )
  ( section_code = 'DB_OBJ'     view_name = 'ZMIG_ANL_DB'  sheet_title = 'Database Objects' sort_order = 40 is_active = 'X' )
  ( section_code = 'BUS_LOGIC'  view_name = 'ZMIG_ANL_LOG' sheet_title = 'Business Logic'   sort_order = 50 is_active = 'X' )
  ( section_code = 'ALV_OUTPUT' view_name = 'ZMIG_ANL_ALV' sheet_title = 'ALV Outputs'      sort_order = 60 is_active = 'X' )
  ( section_code = 'SRC_EVIDEN' view_name = 'ZMIG_ANL_EVD' sheet_title = 'Source Evidences' sort_order = 70 is_active = 'X' )
  ( section_code = 'RECOMMEN'   view_name = 'ZMIG_ANL_REC' sheet_title = 'Recommendations'  sort_order = 80 is_active = 'X' )
  ( section_code = 'MESSAGE'    view_name = 'ZMIG_ANL_MSG' sheet_title = 'Messages'         sort_order = 90 is_active = 'X' )
).

" Nạp dữ liệu thẳng vào Database Table
MODIFY ztb_exp_section FROM TABLE @lt_sec.

IF sy-subrc = 0.
  WRITE: / '✅ Đã nạp thành công 9 Sheet vào bảng ZTB_EXP_SECTION!'.
ELSE.
  WRITE: / '❌ Lỗi nạp dữ liệu. Hãy kiểm tra lại bảng ZTB_EXP_SECTION đã Active chưa.'.
ENDIF.
