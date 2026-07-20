REPORT zmig_pdf_export_content
  LINE-SIZE 100
  LINE-COUNT 65(3).   " 3 dòng cuối mỗi trang dành riêng cho footer

DATA: gt_filter   TYPE TABLE OF ztmig_filter,
      gt_dbtable  TYPE TABLE OF ztmig_dbtable,
      gt_logic    TYPE TABLE OF ztmig_logic,
      gt_roadmap  TYPE TABLE OF ztmig_obj_map,
      gs_overview TYPE ztmig_overview.   " Global - để TOP-OF-PAGE truy cập được

PARAMETERS: p_repid TYPE ztmig_overview-report_id.

START-OF-SELECTION.
  PERFORM load_data.
  PERFORM render_pdf_content.


*&---------------------------------------------------------------*
*&  HEADER - tự động chạy đầu MỖI trang (kể cả khi NEW-PAGE)
*&---------------------------------------------------------------*
TOP-OF-PAGE.
  WRITE: /1 'MIGRATION ANALYSIS REPORT', 75 sy-datum, sy-uzeit.
  WRITE: /1 gs_overview-program_name COLOR COL_HEADING.
  ULINE.


*&---------------------------------------------------------------*
*&  FOOTER - tự động chạy cuối MỖI trang
*&---------------------------------------------------------------*
END-OF-PAGE.
  ULINE.
  WRITE: /1 'Confidential - Internal Use Only', 85 'Page', sy-pagno.


FORM load_data.
  SELECT SINGLE * FROM ztmig_overview WHERE report_id = @p_repid INTO @gs_overview.
  SELECT * FROM ztmig_filter   WHERE report_id = @p_repid INTO TABLE @gt_filter.
  SELECT * FROM ztmig_dbtable  WHERE report_id = @p_repid INTO TABLE @gt_dbtable.
  SELECT * FROM ztmig_logic    WHERE report_id = @p_repid INTO TABLE @gt_logic.
  SELECT * FROM ztmig_obj_map  WHERE report_id = @p_repid INTO TABLE @gt_roadmap.
ENDFORM.


FORM render_pdf_content.
  " ===== Trang 1: Overview =====
  SKIP 2.
  WRITE: / 'Description:',            25 gs_overview-description.
  WRITE: / 'Analyzed By:',            25 gs_overview-analyzed_by.
  WRITE: / 'Total Tables:',           25 gs_overview-total_tables.
  WRITE: / 'Total Filters:',          25 gs_overview-total_filters.
  WRITE: / 'Total Business Objects:', 25 gs_overview-total_objects.
  WRITE: / 'Complexity Score:',       25 gs_overview-complexity_score.
  WRITE: / 'Migration Score:',        25 gs_overview-migration_score.
  WRITE: / 'Cloud Readiness:',        25 gs_overview-cloud_readiness.
  WRITE: / 'Analysis Status:',        25 gs_overview-status.

  " ===== Trang 2: UI Filters =====
  NEW-PAGE.
  WRITE: / 'SECTION: UI FILTERS' COLOR COL_GROUP.
  ULINE.
  LOOP AT gt_filter INTO DATA(ls_filter).
    WRITE: / ls_filter-field_name, 25 ls_filter-description, 60 ls_filter-recommendation.
  ENDLOOP.

  " ===== Trang 3: Database Tables =====
  NEW-PAGE.
  WRITE: / 'SECTION: DATABASE TABLES' COLOR COL_GROUP.
  ULINE.
  LOOP AT gt_dbtable INTO DATA(ls_db).
    WRITE: / ls_db-table_name, 25 ls_db-recommendation.
  ENDLOOP.

  " ===== Trang 4: Business Logic =====
  NEW-PAGE.
  WRITE: / 'SECTION: BUSINESS LOGIC' COLOR COL_GROUP.
  ULINE.
  LOOP AT gt_logic INTO DATA(ls_logic).
    WRITE: / ls_logic-object_name, 25 ls_logic-recommendation.
  ENDLOOP.

  " ===== Trang 5: Roadmap =====
  NEW-PAGE.
  WRITE: / 'SECTION: ROADMAP DATA' COLOR COL_GROUP.
  ULINE.
  IF gt_roadmap IS INITIAL.
    WRITE: / 'No items available.'.
  ELSE.
    LOOP AT gt_roadmap INTO DATA(ls_road).
      WRITE: / ls_road-source_obj, 25 ls_road-target_obj.
    ENDLOOP.
  ENDIF.
ENDFORM.
