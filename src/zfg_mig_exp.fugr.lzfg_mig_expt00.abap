*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_EXP_COL.....................................*
DATA:  BEGIN OF STATUS_ZTB_EXP_COL                   .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_EXP_COL                   .
CONTROLS: TCTRL_ZTB_EXP_COL
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_EXP_COL                   .
TABLES: ZTB_EXP_COL                    .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
