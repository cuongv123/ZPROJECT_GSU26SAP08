REPORT ztest_fix_selfields_sep.

UPDATE ztb_exp_col
  SET value_separator = ', '
  WHERE section_code = 'DB_OBJ'
    AND fieldname    = 'SELECTED_FIELDS'.

IF sy-subrc = 0.
  WRITE: / 'Da cap nhat value_separator cho SELECTED_FIELDS.'.
ELSE.
  WRITE: / 'Khong tim thay dong nao khop dieu kien - kiem tra lai FIELDNAME.'.
ENDIF.

COMMIT WORK.
