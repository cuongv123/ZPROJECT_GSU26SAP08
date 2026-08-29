REPORT zmig_cleanup_expired_jobs.

DATA(lv_now) = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) ).

SELECT COUNT(*) FROM zmig_exp_job WHERE expires_at < @lv_now INTO @DATA(lv_count).

IF lv_count = 0.
  WRITE: / 'Khong co record nao het han can don.'.
ELSE.
  DELETE FROM zmig_exp_job WHERE expires_at < @lv_now.
  IF sy-subrc = 0.
    WRITE: / '✅ Da xoa', lv_count, 'record het han (expires_at nho hon thoi diem hien tai).'.
  ELSE.
    WRITE: / '❌ Xoa that bai (sy-subrc =', sy-subrc, ').'.
  ENDIF.
ENDIF.
