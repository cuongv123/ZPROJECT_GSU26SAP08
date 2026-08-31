CLASS lhc_exportjob DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ExportJob RESULT result.
ENDCLASS.

CLASS lhc_exportjob IMPLEMENTATION.

  METHOD get_instance_authorizations.

    DATA(lv_now) = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) ).

    READ ENTITIES OF zi_mig_exp_job
      ENTITY ExportJob
      FIELDS ( ExpiresAt )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_jobs).

        result = VALUE #( FOR ls_job IN lt_jobs
      ( %tky = ls_job-%tky
         ) ).


  ENDMETHOD.

ENDCLASS.
