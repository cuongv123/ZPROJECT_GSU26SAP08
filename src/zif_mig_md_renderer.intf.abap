INTERFACE zif_mig_md_renderer
  PUBLIC.

  METHODS render
    IMPORTING
      is_document
        TYPE zif_mig_tech_doc_builder=>ty_tech_document

    RETURNING
      VALUE(rv_markdown)
        TYPE string.

ENDINTERFACE.
