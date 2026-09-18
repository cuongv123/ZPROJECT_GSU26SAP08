*&---------------------------------------------------------------------*
*& Report ZTEST_ROLLBACK_EXP_COL_EXTRA_FIXES
*&---------------------------------------------------------------------*
*& Muc dich: HOAN TAC 3 thay doi da COMMIT that vao DB truoc do (ngay
*& 18/09), doc lap voi ZTEST_FIX_EXP_COL_TITLES (report do chi con lai
*& phan sua 13 COLUMN_TITLE, van giu nguyen khong doi):
*&
*&  (A) INSERT lai 7 dong field ky thuat da bi XOA khoi ZTB_EXP_COL
*&      (EvidenceId x4, LayoutEvidenceId, RuleId, SourceItemId).
*&      Gia tri SEQ_NO/ODATA_PROPERTY/COLUMN_TITLE lay DUNG NGUYEN BAN
*&      tu 2 report da tao ra cac dong nay trong git (khong doan):
*&        - ztest_add_missing_cols_final.prog.abap (6/7 dong)
*&        - zinit_exp_col_miss.prog.abap            (RECOMMEN/RULE_ID)
*&
*&  (B) XOA dong MESSAGE.MESSAGE_NO (cot "No") vua INSERT them - vi
*&      dong nay khong hoat dong dung (khong ra du lieu khi export) va
*&      nam trong danh sach can hoan tac theo yeu cau.
*&
*&  (C) UPDATE lai ZTB_EXP_SECTION.SHEET_TITLE cua SRC_EVIDEN ve gia
*&      tri cu 'Source Evidences' (truoc do da doi thanh 'Evidences').
*&
*& Idempotent: chay lai nhieu lan an toan, dong da dung trang thai cu
*& roi se bao [SKIP], khong bao loi. Chay o che do TEST truoc (mac
*& dinh), xem log, roi bo tick P_TEST de commit that.
*&---------------------------------------------------------------------*
REPORT ztest_rollback_exp_col_extra.

PARAMETERS: p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_true.

DATA: lt_log TYPE STANDARD TABLE OF string.

DATA: lt_restore TYPE STANDARD TABLE OF ztb_exp_col WITH EMPTY KEY.

