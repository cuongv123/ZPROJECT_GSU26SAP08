REPORT ztest_check_cleanup_result.

DATA(lv_expired_id) = '8B95F36A4F271FE1A8EF2108D2861391'.
DATA(lv_valid_id)   = '8B95F36A4F271FE1A8EF2108D2863391'.

SELECT SINGLE @abap_true FROM zmig_exp_job
  WHERE export_id = @lv_expired_id
  INTO @DATA(lv_expired_still_there).

SELECT SINGLE @abap_true FROM zmig_exp_job
  WHERE export_id = @lv_valid_id
  INTO @DATA(lv_valid_still_there).

WRITE: / 'EXPIRED_ID con trong bang? (phai la KHONG):', COND string( WHEN lv_expired_still_there = abap_true THEN 'CO - SAI!' ELSE 'KHONG - dung' ).
WRITE: / 'VALID_ID con trong bang? (phai la CO):     ', COND string( WHEN lv_valid_still_there = abap_true THEN 'CO - dung' ELSE 'KHONG - SAI!' ).
