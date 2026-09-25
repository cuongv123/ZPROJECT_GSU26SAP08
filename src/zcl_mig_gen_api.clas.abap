CLASS zcl_mig_gen_api DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES tt_jobs TYPE STANDARD TABLE OF zmig_gen_job WITH EMPTY KEY.
    CLASS-METHODS run
      IMPORTING is_request TYPE zif_mig_odata_gen_svc=>ty_request
                io_generator TYPE REF TO zif_mig_odata_gen_svc OPTIONAL
      RETURNING VALUE(rs_result) TYPE zif_mig_odata_gen_svc=>ty_result
      RAISING zcx_mig_analysis cx_xco_gen_put_exception.
    CLASS-METHODS preflight
      IMPORTING is_request TYPE zif_mig_odata_gen_svc=>ty_request
                io_generator TYPE REF TO zif_mig_odata_gen_svc OPTIONAL
      RETURNING VALUE(rs_result) TYPE zif_mig_odata_gen_svc=>ty_result
      RAISING zcx_mig_analysis cx_xco_gen_put_exception.
    CLASS-METHODS enqueue
      IMPORTING is_request TYPE zif_mig_odata_gen_svc=>ty_request
                iv_request_id TYPE sysuuid_x16
      RETURNING VALUE(rs_job) TYPE zmig_gen_job
      RAISING zcx_mig_analysis cx_xco_gen_put_exception.
    CLASS-METHODS get_status
      IMPORTING iv_analysis_id TYPE sysuuid_x16 iv_request_id TYPE sysuuid_x16
      RETURNING VALUE(rs_job) TYPE zmig_gen_job
      RAISING zcx_mig_analysis.
    CLASS-METHODS save_buffer.
    CLASS-METHODS clear_buffer.
    CLASS-METHODS normalize
      IMPORTING is_request TYPE zif_mig_odata_gen_svc=>ty_request
      RETURNING VALUE(rs_request) TYPE zif_mig_odata_gen_svc=>ty_request
      RAISING zcx_mig_analysis.
  PRIVATE SECTION.
    CLASS-DATA gt_jobs TYPE tt_jobs.
ENDCLASS.


