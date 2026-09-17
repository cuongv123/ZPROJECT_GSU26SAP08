REPORT zrmig_reset_svc_test.

PARAMETERS:
  p_srv  TYPE c LENGTH 30
    DEFAULT 'ZUI_MIG_ZRMIG_SAMPLE_FM_ALV',
  p_conf AS CHECKBOX DEFAULT abap_false.

START-OF-SELECTION.

  IF p_conf <> abap_true.
    MESSAGE 'Select confirmation before deleting registry data.'
      TYPE 'E'.
  ENDIF.

  DELETE FROM zmig_svc_reg
    WHERE binding_name = 'ZUI_MIG_SHARED_O4'
      AND service_name = @p_srv.

  DATA(lv_deleted) = sy-dbcnt.

  COMMIT WORK AND WAIT.

  WRITE:
    / 'Deleted registry rows:', lv_deleted,
    / 'Binding:', 'ZUI_MIG_SHARED_O4',
    / 'Service:', p_srv.
