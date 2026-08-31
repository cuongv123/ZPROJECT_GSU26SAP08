REPORT ztest_make_expired_job.

DATA(lv_now)     = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) ).
DATA(lv_expired) = cl_abap_tstmp=>add( tstmp = lv_now secs = -3600 ).
DATA(lv_export_id) = cl_system_uuid=>create_uuid_x16_static( ).
DATA(lv_dummy_content) = cl_abap_conv_codepage=>create_out( )->convert( 'test' ).

INSERT zmig_exp_job FROM @( VALUE #(
  client = sy-mandt export_id = lv_export_id
  analysis_id = cl_system_uuid=>create_uuid_x16_static( )
  file_format = 'P' export_section = 'ALL' selected_fields = ''
  status = 'READY' file_name = 'ZTEST_EXPIRED_FOR_POSTMAN.pdf' mime_type = 'application/pdf'
  content = lv_dummy_content message = 'test expired cho postman'
  created_by = sy-uname created_at = lv_now expires_at = lv_expired
) ).

WRITE: / 'Da tao job HET HAN, ExportId (dang GUID co gach ngang):'.
DATA(lv_hex) = |{ lv_export_id }|.
WRITE: / to_lower( |{ lv_hex(8) }-{ lv_hex+8(4) }-{ lv_hex+12(4) }-{ lv_hex+16(4) }-{ lv_hex+20(12) }| ).
