INTERFACE zif_mig_odata_gen_svc PUBLIC.

  CONSTANTS:
    gc_status_ready     TYPE c LENGTH 20 VALUE 'READY',
    gc_status_generated TYPE c LENGTH 20 VALUE 'GENERATED',
    gc_status_blocked   TYPE c LENGTH 20 VALUE 'BLOCKED'.

  TYPES:
    BEGIN OF ty_request,
      analysis_id TYPE sysuuid_x16,
      package     TYPE devclass,
      provider_package TYPE devclass,
      provider_language TYPE c LENGTH 10,
      transport   TYPE trkorr,
      execute     TYPE abap_bool,
    END OF ty_request,

    BEGIN OF ty_result,
      analysis_id          TYPE sysuuid_x16,
      status               TYPE c LENGTH 20,
      strategy             TYPE zif_mig_types=>ty_service_strategy,
      manual_review        TYPE abap_bool,
      create_count         TYPE i,
      block_count          TYPE i,
      provider_kind        TYPE c LENGTH 20,
      provider_object      TYPE c LENGTH 120,
      query_provider_class TYPE c LENGTH 30,
      provider_package     TYPE devclass,
      provider_language    TYPE c LENGTH 10,
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
