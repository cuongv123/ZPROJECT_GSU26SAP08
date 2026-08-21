REPORT zrmig_sample_full.

INCLUDE zrmig_sample_full_top.

TABLES t001w.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.

PARAMETERS:
  p_bukrs TYPE t001-bukrs
    OBLIGATORY
    DEFAULT '1000'.

SELECT-OPTIONS:
  s_werks FOR t001w-werks.

PARAMETERS:
  p_commit AS CHECKBOX.

SELECTION-SCREEN END OF BLOCK b1.


INCLUDE zrmig_sample_full_f01.


INITIALIZATION.

  p_commit = abap_false.


AT SELECTION-SCREEN ON p_bukrs.

  PERFORM validate_input.


START-OF-SELECTION.

  PERFORM load_data.
  PERFORM process_data.


END-OF-SELECTION.

  PERFORM display_data.
