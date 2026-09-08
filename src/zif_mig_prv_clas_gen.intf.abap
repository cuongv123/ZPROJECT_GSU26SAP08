INTERFACE zif_mig_prv_clas_gen PUBLIC.
  TYPES:
    ty_name TYPE c LENGTH 30,
    ty_package TYPE c LENGTH 30,
    ty_transport TYPE c LENGTH 20,
    ty_language TYPE c LENGTH 10,
    tt_source TYPE string_table,
    BEGIN OF ty_check,
      allowed TYPE abap_bool,
      language_code TYPE c LENGTH 1,
      message TYPE string,
    END OF ty_check.

  CONSTANTS:
    gc_cloud TYPE ty_language VALUE 'CLOUD',
    gc_standard TYPE ty_language VALUE 'STANDARD'.

  METHODS check_target
    IMPORTING iv_package TYPE ty_package
    RETURNING VALUE(rs_check) TYPE ty_check.

  METHODS generate
    IMPORTING
      iv_class_name TYPE ty_name
      iv_package TYPE ty_package
      iv_transport TYPE ty_transport
      it_select_source TYPE tt_source
    RAISING zcx_mig_analysis.
ENDINTERFACE.
