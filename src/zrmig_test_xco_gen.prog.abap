REPORT zrmig_test_xco_gen.


PARAMETERS:
  p_class TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZCL_MIG_Q_TEST07',

  p_ddls TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZC_MIG_Q_TEST07',

  p_pack TYPE devclass
    DEFAULT 'ZMIG_GEN_TEST',

  p_req TYPE trkorr
    DEFAULT 'S40K918252',

  p_exec AS CHECKBOX
    DEFAULT abap_false.


START-OF-SELECTION.

  DATA ls_mfst
    TYPE zif_mig_types=>ty_art_mfst.

  DATA ls_bp
        TYPE zif_mig_types=>ty_service_blueprint_result.


      ls_bp-blueprint-strategy =
        zif_mig_types=>gc_svc_query.

      ls_bp-blueprint-manual_review =
        abap_false.


      APPEND VALUE #(
        field_name = 'Material'
        label      = 'Material'
        edm_type   = 'Edm.String'
        position   = 10
        key_field  = abap_true
        visible    = abap_true
        filterable = abap_true
        sortable   = abap_true
      ) TO ls_bp-fields.


      APPEND VALUE #(
        field_name = 'Description'
        label      = 'Description'
        edm_type   = 'Edm.String'
        position   = 20
        visible    = abap_true
        filterable = abap_true
        sortable   = abap_true
      ) TO ls_bp-fields.


      APPEND VALUE #(
        field_name = 'Plant'
        label      = 'Plant'
        edm_type   = 'Edm.String'
        position   = 30
        visible    = abap_true
        filterable = abap_true
        sortable   = abap_true
      ) TO ls_bp-fields.

      APPEND VALUE #(
      field_name = 'Quantity'
      label      = 'Quantity'
      edm_type   = 'Edm.Int32'
      position   = 40
      visible    = abap_true
      sortable   = abap_true
    ) TO ls_bp-fields.


    APPEND VALUE #(
      field_name = 'Amount'
      label      = 'Amount'
      edm_type   = 'Edm.Decimal'
      position   = 50
      visible    = abap_true
      sortable   = abap_true
    ) TO ls_bp-fields.


    APPEND VALUE #(
      field_name = 'ValidOn'
      label      = 'Valid On'
      edm_type   = 'Edm.Date'
      position   = 60
      visible    = abap_true
      filterable = abap_true
      sortable   = abap_true
    ) TO ls_bp-fields.


    APPEND VALUE #(
      field_name = 'CreatedAt'
      label      = 'Created At'
      edm_type   = 'Edm.DateTimeOffset'
      position   = 70
      visible    = abap_true
      sortable   = abap_true
    ) TO ls_bp-fields.


    APPEND VALUE #(
      field_name = 'IsActive'
      label      = 'Is Active'
      edm_type   = 'Edm.Boolean'
      position   = 80
      visible    = abap_true
      filterable = abap_true
    ) TO ls_bp-fields.




  "============================================================
  " 1. Tạo manifest tối thiểu cho checkpoint CLAS
  "============================================================
  ls_mfst-strategy =
    zif_mig_types=>gc_svc_query.

  ls_mfst-source_program =
    sy-repid.

  ls_mfst-package =
    p_pack.

  ls_mfst-base_name =
    'TEST01'.

  "Manifest trước Preflight phải READY
  "vì XCO Capability đã được xác nhận
  ls_mfst-status =
    zif_mig_types=>gc_art_ready.

  ls_mfst-manual_review =
    abap_false.


  APPEND VALUE #(
    seq =
      10

    art_type =
      zif_mig_types=>gc_art_clas

    art_role =
      zif_mig_types=>gc_art_query_prv

    object_name =
      p_class

    package =
      p_pack

    description =
      'Generated MIG query provider test'

    gen_order =
      10

    required =
      abap_true

    cap_state =
      zif_mig_types=>gc_art_cap_yes

    gen_state =
      zif_mig_types=>gc_art_planned
  ) TO ls_mfst-items.

    APPEND VALUE #(
  seq =
    20

  art_type =
    zif_mig_types=>gc_art_ddls

  art_role =
    zif_mig_types=>gc_art_entity

  object_name =
    p_ddls

  package =
    p_pack

  description =
    'Generated MIG custom entity test'

  gen_order =
    20

  required =
    abap_true

  cap_state =
    zif_mig_types=>gc_art_cap_yes

  gen_state =
    zif_mig_types=>gc_art_planned
) TO ls_mfst-items.

  APPEND VALUE #(
  art_seq = 20
  req_seq = 10
) TO ls_mfst-dependencies.



  ls_mfst-item_count =
    lines( ls_mfst-items ).

  ls_mfst-dep_count =
    lines( ls_mfst-dependencies ).

  TRY.

      "==========================================================
      " 2. Repository Preflight thật
      "==========================================================
      DATA(lo_pref) =
        NEW zcl_mig_art_pref(
          io_repo =
            NEW zcl_mig_art_repo( )
        ).


      DATA(ls_pref) =
        lo_pref->zif_mig_art_pref~apply(
          is_mfst = ls_mfst
        ).


      WRITE:
        / 'Manifest status :', ls_pref-status,
        / 'Create count    :', ls_pref-create_count,
        / 'Block count     :', ls_pref-block_count.


      LOOP AT ls_pref-items
        INTO DATA(ls_item).

        WRITE:
          / 'Object          :', ls_item-object_name,
          / 'Generation mode :', ls_item-gen_mode,
          / 'Generation state:', ls_item-gen_state,
          / 'Reason          :', ls_item-reason.

      ENDLOOP.


      "==========================================================
      " 3. Không gọi XCO khi Preflight chưa READY
      "==========================================================
      IF ls_pref-status <>
           zif_mig_types=>gc_art_ready.

        WRITE:
          / 'Generator was not executed.'.

        RETURN.

      ENDIF.



      "==========================================================
      " 4. Gọi generator
      "==========================================================
      DATA(lo_gen) =
        NEW zcl_mig_xco_gen( ).


      lo_gen->generate_query(
       is_mfst =
         ls_pref

       is_bp =
         ls_bp

       iv_request =
         p_req

       iv_execute =
         p_exec
     ).


      IF p_exec = abap_true.

        WRITE:
          / 'XCO execute completed.',
          / 'Refresh package:', p_pack.

      ELSE.

        WRITE:
          / 'Dry run completed.',
          / 'No repository object was created.'.

      ENDIF.


    CATCH zcx_mig_analysis INTO DATA(lx_mig).

      WRITE:
        / 'MIG error:',
          lx_mig->get_text( ).


    CATCH cx_xco_gen_put_exception INTO DATA(lx_xco).

  WRITE:
    / 'XCO generation error:',
      lx_xco->get_text( ).


  DATA(lt_messages) =
    lx_xco->if_xco_news~get_messages( ).


  IF lt_messages IS INITIAL.

    WRITE:
      / 'No detailed XCO message returned.'.

  ELSE.

    WRITE:
      / 'Detailed XCO messages:'.


    LOOP AT lt_messages
      INTO DATA(lo_message).

      WRITE:
        / lo_message->get_text( ).

    ENDLOOP.

  ENDIF.


    CATCH cx_root INTO DATA(lx_root).

      WRITE:
        / 'Unexpected error:',
          lx_root->get_text( ).

  ENDTRY.
