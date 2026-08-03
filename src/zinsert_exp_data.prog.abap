*&---------------------------------------------------------------------*
*& Report zinsert_exp_data
*&---------------------------------------------------------------------*
REPORT zinsert_exp_data.

DATA: lt_data TYPE TABLE OF ztb_exp_col.

" Xóa dữ liệu cũ để tránh rác
DELETE FROM ztb_exp_col.

lt_data = VALUE #(
  " 0. OVERVIEW (ZMIG_ANL_H)
  ( section_code = 'OVERVIEW'   seq_no = '0010' fieldname = 'ANALYSIS_ID'        column_title = 'Analysis ID' )
  ( section_code = 'OVERVIEW'   seq_no = '0020' fieldname = 'PROGRAM_NAME'       column_title = 'Program Name' )

  " 1. SRC_STRUCT (ZMIG_ANL_SRC)
  ( section_code = 'SRC_STRUCT' seq_no = '0010' fieldname = 'OBJECT_NAME'        column_title = 'Source Object' )
  ( section_code = 'SRC_STRUCT' seq_no = '0020' fieldname = 'OBJECT_TYPE'        column_title = 'Object Type' )
  ( section_code = 'SRC_STRUCT' seq_no = '0030' fieldname = 'PARENT_OBJECT'      column_title = 'Parent Object' )
  ( section_code = 'SRC_STRUCT' seq_no = '0040' fieldname = 'INCLUDE_DEPTH'      column_title = 'Depth' )
  ( section_code = 'SRC_STRUCT' seq_no = '0050' fieldname = 'LINE_COUNT'         column_title = 'Lines' )

  " 2. UI_FILTER (ZMIG_ANL_UI)
  ( section_code = 'UI_FILTER'  seq_no = '0010' fieldname = 'FIELD_NAME'         column_title = 'Field' )
  ( section_code = 'UI_FILTER'  seq_no = '0020' fieldname = 'FIELD_KIND'         column_title = 'Kind' )
  ( section_code = 'UI_FILTER'  seq_no = '0030' fieldname = 'REFERENCE_TABLE'    column_title = 'Reference Table' )
  ( section_code = 'UI_FILTER'  seq_no = '0040' fieldname = 'REFERENCE_FIELD'    column_title = 'Reference Field' )
  ( section_code = 'UI_FILTER'  seq_no = '0050' fieldname = 'DATA_ELEMENT'       column_title = 'Data Element' )
  ( section_code = 'UI_FILTER'  seq_no = '0060' fieldname = 'MANDATORY'          column_title = 'Mandatory' )
  ( section_code = 'UI_FILTER'  seq_no = '0070' fieldname = 'MULTIPLE_SELECTION' column_title = 'Multiple Selection' )
  ( section_code = 'UI_FILTER'  seq_no = '0080' fieldname = 'CONFIDENCE'         column_title = 'Confidence' )

  " 3. DB_OBJ (ZMIG_ANL_DB)
  ( section_code = 'DB_OBJ'     seq_no = '0010' fieldname = 'OBJECT_NAME'        column_title = 'Object Name' )
  ( section_code = 'DB_OBJ'     seq_no = '0020' fieldname = 'OBJECT_TYPE'        column_title = 'Object Type' )
  ( section_code = 'DB_OBJ'     seq_no = '0030' fieldname = 'OPERATION'          column_title = 'Operation' )
  ( section_code = 'DB_OBJ'     seq_no = '0040' fieldname = 'CONTAINING_ROUTINE' column_title = 'Containing Routine' )
  ( section_code = 'DB_OBJ'     seq_no = '0050' fieldname = 'DYNAMIC_ACCESS'     column_title = 'Dynamic Access' )
  ( section_code = 'DB_OBJ'     seq_no = '0060' fieldname = 'READ_ONLY'          column_title = 'Read Only' )
  ( section_code = 'DB_OBJ'     seq_no = '0070' fieldname = 'PAGING'             column_title = 'Paging' )
  ( section_code = 'DB_OBJ'     seq_no = '0080' fieldname = 'CONFIDENCE'         column_title = 'Confidence' )

  " 4. BUS_LOGIC (ZMIG_ANL_LOG)
  ( section_code = 'BUS_LOGIC'  seq_no = '0010' fieldname = 'OBJECT_NAME'        column_title = 'Object' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0020' fieldname = 'OBJECT_TYPE'        column_title = 'Type' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0030' fieldname = 'CONTAINER_NAME'     column_title = 'Container' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0040' fieldname = 'CALLING_ROUTINE'    column_title = 'Calling Routine' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0050' fieldname = 'SIDE_EFFECT'        column_title = 'Side Effect' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0060' fieldname = 'GUI_DEPENDENCY'     column_title = 'GUI Dependency' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0070' fieldname = 'REUSE_FEASIBILITY'  column_title = 'Reuse Feasibility' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0080' fieldname = 'CONFIDENCE'         column_title = 'Confidence' )

  " 5. ALV_OUTPUT (ZMIG_ANL_ALV)
  ( section_code = 'ALV_OUTPUT' seq_no = '0010' fieldname = 'OUTPUT_NAME'        column_title = 'Output' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0020' fieldname = 'OUTPUT_KIND'        column_title = 'Kind' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0030' fieldname = 'FRAMEWORK'          column_title = 'Framework' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0040' fieldname = 'OUTPUT_TABLE'       column_title = 'Output Table' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0050' fieldname = 'ROW_TYPE'           column_title = 'Row Type' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0060' fieldname = 'EDITABLE'           column_title = 'Editable' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0070' fieldname = 'CONFIDENCE'         column_title = 'Confidence' )

  " 6. SRC_EVIDEN (ZMIG_ANL_EVD) - ĐÃ ĐƯỢC CHỈNH SỬA CHUẨN 100% THEO FIORI UI
  ( section_code = 'SRC_EVIDEN' seq_no = '0010' fieldname = 'SOURCE_OBJECT'      column_title = 'Source Object' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0020' fieldname = 'START_LINE'         column_title = 'Start Line' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0030' fieldname = 'END_LINE'           column_title = 'End Line' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0040' fieldname = 'STATEMENT_INDEX'    column_title = 'Statement' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0050' fieldname = 'CONFIDENCE'         column_title = 'Confidence' )

  " 7. RECOMMEN (ZMIG_ANL_REC)
  ( section_code = 'RECOMMEN'   seq_no = '0010' fieldname = 'SEVERITY'           column_title = 'Severity' )
  ( section_code = 'RECOMMEN'   seq_no = '0020' fieldname = 'DISPLAY_TEXT'       column_title = 'Recommendation' )
  ( section_code = 'RECOMMEN'   seq_no = '0030' fieldname = 'TARGET_LAYER'       column_title = 'Target Layer' )
  ( section_code = 'RECOMMEN'   seq_no = '0040' fieldname = 'REVIEW_STATUS'      column_title = 'Review Status' )
  ( section_code = 'RECOMMEN'   seq_no = '0050' fieldname = 'MANUAL_REVIEW'      column_title = 'Manual Refactoring' )
  ( section_code = 'RECOMMEN'   seq_no = '0060' fieldname = 'CONFIDENCE'         column_title = 'Confidence' )

  " 8. MESSAGE (ZMIG_ANL_MSG)
  ( section_code = 'MESSAGE'    seq_no = '0010' fieldname = 'MESSAGE_TYPE'       column_title = 'Type' )
  ( section_code = 'MESSAGE'    seq_no = '0020' fieldname = 'MESSAGE_CODE'       column_title = 'Code' )
  ( section_code = 'MESSAGE'    seq_no = '0030' fieldname = 'SOURCE_OBJECT'      column_title = 'Source Object' )
  ( section_code = 'MESSAGE'    seq_no = '0040' fieldname = 'SOURCE_LINE'        column_title = 'Source Line' )
  ( section_code = 'MESSAGE'    seq_no = '0050' fieldname = 'MESSAGE_TEXT'       column_title = 'Message' )
).

MODIFY ztb_exp_col FROM TABLE @lt_data.

IF sy-subrc = 0.
  COMMIT WORK.
  WRITE: / 'CHUC MUNG! Da update lai toan bo bang ZTB_EXP_COL chuẩn xac!'.
ELSE.
  ROLLBACK WORK.
  WRITE: / 'Co loi xay ra khi insert!'.
ENDIF.
