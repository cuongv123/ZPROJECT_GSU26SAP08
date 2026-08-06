CLASS zcl_mig_art_repo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_art_repo.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_repo_key,
        object
          TYPE tadir-object,

        obj_name
          TYPE tadir-obj_name,
      END OF ty_repo_key,

      tt_repo_key
        TYPE SORTED TABLE OF ty_repo_key
        WITH UNIQUE KEY
          object
          obj_name.


    TYPES:
      BEGIN OF ty_tadir_row,
        object   TYPE tadir-object,
        obj_name TYPE tadir-obj_name,
        devclass TYPE tadir-devclass,
      END OF ty_tadir_row,

      tt_tadir_hash
        TYPE HASHED TABLE OF ty_tadir_row
        WITH UNIQUE KEY
          object
          obj_name.

ENDCLASS.

CLASS zcl_mig_art_repo IMPLEMENTATION.

  METHOD zif_mig_art_repo~read_info.

    DATA lt_items
      TYPE zif_mig_types=>tt_art_item.


    APPEND VALUE #(
      art_type    = iv_type
      object_name = iv_name
    ) TO lt_items.


    DATA(lt_info) =
      zif_mig_art_repo~read_many(
        it_items = lt_items
      ).


    READ TABLE lt_info
      INDEX 1
      INTO rs_info.


    IF sy-subrc <> 0.

      rs_info-art_type =
        iv_type.

      rs_info-object_name =
        iv_name.

      rs_info-read_ok =
        abap_false.

      rs_info-reason =
        'Repository adapter returned no result.'.

    ENDIF.

  ENDMETHOD.


  METHOD zif_mig_art_repo~read_many.

  CLEAR rt_info.

  IF it_items IS INITIAL.
    RETURN.
  ENDIF.


  DATA lt_keys
    TYPE tt_repo_key.


  LOOP AT it_items
    INTO DATA(ls_item).

    IF ls_item-art_type IS INITIAL
       OR ls_item-object_name IS INITIAL.

      CONTINUE.

    ENDIF.


    INSERT VALUE #(
      object =
        CONV tadir-object(
          ls_item-art_type
        )

      obj_name =
        CONV tadir-obj_name(
          ls_item-object_name
        )
    ) INTO TABLE lt_keys.

  ENDLOOP.


  DATA lt_tadir
    TYPE STANDARD TABLE OF ty_tadir_row
    WITH EMPTY KEY.


  IF lt_keys IS NOT INITIAL.

    TRY.

        SELECT
          object,
          obj_name,
          devclass
          FROM tadir
          FOR ALL ENTRIES IN @lt_keys
          WHERE pgmid    = 'R3TR'
            AND object   = @lt_keys-object
            AND obj_name = @lt_keys-obj_name
          INTO TABLE @lt_tadir.

      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

        LOOP AT it_items
          INTO ls_item.

          APPEND VALUE #(
            art_type =
              ls_item-art_type

            object_name =
              ls_item-object_name

            read_ok =
              abap_false

            exists =
              abap_false

            reason =
              lx_sql->get_text( )
          ) TO rt_info.

        ENDLOOP.

        RETURN.

    ENDTRY.

  ENDIF.


  DATA lt_tadir_hash
    TYPE tt_tadir_hash.

  INSERT LINES OF lt_tadir
    INTO TABLE lt_tadir_hash.


  LOOP AT it_items
    INTO ls_item.

    DATA ls_info
      TYPE zif_mig_types=>ty_art_repo_info.

    CLEAR ls_info.


    ls_info-art_type =
      ls_item-art_type.

    ls_info-object_name =
      ls_item-object_name.


    IF ls_item-art_type IS INITIAL
       OR ls_item-object_name IS INITIAL.

      ls_info-read_ok =
        abap_false.

      ls_info-reason =
        'Artifact type or object name is missing.'.

      APPEND ls_info
        TO rt_info.

      CONTINUE.

    ENDIF.


    ls_info-read_ok =
      abap_true.


    READ TABLE lt_tadir_hash
      WITH TABLE KEY
        object =
          ls_item-art_type

        obj_name =
          CONV tadir-obj_name(
            ls_item-object_name
          )

      INTO DATA(ls_tadir).


    IF sy-subrc = 0.

      ls_info-exists =
        abap_true.

      ls_info-package =
        ls_tadir-devclass.

      ls_info-reason =
        'Repository object exists.'.

    ELSE.

      ls_info-exists =
        abap_false.

      CLEAR ls_info-package.

      ls_info-reason =
        'Repository object does not exist.'.

    ENDIF.


    APPEND ls_info
      TO rt_info.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
