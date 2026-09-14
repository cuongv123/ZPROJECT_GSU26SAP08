REPORT zrmig_sample_fm_alv.


PARAMETERS p_bukrs TYPE zsmigfmrow-bukrs.


DATA:
  gt_result TYPE ztt_mig_sample_fm_row,
  gt_fcat   TYPE lvc_t_fcat,
  gs_fcat   TYPE lvc_s_fcat.


START-OF-SELECTION.

  CALL FUNCTION 'Z_MIG_SAMPLE_FM_GET_DATA'
    EXPORTING
      iv_bukrs = p_bukrs
    IMPORTING
      et_result = gt_result.


  CLEAR gs_fcat.

  gs_fcat-fieldname = 'BUKRS'.
  gs_fcat-coltext   = 'Company Code'.
  gs_fcat-col_pos   = 1.
  gs_fcat-key       = abap_true.
  gs_fcat-datatype  = 'CHAR'.
  gs_fcat-outputlen = 4.

  APPEND gs_fcat TO gt_fcat.


  CLEAR gs_fcat.

  gs_fcat-fieldname = 'BUTXT'.
  gs_fcat-coltext   = 'Company Name'.
  gs_fcat-col_pos   = 2.
  gs_fcat-datatype  = 'CHAR'.
  gs_fcat-outputlen = 25.

  APPEND gs_fcat TO gt_fcat.


  CLEAR gs_fcat.

  gs_fcat-fieldname = 'WAERS'.
  gs_fcat-coltext   = 'Currency'.
  gs_fcat-col_pos   = 3.
  gs_fcat-datatype  = 'CUKY'.
  gs_fcat-outputlen = 5.

  APPEND gs_fcat TO gt_fcat.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program = sy-repid
      it_fieldcat_lvc    = gt_fcat
    TABLES
      t_outtab           = gt_result
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.

    MESSAGE 'Unable to display the FM read-only sample ALV.'
      TYPE 'S'
      DISPLAY LIKE 'E'.

  ENDIF.
