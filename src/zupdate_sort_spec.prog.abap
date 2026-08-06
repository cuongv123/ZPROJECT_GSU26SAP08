*&---------------------------------------------------------------------*
*& Report zupdate_sort_spec
*& Chạy 1 lần để điền SORT_SPEC cho section RECOMMEN
*&---------------------------------------------------------------------*
REPORT zupdate_sort_spec.

UPDATE ztb_exp_section
  SET sort_spec = 'TARGET_LAYER:D,SEVERITY:A'
  WHERE section_code = 'RECOMMEN'.

IF sy-subrc = 0.
  COMMIT WORK.
  WRITE: / 'Cap nhat SORT_SPEC cho RECOMMEN thanh cong.'.
ELSE.
  ROLLBACK WORK.
  WRITE: / 'Khong tim thay dong RECOMMEN de cap nhat.'.
ENDIF.
