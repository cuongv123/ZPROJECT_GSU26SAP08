CLASS ltc_service_blueprint DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS:
      gc_analysis_id TYPE zif_mig_types=>ty_analysis_id
        VALUE '00000000000000000000000000000001',

      gc_output_id TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000002',

      gc_item_id_1 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000003',

      gc_item_id_2 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000004',

      gc_item_id_3 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000005',

      gc_item_id_4 TYPE zif_mig_types=>ty_item_id
        VALUE '00000000000000000000000000000006'.


    METHODS make_read_only_analysis
      RETURNING
        VALUE(rs_analysis)
          TYPE zif_mig_types=>ty_analysis_result.


    METHODS:
      build_query_blueprint
        FOR TESTING
        RAISING zcx_mig_analysis,

      map_selection_parameters
        FOR TESTING
        RAISING zcx_mig_analysis,

      build_output_contract
        FOR TESTING
        RAISING zcx_mig_analysis,

      choose_action_for_write
        FOR TESTING
        RAISING zcx_mig_analysis,

      require_review_for_gui
        FOR TESTING
        RAISING zcx_mig_analysis,

      require_review_without_columns
        FOR TESTING
        RAISING zcx_mig_analysis.

ENDCLASS.


CLASS ltc_service_blueprint IMPLEMENTATION.

  METHOD make_read_only_analysis.

    CLEAR rs_analysis.

    rs_analysis-analysis_id =
      gc_analysis_id.

    rs_analysis-overview-analysis_id =
      gc_analysis_id.

    rs_analysis-overview-program_name =
      'ZRMIG_TEST_FULL'.


    "Một ALV output đã được resolve
    APPEND VALUE #(
      output_id    = gc_output_id
      analysis_id  = gc_analysis_id
      output_name  = 'GT_RESULT'
      output_kind  = 'TABLE'
      framework    = 'SALV'
      output_table = 'GT_RESULT'
      row_type     = 'TY_RESULT'
      editable     = abap_false
      hierarchical = abap_false
    ) TO rs_analysis-alv_outputs.


    "Một output field tối thiểu để report được coi là typed output
    APPEND VALUE #(
      item_id       = gc_item_id_1
      analysis_id   = gc_analysis_id
      output_id     = gc_output_id
      field_name    = 'BUKRS'
      label         = 'Company Code'
      position      = 1
      data_type     = 'C'
      visible       = abap_true
      key_field     = abap_true
      technical     = abap_false
      icon          = abap_false
      source_mapping = 'GT_RESULT-BUKRS'
    ) TO rs_analysis-alv_columns.

  ENDMETHOD.


  "============================================================
  " Test 1:
  " Read-only report với một ALV output và column hợp lệ
  " phải được đề xuất dưới dạng QUERY.
  "============================================================
  METHOD build_query_blueprint.

    DATA(ls_analysis) =
      make_read_only_analysis( ).

    DATA(lo_builder) =
      NEW zcl_mig_service_blueprint( ).

    DATA(ls_result) =
      lo_builder->zif_mig_service_blueprint~build(
        is_analysis = ls_analysis
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_svc_query
      act = ls_result-blueprint-strategy
      msg = 'Read-only report phải sử dụng QUERY strategy'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-blueprint-supports_filter
      msg = 'QUERY phải hỗ trợ filter'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-blueprint-supports_sort
      msg = 'QUERY phải hỗ trợ sort'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-blueprint-supports_paging
      msg = 'QUERY phải hỗ trợ paging'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_result-blueprint-manual_review
      msg = 'Read-only typed output không cần manual review'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZUI_ZRMIG_TEST_FULL'
      act = ls_result-blueprint-service_name
      msg = 'Service name không đúng'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ZC_ZRMIG_TEST_FULL'
      act = ls_result-blueprint-entity_name
      msg = 'Entity name không đúng'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT'
      act = ls_result-blueprint-source_table
      msg = 'Source output table không đúng'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'TY_RESULT'
      act = ls_result-blueprint-source_row_type
      msg = 'Source row type không đúng'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( ls_result-fields )
      msg = 'Output contract phải có một field'
    ).

  ENDMETHOD.


  "============================================================
  " Test 2:
  " Selection-screen fields phải được chuyển thành parameter
  " contract tương ứng.
  "============================================================
  METHOD map_selection_parameters.

    DATA(ls_analysis) =
      make_read_only_analysis( ).


    "PARAMETERS p_waers TYPE c OBLIGATORY
    APPEND VALUE #(
      item_id            = gc_item_id_1
      analysis_id        = gc_analysis_id
      field_name         = 'P_WAERS'
      field_kind         = 'PARAMETER'
      data_type          = 'C'
      mandatory          = abap_true
      checkbox           = abap_false
      multiple_selection = abap_false
      range_supported    = abap_false
    ) TO ls_analysis-ui_filters.


    "PARAMETERS p_max TYPE i DEFAULT 100
    APPEND VALUE #(
      item_id            = gc_item_id_2
      analysis_id        = gc_analysis_id
      field_name         = 'P_MAX'
      field_kind         = 'PARAMETER'
      data_type          = 'I'
      mandatory          = abap_false
      checkbox           = abap_false
      multiple_selection = abap_false
      range_supported    = abap_false
      default_value      = '100'
    ) TO ls_analysis-ui_filters.


    "PARAMETERS p_show AS CHECKBOX
    APPEND VALUE #(
      item_id            = gc_item_id_3
      analysis_id        = gc_analysis_id
      field_name         = 'P_SHOW'
      field_kind         = 'PARAMETER'
      data_type          = 'C'
      mandatory          = abap_false
      checkbox           = abap_true
      multiple_selection = abap_false
      range_supported    = abap_false
    ) TO ls_analysis-ui_filters.


    "SELECT-OPTIONS s_bukrs FOR t001-bukrs
    APPEND VALUE #(
      item_id            = gc_item_id_4
      analysis_id        = gc_analysis_id
      field_name         = 'S_BUKRS'
      field_kind         = 'SELECT_OPTIONS'
      data_type          = 'C'
      reference_table    = 'T001'
      reference_field    = 'BUKRS'
      mandatory          = abap_false
      checkbox           = abap_false
      multiple_selection = abap_true
      range_supported    = abap_true
    ) TO ls_analysis-ui_filters.


    DATA(lo_builder) =
      NEW zcl_mig_service_blueprint( ).

    DATA(ls_result) =
      lo_builder->zif_mig_service_blueprint~build(
        is_analysis = ls_analysis
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = 4
      act = lines( ls_result-parameters )
      msg = 'Phải tạo đủ bốn input parameters'
    ).


    "----------------------------------------------------------
    " P_WAERS
    "----------------------------------------------------------
    READ TABLE ls_result-parameters
      WITH KEY parameter_name = 'P_WAERS'
      INTO DATA(ls_waers).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Không tìm thấy P_WAERS'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'SCALAR'
      act = ls_waers-odata_kind
      msg = 'PARAMETER phải map thành SCALAR'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Edm.String'
      act = ls_waers-edm_type
      msg = 'P_WAERS phải map thành Edm.String'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_waers-mandatory
      msg = 'P_WAERS phải là mandatory'
    ).


    "----------------------------------------------------------
    " P_MAX
    "----------------------------------------------------------
    READ TABLE ls_result-parameters
      WITH KEY parameter_name = 'P_MAX'
      INTO DATA(ls_max).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Không tìm thấy P_MAX'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Edm.Int32'
      act = ls_max-edm_type
      msg = 'ABAP I phải map thành Edm.Int32'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = '100'
      act = ls_max-default_value
      msg = 'Default value của P_MAX không đúng'
    ).


    "----------------------------------------------------------
    " P_SHOW
    "----------------------------------------------------------
    READ TABLE ls_result-parameters
      WITH KEY parameter_name = 'P_SHOW'
      INTO DATA(ls_show).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Không tìm thấy P_SHOW'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Edm.Boolean'
      act = ls_show-edm_type
      msg = 'Checkbox phải map thành Edm.Boolean'
    ).


    "----------------------------------------------------------
    " S_BUKRS
    "----------------------------------------------------------
    READ TABLE ls_result-parameters
      WITH KEY parameter_name = 'S_BUKRS'
      INTO DATA(ls_bukrs).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Không tìm thấy S_BUKRS'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'SELECT_OPTIONS'
      act = ls_bukrs-source_kind
      msg = 'Source kind của S_BUKRS không đúng'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'RANGE'
      act = ls_bukrs-odata_kind
      msg = 'SELECT-OPTIONS phải map thành RANGE'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_bukrs-multiple_selection
      msg = 'S_BUKRS phải hỗ trợ multiple selection'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_bukrs-range_supported
      msg = 'S_BUKRS phải hỗ trợ range'
    ).

  ENDMETHOD.


  "============================================================
  " Test 3:
  " ALV columns phải được chuyển thành output entity fields,
  " đúng EDM type, thứ tự, filterable và sortable.
  "============================================================
  METHOD build_output_contract.

    DATA(ls_analysis) =
      make_read_only_analysis( ).

    CLEAR ls_analysis-alv_columns.


    "Position 3 được append trước để kiểm tra stable sorting
    APPEND VALUE #(
      item_id        = gc_item_id_3
      analysis_id    = gc_analysis_id
      output_id      = gc_output_id
      field_name     = 'AMOUNT'
      label          = 'Amount'
      position       = 3
      data_type      = 'P'
      visible        = abap_true
      technical      = abap_false
      icon           = abap_false
      source_mapping = 'GT_RESULT-AMOUNT'
    ) TO ls_analysis-alv_columns.


    APPEND VALUE #(
      item_id        = gc_item_id_1
      analysis_id    = gc_analysis_id
      output_id      = gc_output_id
      field_name     = 'BUKRS'
      label          = 'Company Code'
      position       = 1
      data_type      = 'C'
      visible        = abap_true
      key_field      = abap_true
      technical      = abap_false
      icon           = abap_false
      source_mapping = 'GT_RESULT-BUKRS'
    ) TO ls_analysis-alv_columns.


    APPEND VALUE #(
      item_id        = gc_item_id_2
      analysis_id    = gc_analysis_id
      output_id      = gc_output_id
      field_name     = 'STATUS_ICON'
      label          = 'Status'
      position       = 2
      data_type      = 'C'
      visible        = abap_true
      key_field      = abap_false
      technical      = abap_true
      icon           = abap_true
      source_mapping = 'GT_RESULT-STATUS_ICON'
    ) TO ls_analysis-alv_columns.


    DATA(lo_builder) =
      NEW zcl_mig_service_blueprint( ).

    DATA(ls_result) =
      lo_builder->zif_mig_service_blueprint~build(
        is_analysis = ls_analysis
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = lines( ls_result-fields )
      msg = 'Output contract phải có ba fields'
    ).


    "----------------------------------------------------------
    " Kiểm tra thứ tự position
    "----------------------------------------------------------
    READ TABLE ls_result-fields
      INDEX 1
      INTO DATA(ls_first_field).

    cl_abap_unit_assert=>assert_equals(
      exp = 'BUKRS'
      act = ls_first_field-field_name
      msg = 'Field position 1 phải là BUKRS'
    ).

    READ TABLE ls_result-fields
      INDEX 2
      INTO DATA(ls_second_field).

    cl_abap_unit_assert=>assert_equals(
      exp = 'STATUS_ICON'
      act = ls_second_field-field_name
      msg = 'Field position 2 phải là STATUS_ICON'
    ).

    READ TABLE ls_result-fields
      INDEX 3
      INTO DATA(ls_third_field).

    cl_abap_unit_assert=>assert_equals(
      exp = 'AMOUNT'
      act = ls_third_field-field_name
      msg = 'Field position 3 phải là AMOUNT'
    ).


    "----------------------------------------------------------
    " BUKRS
    "----------------------------------------------------------
    READ TABLE ls_result-fields
      WITH KEY field_name = 'BUKRS'
      INTO DATA(ls_bukrs_field).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Không tìm thấy output field BUKRS'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Edm.String'
      act = ls_bukrs_field-edm_type
      msg = 'BUKRS phải map thành Edm.String'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_bukrs_field-key_field
      msg = 'BUKRS phải giữ key flag'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_bukrs_field-filterable
      msg = 'BUKRS phải filterable'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_bukrs_field-sortable
      msg = 'BUKRS phải sortable'
    ).


    "----------------------------------------------------------
    " AMOUNT
    "----------------------------------------------------------
    READ TABLE ls_result-fields
      WITH KEY field_name = 'AMOUNT'
      INTO DATA(ls_amount_field).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Không tìm thấy output field AMOUNT'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'Edm.Decimal'
      act = ls_amount_field-edm_type
      msg = 'ABAP P phải map thành Edm.Decimal'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GT_RESULT-AMOUNT'
      act = ls_amount_field-source_mapping
      msg = 'Source mapping của AMOUNT không đúng'
    ).


    "----------------------------------------------------------
    " STATUS_ICON
    "----------------------------------------------------------
    READ TABLE ls_result-fields
      WITH KEY field_name = 'STATUS_ICON'
      INTO DATA(ls_icon_field).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = sy-subrc
      msg = 'Không tìm thấy STATUS_ICON'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_icon_field-filterable
      msg = 'Technical/icon field không được filterable'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_icon_field-sortable
      msg = 'Technical/icon field không được sortable'
    ).

  ENDMETHOD.


  "============================================================
  " Test 4:
  " Report có database write phải được đề xuất bằng RAP ACTION.
  "============================================================
  METHOD choose_action_for_write.

    DATA(ls_analysis) =
      make_read_only_analysis( ).


    APPEND VALUE #(
      item_id       = gc_item_id_2
      analysis_id   = gc_analysis_id
      object_name   = 'ZTMIG_TARGET'
      object_type   = 'TABLE'
      operation     = 'UPDATE'
      dynamic_access = abap_false
      read_only     = abap_false
    ) TO ls_analysis-database_objects.


    DATA(lo_builder) =
      NEW zcl_mig_service_blueprint( ).

    DATA(ls_result) =
      lo_builder->zif_mig_service_blueprint~build(
        is_analysis = ls_analysis
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_svc_action
      act = ls_result-blueprint-strategy
      msg = 'Database write phải dùng ACTION strategy'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_result-blueprint-manual_review
      msg = 'Known write operation không bắt buộc manual review'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_result-blueprint-supports_filter
      msg = 'ACTION không sử dụng query filter capability'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_result-blueprint-supports_sort
      msg = 'ACTION không sử dụng query sort capability'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_result-blueprint-supports_paging
      msg = 'ACTION không sử dụng query paging capability'
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-blueprint-decision_reason
      msg = 'ACTION phải có decision reason'
    ).

  ENDMETHOD.


  "============================================================
  " Test 5:
  " GUI-dependent logic không thể wrap trực tiếp thành OData.
  "============================================================
  METHOD require_review_for_gui.

    DATA(ls_analysis) =
      make_read_only_analysis( ).


    APPEND VALUE #(
      item_id               = gc_item_id_2
      analysis_id           = gc_analysis_id
      object_name           = '0100'
      object_type           = 'DYPRO'
      side_effect           = 'GUI_DEPENDENT'
      transaction_dependency = abap_false
      gui_dependency        = abap_true
      reuse_feasibility     = 'REDESIGN'
    ) TO ls_analysis-business_logic.


    DATA(lo_builder) =
      NEW zcl_mig_service_blueprint( ).

    DATA(ls_result) =
      lo_builder->zif_mig_service_blueprint~build(
        is_analysis = ls_analysis
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_svc_manual
      act = ls_result-blueprint-strategy
      msg = 'GUI dependency phải yêu cầu manual review'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-blueprint-manual_review
      msg = 'Manual review flag phải được bật'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'GUI-dependent logic cannot be exposed directly as OData.'
      act = ls_result-blueprint-decision_reason
      msg = 'GUI review reason không đúng'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = ls_result-blueprint-supports_paging
      msg = 'Manual review blueprint không được bật paging'
    ).

  ENDMETHOD.


  "============================================================
  " Test 6:
  " Có ALV output nhưng không resolve được column thì chưa đủ
  " dữ liệu để tạo strongly typed OData entity.
  "============================================================
  METHOD require_review_without_columns.

    DATA(ls_analysis) =
      make_read_only_analysis( ).

    CLEAR ls_analysis-alv_columns.


    DATA(lo_builder) =
      NEW zcl_mig_service_blueprint( ).

    DATA(ls_result) =
      lo_builder->zif_mig_service_blueprint~build(
        is_analysis = ls_analysis
      ).


    cl_abap_unit_assert=>assert_equals(
      exp = zif_mig_types=>gc_svc_manual
      act = ls_result-blueprint-strategy
      msg = 'Thiếu ALV columns phải yêu cầu manual review'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = ls_result-blueprint-manual_review
      msg = 'Manual review flag chưa được bật'
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'ALV output columns could not be resolved.'
      act = ls_result-blueprint-decision_reason
      msg = 'Missing-column reason không đúng'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_result-fields
      msg = 'Không có ALV columns thì output contract phải rỗng'
    ).

  ENDMETHOD.

ENDCLASS.
