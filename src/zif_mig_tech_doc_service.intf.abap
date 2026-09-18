INTERFACE zif_mig_tech_doc_service
  PUBLIC.

  TYPES:
    BEGIN OF ty_document_result,

      analysis_id
        TYPE zif_mig_types=>ty_analysis_id,

      program_name
        TYPE progname,

      file_name
        TYPE c LENGTH 255,

      mime_type
        TYPE c LENGTH 80,

      markdown
        TYPE string,

    END OF ty_document_result.


  METHODS generate
    IMPORTING

      iv_analysis_id
        TYPE zif_mig_types=>ty_analysis_id

    RETURNING

      VALUE(rs_result)
        TYPE ty_document_result

    RAISING
      zcx_mig_analysis.

ENDINTERFACE.
