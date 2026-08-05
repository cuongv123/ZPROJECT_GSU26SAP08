REPORT zrmig_test_xco_gen.

PARAMETERS:
  p_class TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZCL_MIG_Q_TEST15',

  p_ddls TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZC_MIG_Q_TEST15',

  p_srvd TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZUI_MIG_Q_TEST15',

  p_srvb TYPE zif_mig_types=>ty_art_name
    DEFAULT 'ZUI_MIG_Q_TEST15_O4',

  p_pack TYPE devclass
    DEFAULT 'ZMIG_GEN_TEST',

  p_req TYPE trkorr
    DEFAULT 'S40K918252',

  p_exec AS CHECKBOX
    DEFAULT abap_false.

START-OF-SELECTION.

  CONSTANTS gc_anl_id
    TYPE zif_mig_types=>ty_analysis_id
    VALUE '00000000000000000000000000000088'.

  DATA:
  ls_prv  TYPE zif_mig_types=>ty_provider_contract,
  ls_sig  TYPE zif_mig_types=>ty_sig_result,
  ls_smap TYPE zif_mig_types=>ty_svc_map_result.


  DATA ls_mfst
    TYPE zif_mig_types=>ty_art_mfst.

  DATA ls_bp
        TYPE zif_mig_types=>ty_service_blueprint_result.


      ls_bp-blueprint-strategy =
        zif_mig_types=>gc_svc_query.

      ls_bp-blueprint-manual_review =
        abap_false.
      ls_bp-blueprint-entity_name =
        'MigrationResult'.

      ls_mfst-analysis_id =
         gc_anl_id.

       ls_bp-blueprint-analysis_id =
             gc_anl_id.

       ls_prv-analysis_id =
        gc_anl_id.

      ls_prv-service_strategy =
        zif_mig_types=>gc_svc_query.

      ls_prv-provider_kind =
        zif_mig_types=>gc_provider_class_method.

      ls_prv-provider_status =
        zif_mig_types=>gc_provider_ready.

      ls_prv-source_container_name =
        'ZCL_MIG_TEST_PROVIDER'.

      ls_prv-source_object_name =
        'GET_DATA'.

      ls_prv-manual_review =
        abap_false.

      ls_sig-analysis_id =
  gc_anl_id.

      ls_sig-service_strategy =
        zif_mig_types=>gc_svc_query.

      ls_sig-provider_kind =
        zif_mig_types=>gc_provider_class_method.

      ls_sig-container_name =
        'ZCL_MIG_TEST_PROVIDER'.

      ls_sig-object_name =
        'GET_DATA'.

      ls_sig-status =
        zif_mig_types=>gc_sig_ready.

      ls_sig-manual_review =
        abap_false.
      ls_bp-blueprint-supports_filter =
      abap_true.

    ls_bp-blueprint-source_program =
      sy-repid.

DATA ls_in
  TYPE zif_mig_types=>ty_sig_par.


"============================================================
" Input 1 — Plant
"============================================================
CLEAR ls_in.

ls_in-par_name =
  'IV_PLANT'.

ls_in-direction =
  zif_mig_types=>gc_sig_imp.

ls_in-abap_type =
  'CHAR'.

ls_in-edm_type =
  'Edm.String'.

ls_in-odata_role =
  zif_mig_types=>gc_sig_in.

ls_in-optional =
  abap_true.

ls_in-is_table =
  abap_false.


APPEND ls_in
  TO ls_sig-input_params.

APPEND ls_in
  TO ls_sig-all_params.


"============================================================
" Input 2 — Material
"============================================================
CLEAR ls_in.

ls_in-par_name =
  'IT_MATERIAL'.

ls_in-direction =
  zif_mig_types=>gc_sig_imp.

ls_in-abap_type =
  'TABLE'.

ls_in-type_name =
  'ZCL_MIG_TEST_PROVIDER=>TY_R_MATERIAL'.

ls_in-edm_type =
  'Edm.String'.

ls_in-odata_role =
  zif_mig_types=>gc_sig_in.

ls_in-optional =
  abap_true.

ls_in-is_table =
  abap_true.


APPEND ls_in
  TO ls_sig-input_params.

APPEND ls_in
  TO ls_sig-all_params.

CLEAR ls_in.

ls_in-par_name =
  'IV_QUANTITY'.

ls_in-direction =
  zif_mig_types=>gc_sig_imp.

ls_in-abap_type =
  'INT4'.

ls_in-edm_type =
  'Edm.Int32'.

ls_in-odata_role =
  zif_mig_types=>gc_sig_in.

ls_in-optional =
  abap_true.

ls_in-is_table =
  abap_false.

APPEND ls_in TO ls_sig-input_params.
APPEND ls_in TO ls_sig-all_params.

CLEAR ls_in.

ls_in-par_name =
  'IV_AMOUNT'.

ls_in-direction =
  zif_mig_types=>gc_sig_imp.

ls_in-abap_type =
  'DECFLOAT16'.

ls_in-edm_type =
  'Edm.Decimal'.

ls_in-odata_role =
  zif_mig_types=>gc_sig_in.

ls_in-optional =
  abap_true.

ls_in-is_table =
  abap_false.

APPEND ls_in TO ls_sig-input_params.
APPEND ls_in TO ls_sig-all_params.

