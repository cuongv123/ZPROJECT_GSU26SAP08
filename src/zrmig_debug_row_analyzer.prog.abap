REPORT zrmig_debug_row_analyzer.

PARAMETERS p_prog
  TYPE progname
  DEFAULT 'ZRMIG_TEST_R1_ALV_COVERAGE'
  OBLIGATORY.


START-OF-SELECTION.

  TRY.

      DATA(lo_source_repo) =
        NEW zcl_mig_source_repo( ).

      DATA(lo_scanner) =
        NEW zcl_mig_abap_scanner( ).

      DATA(lo_normalizer) =
        NEW zcl_mig_stmt_normalizer( ).

      DATA(lo_alv_analyzer) =
        NEW zcl_mig_alv_analyzer( ).

      DATA(lo_row_analyzer) =
        NEW zcl_mig_alv_row_analyzer( ).


      DATA(lt_source) =
        lo_source_repo->zif_mig_source_repo~read_program(
          iv_program_name = p_prog
        ).


      DATA(ls_scan_result) =
        lo_scanner->zif_mig_abap_scanner~scan(
          iv_source_object = p_prog
          it_source        = lt_source
        ).


      DATA(ls_normalized) =
        lo_normalizer->zif_mig_stmt_normalizer~normalize(
          is_scan_result = ls_scan_result
        ).


      DATA lt_source_units
        TYPE zif_mig_types=>tt_source_unit.


      APPEND VALUE #(
        source_object = VALUE #(
          object_name  = p_prog
          object_type  = 'PROGRAM'
          source_lines = lt_source
        )
        scan_result = ls_normalized
      ) TO lt_source_units.


      DATA(ls_alv_result) =
        lo_alv_analyzer->zif_mig_alv_analyzer~analyze(
          it_source_units = lt_source_units
        ).


      DATA(ls_row_result) =
        lo_row_analyzer->zif_mig_alv_fcat_analyzer~analyze(
          it_source_units = lt_source_units
          it_alv_outputs  = ls_alv_result-alv_outputs
        ).


      WRITE:
        / 'Program            :', p_prog,
        / 'Source lines       :', lines( lt_source ),
        / 'Statements         :', lines( ls_normalized-statements ),
        / 'Tokens             :', lines( ls_normalized-tokens ),
        / 'ALV outputs        :', lines( ls_alv_result-alv_outputs ),
        / 'Inferred columns   :', lines( ls_row_result-alv_columns ).


      ULINE.


      WRITE:
        / 'ALV OUTPUTS'.


      LOOP AT ls_alv_result-alv_outputs
        INTO DATA(ls_output).

        WRITE:
          / '----------------------------------------------',
          / 'Framework     :', ls_output-framework,
          / 'Output table  :', ls_output-output_table,
          / 'Field catalog :', ls_output-field_catalog,
          / 'Row type      :', ls_output-row_type,
          / 'Output ID     :', ls_output-output_id.

      ENDLOOP.


      ULINE.


      WRITE:
        / 'NORMALIZED TYPES / DATA STATEMENTS'.


      LOOP AT ls_normalized-statements
        INTO DATA(ls_statement).


        DATA(lv_upper_text) =
          to_upper(
            ls_statement-statement_text
          ).


        IF ls_statement-statement_type <> 'TYPES'
           AND ls_statement-statement_type <> 'DATA'
           AND lv_upper_text NS 'TY_RESULT'
           AND lv_upper_text NS 'TT_RESULT'
           AND lv_upper_text NS 'GT_RESULT'.

          CONTINUE.

        ENDIF.


        WRITE:
          / '==============================================',
          / 'Statement ID  :', ls_statement-statement_id,
          / 'Statement type:', ls_statement-statement_type,
          / 'Start line    :', ls_statement-start_line,
          / 'End line      :', ls_statement-end_line,
          / 'Prefix length :', ls_statement-prefix_length,
          / 'Terminator    :', ls_statement-terminator,
          / 'Text          :', ls_statement-statement_text,
          / 'Tokens        :'.


        LOOP AT ls_normalized-tokens
          INTO DATA(ls_token)
          WHERE statement_id = ls_statement-statement_id.

          WRITE:
            / '  ', ls_token-token_text.

        ENDLOOP.

      ENDLOOP.


      ULINE.


      WRITE:
        / 'INFERRED COLUMNS'.


      LOOP AT ls_row_result-alv_columns
        INTO DATA(ls_column).

        WRITE:
          / '----------------------------------------------',
          / 'Field         :', ls_column-field_name,
          / 'Label         :', ls_column-label,
          / 'Data type     :', ls_column-data_type,
          / 'Data element  :', ls_column-data_element,
          / 'Reference     :',
              ls_column-reference_table,
              ls_column-reference_field,
          / 'Output ID     :', ls_column-output_id.

      ENDLOOP.


    CATCH zcx_mig_analysis INTO DATA(lx_mig).

      WRITE:
        / 'MIG error:', lx_mig->get_text( ).


    CATCH cx_root INTO DATA(lx_root).

      WRITE:
        / 'Unexpected error:', lx_root->get_text( ).

  ENDTRY.
