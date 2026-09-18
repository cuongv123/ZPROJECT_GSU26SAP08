CLASS zcl_mig_legacy_capture_api DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        row_count TYPE i,
        rows_json TYPE string,
      END OF ty_result,
      tt_jobs TYPE STANDARD TABLE OF zmig_legacy_job WITH EMPTY KEY.

    CLASS-METHODS enqueue
      IMPORTING iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
                iv_request_id TYPE sysuuid_x16
                iv_selection_json TYPE string
      RETURNING VALUE(rs_job) TYPE zmig_legacy_job
      RAISING zcx_mig_legacy_capture.

    CLASS-METHODS get_status
      IMPORTING iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
                iv_request_id TYPE sysuuid_x16
      RETURNING VALUE(rs_job) TYPE zmig_legacy_job
      RAISING zcx_mig_legacy_capture.

    CLASS-METHODS save_buffer.
    CLASS-METHODS clear_buffer.

    "Only the standalone worker may call this method.
    CLASS-METHODS run
      IMPORTING iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
                iv_selection_json TYPE string
      RETURNING VALUE(rs_result) TYPE ty_result
      RAISING zcx_mig_legacy_capture.

    "Pure conversion step; shared by RUN and ABAP Unit (no SUBMIT).
    CLASS-METHODS build_result
      IMPORTING ir_rows TYPE REF TO data
      RETURNING VALUE(rs_result) TYPE ty_result
      RAISING zcx_mig_legacy_capture.

  PRIVATE SECTION.
    CLASS-DATA gt_jobs TYPE tt_jobs.
    CLASS-METHODS parse_selections
      IMPORTING iv_selection_json TYPE string
      RETURNING VALUE(rt_selections) TYPE zcl_mig_legacy_alv_capture=>ty_t_selections
      RAISING zcx_mig_legacy_capture.
ENDCLASS.

CLASS zcl_mig_legacy_capture_api IMPLEMENTATION.
  METHOD parse_selections.
    "[] is the only explicit request to run without filters.
    IF iv_selection_json IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'SelectionJson must be a JSON array; use [] for no filter.'.
    ENDIF.
    IF iv_selection_json(1) <> '['.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'SelectionJson must be a JSON array; use [] for no filter.'.
    ENDIF.
    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = iv_selection_json
          CHANGING data = rt_selections ).
      CATCH cx_root INTO DATA(lx_json).
        RAISE EXCEPTION TYPE zcx_mig_legacy_capture
          EXPORTING iv_message = |Invalid SelectionJson: { lx_json->get_text( ) }|
                    previous = lx_json.
    ENDTRY.
    IF rt_selections IS INITIAL AND iv_selection_json <> '[]'.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'SelectionJson did not contain valid selection rows; use [] for no filter.'.
    ENDIF.
    LOOP AT rt_selections INTO DATA(ls_selection).
      IF ls_selection-selname IS INITIAL OR
         ( ls_selection-kind <> 'S' AND ls_selection-kind <> 'P' ).
        RAISE EXCEPTION TYPE zcx_mig_legacy_capture
          EXPORTING iv_message = 'Each selection row requires selname and kind S or P.'.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD enqueue.
    IF iv_analysis_id IS INITIAL OR iv_request_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'AnalysisId and a nonzero RequestId (UUID) are required.'.
    ENDIF.
    DATA(lt_selections) = parse_selections( iv_selection_json ).

    rs_job = VALUE #( gt_jobs[ request_id = iv_request_id ] OPTIONAL ).
    IF rs_job IS INITIAL.
      SELECT SINGLE * FROM zmig_legacy_job
        WHERE request_id = @iv_request_id INTO @rs_job.
    ENDIF.
    IF rs_job IS NOT INITIAL.
      IF rs_job-analysis_id <> iv_analysis_id OR
         rs_job-requested_by <> sy-uname OR
         rs_job-selection_json <> iv_selection_json.
        RAISE EXCEPTION TYPE zcx_mig_legacy_capture
          EXPORTING iv_message = 'RequestId already belongs to another capture request.'.
      ENDIF.
      RETURN. "Idempotent retry with the same ID and input.
    ENDIF.

    rs_job = VALUE #( client = sy-mandt request_id = iv_request_id
      analysis_id = iv_analysis_id requested_by = sy-uname
      selection_json = iv_selection_json status = 'QUEUED'
      message = 'Queued. Run ZRMIG_LEGACY_WORKER under the requesting user.' ).
    GET TIME STAMP FIELD rs_job-created_at.
    rs_job-updated_at = rs_job-created_at.
    APPEND rs_job TO gt_jobs.
  ENDMETHOD.

  METHOD get_status.
    IF iv_analysis_id IS INITIAL OR iv_request_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'AnalysisId and RequestId are required.'.
    ENDIF.
    rs_job = VALUE #( gt_jobs[ request_id = iv_request_id ] OPTIONAL ).
    IF rs_job IS INITIAL.
      SELECT SINGLE * FROM zmig_legacy_job
        WHERE request_id = @iv_request_id AND analysis_id = @iv_analysis_id
          AND requested_by = @sy-uname INTO @rs_job.
    ENDIF.
    IF rs_job IS INITIAL OR rs_job-analysis_id <> iv_analysis_id OR
       rs_job-requested_by <> sy-uname.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'Capture request not found for this Analysis and user.'.
    ENDIF.
  ENDMETHOD.

  METHOD save_buffer.
    "Called only from the RAP saver; RAP owns the transaction commit.
    IF gt_jobs IS NOT INITIAL.
      INSERT zmig_legacy_job FROM TABLE @gt_jobs.
    ENDIF.
  ENDMETHOD.

  METHOD clear_buffer.
    CLEAR gt_jobs.
  ENDMETHOD.

  METHOD run.
    DATA(lt_selections) = parse_selections( iv_selection_json ).
    DATA(lr_rows) = NEW zcl_mig_legacy_alv_capture( )->capture(
      iv_analysis_id = iv_analysis_id
      it_selections = lt_selections ).
    rs_result = build_result( lr_rows ).
  ENDMETHOD.

  METHOD build_result.
    IF ir_rows IS NOT BOUND.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'ALV capture returned no table reference.'.
    ENDIF.
    FIELD-SYMBOLS <lt_rows> TYPE ANY TABLE.
    ASSIGN ir_rows->* TO <lt_rows>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'ALV capture returned an unsupported table type.'.
    ENDIF.
    rs_result-row_count = lines( <lt_rows> ).
    rs_result-rows_json = zcl_mig_legacy_alv_capture=>serialize_rows( ir_rows ).
    IF rs_result-rows_json IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'ALV serialization returned an empty JSON document.'.
    ENDIF.

    "Do not publish CAPTURED if the stored JSON has fewer rows than the
    "outtab. Validate the exact payload that will be written to the job.
    DATA lr_readback TYPE REF TO data.
    CREATE DATA lr_readback LIKE <lt_rows>.
    FIELD-SYMBOLS <lt_readback> TYPE ANY TABLE.
    ASSIGN lr_readback->* TO <lt_readback>.
    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = rs_result-rows_json
          CHANGING data = <lt_readback> ).
      CATCH cx_root INTO DATA(lx_json).
        RAISE EXCEPTION TYPE zcx_mig_legacy_capture
          EXPORTING
            iv_message = |Could not verify ALV JSON: { lx_json->get_text( ) }|
            previous = lx_json.
    ENDTRY.
    IF lines( <lt_readback> ) <> rs_result-row_count.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'ALV JSON row count differs from the captured table.'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

