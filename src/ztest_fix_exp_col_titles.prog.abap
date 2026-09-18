*&---------------------------------------------------------------------*
*& Report ZTEST_FIX_EXP_COL_TITLES
*&---------------------------------------------------------------------*
*& Muc dich: dong bo cau hinh cot export (ZTB_EXP_COL) voi UI cockpit
*& SAPUI5 (tu viet, khong phai Fiori Elements) - phat hien qua doi
*& chieu truc tiep dump bang ZTB_EXP_COL vs cac dialog "Choose
*& Columns" tren UI cho tung section.
*&
*& PHAN 1 - sua 13 COLUMN_TITLE bi lech ten so voi UI (chi rut gon/
*& sai tu, khong phai thieu cot). Idempotent: chay lai nhieu lan an
*& toan, dong da sua roi se bao [SKIP] "da dung", khong bao loi.
*&
*& PHAN 2 - them dong con thieu hoan toan: section MESSAGE dang THIEU
*& han cot "No" (ODATA_PROPERTY = MessageNo) - xac nhan day la field
*& that, KEY field cua view entity ZI_MIG_ANL_MSG (khong phai so dong
*& UI tu sinh):
*&   define view entity ZC_MIG_ANL_MSG as projection on ZI_MIG_ANL_MSG {
*&     key AnalysisId, key MessageNo, MessageType, MessageCode,
*&     SourceObject, SourceLine, MessageText, _Analysis : redirected
*&     to parent ZC_MIG_ANALYSIS }
*& => day la INSERT dong cau hinh con thieu (chua tung co trong
*& ZTB_EXP_COL), khong phai UPDATE. Dong moi duoc copy cau truc tu
*& dong MESSAGE_TYPE (de lay dung moi field khac, ke ca ten field
*& "thu tu" ma report nay khong biet truoc ten chinh xac - xu ly
*& dong bang cach thu 1 danh sach ten ung vien qua ASSIGN COMPONENT),
*& dat o cuoi thu tu hien thi (sau MESSAGE_TEXT) de an toan, khong
*& chen giua lam xao tron cac dong khac.
*&
*& Day la fix DU LIEU CAU HINH (khong sua code zcl_mig_export_engine),
*& theo dung tien le da lam voi VALUE_SEPARATOR (xem
*& ZTEST_SET_MULTI_VALUE_COLS / export-module-review.md). LUU Y: sau
*& khi chay xong, PHAI export thu section MESSAGE de xac nhan cot
*& "No" thuc su co gia tri (khong bi trong) - neu trong, nghia la
*& tang du lieu dang doc MESSAGE (o class khac, khong phai
*& zcl_mig_export_engine) chua SELECT them field MessageNo, se can
*& sua code o do, khong chi sua ZTB_EXP_COL.
*&
*& Chay o che do TEST truoc (mac dinh), xem log so sanh truoc/sau,
*& roi doi P_TEST = ' ' (bo tick "Test only") de commit that.
*&---------------------------------------------------------------------*
REPORT ztest_fix_exp_col_titles.

PARAMETERS: p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_true.

TYPES: BEGIN OF ty_fix,
         section_code TYPE ztb_exp_col-section_code,
         fieldname    TYPE ztb_exp_col-fieldname,
         old_title    TYPE ztb_exp_col-column_title,
         new_title    TYPE ztb_exp_col-column_title,
       END OF ty_fix.

TYPES: BEGIN OF ty_fix_key,
         section_code TYPE ztb_exp_col-section_code,
         fieldname    TYPE ztb_exp_col-fieldname,
       END OF ty_fix_key.
TYPES ty_fix_key_tab TYPE STANDARD TABLE OF ty_fix_key WITH EMPTY KEY.

DATA: lt_fix            TYPE STANDARD TABLE OF ty_fix,
      lt_log            TYPE STANDARD TABLE OF string,
      lt_seq_candidates TYPE STANDARD TABLE OF string.

