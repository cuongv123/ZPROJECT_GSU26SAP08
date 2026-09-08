REPORT zrmig_sample_bapi_alv.


DATA gs_headerdata TYPE bapi_epm_product_header.


SELECT-OPTIONS s_prodid
  FOR gs_headerdata-product_id.


DATA:
  gt_headerdata TYPE STANDARD TABLE OF bapi_epm_product_header
    WITH DEFAULT KEY,
  gt_return     TYPE STANDARD TABLE OF bapiret2
    WITH DEFAULT KEY,
  gt_fcat       TYPE lvc_t_fcat,
  gs_fcat       TYPE lvc_s_fcat.


START-OF-SELECTION.

  CALL FUNCTION 'BAPI_EPM_PRODUCT_GET_LIST'
    TABLES
      headerdata        = gt_headerdata
      selparamproductid = s_prodid
      return            = gt_return.


  LOOP AT gt_return
    INTO DATA(gs_return)
    WHERE type CA 'AEX'.

    MESSAGE gs_return-message
      TYPE 'S'
      DISPLAY LIKE 'E'.

    RETURN.

  ENDLOOP.


  CLEAR gs_fcat.
  gs_fcat-fieldname = 'PRODUCT_ID'.
  gs_fcat-coltext   = 'Product ID'.
  gs_fcat-col_pos   = 1.
  gs_fcat-key       = abap_true.
  gs_fcat-datatype  = 'CHAR'.
  gs_fcat-outputlen = 10.
  APPEND gs_fcat TO gt_fcat.


  CLEAR gs_fcat.
  gs_fcat-fieldname = 'NAME'.
  gs_fcat-coltext   = 'Product Name'.
  gs_fcat-col_pos   = 2.
  gs_fcat-datatype  = 'CHAR'.
  gs_fcat-outputlen = 40.
  APPEND gs_fcat TO gt_fcat.


  CLEAR gs_fcat.
  gs_fcat-fieldname = 'CATEGORY'.
  gs_fcat-coltext   = 'Category'.
  gs_fcat-col_pos   = 3.
  gs_fcat-datatype  = 'CHAR'.
  gs_fcat-outputlen = 40.
  APPEND gs_fcat TO gt_fcat.


  CLEAR gs_fcat.
  gs_fcat-fieldname = 'SUPPLIER_NAME'.
  gs_fcat-coltext   = 'Supplier Name'.
  gs_fcat-col_pos   = 4.
  gs_fcat-datatype  = 'CHAR'.
  gs_fcat-outputlen = 40.
  APPEND gs_fcat TO gt_fcat.


  CLEAR gs_fcat.
  gs_fcat-fieldname = 'CURRENCY_CODE'.
  gs_fcat-coltext   = 'Currency'.
  gs_fcat-col_pos   = 5.
  gs_fcat-datatype  = 'CUKY'.
  gs_fcat-outputlen = 5.
  APPEND gs_fcat TO gt_fcat.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program = sy-repid
      it_fieldcat_lvc    = gt_fcat
    TABLES
      t_outtab           = gt_headerdata
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.

    MESSAGE 'Unable to display the read-only BAPI sample ALV.'
      TYPE 'S'
      DISPLAY LIKE 'E'.

  ENDIF.
