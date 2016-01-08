*&---------------------------------------------------------------------*
*& Report  ZPROCESS_PARALLEL_BAPI
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZPROCESS_PARALLEL_BAPI.
*USING BAPI ZPO_POPULATE_TABLE..
*TO TEST PARRALEL BAPI PROCESSING FOR PI ATC AND ABAP PROXY SCENARIO
DATA: COUNT TYPE I,
      STATUS TYPE STRING,
      TEXT TYPE STRING,
      SNUM TYPE STRING,
      MAXDOCNUM TYPE INT4,
      NUM TYPE INT4.
PARAMETERS: BATCH TYPE INT4.

START-OF-SELECTION.

  IF BATCH IS NOT INITIAL.
    SELECT MAX( DOCNUM ) FROM ZZDOCS INTO MAXDOCNUM.
    IF SY-SUBRC = 0.
* INITIALIZE COUNT
      COUNT = 1.
      WHILE COUNT <> BATCH.
        NUM = MAXDOCNUM + COUNT.
        SNUM = NUM.
        CONCATENATE 'CREATE DOCNUM ' SNUM INTO TEXT RESPECTING BLANKS.
        CALL FUNCTION 'ZPO_POPULATE_TABLE'
          STARTING NEW TASK TEXT
          DESTINATION 'NONE'
          EXPORTING
            DOCNUM        = NUM
            TEXT          = TEXT
*   IMPORTING
           STATUS        = STATUS
*   TABLES
*     ZZDOCS        =
                  .
        "INCREMENT COUNT
        COUNT = COUNT + 1.
        CLEAR: NUM, SNUM, TEXT.
      ENDWHILE.
    ENDIF.
  ENDIF.
  WRITE 'DONE PROCESSING'.