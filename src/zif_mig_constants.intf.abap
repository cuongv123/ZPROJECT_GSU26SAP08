INTERFACE zif_mig_constants
  PUBLIC .

  " 1. Object Types (Dùng cho Type của Node)
  CONSTANTS:
    BEGIN OF c_obj_type,
      table  TYPE string VALUE 'TABLE',
      filter TYPE string VALUE 'FILTER',
      cds    TYPE string VALUE 'CDS_VIEW',
      rap_bo TYPE string VALUE 'RAP_BO',
      bapi   TYPE string VALUE 'BAPI',
      action TYPE string VALUE 'RAP_ACTION',
    END OF c_obj_type.

  " 2. Relation Types (Dùng cho loại Cạnh/Đường nối)
  CONSTANTS:
    BEGIN OF c_rel_type,
      queries       TYPE string VALUE 'QUERIES',       " VD: Filter queries Table
      migrates_to   TYPE string VALUE 'MIGRATES_TO',   " VD: Table migrates to CDS
      implemented_by TYPE string VALUE 'IMPLEMENTED_BY', " VD: BAPI implemented by RAP Action
    END OF c_rel_type.

    " 3. Analysis Status
  CONSTANTS:
    BEGIN OF c_status,
      analyzed    TYPE string VALUE 'Analyzed',
      in_progress TYPE string VALUE 'In Progress',
      failed      TYPE string VALUE 'Failed',
    END OF c_status.

  " 4. Complexity Levels
  CONSTANTS:
    BEGIN OF c_complexity,
      low    TYPE i VALUE 1,
      medium TYPE i VALUE 2,
      high   TYPE i VALUE 3,
      severe TYPE i VALUE 4,
    END OF c_complexity.

ENDINTERFACE.
