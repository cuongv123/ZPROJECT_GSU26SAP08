REPORT zmig_test_query_filter.

DATA(lv_now)     = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) ).
DATA(lv_expired) = cl_abap_tstmp=>add( tstmp = lv_now secs = -3600 ).
DATA(lv_valid)   = cl_abap_tstmp=>add( tstmp = lv_now secs = 3600 ).

DATA(lv_expired_id) = cl_system_uuid=>create_uuid_x16_static( ).
DATA(lv_valid_id)   = cl_system_uuid=>create_uuid_x16_static( ).

DATA(lv_dummy_content) = cl_abap_conv_codepage=>create_out( )->convert( 'test' ).

INSERT zmig_exp_job FROM TABLE @( VALUE #(
  ( client = sy-mandt export_id = lv_expired_id analysis_id = cl_system_uuid=>create_uuid_x16_static( )
    file_format = 'PDF' export_section = 'ALL' selected_fields = ''
    status = 'READY' file_name = 'ZTEST_EXPIRED.pdf' mime_type = 'application/pdf'
    content = lv_dummy_content message = 'test expired'
    created_by = sy-uname created_at = lv_now expires_at = lv_expired )
  ( client = sy-mandt export_id = lv_valid_id analysis_id = cl_system_uuid=>create_uuid_x16_static( )
    file_format = 'PDF' export_section = 'ALL' selected_fields = ''
    status = 'READY' file_name = 'ZTEST_VALID.pdf' mime_type = 'application/pdf'
    content = lv_dummy_content message = 'test valid'
    created_by = sy-uname created_at = lv_now expires_at = lv_valid )
) ).

WRITE: / 'Da tao 2 record test:'.
WRITE: / '  Het han:', lv_expired_id.
WRITE: / '  Con han:', lv_valid_id.
WRITE: / ''.

READ ENTITIES OF zi_mig_exp_job
  ENTITY ExportJob
  FIELDS ( FileName )
  WITH VALUE #( ( ExportId = lv_expired_id ) ( ExportId = lv_valid_id ) )
  RESULT DATA(lt_result)
  FAILED DATA(lt_failed).

WRITE: / 'So record doc duoc qua RAP (mong doi = 1):', lines( lt_result ).

IF line_exists( lt_result[ ExportId = lv_expired_id ] ).
  WRITE: / 'FAIL: Job HET HAN van doc duoc - filter CHUA hoat dong.'.
ELSE.
  WRITE: / 'OK: Job het han bi loai dung nhu mong doi.'.
ENDIF.

IF line_exists( lt_result[ ExportId = lv_valid_id ] ).
  WRITE: / 'OK: Job con han doc duoc binh thuong.'.
ELSE.
  WRITE: / 'FAIL: Job con han lai KHONG doc duoc.'.
ENDIF.

DELETE FROM zmig_exp_job WHERE export_id = @lv_expired_id OR export_id = @lv_valid_id.
WRITE: / ''.
WRITE: / 'Da xoa 2 record test.'.
