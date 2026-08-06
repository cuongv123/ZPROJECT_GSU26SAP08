INTERFACE zif_mig_odata_gen_svc PUBLIC.

  TYPES:
    BEGIN OF ty_request,
      analysis_id TYPE sysuuid_x16,
      package     TYPE devclass,
      transport   TYPE trkorr,
      execute     TYPE abap_bool,
    END OF ty_request,

    BEGIN OF ty_result,
      analysis_id          TYPE sysuuid_x16,
      status               TYPE c LENGTH 20,
      provider_kind        TYPE c LENGTH 20,
      provider_object      TYPE c LENGTH 120,
      query_provider_class TYPE c LENGTH 30,
      entity_name          TYPE c LENGTH 30,
      service_name         TYPE c LENGTH 30,
      service_binding      TYPE c LENGTH 30,
      service_url          TYPE string,
      message              TYPE string,
    END OF ty_result.

  METHODS generate
    IMPORTING
      is_request TYPE ty_request
    RETURNING
      VALUE(rs_result) TYPE ty_result
    RAISING
      zcx_mig_analysis
      cx_xco_gen_put_exception.

ENDINTERFACE.
