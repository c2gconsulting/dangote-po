*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZPO_FG_COMP_PLAN
*   generation date: 09.10.2015 at 12:55:04
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZPO_FG_COMP_PLAN   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.