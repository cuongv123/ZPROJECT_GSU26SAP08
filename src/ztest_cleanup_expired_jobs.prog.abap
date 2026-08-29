REPORT ztest_cleanup_expired_jobs.

DATA(lv_now) = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) ).
DATA(lv_expires_past)   = cl_abap_tstmp=>add( tstmp = lv_now secs = -3600 ).
DATA(lv_expires_future) = cl_abap_tstmp=>add( tstmp = lv_now secs = 3600 ).

DATA(lv_expired_id) = cl_system_uuid=>create_uuid_x16_static( ).
DATA(lv_valid_id)   = cl_system_uuid=>create_uuid_x16_static( ).

INSERT zmig_exp_job FROM TABLE @( VALUE #(
  ( export_id = lv_expired_id file_format = 'C' status = 'READY'
    created_by = sy-uname created_at = lv_now expires_at = lv_expires_past )
  ( export_id = lv_valid_id file_format = 'C' status = 'READY'
    created_by = sy-uname created_at = lv_now expires_at = lv_expires_future )
) ).

IF sy-subrc = 0.
  WRITE: / 'Da tao 2 record test.'.
  WRITE: / 'EXPIRED_ID (se bi xoa):', lv_expired_id.
  WRITE: / 'VALID_ID (khong duoc xoa):', lv_valid_id.
ELSE.
  WRITE: / 'Insert that bai, sy-subrc =', sy-subrc.
ENDIF.