CLEAR ls_in.

ls_in-par_name =
  'IV_VALID_ON'.

ls_in-direction =
  zif_mig_types=>gc_sig_imp.

ls_in-abap_type =
  'DATS'.

ls_in-edm_type =
  'Edm.Date'.

ls_in-odata_role =
  zif_mig_types=>gc_sig_in.

ls_in-optional =
  abap_true.

ls_in-is_table =
  abap_false.

APPEND ls_in TO ls_sig-input_params.
APPEND ls_in TO ls_sig-all_params.

DATA ls_ret
  TYPE zif_mig_types=>ty_sig_par.


        ls_ret-par_name =
          'RT_DATA'.

        ls_ret-direction =
          zif_mig_types=>gc_sig_ret.

        ls_ret-abap_type =
          'TABLE'.

        ls_ret-type_name =
          'ZCL_MIG_TEST_PROVIDER=>TT_DATA'.

        ls_ret-edm_type =
          'Collection'.

        ls_ret-odata_role =
          zif_mig_types=>gc_sig_out.

        ls_ret-is_table =
          abap_true.


        APPEND ls_ret
          TO ls_sig-output_params.

        APPEND ls_ret
          TO ls_sig-all_params.


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
        filterable = abap_false
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
      filterable = abap_true
      sortable   = abap_true
    ) TO ls_bp-fields.


    APPEND VALUE #(
   field_name = 'Amount'
   label      = 'Amount'
   edm_type   = 'Edm.Decimal'
   position   = 50
   visible    = abap_true
   filterable = abap_true
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
      filterable = abap_false
    ) TO ls_bp-fields.

    APPEND VALUE #(
      parameter_name     = 'Plant'
      source_kind        = 'PARAMETERS'
      odata_kind         = 'SCALAR'
      edm_type           = 'Edm.String'
      mandatory          = abap_false
      multiple_selection = abap_false
      range_supported    = abap_false
    ) TO ls_bp-parameters.

    APPEND VALUE #(
    parameter_name     = 'Material'
    source_kind        = 'SELECT-OPTIONS'
    odata_kind         = 'RANGE'
    edm_type           = 'Edm.String'
    mandatory          = abap_false
    multiple_selection = abap_true
    range_supported    = abap_true
  ) TO ls_bp-parameters.

    APPEND VALUE #(
  parameter_name     = 'Quantity'
  source_kind        = 'PARAMETERS'
  odata_kind         = 'SCALAR'
  edm_type           = 'Edm.Int32'
  mandatory          = abap_false
  multiple_selection = abap_false
  range_supported    = abap_false
) TO ls_bp-parameters.


APPEND VALUE #(
  parameter_name     = 'Amount'
  source_kind        = 'PARAMETERS'
  odata_kind         = 'SCALAR'
  edm_type           = 'Edm.Decimal'
  mandatory          = abap_false
  multiple_selection = abap_false
  range_supported    = abap_false
) TO ls_bp-parameters.


APPEND VALUE #(
  parameter_name     = 'ValidOn'
  source_kind        = 'PARAMETERS'
  odata_kind         = 'SCALAR'
  edm_type           = 'Edm.Date'
  mandatory          = abap_false
  multiple_selection = abap_false
  range_supported    = abap_false
) TO ls_bp-parameters.

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
  seq =
    40

  art_type =
    zif_mig_types=>gc_art_srvd

  art_role =
    zif_mig_types=>gc_art_srv_def

  object_name =
    p_srvd

  package =
    p_pack

  description =
    'Generated MIG service definition test'

  gen_order =
    40

  required =
    abap_true

  cap_state =
    zif_mig_types=>gc_art_cap_yes

  gen_state =
    zif_mig_types=>gc_art_planned
) TO ls_mfst-items.

  APPEND VALUE #(
  seq =
    50

  art_type =
    zif_mig_types=>gc_art_srvb

  art_role =
    zif_mig_types=>gc_art_srv_bind

  object_name =
    p_srvb

  package =
    p_pack

  description =
    'Generated MIG OData V4 binding test'

  gen_order =
    50

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

  APPEND VALUE #(
  art_seq = 40
  req_seq = 20
) TO ls_mfst-dependencies.
  APPEND VALUE #(
    art_seq = 50
    req_seq = 40
  ) TO ls_mfst-dependencies.


  ls_mfst-item_count =
    lines( ls_mfst-items ).

  ls_mfst-dep_count =
    lines( ls_mfst-dependencies ).

  TRY.

      "==========================================================
    " Build Service Mapping
    "==========================================================
    ls_smap =
      NEW zcl_mig_svc_map(
        )->zif_mig_svc_map~build(
          is_bp =
            ls_bp

          is_sig =
            ls_sig
        ).


    WRITE:
      / 'Service map status :', ls_smap-status,
      / 'Mapped inputs      :', ls_smap-mapped_inputs,
      / 'Mapping issues     :', ls_smap-issue_count.


    IF ls_smap-status <>
         zif_mig_types=>gc_smap_ready.

      WRITE:
        / 'Generator stopped because service mapping is not ready.'.

      RETURN.

    ENDIF.


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

        is_prv =
          ls_prv

        is_sig =
          ls_sig

        is_smap =
          ls_smap

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
