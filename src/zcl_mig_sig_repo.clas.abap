CLASS zcl_mig_sig_repo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_sig_repo.

  PRIVATE SECTION.

    METHODS add_fm_par
      IMPORTING
        VALUE(iv_name) TYPE string
        VALUE(iv_dir)  TYPE zif_mig_types=>ty_sig_dir
        VALUE(iv_type) TYPE string
        VALUE(iv_opt)  TYPE abap_bool
        VALUE(iv_tab)  TYPE abap_bool
        VALUE(iv_ref)  TYPE abap_bool
      CHANGING
        ct_par TYPE zif_mig_types=>tt_sig_par.

    METHODS enrich_par
      CHANGING
        cs_par TYPE zif_mig_types=>ty_sig_par.

    METHODS fill_rtti
      IMPORTING
        io_type TYPE REF TO cl_abap_datadescr
      CHANGING
        cs_par TYPE zif_mig_types=>ty_sig_par.

ENDCLASS.

CLASS zcl_mig_sig_repo IMPLEMENTATION.

  METHOD zif_mig_sig_repo~read_fm.

    DATA:
      lv_fm  TYPE rs38l-name,

      lt_imp TYPE STANDARD TABLE OF rsimp
        WITH DEFAULT KEY,

      lt_exp TYPE STANDARD TABLE OF rsexp
        WITH DEFAULT KEY,

      lt_chg TYPE STANDARD TABLE OF rscha
        WITH DEFAULT KEY,

      lt_tab TYPE STANDARD TABLE OF rstbl
        WITH DEFAULT KEY,

      lt_exc TYPE STANDARD TABLE OF rsexc
        WITH DEFAULT KEY.

    CLEAR rs_sig.

    lv_fm =
      to_upper(
        CONV string( iv_fm )
      ).

    rs_sig-obj_name =
      lv_fm.

    IF lv_fm CP 'BAPI_*'.

      rs_sig-provider_kind =
        zif_mig_types=>gc_provider_bapi.

    ELSE.

      rs_sig-provider_kind =
        zif_mig_types=>gc_provider_function.

    ENDIF.

    CALL FUNCTION 'FUNCTION_IMPORT_INTERFACE'
      EXPORTING
        funcname           = lv_fm
      TABLES
        exception_list     = lt_exc
        import_parameter   = lt_imp
        export_parameter   = lt_exp
        changing_parameter = lt_chg
        tables_parameter   = lt_tab
      EXCEPTIONS
        error_message      = 1
        function_not_found = 2
        invalid_name       = 3
        OTHERS             = 4.

    IF sy-subrc <> 0.

      rs_sig-exists =
        abap_false.

      RETURN.

    ENDIF.


    rs_sig-exists =
      abap_true.


    "==========================================================
    " IMPORTING
    "==========================================================
    LOOP AT lt_imp
      INTO DATA(ls_imp).

      DATA(lv_imp_type) =
        CONV string( ls_imp-typ ).

      IF lv_imp_type IS INITIAL.

        lv_imp_type =
          CONV string( ls_imp-dbfield ).

      ENDIF.


      add_fm_par(
        EXPORTING
          iv_name = CONV string(
            ls_imp-parameter
          )

          iv_dir =
            zif_mig_types=>gc_sig_imp

          iv_type =
            lv_imp_type

          iv_opt =
            xsdbool(
              ls_imp-optional = abap_true
            )

          iv_tab =
            xsdbool(
              ls_imp-table_of = abap_true
            )

          iv_ref =
            xsdbool(
              ls_imp-ref_class = abap_true
            )

        CHANGING
          ct_par =
            rs_sig-params
      ).

    ENDLOOP.


    "==========================================================
    " EXPORTING
    "==========================================================
    LOOP AT lt_exp
      INTO DATA(ls_exp).

      DATA(lv_exp_type) =
        CONV string( ls_exp-typ ).

      IF lv_exp_type IS INITIAL.

        lv_exp_type =
          CONV string( ls_exp-dbfield ).

      ENDIF.


      add_fm_par(
        EXPORTING
          iv_name = CONV string(
            ls_exp-parameter
          )

          iv_dir =
            zif_mig_types=>gc_sig_exp

          iv_type =
            lv_exp_type

          iv_opt =
            abap_false

          iv_tab =
            xsdbool(
              ls_exp-table_of = abap_true
            )

          iv_ref =
            xsdbool(
              ls_exp-ref_class = abap_true
            )

        CHANGING
          ct_par =
            rs_sig-params
      ).

    ENDLOOP.


    "==========================================================
    " CHANGING
    "==========================================================
    LOOP AT lt_chg
      INTO DATA(ls_chg).

      DATA(lv_chg_type) =
        CONV string( ls_chg-typ ).

      IF lv_chg_type IS INITIAL.

        lv_chg_type =
          CONV string( ls_chg-dbfield ).

      ENDIF.


      add_fm_par(
        EXPORTING
          iv_name = CONV string(
            ls_chg-parameter
          )

          iv_dir =
            zif_mig_types=>gc_sig_chg

          iv_type =
            lv_chg_type

          iv_opt =
            xsdbool(
              ls_chg-optional = abap_true
            )

          iv_tab =
            xsdbool(
              ls_chg-table_of = abap_true
            )

          iv_ref =
            xsdbool(
              ls_chg-ref_class = abap_true
            )

        CHANGING
          ct_par =
            rs_sig-params
      ).

    ENDLOOP.


    "==========================================================
    " TABLES
    "==========================================================
    LOOP AT lt_tab
      INTO DATA(ls_tab).

      DATA(lv_tab_type) =
        CONV string( ls_tab-typ ).

      IF lv_tab_type IS INITIAL.

        lv_tab_type =
          CONV string( ls_tab-dbstruct ).

      ENDIF.


      add_fm_par(
        EXPORTING
          iv_name = CONV string(
            ls_tab-parameter
          )

          iv_dir =
            zif_mig_types=>gc_sig_tab

          iv_type =
            lv_tab_type

          iv_opt =
            xsdbool(
              ls_tab-optional = abap_true
            )

          iv_tab =
            abap_true

          iv_ref =
            abap_false

        CHANGING
          ct_par =
            rs_sig-params
      ).

    ENDLOOP.


    SORT rs_sig-params
      BY direction
         par_name.

  ENDMETHOD.

    METHOD zif_mig_sig_repo~read_mth.

    DATA:
      lv_class TYPE string,
      lv_mth   TYPE string.

    CLEAR rs_sig.

    lv_class =
      to_upper(
        CONV string( iv_class )
      ).

    lv_mth =
      to_upper(
        CONV string( iv_mth )
      ).


    rs_sig-provider_kind =
      zif_mig_types=>gc_provider_class_method.

    rs_sig-class_name =
      lv_class.

    rs_sig-method_name =
      lv_mth.


    TRY.

        DATA(lo_cls) =
          CAST cl_abap_classdescr(
            cl_abap_typedescr=>describe_by_name(
              lv_class
            )
          ).

      CATCH cx_root INTO DATA(lx_error).

        rs_sig-exists =
          abap_false.

        CLEAR rs_sig-params.

        RETURN.

    ENDTRY.


    READ TABLE lo_cls->methods
      WITH KEY name = lv_mth
      INTO DATA(ls_mth).

    IF sy-subrc <> 0.

      rs_sig-exists =
        abap_false.

      RETURN.

    ENDIF.


    "Chỉ chọn public method làm provider target
    IF ls_mth-visibility <>
         cl_abap_objectdescr=>public.

      rs_sig-exists =
        abap_false.

      RETURN.

    ENDIF.


    rs_sig-exists =
      abap_true.

    rs_sig-is_static =
      ls_mth-is_class.


    LOOP AT ls_mth-parameters
      INTO DATA(ls_mth_par).

      DATA ls_sig_par
        TYPE zif_mig_types=>ty_sig_par.

      CLEAR ls_sig_par.


      ls_sig_par-par_name =
        ls_mth_par-name.

      ls_sig_par-optional =
        ls_mth_par-is_optional.


      CASE ls_mth_par-parm_kind.

        WHEN cl_abap_objectdescr=>importing.

          ls_sig_par-direction =
            zif_mig_types=>gc_sig_imp.


        WHEN cl_abap_objectdescr=>exporting.

          ls_sig_par-direction =
            zif_mig_types=>gc_sig_exp.


        WHEN cl_abap_objectdescr=>changing.

          ls_sig_par-direction =
            zif_mig_types=>gc_sig_chg.


        WHEN cl_abap_objectdescr=>returning.

          ls_sig_par-direction =
            zif_mig_types=>gc_sig_ret.


        WHEN OTHERS.

          CONTINUE.

      ENDCASE.


      DATA lo_type
        TYPE REF TO cl_abap_datadescr.

      CALL METHOD lo_cls->get_method_parameter_type
        EXPORTING
          p_method_name    = lv_mth
          p_parameter_name = ls_mth_par-name
        RECEIVING
          p_descr_ref      = lo_type
        EXCEPTIONS
          parameter_not_found = 1
          method_not_found    = 2
          OTHERS              = 3.

      IF sy-subrc = 0
         AND lo_type IS BOUND.

        fill_rtti(
          EXPORTING
            io_type = lo_type
          CHANGING
            cs_par  = ls_sig_par
        ).

      ENDIF.


      APPEND ls_sig_par
        TO rs_sig-params.

    ENDLOOP.


    SORT rs_sig-params
      BY direction
         par_name.

  ENDMETHOD.

    METHOD add_fm_par.

    DATA ls_par
      TYPE zif_mig_types=>ty_sig_par.

    CLEAR ls_par.


    DATA(lv_name) =
      to_upper( iv_name ).

    IF strlen( lv_name ) > 30.

      lv_name =
        substring(
          val = lv_name
          len = 30
        ).

    ENDIF.


    ls_par-par_name =
      lv_name.

    ls_par-direction =
      iv_dir.

    ls_par-abap_type =
      iv_type.

    ls_par-type_name =
      iv_type.

    ls_par-optional =
      iv_opt.

    ls_par-is_table =
      iv_tab.

    ls_par-is_ref =
      iv_ref.

    ls_par-is_deep =
      abap_false.


    enrich_par(
      CHANGING
        cs_par = ls_par
    ).


    "Không để RTTS làm mất thông tin TABLES
    IF iv_tab = abap_true.

      ls_par-is_table =
        abap_true.

    ENDIF.


    "Không để RTTS làm mất reference flag gốc
    IF iv_ref = abap_true.

      ls_par-is_ref =
        abap_true.

    ENDIF.


    APPEND ls_par
      TO ct_par.

  ENDMETHOD.

    METHOD enrich_par.

    IF cs_par-type_name IS INITIAL.
      RETURN.
    ENDIF.


    TRY.

        DATA(lo_type) =
          CAST cl_abap_datadescr(
            cl_abap_typedescr=>describe_by_name(
              cs_par-type_name
            )
          ).

        fill_rtti(
          EXPORTING
            io_type = lo_type
          CHANGING
            cs_par  = cs_par
        ).

      CATCH cx_root.

        "Giữ metadata lấy từ Function Builder.
        "Không biến signature hợp lệ thành lỗi chỉ vì
        "type name không resolve trực tiếp bằng RTTS.

    ENDTRY.

  ENDMETHOD.

    METHOD fill_rtti.

    IF io_type IS NOT BOUND.
      RETURN.
    ENDIF.


    cs_par-abap_type =
      io_type->type_kind.


    IF io_type->absolute_name IS NOT INITIAL.

      cs_par-type_name =
        io_type->absolute_name.

    ENDIF.


    IF io_type IS INSTANCE OF
         cl_abap_tabledescr.

      cs_par-is_table =
        abap_true.

    ENDIF.


    IF io_type IS INSTANCE OF
         cl_abap_refdescr.

      cs_par-is_ref =
        abap_true.

    ENDIF.


    "Nested/deep structure detection sẽ làm ở bước riêng.
    cs_par-is_deep =
      abap_false.

  ENDMETHOD.

ENDCLASS.
