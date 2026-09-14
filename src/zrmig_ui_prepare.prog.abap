REPORT zrmig_ui_prepare LINE-SIZE 200.

PARAMETERS p_anlid TYPE sysuuid_c32 OBLIGATORY.
PARAMETERS p_pack TYPE devclass OBLIGATORY.
PARAMETERS p_url TYPE string LOWER CASE.

START-OF-SELECTION.
  TRY.
      IF strlen( p_anlid ) <> 32 OR p_anlid CN '0123456789ABCDEF'.
        WRITE / 'Analysis ID must contain exactly 32 hexadecimal characters.'.
        RETURN.
      ENDIF.
      DATA(lv_analysis_id) = CONV sysuuid_x16( p_anlid ).
      DATA(ls_config) = NEW zcl_mig_ui_service( )->prepare(
        iv_analysis_id = lv_analysis_id iv_package = p_pack iv_service_root_url = p_url ).
      WRITE: / 'Analysis ID:', ls_config-analysis_id,
             / 'Status:', ls_config-status,
             / 'Runtime check:', ls_config-runtime_check,
             / 'Template:', ls_config-template,
             / 'Entity set (SRVD alias):', ls_config-entity_set,
             / 'Custom entity:', ls_config-custom_entity,
             / 'Service definition:', ls_config-service_definition,
             / 'Query provider:', ls_config-query_provider,
             / 'Shared binding:', ls_config-service_binding,
             / 'Metadata URL:'.
      PERFORM write_wrapped USING ls_config-metadata_url.
      SKIP.
      WRITE / 'Columns: property / EDM type / key / label'.
      LOOP AT ls_config-columns INTO DATA(ls_column).
        DATA(lv_text) = |{ ls_column-property } / { ls_column-edm_type } / { ls_column-is_key } / { ls_column-label }|.
        PERFORM write_wrapped USING lv_text.
      ENDLOOP.
      SKIP.
      WRITE / 'Filters: selection parameter -> OData property -> provider input / kind / required'.
      LOOP AT ls_config-filters INTO DATA(ls_filter).
        lv_text = |{ ls_filter-source_parameter } -> { ls_filter-property } -> { ls_filter-provider_parameter } / { ls_filter-kind } / { ls_filter-required }|.
        PERFORM write_wrapped USING lv_text.
      ENDLOOP.
      SKIP.
      WRITE / 'Default sort: property / descending'.
      LOOP AT ls_config-default_sort INTO DATA(ls_sort).
        WRITE: / ls_sort-property, ls_sort-descending.
      ENDLOOP.
      SKIP.
      WRITE / 'Diagnostics:'.
      LOOP AT ls_config-issues INTO DATA(ls_issue).
        lv_text = |{ ls_issue-severity } { ls_issue-code } ({ ls_issue-target }): { ls_issue-message }|.
        PERFORM write_wrapped USING lv_text.
      ENDLOOP.
      "Same serialization as RAP. Inspect LV_JSON in debugger for exact JSON;
      "the list output is for humans and does not truncate a long JSON document.
      DATA(lv_json) = zcl_mig_ui_service=>to_json( ls_config ).
      WRITE: / 'Config JSON length:', strlen( lv_json ),
             / 'Exact ConfigJson is returned by the PrepareFioriUi action.',
             / 'No repository objects were created. Fetch live metadata before UI generation/preview.'.
    CATCH cx_root INTO DATA(lx_error).
      DATA(lv_error) = lx_error->get_text( ).
      PERFORM write_wrapped USING lv_error.
  ENDTRY.

FORM write_wrapped USING iv_text TYPE string.
  DATA lv_offset TYPE i.
  DATA lv_length TYPE i.
  WHILE lv_offset < strlen( iv_text ).
    lv_length = nmin( val1 = 180 val2 = strlen( iv_text ) - lv_offset ).
    WRITE / iv_text+lv_offset(lv_length).
    lv_offset += lv_length.
  ENDWHILE.
ENDFORM.
