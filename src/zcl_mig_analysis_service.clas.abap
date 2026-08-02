    CLASS zcl_mig_analysis_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_analysis_service.

    METHODS constructor
      IMPORTING
        io_source_repo
          TYPE REF TO zif_mig_source_repo OPTIONAL

        io_include_resolver
          TYPE REF TO zif_mig_include_resolver OPTIONAL

        io_scanner
          TYPE REF TO zif_mig_abap_scanner OPTIONAL

        io_normalizer
          TYPE REF TO zif_mig_stmt_normalizer OPTIONAL

        io_aggregator
          TYPE REF TO zif_mig_analysis_agg OPTIONAL

        io_store
          TYPE REF TO zif_mig_analysis_store OPTIONAL.

  PRIVATE SECTION.

    DATA:
      mo_source_repo
        TYPE REF TO zif_mig_source_repo,

      mo_include_resolver
        TYPE REF TO zif_mig_include_resolver,

      mo_scanner
        TYPE REF TO zif_mig_abap_scanner,

      mo_normalizer
        TYPE REF TO zif_mig_stmt_normalizer,

      mo_aggregator
        TYPE REF TO zif_mig_analysis_agg,

      mo_store
        TYPE REF TO zif_mig_analysis_store.

    METHODS build_source_units
      IMPORTING
        iv_program_name TYPE zif_mig_types=>ty_program_name
        iv_analysis_id  TYPE zif_mig_types=>ty_analysis_id
      RETURNING
        VALUE(rt_source_units)
          TYPE zif_mig_types=>tt_source_unit
      RAISING
        zcx_mig_analysis.

    METHODS create_uuid
      IMPORTING
        iv_program_name TYPE zif_mig_types=>ty_program_name
      RETURNING
        VALUE(rv_analysis_id)
          TYPE zif_mig_types=>ty_analysis_id
      RAISING
        zcx_mig_analysis.
     METHODS create_item_id
      IMPORTING
        iv_source_object TYPE progname
      RETURNING
        VALUE(rv_item_id)
          TYPE zif_mig_types=>ty_item_id
      RAISING
        zcx_mig_analysis.

ENDCLASS.

CLASS zcl_mig_analysis_service IMPLEMENTATION.

METHOD constructor.

  IF io_source_repo IS BOUND.

    mo_source_repo =
      io_source_repo.

  ELSE.

    mo_source_repo =
      NEW zcl_mig_source_repo( ).

  ENDIF.


  IF io_scanner IS BOUND.

    mo_scanner =
      io_scanner.

  ELSE.

    mo_scanner =
      NEW zcl_mig_abap_scanner( ).

  ENDIF.


  IF io_include_resolver IS BOUND.

    mo_include_resolver =
      io_include_resolver.

  ELSE.

    mo_include_resolver =
      NEW zcl_mig_include_resolver(
        io_source_repo = mo_source_repo
        io_scanner     = mo_scanner
      ).

  ENDIF.


  IF io_normalizer IS BOUND.

    mo_normalizer =
      io_normalizer.

  ELSE.

    mo_normalizer =
      NEW zcl_mig_stmt_normalizer( ).

  ENDIF.


  IF io_aggregator IS BOUND.

    mo_aggregator =
      io_aggregator.

  ELSE.

    mo_aggregator =
      NEW zcl_mig_analysis_agg( ).

  ENDIF.


  "==========================================================
  " Persistence Store
  "==========================================================
  IF io_store IS BOUND.

    mo_store =
      io_store.

  ELSE.

    mo_store =
      NEW zcl_mig_analysis_store( ).

  ENDIF.

ENDMETHOD.

