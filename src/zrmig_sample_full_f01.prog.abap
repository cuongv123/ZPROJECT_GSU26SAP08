
FORM validate_input.

  IF p_bukrs IS INITIAL.

    MESSAGE 'Company code is required'
      TYPE 'E'.

  ENDIF.

ENDFORM.


FORM load_data.

  CLEAR gt_result.

  SELECT
    t001~bukrs,
    t001~butxt,
    t001w~werks
    FROM t001
    INNER JOIN t001k
      ON t001k~bukrs = t001~bukrs
    INNER JOIN t001w
      ON t001w~bwkey = t001k~bwkey
    WHERE t001~bukrs = @p_bukrs
      AND t001w~werks IN @s_werks
    INTO TABLE @gt_result.

ENDFORM.


FORM process_data.

  lcl_worker=>enrich_static(
    CHANGING
      ct_result = gt_result
  ).

  DATA(lo_worker) =
    NEW lcl_worker( ).

  lo_worker->calculate(
    CHANGING
      ct_result = gt_result
  ).


  DATA lt_dfies
    TYPE STANDARD TABLE OF dfies
    WITH EMPTY KEY.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname   = 'T001'
    TABLES
      dfies_tab = lt_dfies
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.


  DATA ls_address TYPE bapiaddr3.

  DATA lt_return
    TYPE STANDARD TABLE OF bapiret2
    WITH EMPTY KEY.

  CALL FUNCTION 'BAPI_USER_GET_DETAIL'
    EXPORTING
      username = sy-uname
    IMPORTING
      address  = ls_address
    TABLES
      return   = lt_return.


  IF p_commit = abap_true.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.

  ENDIF.

ENDFORM.


FORM build_fieldcat.

  CLEAR gt_fcat.

  DATA ls_fcat TYPE lvc_s_fcat.


  CLEAR ls_fcat.

  ls_fcat-fieldname = 'BUKRS'.
  ls_fcat-coltext   = 'Company Code'.
  ls_fcat-col_pos   = 1.
  ls_fcat-key       = abap_true.

  APPEND ls_fcat
    TO gt_fcat.


  CLEAR ls_fcat.

  ls_fcat-fieldname = 'BUTXT'.
  ls_fcat-coltext   = 'Company Name'.
  ls_fcat-col_pos   = 2.

  APPEND ls_fcat
    TO gt_fcat.


  CLEAR ls_fcat.

  ls_fcat-fieldname = 'WERKS'.
  ls_fcat-coltext   = 'Plant'.
  ls_fcat-col_pos   = 3.

  APPEND ls_fcat
    TO gt_fcat.

ENDFORM.


FORM build_sort.

  CLEAR gt_sort.

  DATA ls_sort TYPE lvc_s_sort.

  CLEAR ls_sort.

  ls_sort-fieldname = 'BUKRS'.
  ls_sort-spos      = 1.
  ls_sort-up        = abap_true.

  APPEND ls_sort
    TO gt_sort.

ENDFORM.


FORM build_filter.

  CLEAR gt_filter.

  DATA ls_filter TYPE lvc_s_filt.

  CLEAR ls_filter.

  ls_filter-fieldname = 'BUKRS'.
  ls_filter-sign      = 'I'.
  ls_filter-option    = 'EQ'.
  ls_filter-low       = p_bukrs.

  APPEND ls_filter
    TO gt_filter.

ENDFORM.


FORM display_data.

  PERFORM build_fieldcat.
  PERFORM build_sort.
  PERFORM build_filter.


  gs_layout-zebra      = abap_true.
  gs_layout-cwidth_opt = abap_true.
  gs_layout-edit       = abap_false.
  gs_layout-sel_mode   = 'A'.

  gs_variant-report =
    sy-repid.


  IF go_container IS NOT BOUND.

    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_ALV'.

  ENDIF.


  IF go_grid IS NOT BOUND.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_container.

  ENDIF.


  IF go_handler IS NOT BOUND.

    CREATE OBJECT go_handler.

    SET HANDLER
      go_handler->handle_double_click
      FOR go_grid.

  ENDIF.


  go_grid->set_table_for_first_display(
    EXPORTING
      is_layout       = gs_layout
      is_variant      = gs_variant
      i_save          = 'A'
    CHANGING
      it_outtab       = gt_result
      it_fieldcatalog = gt_fcat
      it_sort         = gt_sort
      it_filter       = gt_filter
  ).

ENDFORM.
