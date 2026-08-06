REPORT zrmig_test_r1_alv_coverage.

TABLES t001.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

SELECT-OPTIONS:
  s_bukrs FOR t001-bukrs.

PARAMETERS:
  p_max   TYPE i DEFAULT 20 OBLIGATORY,
  p_grid  RADIOBUTTON GROUP dsp DEFAULT 'X',
  p_salv  RADIOBUTTON GROUP dsp,
  p_note  TYPE char20 DEFAULT 'R1_TEST' LOWER CASE.

SELECTION-SCREEN END OF BLOCK b1.

TYPES:
  BEGIN OF ty_result,
    bukrs     TYPE t001-bukrs,
    bukrs_ext TYPE char10,
    butxt     TYPE t001-butxt,
    ort01     TYPE t001-ort01,
    waers     TYPE t001-waers,
    status    TYPE char10,
  END OF ty_result,

  tt_result TYPE STANDARD TABLE OF ty_result
    WITH EMPTY KEY.

DATA:
  gt_result   TYPE tt_result,
  gt_fieldcat TYPE lvc_t_fcat,
  gs_fieldcat TYPE lvc_s_fcat,
  gt_sort     TYPE lvc_t_sort,
  gs_sort     TYPE lvc_s_sort,
  gs_layout   TYPE lvc_s_layo,
  gs_variant  TYPE disvariant.

AT SELECTION-SCREEN.

  IF p_max <= 0.
    MESSAGE 'Maximum rows must be greater than zero' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.

  PERFORM select_data.

  IF gt_result IS INITIAL.
    MESSAGE 'No company code data was found'
      TYPE 'S'
      DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM enrich_first_row.

  IF p_grid = abap_true.
    PERFORM build_field_catalog.
    PERFORM build_sort.
    PERFORM build_layout.
    PERFORM display_grid.
  ELSEIF p_salv = abap_true.
    PERFORM display_salv.
  ENDIF.

FORM select_data.

  CLEAR gt_result.

  SELECT
    bukrs,
    butxt,
    ort01,
    waers
    FROM t001
    WHERE bukrs IN @s_bukrs
    ORDER BY PRIMARY KEY
    INTO CORRESPONDING FIELDS OF TABLE @gt_result
    UP TO @p_max ROWS.

  LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<result>).
    IF <result>-waers IS INITIAL.
      <result>-status = 'CHECK'.
    ELSE.
      <result>-status = 'READY'.
    ENDIF.
  ENDLOOP.

ENDFORM.

FORM enrich_first_row.

  READ TABLE gt_result
    ASSIGNING FIELD-SYMBOL(<first_result>)
    INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      input  = <first_result>-bukrs
    IMPORTING
      output = <first_result>-bukrs_ext.

ENDFORM.

FORM build_field_catalog.

  CLEAR gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'BUKRS'.
  gs_fieldcat-coltext = 'Company Code'.
  gs_fieldcat-col_pos = 10.
  gs_fieldcat-key = abap_true.
  gs_fieldcat-ref_table = 'T001'.
  gs_fieldcat-ref_field = 'BUKRS'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'BUKRS_EXT'.
  gs_fieldcat-coltext = 'External Company Code'.
  gs_fieldcat-col_pos = 20.
  gs_fieldcat-datatype = 'CHAR'.
  gs_fieldcat-outputlen = 10.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'BUTXT'.
  gs_fieldcat-coltext = 'Company Name'.
  gs_fieldcat-col_pos = 30.
  gs_fieldcat-ref_table = 'T001'.
  gs_fieldcat-ref_field = 'BUTXT'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'ORT01'.
  gs_fieldcat-coltext = 'City'.
  gs_fieldcat-col_pos = 40.
  gs_fieldcat-ref_table = 'T001'.
  gs_fieldcat-ref_field = 'ORT01'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'WAERS'.
  gs_fieldcat-coltext = 'Currency'.
  gs_fieldcat-col_pos = 50.
  gs_fieldcat-ref_table = 'T001'.
  gs_fieldcat-ref_field = 'WAERS'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'STATUS'.
  gs_fieldcat-coltext = 'Migration Status'.
  gs_fieldcat-col_pos = 60.
  gs_fieldcat-datatype = 'CHAR'.
  gs_fieldcat-outputlen = 10.
  APPEND gs_fieldcat TO gt_fieldcat.

ENDFORM.

FORM build_sort.

  CLEAR gt_sort.

  CLEAR gs_sort.
  gs_sort-spos = 1.
  gs_sort-fieldname = 'BUKRS'.
  gs_sort-up = abap_true.
  gs_sort-subtot = abap_false.
  APPEND gs_sort TO gt_sort.

ENDFORM.

FORM build_layout.

  CLEAR:
    gs_layout,
    gs_variant.

  gs_layout-zebra = abap_true.
  gs_layout-cwidth_opt = abap_true.
  gs_layout-sel_mode = 'A'.

  gs_variant-report = sy-repid.

ENDFORM.

FORM display_grid.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program = sy-repid
      is_layout_lvc      = gs_layout
      it_fieldcat_lvc    = gt_fieldcat
      it_sort_lvc        = gt_sort
      i_save             = 'A'
      is_variant         = gs_variant
    TABLES
      t_outtab            = gt_result
    EXCEPTIONS
      program_error       = 1
      OTHERS              = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Classic ALV Grid could not be displayed'
      TYPE 'S'
      DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.

FORM display_salv.

  TRY.

      DATA:
        lo_salv    TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_funcs   TYPE REF TO cl_salv_functions_list.

      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_salv
        CHANGING
          t_table      = gt_result
      ).

      lo_columns = lo_salv->get_columns( ).
      lo_columns->set_optimize( value = abap_true ).

      lo_funcs = lo_salv->get_functions( ).
      lo_funcs->set_all( value = abap_true ).

      lo_salv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv).

      MESSAGE lx_salv->get_text( )
        TYPE 'S'
        DISPLAY LIKE 'E'.

  ENDTRY.

ENDFORM.
