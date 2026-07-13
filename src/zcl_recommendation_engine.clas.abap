CLASS zcl_recommendation_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_recommendation_engine.

  PRIVATE SECTION.
    METHODS get_data_element_text
      IMPORTING iv_rollname    TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    METHODS get_table_text
      IMPORTING iv_tabname     TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    METHODS get_logic_text
      IMPORTING
                iv_name        TYPE string
                iv_object_type TYPE string
      RETURNING VALUE(rv_text) TYPE string.

ENDCLASS.

CLASS zcl_recommendation_engine IMPLEMENTATION.
  METHOD get_data_element_text.
    SELECT SINGLE ddtext
      INTO @rv_text
      FROM dd04t
     WHERE rollname   = @iv_rollname
       AND ddlanguage = @sy-langu.
    IF sy-subrc <> 0.
      rv_text = iv_rollname.
    ENDIF.
  ENDMETHOD.

  METHOD get_table_text.
    SELECT SINGLE ddtext
      INTO @rv_text
      FROM dd02t
     WHERE tabname    = @iv_tabname
       AND ddlanguage = @sy-langu.
    IF sy-subrc <> 0.
      rv_text = iv_tabname.
    ENDIF.
  ENDMETHOD.

  METHOD get_logic_text.
    CASE iv_object_type.
      WHEN 'FUNCTION MODULE'.
        SELECT SINGLE stext
          INTO @rv_text
          FROM tftit
         WHERE funcname = @iv_name
           AND spras    = @sy-langu.
      WHEN 'CALL SCREEN'.
        rv_text = 'Dynpro Screen'.
      WHEN 'METHOD'.
        rv_text = 'Class Method'.
      WHEN 'CLASS'.
        rv_text = 'ABAP Object'.
      WHEN 'SUBMIT'.
        rv_text = 'Program Call'.
      WHEN OTHERS.
        rv_text = iv_name.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_recommendation_engine~enrich_ui_filter.
    DATA(lo_repo) = NEW zcl_rule_repository( ).
    DATA(lt_rules_std) = lo_repo->get_ui_rules( ).
    DATA lt_rules TYPE HASHED TABLE OF zcl_parser_types=>ty_ui_rule
      WITH UNIQUE KEY filter_type.
    lt_rules = lt_rules_std.
    DATA ls_rule TYPE zcl_parser_types=>ty_ui_rule.
    LOOP AT it_raw_ui_filter INTO DATA(ls_raw).
      CLEAR ls_rule.
      READ TABLE lt_rules
        INTO ls_rule
        WITH TABLE KEY
          filter_type = ls_raw-filter_type.
      DATA(lv_found) = xsdbool( sy-subrc = 0 ).

      IF lv_found = abap_false.
        READ TABLE lt_rules
          INTO ls_rule
          WITH TABLE KEY
            filter_type = '*'.
        IF sy-subrc = 0.
          lv_found = abap_true.
        ENDIF.
      ENDIF.

      IF lv_found = abap_true.
        " Nếu tìm thấy quy tắc đặc biệt trong DB
        APPEND VALUE zcl_parser_types=>ty_ui_filter(
          program_name      = iv_program_name
          field_name        = ls_raw-field_name
          description       = get_data_element_text( ls_raw-data_element )
          filter_type       = ls_raw-filter_type
          data_element      = ls_raw-data_element
          mandatory_flag    = abap_false
          multi_value_flag  = xsdbool( ls_raw-filter_type = 'SELECT-OPTIONS' )
          migration_target  = ls_rule-migration_target
          severity          = ls_rule-severity
          recommendation    = ls_rule-recommendation
          fiori_adaptation  = ls_rule-fiori_adaptation
        ) TO et_ui_filter.

      ELSE.
        " XỬ LÝ MẶC ĐỊNH CHO CÁC BIẾN MÀN HÌNH CHỌN
        DATA lv_migration_target TYPE string.
        DATA lv_recommendation   TYPE string.
        DATA lv_fiori_adapt      TYPE string VALUE 'Auto-Generate'.

        IF ls_raw-filter_type = 'Single Value'.
          lv_migration_target = 'Fiori SmartFilterBar (Single)'.
          lv_recommendation   = 'Sẵn sàng sinh mã @UI.selectionField'.
        ELSEIF ls_raw-filter_type = 'Multiple Range'.
          lv_migration_target = 'Fiori SmartFilterBar (Multi)'.
          lv_recommendation   = 'Sinh mã @UI.selectionField. Chú ý: Cần Custom Entity nếu Range phức tạp'.
        ENDIF.

        " Kích hoạt AI tư vấn dựa trên cờ Mandatory và Matchcode
        IF ls_raw-mandatory_flag = abap_true.
          lv_fiori_adapt = |Gắn Annotation @ObjectModel.mandatory: true|.
        ENDIF.
        IF ls_raw-matchcode_object IS NOT INITIAL.
          lv_recommendation = lv_recommendation && | + Kèm Search Help '{ ls_raw-matchcode_object }'|.
          lv_fiori_adapt = |Gắn Annotation @Consumption.valueHelpDefinition|.
        ENDIF.

        APPEND VALUE zcl_parser_types=>ty_ui_filter(
          program_name      = iv_program_name
          field_name        = ls_raw-field_name
          description       = get_data_element_text( ls_raw-data_element )
          filter_type       = ls_raw-filter_type
          data_element      = ls_raw-data_element
          mandatory_flag    = ls_raw-mandatory_flag " <--- MAP DỮ LIỆU
          multi_value_flag  = xsdbool( ls_raw-filter_type = 'Multiple Range' )
          migration_target  = lv_migration_target
          severity          = 'LOW'
          recommendation    = lv_recommendation
          fiori_adaptation  = lv_fiori_adapt        " <--- LỜI KHUYÊN UI MỚI
        ) TO et_ui_filter.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD zif_recommendation_engine~enrich_db_table.
    TYPES:
      BEGIN OF ty_db_agg,
        table_name TYPE string,
        operations TYPE string,
        fields     TYPE string,
      END OF ty_db_agg.
    DATA lt_db_agg TYPE SORTED TABLE OF ty_db_agg
                     WITH UNIQUE KEY table_name.
    DATA ls_rule TYPE zcl_parser_types=>ty_db_rule.

    "========================================
    " Aggregate Operations per Table
    "========================================
    LOOP AT it_raw_db_table INTO DATA(ls_raw).
      READ TABLE lt_db_agg ASSIGNING FIELD-SYMBOL(<ls_agg>)
        WITH TABLE KEY table_name = ls_raw-table_name.
      IF sy-subrc = 0.
        IF <ls_agg>-operations NS ls_raw-operation.
          <ls_agg>-operations =
            |{ <ls_agg>-operations }, { ls_raw-operation }|.
        ENDIF.
        IF ls_raw-fields = '*'.
           <ls_agg>-fields = '*'.
        ELSEIF ls_raw-fields IS NOT INITIAL AND <ls_agg>-fields NS ls_raw-fields.
           <ls_agg>-fields = <ls_agg>-fields && ` ` && ls_raw-fields.
        ENDIF.

      ELSE.
        INSERT VALUE #(
          table_name = ls_raw-table_name
          operations = ls_raw-operation
          fields     = ls_raw-fields
        ) INTO TABLE lt_db_agg.
      ENDIF.
    ENDLOOP.

    "========================================
    " Load DB Rules
    "========================================
    DATA(lo_repo) = NEW zcl_rule_repository( ).
    DATA(lt_rules_std) = lo_repo->get_db_rules( ).
    DATA lt_rules TYPE HASHED TABLE OF zcl_parser_types=>ty_db_rule
      WITH UNIQUE KEY table_name.
    lt_rules = lt_rules_std.

    "========================================
    " Enrich DB Tables
    "========================================
    LOOP AT lt_db_agg INTO DATA(ls_agg).
      CLEAR ls_rule.
      READ TABLE lt_rules
        INTO ls_rule
        WITH TABLE KEY
          table_name = ls_agg-table_name.
      DATA(lv_found) = xsdbool( sy-subrc = 0 ).

      "--------------------------------------
      " Wildcard Fallback
      "--------------------------------------
      IF lv_found = abap_false.
        READ TABLE lt_rules
          INTO ls_rule
          WITH TABLE KEY
            table_name = '*'.
        IF sy-subrc = 0.
          lv_found = abap_true.
        ENDIF.
      ENDIF.

      "--------------------------------------
      " Rule Found
      "--------------------------------------
      IF lv_found = abap_true.
        APPEND VALUE zcl_parser_types=>ty_db_table(
          program_name       = iv_program_name
          table_name         = ls_agg-table_name
          table_description  = get_table_text( ls_agg-table_name )
          operations         = ls_agg-operations
          fields             = ls_agg-fields
          cds_candidate      = ls_rule-cds_candidate
          priority           = ls_rule-priority
          recommendation     = ls_rule-recommendation
          migration_approach = ls_rule-migration_approach
        ) TO et_db_table.

      ELSE.
        APPEND VALUE zcl_parser_types=>ty_db_table(
          program_name       = iv_program_name
          table_name         = ls_agg-table_name
          table_description  = get_table_text( ls_agg-table_name )
          operations         = ls_agg-operations
          fields             = ls_agg-fields
          cds_candidate      = 'NO_RULE_FOUND'
          priority           = 'HIGH'
          recommendation     = 'Missing migration rule in ZMIG_DB_RULE'
          migration_approach = 'Maintain SM30 rule'
        ) TO et_db_table.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD zif_recommendation_engine~enrich_business_logic.

    DATA(lo_repo) = NEW zcl_rule_repository( ).
    DATA(lt_rules_std) = lo_repo->get_logic_rules( ).
    " HASHED TABLE cho O(1) lookup
    DATA lt_rules TYPE HASHED TABLE OF zcl_parser_types=>ty_logic_rule
      WITH UNIQUE KEY object_type object_name.
    lt_rules = lt_rules_std.
    LOOP AT it_raw_logic INTO DATA(ls_raw).

      "==========================
      " Build base DTO
      "==========================
      DATA(ls_final) = VALUE zcl_parser_types=>ty_business_logic(
        program_name = iv_program_name
        object_name  = ls_raw-object_name
        object_type  = ls_raw-object_type
        target_structure = ls_raw-target_structure
        description  = get_logic_text(
                         iv_name        = ls_raw-object_name
                         iv_object_type = ls_raw-object_type )
      ).
      CLEAR ls_final-severity.
      CLEAR ls_final-recommendation.

      "==========================
      " RULE LOOKUP - EXACT MATCH
      "==========================
      READ TABLE lt_rules INTO DATA(ls_rule)
        WITH TABLE KEY
          object_type = ls_raw-object_type
          object_name = ls_raw-object_name.

      DATA(lv_found) = xsdbool( sy-subrc = 0 ).

      "==========================
      " FALLBACK: WILDCARD MATCH
      "==========================
      IF lv_found = abap_false.
        READ TABLE lt_rules
          INTO ls_rule
          WITH TABLE KEY
            object_type = CONV #( ls_raw-object_type )
            object_name = '*'.
        IF sy-subrc = 0.
          lv_found = abap_true.
        ENDIF.
      ENDIF.

      "==========================
      " ENRICH RESULT
      "==========================
      IF lv_found = abap_true.
        ls_final-migration_target       = ls_rule-migration_target.
        ls_final-severity               = ls_rule-severity.
        ls_final-recommendation         = ls_rule-recommendation.
        ls_final-remediation_complexity = ls_rule-remediation_complexity.
        ls_final-cloud_compliant = xsdbool( ls_rule-cloud_compliant = abap_true OR ls_rule-cloud_compliant = 'X' ).
        ls_final-api_released_flag = xsdbool( ls_rule-api_released = abap_true OR ls_rule-api_released = 'X' ).
      ELSE.
        " XỬ LÝ RIÊNG CHO CÁC GIAO DIỆN ALV ĐƯỢC TÌM THẤY BỞI PARSER
        CASE ls_raw-object_type.
          WHEN 'ALV_CLASSIC'.
            ls_final-migration_target       = 'Fiori Elements List Report'.
            ls_final-severity               = 'HIGH'.
            ls_final-recommendation         = 'Thay thế hoàn toàn. Sử dụng UI Annotation @UI.lineItem'.
            ls_final-remediation_complexity = 'HIGH'.
            ls_final-cloud_compliant        = abap_false.
          WHEN 'ALV_OO'.
            ls_final-migration_target       = 'Fiori Elements List Report'.
            ls_final-severity               = 'HIGH'.
            ls_final-recommendation         = 'Chuyển Data Retrieval sang RAP. Bỏ qua khai báo UI Grid'.
            ls_final-remediation_complexity = 'MEDIUM'.
            ls_final-cloud_compliant        = abap_false.
          WHEN 'ALV_SALV'.
            ls_final-migration_target       = 'Fiori Elements SmartTable'.
            ls_final-severity               = 'MEDIUM'.
            ls_final-recommendation         = 'Sử dụng cấu trúc bảng nội bộ để sinh CDS View tự động'.
            ls_final-remediation_complexity = 'MEDIUM'.
            ls_final-cloud_compliant        = abap_false.
          WHEN 'AUTHORITY-CHECK'.
            ls_final-migration_target       = 'RAP Access Control (DCL)'.
            ls_final-severity               = 'HIGH'.
            ls_final-recommendation         = |Tạo file DCL mapping với Authorization Object '{ ls_raw-object_name }'|.
            ls_final-remediation_complexity = 'MEDIUM'.
            ls_final-cloud_compliant        = abap_true.
          WHEN OTHERS.
            " DEFAULT RULE CHO CÁC LOGIC KHÁC CHƯA CÓ TRONG BẢNG QUY TẮC
            ls_final-severity       = 'LOW'.
            ls_final-recommendation = 'Manual Assessment Required'.
        ENDCASE.
      ENDIF.

      APPEND ls_final TO et_business_logic.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
