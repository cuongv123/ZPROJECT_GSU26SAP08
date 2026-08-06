*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_EXP_SECTION.................................*
DATA:  BEGIN OF STATUS_ZTB_EXP_SECTION               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_EXP_SECTION               .
CONTROLS: TCTRL_ZTB_EXP_SECTION
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_EXP_SECTION               .
TABLES: ZTB_EXP_SECTION                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