METHOD build_source_units.

  "==========================================================
  " Resolver đã thực hiện:
  " - đọc root program
  " - tìm nested INCLUDE
  " - đọc source từng object
  " - scan từng object
  "
  " Kết quả đã là TT_SOURCE_UNIT.
  "==========================================================
  rt_source_units =
    mo_include_resolver->resolve(
      iv_root_program = iv_program_name
    ).


  IF rt_source_units IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid       = zcx_mig_analysis=>analysis_failed
      program_name = iv_program_name
    ).

  ENDIF.


  LOOP AT rt_source_units
  ASSIGNING FIELD-SYMBOL(<source_unit>).

  "Toàn bộ root/include thuộc cùng analysis
  <source_unit>-source_object-analysis_id =
    iv_analysis_id.

  "Mỗi source object có identity riêng trong snapshot
  IF <source_unit>-source_object-item_id IS INITIAL.

    <source_unit>-source_object-item_id =
      create_item_id(
        iv_source_object =
          <source_unit>-source_object-object_name
      ).

  ENDIF.

  <source_unit>-source_object-line_count =
    lines(
      <source_unit>-source_object-source_lines
    ).

  DATA(ls_normalized_scan) =
    mo_normalizer->normalize(
      is_scan_result =
        <source_unit>-scan_result
    ).

  <source_unit>-scan_result =
    ls_normalized_scan.

ENDLOOP.

ENDMETHOD.

METHOD zif_mig_analysis_service~analyze_program.

  DATA lv_program_name
    TYPE zif_mig_types=>ty_program_name.

  lv_program_name =
    to_upper(
      CONV string(
        iv_program_name
      )
    ).

  CONDENSE lv_program_name NO-GAPS.


  IF lv_program_name IS INITIAL.

    RAISE EXCEPTION NEW zcx_mig_analysis(
      textid       = zcx_mig_analysis=>analysis_failed
      program_name = lv_program_name
    ).

  ENDIF.


  "==========================================================
  " Analysis ID
  "==========================================================
  DATA lv_analysis_id
    TYPE zif_mig_types=>ty_analysis_id.

  lv_analysis_id =
    iv_analysis_id.

  IF lv_analysis_id IS INITIAL.

    lv_analysis_id =
      create_uuid(
        iv_program_name = lv_program_name
      ).

  ENDIF.


  "==========================================================
  " Root + nested includes + normalized statements
  "==========================================================
  DATA(lt_source_units) =
    build_source_units(
      iv_program_name = lv_program_name
      iv_analysis_id  = lv_analysis_id
    ).


  "==========================================================
  " Aggregate all facts and enrichments
  "==========================================================
  rs_result =
    mo_aggregator->analyze(
      iv_analysis_id  = lv_analysis_id
      it_source_units = lt_source_units
    ).


  "==========================================================
  " Preserve application-level identity
  "==========================================================
  rs_result-analysis_id =
    lv_analysis_id.

  rs_result-overview-analysis_id =
    lv_analysis_id.

  rs_result-overview-program_name =
    lv_program_name.

ENDMETHOD.

METHOD zif_mig_analysis_service~analyze_and_save.

  "==========================================================
  " 1. Chạy toàn bộ analysis pipeline
  "==========================================================
  rs_result =
    me->zif_mig_analysis_service~analyze_program(
      iv_program_name = iv_program_name
      iv_analysis_id  = iv_analysis_id
    ).


  "==========================================================
  " 2. Persist toàn bộ kết quả
  "
  " Store không COMMIT WORK.
  " Caller hoặc RAP LUW sẽ quản lý transaction.
  "==========================================================
  mo_store->save(
    is_result = rs_result
  ).

ENDMETHOD.

METHOD create_uuid.

  TRY.

      rv_analysis_id =
        cl_system_uuid=>create_uuid_x16_static( ).

    CATCH cx_uuid_error INTO DATA(lx_uuid).

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        previous     = lx_uuid
        program_name = iv_program_name
      ).

  ENDTRY.

ENDMETHOD.

METHOD create_item_id.

  TRY.

      rv_item_id =
        cl_system_uuid=>create_uuid_x16_static( ).

    CATCH cx_uuid_error INTO DATA(lx_uuid).

      RAISE EXCEPTION NEW zcx_mig_analysis(
        textid       = zcx_mig_analysis=>analysis_failed
        previous     = lx_uuid
        program_name = iv_source_object
      ).

  ENDTRY.

ENDMETHOD.

ENDCLASS.
