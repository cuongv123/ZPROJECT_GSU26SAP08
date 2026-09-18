CLASS zcl_mig_stmt_normalizer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mig_stmt_normalizer.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_text_entry,
        statement_id TYPE i,
        prefix_length TYPE i,
        token_count   TYPE i,

        token_1       TYPE string,
        token_2       TYPE string,
        token_3       TYPE string,
        token_4       TYPE string,

        segment_text  TYPE string,
        prefix_text   TYPE string,
      END OF ty_text_entry,

      tt_text_map TYPE HASHED TABLE OF ty_text_entry
        WITH UNIQUE KEY statement_id.

      TYPES:
          BEGIN OF ty_block_frame,
            block_type     TYPE c LENGTH 30,
            context_before TYPE string,
            block_header   TYPE string,
            active_context TYPE string,
          END OF ty_block_frame,

          tt_block_stack TYPE STANDARD TABLE OF ty_block_frame
            WITH EMPTY KEY.

ENDCLASS.

CLASS zcl_mig_stmt_normalizer IMPLEMENTATION.

  METHOD zif_mig_stmt_normalizer~normalize.

    DATA:
      lt_text_map    TYPE tt_text_map,
      lt_block_stack TYPE tt_block_stack,

      lv_chain_active  TYPE abap_bool,
      lv_chain_prefix  TYPE string,
      lv_chain_keyword TYPE string,

      lv_routine_name TYPE c LENGTH 120,
      lv_routine_type TYPE c LENGTH 20,

      lv_execution_context TYPE string,

      lv_conditional_depth TYPE i,
      lv_iteration_depth   TYPE i,
      lv_try_depth         TYPE i,

      lv_context_category_count TYPE i,
      lv_context_boundary       TYPE abap_bool,
      lv_stack_index            TYPE i,

      ls_block_frame TYPE ty_block_frame.

    FIELD-SYMBOLS:
      <block_frame> TYPE ty_block_frame.

    rs_result = is_scan_result.

    LOOP AT rs_result-statements
      ASSIGNING FIELD-SYMBOL(<statement_init>).

      INSERT VALUE #(
        statement_id  = <statement_init>-statement_id
        prefix_length = <statement_init>-prefix_length
      ) INTO TABLE lt_text_map.

    ENDLOOP.

    LOOP AT rs_result-tokens
      ASSIGNING FIELD-SYMBOL(<token>).

      IF <token>-statement_id <= 0.
        CONTINUE.
      ENDIF.

      READ TABLE lt_text_map
        WITH TABLE KEY
          statement_id = <token>-statement_id
        ASSIGNING FIELD-SYMBOL(<text_entry>).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      <text_entry>-token_count += 1.


      CASE <text_entry>-token_count.

        WHEN 1.
          <text_entry>-token_1 = <token>-token_text.

        WHEN 2.
          <text_entry>-token_2 = <token>-token_text.

        WHEN 3.
          <text_entry>-token_3 = <token>-token_text.

        WHEN 4.
          <text_entry>-token_4 = <token>-token_text.

      ENDCASE.


      IF <text_entry>-segment_text IS INITIAL.

        <text_entry>-segment_text =
          <token>-token_text.

      ELSE.

        <text_entry>-segment_text =
          |{ <text_entry>-segment_text } {
             <token>-token_text }|.

      ENDIF.


      IF <text_entry>-prefix_length > 0
         AND <text_entry>-token_count
               <= <text_entry>-prefix_length.

        IF <text_entry>-prefix_text IS INITIAL.

          <text_entry>-prefix_text =
            <token>-token_text.

        ELSE.

          <text_entry>-prefix_text =
            |{ <text_entry>-prefix_text } {
               <token>-token_text }|.

        ENDIF.

      ENDIF.

    ENDLOOP.

    LOOP AT rs_result-statements
      ASSIGNING FIELD-SYMBOL(<statement>).

      READ TABLE lt_text_map
        WITH TABLE KEY
          statement_id = <statement>-statement_id
        ASSIGNING <text_entry>.

      IF sy-subrc <> 0.

        CLEAR:
          <statement>-statement_text,
          <statement>-parent_routine,
          <statement>-routine_type,
          <statement>-parent_block,
          <statement>-block_depth.

        CONTINUE.

      ENDIF.

      DATA:
        lv_statement_text TYPE string,
        lv_statement_type TYPE string,
        lv_token_1        TYPE string,
        lv_token_2        TYPE string,
        lv_token_3        TYPE string,
        lv_dummy          TYPE string.

      CLEAR:
        lv_statement_text,
        lv_statement_type,
        lv_token_1,
        lv_token_2,
        lv_token_3,
        lv_dummy.

      lv_token_1 =
        to_upper( <text_entry>-token_1 ).

      lv_token_2 =
        to_upper( <text_entry>-token_2 ).

      lv_token_3 =
        to_upper( <text_entry>-token_3 ).


        IF lv_chain_active = abap_true.


          IF lv_token_1 = lv_chain_keyword.

            lv_statement_text =
              <text_entry>-segment_text.

          ELSE.

            lv_statement_text =
              |{ lv_chain_prefix } {
                 <text_entry>-segment_text }|.

          ENDIF.

          lv_statement_type =
            lv_chain_keyword.

          IF <statement>-terminator = ','.

            lv_chain_active = abap_true.

          ELSE.

            CLEAR:
              lv_chain_active,
              lv_chain_prefix,
              lv_chain_keyword.

          ENDIF.

        ELSEIF <statement>-prefix_length > 0.


          lv_chain_prefix =
            <text_entry>-prefix_text.

          SPLIT lv_chain_prefix AT space
            INTO lv_chain_keyword lv_dummy.

          lv_chain_keyword =
            to_upper( lv_chain_keyword ).

          lv_statement_text =
            <text_entry>-segment_text.

          lv_statement_type =
            lv_chain_keyword.

          IF <statement>-terminator = ','.

            lv_chain_active = abap_true.

          ELSE.

            CLEAR:
              lv_chain_active,
              lv_chain_prefix,
              lv_chain_keyword.

          ENDIF.

        ELSE.

          CLEAR:
            lv_chain_active,
            lv_chain_prefix,
            lv_chain_keyword.

          lv_statement_text =
            <text_entry>-segment_text.

          lv_statement_type =
            lv_token_1.

        ENDIF.

      IF <statement>-terminator IS NOT INITIAL.

        lv_statement_text =
          |{ lv_statement_text }{
             <statement>-terminator }|.

      ENDIF.

      <statement>-statement_type =
        lv_statement_type.

      <statement>-statement_text =
        lv_statement_text.


        CLEAR lv_context_boundary.

        CASE <statement>-statement_type.

          WHEN 'FORM'
            OR 'METHOD'
            OR 'FUNCTION'
            OR 'MODULE'
            OR 'INITIALIZATION'
            OR 'START-OF-SELECTION'
            OR 'END-OF-SELECTION'
            OR 'TOP-OF-PAGE'
            OR 'END-OF-PAGE'
            OR 'LOAD-OF-PROGRAM'.

            lv_context_boundary =
              abap_true.

          WHEN 'AT'.

            IF lv_token_2 = 'SELECTION-SCREEN'
               OR lv_token_2 = 'LINE-SELECTION'
               OR lv_token_2 = 'USER-COMMAND'.

              lv_context_boundary =
                abap_true.

            ENDIF.

        ENDCASE.

        IF lv_context_boundary = abap_true.

          CLEAR:
            lt_block_stack,
            lv_execution_context,
            lv_conditional_depth,
            lv_iteration_depth,
            lv_try_depth.

        ENDIF.


      CASE <statement>-statement_type.

        WHEN 'FORM'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'FORM'.

          CLEAR lt_block_stack.

        WHEN 'METHOD'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'METHOD'.

          CLEAR lt_block_stack.

        WHEN 'FUNCTION'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'FUNCTION'.

          CLEAR lt_block_stack.

        WHEN 'MODULE'.

          lv_routine_name =
            lv_token_2.

          lv_routine_type = 'MODULE'.

          CLEAR lt_block_stack.

        WHEN 'INITIALIZATION'.

          lv_routine_name = 'INITIALIZATION'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'START-OF-SELECTION'.

          lv_routine_name = 'START-OF-SELECTION'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'END-OF-SELECTION'.

          lv_routine_name = 'END-OF-SELECTION'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'TOP-OF-PAGE'.

          lv_routine_name = 'TOP-OF-PAGE'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'END-OF-PAGE'.

          lv_routine_name = 'END-OF-PAGE'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'LOAD-OF-PROGRAM'.

          lv_routine_name = 'LOAD-OF-PROGRAM'.
          lv_routine_type = 'EVENT'.

          CLEAR lt_block_stack.

        WHEN 'AT'.

          CASE lv_token_2.

            WHEN 'SELECTION-SCREEN'.

              lv_routine_name =
                'AT SELECTION-SCREEN'.

              lv_routine_type = 'EVENT'.

              CLEAR lt_block_stack.

            WHEN 'LINE-SELECTION'.

              lv_routine_name =
                'AT LINE-SELECTION'.

              lv_routine_type = 'EVENT'.

              CLEAR lt_block_stack.

            WHEN 'USER-COMMAND'.

              lv_routine_name =
                'AT USER-COMMAND'.

              lv_routine_type = 'EVENT'.

              CLEAR lt_block_stack.

            WHEN OTHERS.



          ENDCASE.

      ENDCASE.


      <statement>-parent_routine =
        lv_routine_name.

      <statement>-routine_type =
        lv_routine_type.


        <statement>-block_depth =
          lines( lt_block_stack ).

        CLEAR <statement>-parent_block.

        IF lt_block_stack IS NOT INITIAL.

          lv_stack_index =
            lines( lt_block_stack ).

          READ TABLE lt_block_stack
            INDEX lv_stack_index
            ASSIGNING <block_frame>.

          IF sy-subrc = 0.

            <statement>-parent_block =
              <block_frame>-block_type.

          ENDIF.

        ENDIF.


        <statement>-execution_context =
          lv_execution_context.



        CLEAR lv_context_category_count.

        IF lv_conditional_depth > 0.
          lv_context_category_count += 1.
        ENDIF.

        IF lv_iteration_depth > 0.
          lv_context_category_count += 1.
        ENDIF.

        IF lv_try_depth > 0.
          lv_context_category_count += 1.
        ENDIF.


        CASE lv_context_category_count.

          WHEN 0.

            <statement>-execution_kind =
              'DIRECT'.

          WHEN 1.

            IF lv_conditional_depth > 0.

              <statement>-execution_kind =
                'CONDITIONAL'.

            ELSEIF lv_iteration_depth > 0.

              <statement>-execution_kind =
                'ITERATIVE'.

            ELSE.

              <statement>-execution_kind =
                'TRY_CONTEXT'.

            ENDIF.

          WHEN OTHERS.

            <statement>-execution_kind =
              'MIXED'.

        ENDCASE.



        CASE <statement>-statement_type.


          WHEN 'ELSEIF'
            OR 'ELSE'.

            IF lt_block_stack IS NOT INITIAL.

              lv_stack_index =
                lines( lt_block_stack ).

              READ TABLE lt_block_stack
                INDEX lv_stack_index
                ASSIGNING <block_frame>.

              IF sy-subrc = 0
                 AND <block_frame>-block_type = 'IF'.

                <block_frame>-active_context =
                  <statement>-statement_text.

                IF <block_frame>-context_before IS INITIAL.

                  lv_execution_context =
                    <block_frame>-active_context.

                ELSE.

                  lv_execution_context =
                    |{ <block_frame>-context_before } > {
                       <block_frame>-active_context }|.

                ENDIF.

              ENDIF.

            ENDIF.


          WHEN 'WHEN'.

            IF lt_block_stack IS NOT INITIAL.

              lv_stack_index =
                lines( lt_block_stack ).

              READ TABLE lt_block_stack
                INDEX lv_stack_index
                ASSIGNING <block_frame>.

              IF sy-subrc = 0
                 AND <block_frame>-block_type = 'CASE'.

                <block_frame>-active_context =
                  |{ <block_frame>-block_header } > {
                     <statement>-statement_text }|.

                IF <block_frame>-context_before IS INITIAL.

                  lv_execution_context =
                    <block_frame>-active_context.

                ELSE.

                  lv_execution_context =
                    |{ <block_frame>-context_before } > {
                       <block_frame>-active_context }|.

                ENDIF.

              ENDIF.

            ENDIF.



          WHEN 'CATCH'
            OR 'CLEANUP'.

            IF lt_block_stack IS NOT INITIAL.

              lv_stack_index =
                lines( lt_block_stack ).

              READ TABLE lt_block_stack
                INDEX lv_stack_index
                ASSIGNING <block_frame>.

              IF sy-subrc = 0
                 AND <block_frame>-block_type = 'TRY'.

                <block_frame>-active_context =
                  |{ <block_frame>-block_header } > {
                     <statement>-statement_text }|.

                IF <block_frame>-context_before IS INITIAL.

                  lv_execution_context =
                    <block_frame>-active_context.

                ELSE.

                  lv_execution_context =
                    |{ <block_frame>-context_before } > {
                       <block_frame>-active_context }|.

                ENDIF.

              ENDIF.

            ENDIF.

        ENDCASE.



        CASE <statement>-statement_type.

          WHEN 'IF'
            OR 'CASE'
            OR 'LOOP'
            OR 'DO'
            OR 'WHILE'
            OR 'TRY'.

            CLEAR ls_block_frame.

            ls_block_frame-block_type =
              <statement>-statement_type.

            ls_block_frame-context_before =
              lv_execution_context.

            ls_block_frame-block_header =
              <statement>-statement_text.

            ls_block_frame-active_context =
              <statement>-statement_text.


            APPEND ls_block_frame
              TO lt_block_stack.


            IF lv_execution_context IS INITIAL.

              lv_execution_context =
                ls_block_frame-active_context.

            ELSE.

              lv_execution_context =
                |{ lv_execution_context } > {
                   ls_block_frame-active_context }|.

            ENDIF.


            CASE <statement>-statement_type.

              WHEN 'IF'
                OR 'CASE'.

                lv_conditional_depth += 1.

              WHEN 'LOOP'
                OR 'DO'
                OR 'WHILE'.

                lv_iteration_depth += 1.

              WHEN 'TRY'.

                lv_try_depth += 1.

            ENDCASE.

        ENDCASE.



        CASE <statement>-statement_type.

          WHEN 'ENDIF'
            OR 'ENDCASE'
            OR 'ENDLOOP'
            OR 'ENDDO'
            OR 'ENDWHILE'
            OR 'ENDTRY'.

            IF lt_block_stack IS NOT INITIAL.

              lv_stack_index =
                lines( lt_block_stack ).

              READ TABLE lt_block_stack
                INDEX lv_stack_index
                INTO ls_block_frame.

              IF sy-subrc = 0.

                CASE ls_block_frame-block_type.

                  WHEN 'IF'
                    OR 'CASE'.

                    IF lv_conditional_depth > 0.
                      lv_conditional_depth -= 1.
                    ENDIF.

                  WHEN 'LOOP'
                    OR 'DO'
                    OR 'WHILE'.

                    IF lv_iteration_depth > 0.
                      lv_iteration_depth -= 1.
                    ENDIF.

                  WHEN 'TRY'.

                    IF lv_try_depth > 0.
                      lv_try_depth -= 1.
                    ENDIF.

                ENDCASE.


                lv_execution_context =
                  ls_block_frame-context_before.


                DELETE lt_block_stack
                  INDEX lv_stack_index.

              ENDIF.

            ENDIF.

        ENDCASE.


      CASE <statement>-statement_type.

          WHEN 'ENDFORM'
            OR 'ENDMETHOD'
            OR 'ENDFUNCTION'
            OR 'ENDMODULE'.

            CLEAR:
              lv_routine_name,
              lv_routine_type,
              lt_block_stack,
              lv_execution_context,
              lv_conditional_depth,
              lv_iteration_depth,
              lv_try_depth.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
