FUNCTION ZPO_PROC_ATC_WITH_PROXY_RESP.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(TRANSID) TYPE  STRING
*"     VALUE(DOC_TYPE) TYPE  STRING
*"     VALUE(ORDER_HEADER_IN) TYPE  BAPISDHD1
*"     VALUE(DOC_ITEM) TYPE  INT1
*"  TABLES
*"      ORDER_ITEMS_IN STRUCTURE  BAPISDITM OPTIONAL
*"      ORDER_PARTNERS STRUCTURE  BAPIPARNR OPTIONAL
*"      ORDER_SCHEDULES_IN STRUCTURE  BAPISCHDL OPTIONAL
*"----------------------------------------------------------------------
*no more using abap proxy to send data back to pi.

* function module to create ATC(sales order) and send response to pi using abap proxy.
* neccesary details will be compiled and sent to a background task for each individual order
* no ned for import and export parameters
* sometimes parent documents are either enqueued or archieved.. try processing one more time

  DATA: SALESDOCUMENT LIKE BAPIVBELN-VBELN,
        RETURN TYPE STANDARD TABLE OF BAPIRET2 WITH HEADER LINE,
        wa_ch type ZCHILDATC.

  DATA: ERROR TYPE STRING,
        TLINES TYPE I.
  TABLES ZCHILDATC.

  DESCRIBE TABLE ORDER_ITEMS_IN LINES TLINES.

  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      ORDER_HEADER_IN       = ORDER_HEADER_IN
      INT_NUMBER_ASSIGNMENT = 'X'
    IMPORTING
      SALESDOCUMENT         = SALESDOCUMENT
    TABLES
      RETURN                = RETURN
      ORDER_ITEMS_IN        = ORDER_ITEMS_IN
      ORDER_PARTNERS        = ORDER_PARTNERS
      ORDER_SCHEDULES_IN    = ORDER_SCHEDULES_IN.
  if ( sy-subrc = 0 and salesdocument is not initial ) .
    COMMIT WORK.
  endif.

* attempt one more time if salesdocument is empty attempt to post one more time
* better ways to handle failure will be reviewed
* wait for 1 second and try again

  if salesdocument is initial.
    clear return.
    wait UP TO 1 SECONDS.
    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        ORDER_HEADER_IN       = ORDER_HEADER_IN
        INT_NUMBER_ASSIGNMENT = 'X'
      IMPORTING
        SALESDOCUMENT         = SALESDOCUMENT
      TABLES
        RETURN                = RETURN
        ORDER_ITEMS_IN        = ORDER_ITEMS_IN
        ORDER_PARTNERS        = ORDER_PARTNERS
        ORDER_SCHEDULES_IN    = ORDER_SCHEDULES_IN.
    if sy-subrc = 0.
      COMMIT WORK.
    endif.
  endif.
* IF SALESDOCUMENT IS NOT INITIAL IT MEANS SLAES ORDER CREATION IS SUCCESSFUL
* IF RETURN IS NOT INITIAL SEND ERROR IN MT_SI_PROXY _OUTBOUND.

*CONSIDER EITHER SENDING ALL RETURN VALUES TO PI OR PROCESSING THE VALUES AND SEND
*SPECIFIC STATUS TO PI TO REDUCE THE PAYLOAD.

*move transaction id to wa_ch-trans_id.
move TRANSID to zchildatc-transid.
move doc_item to zchildatc-doc_item.
*MOVE DATA INTO WORK AREA OF ATC_IN.
  MOVE SALESDOCUMENT TO zchildatc-doc_num.
* CONCATENATE LINES OF RETURN INTO ERROR
  if SALESDOCUMENT is initial.
    "loop at return into errror

    loop at return.
      CONCATENATE zchildatc-MESSAGE ' '  RETURN-MESSAGE INTO zchildatc-MESSAGE.
    endloop.
  endif.
* MOVE DOC TYPE E.G PARENT OR CHILD ATC TO ATC_IN-DOC_TYPE
  MOVE DOC_TYPE TO zchildatc-doc_type.

* persist result in customer table
INSERT ZCHILDATC.

ENDFUNCTION.