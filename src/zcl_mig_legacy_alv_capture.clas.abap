" Read the actual ALV outtab of a previously analyzed report.
" Create this object with ABAP language version Standard ABAP.
CLASS zcl_mig_legacy_alv_capture DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_selections TYPE STANDARD TABLE OF rsparams WITH EMPTY KEY.

    METHODS capture
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_selections  TYPE ty_t_selections OPTIONAL
      RETURNING VALUE(rr_rows) TYPE REF TO data
      RAISING zcx_mig_legacy_capture.

    METHODS capture_json
      IMPORTING
        iv_analysis_id TYPE zif_mig_types=>ty_analysis_id
        it_selections  TYPE ty_t_selections OPTIONAL
      RETURNING VALUE(rv_json) TYPE string
      RAISING zcx_mig_legacy_capture.
ENDCLASS.

CLASS zcl_mig_legacy_alv_capture IMPLEMENTATION.
  METHOD capture.
    IF iv_analysis_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'Analysis ID is required.'.
    ENDIF.

    TRY.
        DATA(lo_reader) = NEW zcl_mig_analysis_reader( ).
        DATA(ls_analysis) = lo_reader->zif_mig_analysis_reader~read(
          iv_analysis_id ).
      CATCH zcx_mig_analysis INTO DATA(lx_analysis).
        RAISE EXCEPTION TYPE zcx_mig_legacy_capture
          EXPORTING
            iv_message = |Could not read analysis: { lx_analysis->get_text( ) }|
            previous   = lx_analysis.
    ENDTRY.

    DATA(lv_program) = ls_analysis-overview-program_name.
    IF lv_program IS INITIAL OR ls_analysis-alv_outputs IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = 'Analysis has no source report or ALV output.'.
    ENDIF.

    " Only selection fields found during analysis may be passed to SUBMIT.
    LOOP AT it_selections INTO DATA(ls_selection).
      IF ls_selection-selname IS INITIAL OR
         NOT line_exists( ls_analysis-ui_filters[
           field_name = ls_selection-selname ] ).
        RAISE EXCEPTION TYPE zcx_mig_legacy_capture
          EXPORTING
            iv_message = |Selection field { ls_selection-selname } is not in the analysis.|.
      ENDIF.
    ENDLOOP.

    TRY.
        cl_salv_bs_runtime_info=>set(
          display  = abap_false
          metadata = abap_false
          data     = abap_true ).

        SUBMIT (lv_program)
          WITH SELECTION-TABLE it_selections
          AND RETURN.

        cl_salv_bs_runtime_info=>get_data_ref(
          IMPORTING r_data = rr_rows ).
      CATCH cx_root INTO DATA(lx_runtime).
        cl_salv_bs_runtime_info=>clear_all( ).
        RAISE EXCEPTION TYPE zcx_mig_legacy_capture
          EXPORTING
            iv_message = |Could not capture { lv_program }: { lx_runtime->get_text( ) }|
            previous   = lx_runtime.
    ENDTRY.

    cl_salv_bs_runtime_info=>clear_all( ).
    IF rr_rows IS NOT BOUND.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = |Report { lv_program } returned no ALV table reference.|.
    ENDIF.

    FIELD-SYMBOLS <lt_rows> TYPE ANY TABLE.
    ASSIGN rr_rows->* TO <lt_rows>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_mig_legacy_capture
        EXPORTING iv_message = |Report { lv_program } returned an unsupported ALV data type.|.
    ENDIF.
  ENDMETHOD.

  METHOD capture_json.
    DATA(lr_rows) = capture(
      iv_analysis_id = iv_analysis_id
      it_selections  = it_selections ).
    FIELD-SYMBOLS <lt_rows> TYPE ANY TABLE.
    ASSIGN lr_rows->* TO <lt_rows>.
    rv_json = /ui2/cl_json=>serialize(
      data     = <lt_rows>
      compress = abap_true ).
  ENDMETHOD.
ENDCLASS.