CLASS zcl_mig_gen_api IMPLEMENTATION.

  METHOD normalize.
    rs_request = is_request.
    rs_request-package = to_upper( condense( rs_request-package ) ).
    rs_request-provider_package = to_upper( condense( rs_request-provider_package ) ).
    rs_request-provider_language = to_upper( condense( rs_request-provider_language ) ).
    rs_request-transport = to_upper( condense( rs_request-transport ) ).
    IF rs_request-provider_language IS INITIAL.
      rs_request-provider_language = zif_mig_prv_clas_gen=>gc_cloud.
    ENDIF.
    IF rs_request-analysis_id IS INITIAL OR rs_request-package IS INITIAL OR
       ( rs_request-provider_language <> zif_mig_prv_clas_gen=>gc_cloud AND
         rs_request-provider_language <> zif_mig_prv_clas_gen=>gc_standard ) OR
       ( rs_request-provider_language = zif_mig_prv_clas_gen=>gc_standard AND
         rs_request-provider_package IS INITIAL ) OR
       ( rs_request-execute = abap_true AND rs_request-transport IS INITIAL ).
      RAISE EXCEPTION TYPE zcx_mig_generation
        EXPORTING iv_detail = 'AnalysisId/TargetPackage required; ProviderLanguage must be CLOUD or STANDARD; STANDARD needs ProviderPackage; execute needs TransportRequest.'.
    ENDIF.
  ENDMETHOD.


  METHOD run.
    "Production calls reuse a deployment before normalization/preflight.
    "Injected generators are ABAP Unit seams and keep their old behavior.
    IF io_generator IS NOT BOUND.
      DATA(ls_existing) =
        NEW zcl_mig_svc_registry( )->find_by_analysis(
          iv_analysis_id = is_request-analysis_id ).

      IF ls_existing-status = zif_mig_odata_gen_svc=>gc_status_generated
         OR ls_existing-status = zif_mig_odata_gen_svc=>gc_status_stale.
        rs_result = ls_existing.
        RETURN.
      ENDIF.
    ENDIF.

    "Only report/worker may call this method with execute = X.
    DATA(ls_request) = normalize( is_request ).
    IF io_generator IS BOUND.
      rs_result = io_generator->generate( ls_request ).
      RETURN.
    ENDIF.
    DATA lo_provider TYPE REF TO zif_mig_prv_clas_gen.
    IF ls_request-provider_language = zif_mig_prv_clas_gen=>gc_standard.
      lo_provider = NEW zcl_mig_prv_std_gen( ).
    ENDIF.
    rs_result = NEW zcl_mig_odata_gen_svc( io_provider_gen = lo_provider
      )->zif_mig_odata_gen_svc~generate( ls_request ).
  ENDMETHOD.


  METHOD preflight.
    DATA(ls_request) = is_request.
    ls_request-execute = abap_false.
    rs_result = run( is_request = ls_request io_generator = io_generator ).
  ENDMETHOD.


  METHOD get_status.
    "Request IDs cannot be used to read another user's results.
    rs_job = VALUE #( gt_jobs[ request_id = iv_request_id ] OPTIONAL ).
    IF rs_job IS INITIAL.
      SELECT SINGLE * FROM zmig_gen_job
        WHERE request_id = @iv_request_id AND analysis_id = @iv_analysis_id
          AND requested_by = @sy-uname INTO @rs_job.
    ENDIF.
    IF rs_job IS INITIAL OR rs_job-analysis_id <> iv_analysis_id OR
       rs_job-requested_by <> sy-uname.
      RAISE EXCEPTION TYPE zcx_mig_generation
        EXPORTING iv_detail = 'Generation request not found for this Analysis and user.'.
    ENDIF.
  ENDMETHOD.


  METHOD enqueue.
    DATA(ls_input) = is_request.
    ls_input-execute = abap_true.
    DATA(ls_request) = normalize( ls_input ).
    IF iv_request_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mig_generation
        EXPORTING iv_detail = 'A nonzero client-generated RequestId (UUID) is required.'.
    ENDIF.
    DATA(lv_request_json) = /ui2/cl_json=>serialize( data = ls_request ).
    rs_job = VALUE #( gt_jobs[ request_id = iv_request_id ] OPTIONAL ).
    IF rs_job IS INITIAL.
      SELECT SINGLE * FROM zmig_gen_job WHERE request_id = @iv_request_id INTO @rs_job.
    ENDIF.
    IF rs_job IS NOT INITIAL.
      IF rs_job-requested_by <> sy-uname OR rs_job-request_json <> lv_request_json.
        RAISE EXCEPTION TYPE zcx_mig_generation
          EXPORTING iv_detail = 'RequestId already belongs to a different request. Use a new UUID for new parameters.'.
      ENDIF.
      RETURN.
    ENDIF.
    DATA(ls_check) = preflight( ls_request ).
    rs_job = VALUE #( client = sy-mandt request_id = iv_request_id
      analysis_id = ls_request-analysis_id requested_by = sy-uname
      request_json = lv_request_json status = ls_check-status
      result_json = /ui2/cl_json=>serialize( data = ls_check
        pretty_name = /ui2/cl_json=>pretty_mode-camel_case )
      message = ls_check-message ).
    GET TIME STAMP FIELD rs_job-created_at.
    rs_job-updated_at = rs_job-created_at.
    IF ls_check-status = zif_mig_odata_gen_svc=>gc_status_ready.
      rs_job-status = 'QUEUED'.
      rs_job-message = 'Queued. A generation worker must process this request.'.
    ENDIF.
    APPEND rs_job TO gt_jobs.
  ENDMETHOD.


  METHOD save_buffer.
    "Called only during RAP save. Never COMMIT or execute XCO here.
    IF gt_jobs IS NOT INITIAL.
      INSERT zmig_gen_job FROM TABLE @gt_jobs.
    ENDIF.
  ENDMETHOD.


  METHOD clear_buffer.
    CLEAR gt_jobs.
  ENDMETHOD.

ENDCLASS.