START-OF-SELECTION.

  "-----------------------------------------------------------------
  " PHAN 1: 13 COLUMN_TITLE bi lech ten so voi UI
  "-----------------------------------------------------------------
  " 10 cho: chi la rut gon/thieu chu so voi UI -> sua theo UI.
  " 3 cho con lai (SRC_EVIDEN Start/End, RECOMMEN Title, RECOMMEN
  " Manual Review) da duoc chu du an xac nhan: lay theo UI lam chuan.
  lt_fix = VALUE #(
    ( section_code = 'UI_FILTER'  fieldname = 'FIELD_NAME'         old_title = 'Field'              new_title = 'Field Name' )
    ( section_code = 'UI_FILTER'  fieldname = 'FIELD_KIND'         old_title = 'Kind'               new_title = 'Field Kind' )
    ( section_code = 'DB_OBJ'     fieldname = 'PAGING_CAPABILITY'  old_title = 'Paging'              new_title = 'Paging Capability' )
    ( section_code = 'BUS_LOGIC'  fieldname = 'OBJECT_NAME'        old_title = 'Object'              new_title = 'Object Name' )
    ( section_code = 'BUS_LOGIC'  fieldname = 'OBJECT_TYPE'        old_title = 'Type'                new_title = 'Object Type' )
    ( section_code = 'BUS_LOGIC'  fieldname = 'CONTAINER_NAME'     old_title = 'Container'           new_title = 'Container Name' )
    ( section_code = 'ALV_OUTPUT' fieldname = 'OUTPUT_NAME'        old_title = 'Output'              new_title = 'Output Name' )
    ( section_code = 'ALV_OUTPUT' fieldname = 'OUTPUT_KIND'        old_title = 'Kind'                new_title = 'Output Kind' )
    ( section_code = 'SRC_EVIDEN' fieldname = 'START_LINE'         old_title = 'Start Line'          new_title = 'Start' )
    ( section_code = 'SRC_EVIDEN' fieldname = 'END_LINE'           old_title = 'End Line'            new_title = 'End' )
    ( section_code = 'MESSAGE'    fieldname = 'MESSAGE_CODE'       old_title = 'Code'                new_title = 'Message Code' )
    ( section_code = 'RECOMMEN'   fieldname = 'TITLE'              old_title = 'Recommendation'      new_title = 'Title' )
    ( section_code = 'RECOMMEN'   fieldname = 'MANUAL_REVIEW'      old_title = 'Manual Refactoring'  new_title = 'Manual Review' )
  ).

  LOOP AT lt_fix INTO DATA(ls_fix).

    SELECT SINGLE column_title
      FROM ztb_exp_col
      WHERE section_code = @ls_fix-section_code
        AND fieldname    = @ls_fix-fieldname
      INTO @DATA(lv_current_title).

    IF sy-subrc <> 0.
      APPEND |[SKIP] { ls_fix-section_code }-{ ls_fix-fieldname }: khong tim thay dong trong ZTB_EXP_COL| TO lt_log.
      CONTINUE.
    ENDIF.

    IF lv_current_title = ls_fix-new_title.
      APPEND |[SKIP] { ls_fix-section_code }-{ ls_fix-fieldname }: da dung '{ ls_fix-new_title }' tu truoc, khong can sua| TO lt_log.
      CONTINUE.
    ENDIF.

    IF lv_current_title <> ls_fix-old_title.
      APPEND |[WARN] { ls_fix-section_code }-{ ls_fix-fieldname }: gia tri hien tai '{ lv_current_title }' khac voi gia tri ky vong '{ ls_fix-old_title }' - kiem tra lai truoc khi sua, BO QUA dong nay.| TO lt_log.
      CONTINUE.
    ENDIF.

    IF p_test = abap_true.
      APPEND |[TEST] { ls_fix-section_code }-{ ls_fix-fieldname }: '{ ls_fix-old_title }' -> '{ ls_fix-new_title }' (chua ghi, dang o che do test)| TO lt_log.
    ELSE.
      UPDATE ztb_exp_col
        SET column_title = @ls_fix-new_title
        WHERE section_code = @ls_fix-section_code
          AND fieldname    = @ls_fix-fieldname.

      IF sy-subrc = 0.
        APPEND |[OK]   { ls_fix-section_code }-{ ls_fix-fieldname }: '{ ls_fix-old_title }' -> '{ ls_fix-new_title }'| TO lt_log.
      ELSE.
        APPEND |[FAIL] { ls_fix-section_code }-{ ls_fix-fieldname }: UPDATE that bai| TO lt_log.
      ENDIF.
    ENDIF.

  ENDLOOP.

  "-----------------------------------------------------------------
  " PHAN 2: them dong con thieu - MESSAGE.MESSAGE_NO (cot "No")
  "-----------------------------------------------------------------
  SELECT SINGLE fieldname
    FROM ztb_exp_col
    WHERE section_code = 'MESSAGE'
      AND fieldname    = 'MESSAGE_NO'
    INTO @DATA(lv_no_exists).

  IF sy-subrc = 0.
    APPEND `[SKIP] MESSAGE-MESSAGE_NO: da ton tai san trong ZTB_EXP_COL, khong them lai` TO lt_log.

  ELSE.
    SELECT SINGLE *
      FROM ztb_exp_col
      WHERE section_code = 'MESSAGE'
        AND fieldname    = 'MESSAGE_TYPE'
      INTO @DATA(ls_anchor).

    IF sy-subrc <> 0.
      APPEND `[SKIP] MESSAGE-MESSAGE_NO: khong tim thay dong neo MESSAGE_TYPE de copy cau truc, huy them dong moi` TO lt_log.
    ELSE.
      DATA(ls_new) = ls_anchor.

      ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE ls_new TO FIELD-SYMBOL(<fs_fieldname>).
      IF sy-subrc = 0. <fs_fieldname> = 'MESSAGE_NO'. ENDIF.

      ASSIGN COMPONENT 'ODATA_PROPERTY' OF STRUCTURE ls_new TO FIELD-SYMBOL(<fs_odata>).
      IF sy-subrc = 0. <fs_odata> = 'MessageNo'. ENDIF.

      ASSIGN COMPONENT 'COLUMN_TITLE' OF STRUCTURE ls_new TO FIELD-SYMBOL(<fs_title>).
      IF sy-subrc = 0. <fs_title> = 'No'. ENDIF.

      " Ten field luu thu tu hien thi cot: xac nhan qua SE11 la
      " SEQ_NO (NUMC4, la 1 phan cua khoa chinh cung SECTION_CODE).
      " Dat = 60 (sau MESSAGE_TEXT = 50) de dong moi nam CUOI section,
      " an toan khong xao tron thu tu cac dong khac. Van giu them vai
      " ten ung vien du phong (phong truong hop chay tren he thong
      " khac co ten field khac) - SEQ_NO dat dau tien vi da xac nhan.
      lt_seq_candidates = VALUE #(
        ( `SEQ_NO` ) ( `SEQ` ) ( `SEQUENCE` ) ( `SORT_SEQ` )
        ( `SORTORDER` ) ( `POSITION` ) ( `POSN` ) ( `ITEM_NO` )
        ( `ORDER_NO` ) ( `ROW_SEQ` ) ( `COL_SEQ` ) ( `DISP_SEQ` )
        ( `SEQNR` ) ).

      LOOP AT lt_seq_candidates INTO DATA(lv_cand).
        ASSIGN COMPONENT lv_cand OF STRUCTURE ls_new TO FIELD-SYMBOL(<fs_seq>).
        IF sy-subrc = 0.
          TRY.
              <fs_seq> = CONV #( 60 ).
            CATCH cx_root.
          ENDTRY.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF p_test = abap_true.
        APPEND `[TEST] MESSAGE-MESSAGE_NO: se them dong moi (ODATA_PROPERTY=MessageNo, COLUMN_TITLE='No', dat cuoi section) - chua ghi, dang o che do test` TO lt_log.
      ELSE.
        INSERT ztb_exp_col FROM ls_new.
        IF sy-subrc = 0.
          APPEND `[OK]   MESSAGE-MESSAGE_NO: da them dong moi (No / MessageNo) - NHO export thu section MESSAGE de xac nhan cot co du lieu, khong bi trong` TO lt_log.
        ELSE.
          APPEND `[FAIL] MESSAGE-MESSAGE_NO: INSERT that bai (co the trung khoa chinh - kiem tra lai ten field thu tu hien thi trong DDIC ZTB_EXP_COL)` TO lt_log.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  "-----------------------------------------------------------------
  " PHAN 3: doi ten hien thi section SRC_EVIDEN -> "Evidences"
  "-----------------------------------------------------------------
  " Day la bang khac (ZTB_EXP_SECTION - ten hien thi cua CA section,
  " khac ZTB_EXP_COL la ten hien thi cua TUNG COT da sua o Phan 1).
  " Khong biet truoc chinh xac ten field luu "ten hien thi" trong
  " DDIC nay, nen cung thu theo danh sach ung vien nhu Phan 2.
  SELECT SINGLE *
    FROM ztb_exp_section
    WHERE section_code = 'SRC_EVIDEN'
    INTO @DATA(ls_section).

  IF sy-subrc <> 0.
    APPEND `[SKIP] SRC_EVIDEN (ZTB_EXP_SECTION): khong tim thay dong` TO lt_log.
  ELSE.
    " Xac nhan qua SE11: ZTB_EXP_SECTION dung field SHEET_TITLE
    " (CHAR50) lam ten hien thi section - dat dau tien vi da xac
    " nhan, cac ten khac chi la du phong.
    DATA(lt_title_candidates) = VALUE string_table(
      ( `SHEET_TITLE` ) ( `SECTION_TITLE` ) ( `SECTION_NAME` )
      ( `SECTION_TEXT` ) ( `DISPLAY_NAME` ) ( `TITLE` )
      ( `DESCRIPT` ) ( `DESCRIPTION` ) ( `TEXT` )
      ( `SECTION_LABEL` ) ( `LABEL` ) ).

    DATA(lv_title_field_found) = abap_false.
    LOOP AT lt_title_candidates INTO DATA(lv_tcand).
      ASSIGN COMPONENT lv_tcand OF STRUCTURE ls_section TO FIELD-SYMBOL(<fs_sectitle>).
      IF sy-subrc = 0.
        lv_title_field_found = abap_true.
        DATA(lv_current_section_title) = CONV string( <fs_sectitle> ).

        IF lv_current_section_title = 'Evidences'.
          APPEND `[SKIP] SRC_EVIDEN: ten hien thi da la 'Evidences' tu truoc, khong can sua` TO lt_log.
        ELSE.
          IF p_test = abap_true.
            APPEND |[TEST] SRC_EVIDEN ({ lv_tcand }): '{ lv_current_section_title }' -> 'Evidences' (chua ghi)| TO lt_log.
          ELSE.
            <fs_sectitle> = 'Evidences'.
            MODIFY ztb_exp_section FROM ls_section.
            IF sy-subrc = 0.
              APPEND |[OK]   SRC_EVIDEN ({ lv_tcand }): '{ lv_current_section_title }' -> 'Evidences'| TO lt_log.
            ELSE.
              APPEND `[FAIL] SRC_EVIDEN: MODIFY ZTB_EXP_SECTION that bai` TO lt_log.
            ENDIF.
          ENDIF.
        ENDIF.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF lv_title_field_found = abap_false.
      APPEND `[SKIP] SRC_EVIDEN: khong doan duoc ten field luu ten hien thi trong ZTB_EXP_SECTION - kiem tra SE11 roi cho minh ten field chinh xac de sua tiep` TO lt_log.
    ENDIF.
  ENDIF.

  "-----------------------------------------------------------------
  " PHAN 4: xoa cac cot ky thuat khong xuat hien tren UI (doi y -
  " truoc do (18/09) da quyet dinh GIU LAI, nay doi lai la XOA)
  "-----------------------------------------------------------------
  " EvidenceId (UI_FILTER/DB_OBJ/ALV_OUTPUT/RECOMMEN),
  " LayoutEvidenceId (ALV_OUTPUT), RuleId + SourceItemId (RECOMMEN) -
  " khong xuat hien trong dialog "Choose Columns" cua UI cho section
  " nao, nen xoa het khoi ZTB_EXP_COL de export khop dung 100% voi
  " danh sach cot UI dang cho chon.
  DATA(lt_delete) = VALUE ty_fix_key_tab(
    ( section_code = 'UI_FILTER' fieldname = 'EVIDENCE_ID' )
    ( section_code = 'DB_OBJ'    fieldname = 'EVIDENCE_ID' )
    ( section_code = 'ALV_OUTPUT' fieldname = 'EVIDENCE_ID' )
    ( section_code = 'ALV_OUTPUT' fieldname = 'LAYOUT_EVIDENCE_ID' )
    ( section_code = 'RECOMMEN'  fieldname = 'EVIDENCE_ID' )
    ( section_code = 'RECOMMEN'  fieldname = 'RULE_ID' )
    ( section_code = 'RECOMMEN'  fieldname = 'SOURCE_ITEM_ID' )
  ).

  LOOP AT lt_delete INTO DATA(ls_del).
    SELECT SINGLE fieldname
      FROM ztb_exp_col
      WHERE section_code = @ls_del-section_code
        AND fieldname    = @ls_del-fieldname
      INTO @DATA(lv_del_exists).

    IF sy-subrc <> 0.
      APPEND |[SKIP] { ls_del-section_code }-{ ls_del-fieldname }: khong ton tai (co the da xoa tu truoc), khong can xoa lai| TO lt_log.
      CONTINUE.
    ENDIF.

    IF p_test = abap_true.
      APPEND |[TEST] { ls_del-section_code }-{ ls_del-fieldname }: se DELETE khoi ZTB_EXP_COL (chua ghi)| TO lt_log.
    ELSE.
      DELETE FROM ztb_exp_col
        WHERE section_code = @ls_del-section_code
          AND fieldname    = @ls_del-fieldname.
      IF sy-subrc = 0.
        APPEND |[OK]   { ls_del-section_code }-{ ls_del-fieldname }: da xoa khoi ZTB_EXP_COL| TO lt_log.
      ELSE.
        APPEND |[FAIL] { ls_del-section_code }-{ ls_del-fieldname }: DELETE that bai| TO lt_log.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    COMMIT WORK AND WAIT.
  ENDIF.

  cl_demo_output=>display( lt_log ).

  IF p_test = abap_true.
    cl_demo_output=>display( |Dang o che do TEST ONLY - chua ghi gi vao DB. Bo tick "Test only" (P_TEST) roi chay lai de commit that.| ).
  ELSE.
    cl_demo_output=>display( |Da COMMIT xong. Vao lai UI cockpit / export 1 file MOI (khong dung lai job cu) de xac nhan: header dung, cot MESSAGE No co du lieu, cac cot ky thuat da bien mat.| ).
  ENDIF.
