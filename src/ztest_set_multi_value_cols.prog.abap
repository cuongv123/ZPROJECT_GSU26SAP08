*&---------------------------------------------------------------*
*& Report ZTEST_SET_MULTI_VALUE_COLS
*&---------------------------------------------------------------*
*& Chạy 1 lần sau khi đã thêm 2 field IS_MULTI_VALUE/VALUE_SEPARATOR
*& vào ZTB_EXP_COL (xem hướng dẫn DDIC bên dưới). Đánh dấu đúng 2
*& field đã xác nhận qua research là danh sách giá trị sạch:
*&   - DB_OBJ / SELECTED_FIELDS  -> tách theo dấu CÁCH
*&   - DB_OBJ / JOINED_OBJECTS   -> tách theo dấu PHẨY + cách ", "
*& KHÔNG đánh dấu WHERE_FIELDS/JOIN_CONDITION (là câu điều kiện tái
*& tạo lại, không phải danh sách giá trị - xem thiết kế đã duyệt).
*&---------------------------------------------------------------*
REPORT ztest_set_multi_value_cols.

UPDATE ztb_exp_col
   SET is_multi_value  = abap_true
       value_separator = ' '
 WHERE section_code = 'DB_OBJ'
   AND fieldname     = 'SELECTED_FIELDS'.

IF sy-subrc = 0.
  WRITE: / 'SELECTED_FIELDS: OK, rows updated =', sy-dbcnt.
ELSE.
  WRITE: / 'SELECTED_FIELDS: KHONG tim thay dong nao khop - kiem tra lai section_code/fieldname trong ZTB_EXP_COL.'.
ENDIF.

UPDATE ztb_exp_col
   SET is_multi_value  = abap_true
       value_separator = ', '
 WHERE section_code = 'DB_OBJ'
   AND fieldname     = 'JOINED_OBJECTS'.

IF sy-subrc = 0.
  WRITE: / 'JOINED_OBJECTS: OK, rows updated =', sy-dbcnt.
ELSE.
  WRITE: / 'JOINED_OBJECTS: KHONG tim thay dong nao khop - kiem tra lai section_code/fieldname trong ZTB_EXP_COL.'.
ENDIF.

COMMIT WORK.

WRITE: / 'Done. Kiem tra lai bang SE16/ADT Data Preview de xac nhan 2 dong tren co IS_MULTI_VALUE = X.'.
