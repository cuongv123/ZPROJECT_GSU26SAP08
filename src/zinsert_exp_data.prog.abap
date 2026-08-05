*&---------------------------------------------------------------------*
*& Report zinsert_exp_data
*&---------------------------------------------------------------------*
REPORT zinsert_exp_data.

DATA: lt_data TYPE TABLE OF ztb_exp_col.

" Xóa dữ liệu cũ để tránh rác
DELETE FROM ztb_exp_col.

lt_data = VALUE #(
  " 0. OVERVIEW (ZMIG_ANL_H)
  ( section_code = 'OVERVIEW'   seq_no = '0010' fieldname = 'ANALYSIS_ID'        column_title = 'Analysis ID'        odata_property = 'AnalysisId' )
  ( section_code = 'OVERVIEW'   seq_no = '0020' fieldname = 'PROGRAM_NAME'       column_title = 'Program Name'       odata_property = 'ProgramName' )

  " 1. SRC_STRUCT (ZMIG_ANL_SRC)
  ( section_code = 'SRC_STRUCT' seq_no = '0010' fieldname = 'OBJECT_NAME'        column_title = 'Source Object'      odata_property = 'ObjectName' )
  ( section_code = 'SRC_STRUCT' seq_no = '0020' fieldname = 'OBJECT_TYPE'        column_title = 'Object Type'        odata_property = 'ObjectType' )
  ( section_code = 'SRC_STRUCT' seq_no = '0030' fieldname = 'PARENT_OBJECT'      column_title = 'Parent Object'      odata_property = 'ParentObject' )
  ( section_code = 'SRC_STRUCT' seq_no = '0040' fieldname = 'INCLUDE_DEPTH'      column_title = 'Depth'              odata_property = 'IncludeDepth' )
  ( section_code = 'SRC_STRUCT' seq_no = '0050' fieldname = 'LINE_COUNT'         column_title = 'Lines'              odata_property = 'LineCount' )

  " 2. UI_FILTER (ZMIG_ANL_UI)
  ( section_code = 'UI_FILTER'  seq_no = '0010' fieldname = 'FIELD_NAME'         column_title = 'Field'              odata_property = 'FieldName' )
  ( section_code = 'UI_FILTER'  seq_no = '0020' fieldname = 'FIELD_KIND'         column_title = 'Kind'               odata_property = 'FieldKind' )
  ( section_code = 'UI_FILTER'  seq_no = '0030' fieldname = 'REFERENCE_TABLE'    column_title = 'Reference Table'    odata_property = 'ReferenceTable' )
  ( section_code = 'UI_FILTER'  seq_no = '0040' fieldname = 'REFERENCE_FIELD'    column_title = 'Reference Field'    odata_property = 'ReferenceField' )
  ( section_code = 'UI_FILTER'  seq_no = '0050' fieldname = 'DATA_ELEMENT'       column_title = 'Data Element'       odata_property = 'DataElement' )
  ( section_code = 'UI_FILTER'  seq_no = '0060' fieldname = 'MANDATORY'          column_title = 'Mandatory'          odata_property = 'Mandatory' )
  ( section_code = 'UI_FILTER'  seq_no = '0070' fieldname = 'MULTIPLE_SELECTION' column_title = 'Multiple Selection' odata_property = 'MultipleSelection' )
  ( section_code = 'UI_FILTER'  seq_no = '0080' fieldname = 'CONFIDENCE'         column_title = 'Confidence'         odata_property = 'Confidence' )

  " 3. DB_OBJ (ZMIG_ANL_DB)
  ( section_code = 'DB_OBJ'     seq_no = '0010' fieldname = 'OBJECT_NAME'        column_title = 'Object Name'        odata_property = 'ObjectName' )
  ( section_code = 'DB_OBJ'     seq_no = '0020' fieldname = 'OBJECT_TYPE'        column_title = 'Object Type'        odata_property = 'ObjectType' )
  ( section_code = 'DB_OBJ'     seq_no = '0030' fieldname = 'OPERATION'          column_title = 'Operation'          odata_property = 'Operation' )
  ( section_code = 'DB_OBJ'     seq_no = '0040' fieldname = 'CONTAINING_ROUTINE' column_title = 'Containing Routine' odata_property = 'ContainingRoutine' )
  ( section_code = 'DB_OBJ'     seq_no = '0050' fieldname = 'DYNAMIC_ACCESS'     column_title = 'Dynamic Access'     odata_property = 'DynamicAccess' )
  ( section_code = 'DB_OBJ'     seq_no = '0060' fieldname = 'READ_ONLY'          column_title = 'Read Only'          odata_property = 'ReadOnly' )
  ( section_code = 'DB_OBJ'     seq_no = '0070' fieldname = 'PAGING'             column_title = 'Paging'             odata_property = 'Paging' )
  ( section_code = 'DB_OBJ'     seq_no = '0080' fieldname = 'CONFIDENCE'         column_title = 'Confidence'         odata_property = 'Confidence' )

  " 4. BUS_LOGIC (ZMIG_ANL_LOG)
  ( section_code = 'BUS_LOGIC'  seq_no = '0010' fieldname = 'OBJECT_NAME'        column_title = 'Object'             odata_property = 'ObjectName' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0020' fieldname = 'OBJECT_TYPE'        column_title = 'Type'               odata_property = 'ObjectType' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0030' fieldname = 'CONTAINER_NAME'     column_title = 'Container'          odata_property = 'ContainerName' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0040' fieldname = 'CALLING_ROUTINE'    column_title = 'Calling Routine'    odata_property = 'CallingRoutine' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0050' fieldname = 'SIDE_EFFECT'        column_title = 'Side Effect'        odata_property = 'SideEffect' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0060' fieldname = 'GUI_DEPENDENCY'     column_title = 'GUI Dependency'     odata_property = 'GuiDependency' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0070' fieldname = 'REUSE_FEASIBILITY'  column_title = 'Reuse Feasibility'  odata_property = 'ReuseFeasibility' )
  ( section_code = 'BUS_LOGIC'  seq_no = '0080' fieldname = 'CONFIDENCE'         column_title = 'Confidence'         odata_property = 'Confidence' )

  " 5. ALV_OUTPUT (ZMIG_ANL_ALV)
  ( section_code = 'ALV_OUTPUT' seq_no = '0010' fieldname = 'OUTPUT_NAME'        column_title = 'Output'             odata_property = 'OutputName' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0020' fieldname = 'OUTPUT_KIND'        column_title = 'Kind'               odata_property = 'OutputKind' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0030' fieldname = 'FRAMEWORK'          column_title = 'Framework'          odata_property = 'Framework' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0040' fieldname = 'OUTPUT_TABLE'       column_title = 'Output Table'       odata_property = 'OutputTable' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0050' fieldname = 'ROW_TYPE'           column_title = 'Row Type'           odata_property = 'RowType' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0060' fieldname = 'EDITABLE'           column_title = 'Editable'           odata_property = 'Editable' )
  ( section_code = 'ALV_OUTPUT' seq_no = '0070' fieldname = 'CONFIDENCE'         column_title = 'Confidence'         odata_property = 'Confidence' )

  " 6. SRC_EVIDEN (ZMIG_ANL_EVD)
  ( section_code = 'SRC_EVIDEN' seq_no = '0010' fieldname = 'SOURCE_OBJECT'      column_title = 'Source Object'      odata_property = 'SourceObject' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0020' fieldname = 'START_LINE'         column_title = 'Start Line'         odata_property = 'StartLine' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0030' fieldname = 'END_LINE'           column_title = 'End Line'           odata_property = 'EndLine' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0040' fieldname = 'STATEMENT_ID'       column_title = 'Statement'          odata_property = 'StatementId' )
  ( section_code = 'SRC_EVIDEN' seq_no = '0050' fieldname = 'CONFIDENCE'         column_title = 'Confidence'         odata_property = 'Confidence' )

  " 7. RECOMMEN (ZMIG_ANL_REC)
  ( section_code = 'RECOMMEN'   seq_no = '0010' fieldname = 'SEVERITY'           column_title = 'Severity'           odata_property = 'Severity' )
  ( section_code = 'RECOMMEN'   seq_no = '0020' fieldname = 'TITLE'              column_title = 'Recommendation'     odata_property = 'Title' )
  ( section_code = 'RECOMMEN'   seq_no = '0030' fieldname = 'TARGET_LAYER'       column_title = 'Target Layer'       odata_property = 'TargetLayer' )
  ( section_code = 'RECOMMEN'   seq_no = '0040' fieldname = 'REVIEW_STATUS'      column_title = 'Review Status'      odata_property = 'ReviewStatus' )
  ( section_code = 'RECOMMEN'   seq_no = '0050' fieldname = 'MANUAL_REVIEW'      column_title = 'Manual Refactoring' odata_property = 'ManualReview' )
  ( section_code = 'RECOMMEN'   seq_no = '0060' fieldname = 'CONFIDENCE'         column_title = 'Confidence'         odata_property = 'Confidence' )

  " 8. MESSAGE (ZMIG_ANL_MSG)
  ( section_code = 'MESSAGE'    seq_no = '0010' fieldname = 'MESSAGE_TYPE'       column_title = 'Type'               odata_property = 'MessageType' )
  ( section_code = 'MESSAGE'    seq_no = '0020' fieldname = 'MESSAGE_CODE'       column_title = 'Code'               odata_property = 'MessageCode' )
  ( section_code = 'MESSAGE'    seq_no = '0030' fieldname = 'SOURCE_OBJECT'      column_title = 'Source Object'      odata_property = 'SourceObject' )
  ( section_code = 'MESSAGE'    seq_no = '0040' fieldname = 'SOURCE_LINE'        column_title = 'Source Line'        odata_property = 'SourceLine' )
  ( section_code = 'MESSAGE'    seq_no = '0050' fieldname = 'MESSAGE_TEXT'       column_title = 'Message'            odata_property = 'MessageText' )
).

MODIFY ztb_exp_col FROM TABLE @lt_data.

IF sy-subrc = 0.
  COMMIT WORK.
  WRITE: / 'CHUC MUNG! Da update lai toan bo bang ZTB_EXP_COL chuan xac (co odata_property)!'.
ELSE.
  ROLLBACK WORK.
  WRITE: / 'Co loi xay ra khi insert!'.
ENDIF.
