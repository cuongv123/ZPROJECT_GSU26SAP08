REPORT zinit_exp_col_missing.

DATA lt_col TYPE TABLE OF ztb_exp_col.

lt_col = VALUE #(
  " ===== SRC_STRUCT =====
  ( section_code = 'SRC_STRUCT' seq_no = 60  fieldname = 'SOURCE_HASH'          odata_property = 'SourceHash'          column_title = 'Source Hash' )

  " ===== UI_FILTER =====
  ( section_code = 'UI_FILTER'  seq_no = 90  fieldname = 'DATA_TYPE'            odata_property = 'DataType'            column_title = 'Data Type' )
  ( section_code = 'UI_FILTER'  seq_no = 100 fieldname = 'DESCRIPTION'          odata_property = 'Description'         column_title = 'Description' )
  ( section_code = 'UI_FILTER'  seq_no = 110 fieldname = 'SELECTION_BLOCK'      odata_property = 'SelectionBlock'      column_title = 'Selection Block' )
  ( section_code = 'UI_FILTER'  seq_no = 120 fieldname = 'HIDDEN'               odata_property = 'Hidden'              column_title = 'Hidden' )
  ( section_code = 'UI_FILTER'  seq_no = 130 fieldname = 'CHECKBOX'             odata_property = 'Checkbox'            column_title = 'Checkbox' )
  ( section_code = 'UI_FILTER'  seq_no = 140 fieldname = 'RADIO_GROUP'          odata_property = 'RadioGroup'          column_title = 'Radio Group' )
  ( section_code = 'UI_FILTER'  seq_no = 150 fieldname = 'RANGE_SUPPORTED'      odata_property = 'RangeSupported'      column_title = 'Range Supported' )
  ( section_code = 'UI_FILTER'  seq_no = 160 fieldname = 'DEFAULT_VALUE'        odata_property = 'DefaultValue'        column_title = 'Default Value' )
  ( section_code = 'UI_FILTER'  seq_no = 170 fieldname = 'VALIDATION_ROUTINE'   odata_property = 'ValidationRoutine'   column_title = 'Validation Routine' )

  " ===== DB_OBJ =====
  ( section_code = 'DB_OBJ'     seq_no = 90  fieldname = 'SELECTED_FIELDS'      odata_property = 'SelectedFields'      column_title = 'Selected Fields' )
  ( section_code = 'DB_OBJ'     seq_no = 100 fieldname = 'WHERE_FIELDS'         odata_property = 'WhereFields'         column_title = 'Where Fields' )
  ( section_code = 'DB_OBJ'     seq_no = 110 fieldname = 'JOINED_OBJECTS'       odata_property = 'JoinedObjects'       column_title = 'Joined Objects' )
  ( section_code = 'DB_OBJ'     seq_no = 120 fieldname = 'JOIN_CONDITION'       odata_property = 'JoinCondition'       column_title = 'Join Condition' )
  ( section_code = 'DB_OBJ'     seq_no = 130 fieldname = 'AGGREGATION'         odata_property = 'Aggregation'         column_title = 'Aggregation' )
  ( section_code = 'DB_OBJ'     seq_no = 140 fieldname = 'DESCRIPTION'          odata_property = 'Description'         column_title = 'Description' )

  " ===== BUS_LOGIC =====
  ( section_code = 'BUS_LOGIC'  seq_no = 90  fieldname = 'INTERFACE_SUMMARY'    odata_property = 'InterfaceSummary'    column_title = 'Interface Summary' )
  ( section_code = 'BUS_LOGIC'  seq_no = 100 fieldname = 'DESCRIPTION'          odata_property = 'Description'         column_title = 'Description' )
  ( section_code = 'BUS_LOGIC'  seq_no = 110 fieldname = 'TRANSACTION_DEPENDENCY' odata_property = 'TransactionDependency' column_title = 'Transaction Dependency' )

  " ===== ALV_OUTPUT =====
  ( section_code = 'ALV_OUTPUT' seq_no = 80  fieldname = 'CONTROL_OBJECT'       odata_property = 'ControlObject'       column_title = 'Control Object' )
  ( section_code = 'ALV_OUTPUT' seq_no = 90  fieldname = 'FIELD_CATALOG'        odata_property = 'FieldCatalog'        column_title = 'Field Catalog' )
  ( section_code = 'ALV_OUTPUT' seq_no = 100 fieldname = 'SORT_TABLE'           odata_property = 'SortTable'           column_title = 'Sort Table' )
  ( section_code = 'ALV_OUTPUT' seq_no = 110 fieldname = 'FILTER_TABLE'         odata_property = 'FilterTable'         column_title = 'Filter Table' )
  ( section_code = 'ALV_OUTPUT' seq_no = 120 fieldname = 'LAYOUT_OBJECT'        odata_property = 'LayoutObject'        column_title = 'Layout Object' )
  ( section_code = 'ALV_OUTPUT' seq_no = 130 fieldname = 'VARIANT_OBJECT'       odata_property = 'VariantObject'       column_title = 'Variant Object' )
  ( section_code = 'ALV_OUTPUT' seq_no = 140 fieldname = 'HIERARCHICAL'         odata_property = 'Hierarchical'        column_title = 'Hierarchical' )
  ( section_code = 'ALV_OUTPUT' seq_no = 150 fieldname = 'ZEBRA'                odata_property = 'Zebra'               column_title = 'Zebra' )
  ( section_code = 'ALV_OUTPUT' seq_no = 160 fieldname = 'AUTO_WIDTH'           odata_property = 'AutoWidth'           column_title = 'Auto Width' )
  ( section_code = 'ALV_OUTPUT' seq_no = 170 fieldname = 'SELECTION_MODE'       odata_property = 'SelectionMode'       column_title = 'Selection Mode' )

  " ===== SRC_EVIDEN =====
  ( section_code = 'SRC_EVIDEN' seq_no = 60  fieldname = 'STATEMENT_TEXT'       odata_property = 'StatementText'       column_title = 'Statement Text' )

  " ===== RECOMMEN =====
  ( section_code = 'RECOMMEN'   seq_no = 70  fieldname = 'RULE_ID'              odata_property = 'RuleId'              column_title = 'Rule ID' )
  ( section_code = 'RECOMMEN'   seq_no = 80  fieldname = 'RULE_VERSION'         odata_property = 'RuleVersion'         column_title = 'Rule Version' )
  ( section_code = 'RECOMMEN'   seq_no = 90  fieldname = 'DISPLAY_TEXT'         odata_property = 'DisplayText'         column_title = 'Display Text' )
  ( section_code = 'RECOMMEN'   seq_no = 100 fieldname = 'EXPLANATION'          odata_property = 'Explanation'         column_title = 'Explanation' )
).

INSERT ztb_exp_col FROM TABLE @lt_col.

IF sy-subrc = 0.
  WRITE: / '✅ Đã thêm', lines( lt_col ), 'record mới vào ZTB_EXP_COL thành công!'.
ELSE.
  WRITE: / '❌ INSERT thất bại (sy-subrc =', sy-subrc, '). Có thể trùng key (section_code+seq_no) đã tồn tại — kiểm tra lại.'.
ENDIF.