START-OF-SELECTION.

  "-----------------------------------------------------------------
  " (A) INSERT LAI 7 dong field ky thuat da bi xoa (nguyen ban tu git)
  "-----------------------------------------------------------------
  lt_restore = VALUE #(
    ( mandt = sy-mandt section_code = 'UI_FILTER'  seq_no = '9010' fieldname = 'EVIDENCE_ID'        odata_property = 'EvidenceId'       column_title = 'Evidence ID' )
    ( mandt = sy-mandt section_code = 'DB_OBJ'     seq_no = '9040' fieldname = 'EVIDENCE_ID'        odata_property = 'EvidenceId'       column_title = 'Evidence ID' )
    ( mandt = sy-mandt section_code = 'ALV_OUTPUT' seq_no = '9020' fieldname = 'EVIDENCE_ID'        odata_property = 'EvidenceId'       column_title = 'Evidence ID' )
    ( mandt = sy-mandt section_code = 'ALV_OUTPUT' seq_no = '9030' fieldname = 'LAYOUT_EVIDENCE_ID' odata_property = 'LayoutEvidenceId' column_title = 'Layout Evidence ID' )
    ( mandt = sy-mandt section_code = 'RECOMMEN'   seq_no = '9010' fieldname = 'EVIDENCE_ID'        odata_property = 'EvidenceId'       column_title = 'Evidence ID' )
    ( mandt = sy-mandt section_code = 'RECOMMEN'   seq_no = '9020' fieldname = 'SOURCE_ITEM_ID'     odata_property = 'SourceItemId'     column_title = 'Source Item ID' )
    ( mandt = sy-mandt section_code = 'RECOMMEN'   seq_no = '0070' fieldname = 'RULE_ID'            odata_property = 'RuleId'           column_title = 'Rule ID' )
  ).

  LOOP AT lt_restore INTO DATA(ls_restore).

    SELECT SINGLE fieldname
      FROM ztb_exp_col
      WHERE section_code = @ls_restore-section_code
        AND fieldname    = @ls_restore-fieldname
      INTO @DATA(lv_exists).

    IF sy-subrc = 0.
      APPEND |[SKIP] { ls_restore-section_code }-{ ls_restore-fieldname }: da ton tai san, khong them lai| TO lt_log.
      CONTINUE.
    ENDIF.

    IF p_test = abap_true.
      APPEND |[TEST] { ls_restore-section_code }-{ ls_restore-fieldname }: se INSERT lai (SEQ_NO={ ls_restore-seq_no }, ODATA_PROPERTY={ ls_restore-odata_property }, COLUMN_TITLE='{ ls_restore-column_title }') - chua ghi| TO lt_log.
    ELSE.
      INSERT ztb_exp_col FROM ls_restore.
      IF sy-subrc = 0.
        APPEND |[OK]   { ls_restore-section_code }-{ ls_restore-fieldname }: da INSERT lai (SEQ_NO={ ls_restore-seq_no })| TO lt_log.
      ELSE.
        APPEND |[FAIL] { ls_restore-section_code }-{ ls_restore-fieldname }: INSERT that bai (co the trung khoa SECTION_CODE+SEQ_NO - kiem tra lai)| TO lt_log.
      ENDIF.
    ENDIF.

  ENDLOOP.

  "-----------------------------------------------------------------
  " (B) XOA dong MESSAGE.MESSAGE_NO vua them (khong hoat dong dung)
  "-----------------------------------------------------------------
  SELECT SINGLE fieldname
    FROM ztb_exp_col
    WHERE section_code = 'MESSAGE'
      AND fieldname    = 'MESSAGE_NO'
    INTO @DATA(lv_no_exists).

  IF sy-subrc <> 0.
    APPEND `[SKIP] MESSAGE-MESSAGE_NO: khong ton tai (co the da xoa tu truoc), khong can xoa lai` TO lt_log.
  ELSE.
    IF p_test = abap_true.
      APPEND `[TEST] MESSAGE-MESSAGE_NO: se DELETE khoi ZTB_EXP_COL (chua ghi)` TO lt_log.
    ELSE.
      DELETE FROM ztb_exp_col
        WHERE section_code = 'MESSAGE'
          AND fieldname    = 'MESSAGE_NO'.
      IF sy-subrc = 0.
        APPEND `[OK]   MESSAGE-MESSAGE_NO: da xoa khoi ZTB_EXP_COL` TO lt_log.
      ELSE.
        APPEND `[FAIL] MESSAGE-MESSAGE_NO: DELETE that bai` TO lt_log.
      ENDIF.
    ENDIF.
  ENDIF.

  "-----------------------------------------------------------------
  " (C) Doi ten hien thi section SRC_EVIDEN ve lai "Source Evidences"
  "-----------------------------------------------------------------
  SELECT SINGLE sheet_title
    FROM ztb_exp_section
    WHERE section_code = 'SRC_EVIDEN'
    INTO @DATA(lv_current_sheet_title).

  IF sy-subrc <> 0.
    APPEND `[SKIP] SRC_EVIDEN (ZTB_EXP_SECTION): khong tim thay dong` TO lt_log.
  ELSEIF lv_current_sheet_title = 'Source Evidences'.
    APPEND `[SKIP] SRC_EVIDEN: SHEET_TITLE da la 'Source Evidences' tu truoc, khong can sua` TO lt_log.
  ELSE.
    IF p_test = abap_true.
      APPEND |[TEST] SRC_EVIDEN: '{ lv_current_sheet_title }' -> 'Source Evidences' (chua ghi)| TO lt_log.
    ELSE.
      UPDATE ztb_exp_section
        SET sheet_title = 'Source Evidences'
        WHERE section_code = 'SRC_EVIDEN'.
      IF sy-subrc = 0.
        APPEND |[OK]   SRC_EVIDEN: '{ lv_current_sheet_title }' -> 'Source Evidences'| TO lt_log.
      ELSE.
        APPEND `[FAIL] SRC_EVIDEN: UPDATE ZTB_EXP_SECTION that bai` TO lt_log.
      ENDIF.
    ENDIF.
  ENDIF.

  IF p_test = abap_false.
    COMMIT WORK AND WAIT.
  ENDIF.

  cl_demo_output=>display( lt_log ).

  IF p_test = abap_true.
    cl_demo_output=>display( |Dang o che do TEST ONLY - chua ghi gi vao DB. Bo tick "Test only" (P_TEST) roi chay lai de commit that.| ).
  ELSE.
    cl_demo_output=>display( |Da COMMIT xong. ZTB_EXP_COL/ZTB_EXP_SECTION da quay ve dung trang thai truoc khi chay Phan 2/3/4 cua ZTEST_FIX_EXP_COL_TITLES (chi con giu lai 13 COLUMN_TITLE da sua o Phan 1).| ).
  ENDIF.
