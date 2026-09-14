TYPES:
  BEGIN OF ty_result,
    bukrs TYPE t001-bukrs,
    butxt TYPE t001-butxt,
    werks TYPE t001w-werks,
  END OF ty_result,

  tt_result TYPE STANDARD TABLE OF ty_result
    WITH EMPTY KEY.


DATA:
  gt_result TYPE tt_result,

  gt_fcat   TYPE lvc_t_fcat,
  gt_sort   TYPE lvc_t_sort,
  gt_filter TYPE lvc_t_filt,

  gs_layout  TYPE lvc_s_layo,
  gs_variant TYPE disvariant.


CLASS lcl_worker DEFINITION FINAL.

  PUBLIC SECTION.

    CLASS-METHODS enrich_static
      CHANGING
        ct_result TYPE tt_result.

    METHODS calculate
      CHANGING
        ct_result TYPE tt_result.

ENDCLASS.


CLASS lcl_handler DEFINITION FINAL.

  PUBLIC SECTION.

    METHODS handle_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING
        e_row
        e_column.

ENDCLASS.


CLASS lcl_worker IMPLEMENTATION.

  METHOD enrich_static.

    IF ct_result IS INITIAL.
      RETURN.
    ENDIF.

  ENDMETHOD.


  METHOD calculate.

    IF ct_result IS INITIAL.
      RETURN.
    ENDIF.

  ENDMETHOD.

ENDCLASS.


CLASS lcl_handler IMPLEMENTATION.

  METHOD handle_double_click.

    IF e_row-index IS INITIAL.
      RETURN.
    ENDIF.

  ENDMETHOD.

ENDCLASS.


DATA:
  go_container TYPE REF TO cl_gui_custom_container,
  go_grid      TYPE REF TO cl_gui_alv_grid,
  go_handler   TYPE REF TO lcl_handler.
