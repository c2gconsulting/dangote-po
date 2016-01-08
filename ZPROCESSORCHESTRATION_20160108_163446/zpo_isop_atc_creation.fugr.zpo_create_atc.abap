FUNCTION ZPO_CREATE_ATC.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(DELIVERY_STATUS) TYPE  STRING OPTIONAL
*"     VALUE(TRANSACTION_ID) TYPE  STRING OPTIONAL
*"     VALUE(SALES_ORG) TYPE  VKORG OPTIONAL
*"     VALUE(DIVISION) TYPE  SPART OPTIONAL
*"     VALUE(PLANT) TYPE  WERKS_D OPTIONAL
*"     VALUE(CUST_NUM) TYPE  KUNNR OPTIONAL
*"     VALUE(CITY) TYPE  STRING OPTIONAL
*"     VALUE(STREET) TYPE  STRING OPTIONAL
*"     VALUE(COUNTRY) TYPE  STRING OPTIONAL
*"     VALUE(CUST_NAME) TYPE  STRING OPTIONAL
*"     VALUE(REGION) TYPE  REGIO OPTIONAL
*"     VALUE(IS_PARENT) TYPE  BOOLEAN OPTIONAL
*"     VALUE(REF_DOC_NO) TYPE  VBELN_VA OPTIONAL
*"     VALUE(ACCESS_TOKEN) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(TRAN_ID) TYPE  STRING
*"     VALUE(SPLIT_NUM) TYPE  STRING
*"  TABLES
*"      MATERIALS STRUCTURE  ZMATERIALS OPTIONAL
*"      QUANTITIES STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"      DOCUMENT_LIST STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"      SPLIT_QTY STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"----------------------------------------------------------------------
**"----------------------------------------------------------------------
  DATA USER TYPE USERNAME.
  data: g_idoc_control_record like edi_dc40 occurs 0 with header line.
  data: g_edidd like edi_dd40 occurs 0 with header line.
  data: parenttype type string.
  data ct type i.

  data:
        g_E1SALESORDER_CREATEFROMDAT2 like E1SALESORDER_CREATEFROMDAT2,
        g_E1BPSDHD1 like E1BPSDHD1,
        g_E1BPSDITM like E1BPSDITM,
        g_E1BPSDITM1 like E1BPSDITM1,
        g_E1BPPARNR like E1BPPARNR,
        g_E1BPSCHDL like E1BPSCHDL.

  data mode type c value 'A'.
  DATA:
  PE_IDOC_NUMBER  LIKE  EDIDC-DOCNUM,
  PE_ERROR_PRIOR_TO_APPLICATION LIKE  EDI_HELP-ERROR_FLAG.

  refresh: g_idoc_control_record, g_edidd.
  clear:   g_idoc_control_record, g_edidd.

  data cbn like zpo_users_auth-cbn.
  select single cbn into cbn from zpo_users_auth where access_token = access_token.
  data salesdocparent type vbak-vbeln.
  data purchnoc type string.
  concatenate cbn '_A_' TRANSACTION_ID into purchnoc.
  data material_line like line of MATERIALS.
  data q_line like line of QUANTITIES.
  data doc_list_line like line of DOCUMENT_LIST.


    move TRANSACTION_ID to tran_id.
  perform getUser using access_token user.

  loop at materials into material_line.

    endloop.

  loop at quantities into q_line.

    endloop.

*  Create parent ATC.
  clear: G_IDOC_CONTROL_RECORD[] , G_EDIDD[].

  clear: G_IDOC_CONTROL_RECORD , G_E1BPPARNR,
  G_E1BPSCHDL , G_E1BPSDHD1 , G_E1BPSDITM,G_E1BPSDITM1,
  G_E1SALESORDER_CREATEFROMDAT2                                                     .

  g_idoc_control_record-mestyp  = 'SALESORDER_CREATEFROMDAT2'.   "Message type
  g_idoc_control_record-idoctyp = 'SALESORDER_CREATEFROMDAT201'. "IDOC type
  g_idoc_control_record-direct  = '2'.              "Direction

* Receiver
  case sy-sysid.
    when 'DCD'.
      g_idoc_control_record-rcvpor = 'DCDCLNT200'.     "Port
      g_idoc_control_record-rcvprn = 'ISOP_E_DP'. "Partner number
  endcase.

  g_idoc_control_record-rcvprt = 'LS'.             "Partner type
  g_idoc_control_record-rcvpfc = ''.               "Partner function

* Sender
  g_idoc_control_record-sndpor = 'SAPDCD'.      "Port

  case sy-sysid.
    when 'DCD'.
      g_idoc_control_record-sndprn = 'ISOP_E_DP'. "Partner number
  endcase.
  g_idoc_control_record-sndprt = 'LS'.             "Partner type
  g_idoc_control_record-sndpfc = ''.               "Partner function
  g_idoc_control_record-refmes = 'ATC Parent Creation'.
  APPEND G_IDOC_CONTROL_RECORD.

*  *prepare idoc for post.

*build idoc segment
* SEGMENT E1SALESORDER_CREATEFROMDAT2
clear g_edidd.
g_edidd-segnam = 'E1SALESORDER_CREATEFROMDAT2'.
g_edidd-segnum = 1.

clear g_E1SALESORDER_CREATEFROMDAT2.
g_E1SALESORDER_CREATEFROMDAT2-INT_NUMBER_ASSIGNMENT = 'X'.
*g_E1SALESORDER_CREATEFROMDAT2-TESTRUN = 'X'.

MOVE  G_E1SALESORDER_CREATEFROMDAT2 TO G_EDIDD-SDATA.
APPEND G_EDIDD.



*SEGMENT E1BPSDHD1
clear g_edidd.
g_edidd-segnam = 'E1BPSDHD1'.
g_edidd-segnum = 2.

clear g_E1BPSDHD1.

if ( DELIVERY_STATUS eq 'D' ).
  g_E1BPSDHD1-DOC_TYPE = 'ZDOR'.
  PARENTTYPE = 'ZDOR'.
  G_E1BPSDHD1-INCOTERMS1 = 'CFR'.
  else.
    PARENTTYPE = 'ZSOR'.
    g_E1BPSDHD1-DOC_TYPE = 'ZSOR'.
    G_E1BPSDHD1-INCOTERMS1 = 'EXW'.
    endif.
*g_E1BPSDHD1-DOC_TYPE = 'ZDOR'.
g_E1BPSDHD1-SALES_ORG = SALES_ORG.
g_E1BPSDHD1-DISTR_CHAN = '10'.
G_E1BPSDHD1-DIVISION = DIVISION.
G_E1BPSDHD1-SALES_GRP = '100'.
G_E1BPSDHD1-SALES_OFF = '1050'.
G_E1BPSDHD1-REQ_DATE_H = SY-DATUM.
G_E1BPSDHD1-NAME = CUST_NAME.
*G_E1BPSDHD1-INCOTERMS1 = 'EXW'.
G_E1BPSDHD1-INCOTERMS2 = PLANT.
G_E1BPSDHD1-PMNTTRMS = 'V001'.
G_E1BPSDHD1-ORD_REASON = '100'.
G_E1BPSDHD1-PURCH_NO_C = PURCHNOC.
G_E1BPSDHD1-SD_DOC_CAT = 'C'.

G_E1BPSDHD1-CREATED_BY =  user.
MOVE G_E1BPSDHD1 to g_edidd-sdata.
append g_edidd.




*segment E1BPSDITM
clear g_edidd.
g_edidd-segnam = 'E1BPSDITM'.
g_edidd-segnum = 3.

clear g_E1BPSDITM.
g_E1BPSDITM-ITM_NUMBER = '000010'.
g_E1BPSDITM-MATERIAL =  MATERIAL_LINE-MATERIAL_NUMBER.
g_E1BPSDITM-PLANT = PLANT.
g_E1BPSDITM-TARGET_QTY = Q_LINE-QTY.
*if is_parent = 'X'. " There should be rejection if the split indicator is checked
g_E1BPSDITM-REASON_REJ = '07'.
*endif.
move g_E1BPSDITM to g_edidd-sdata.
append g_edidd.


* segment E1BPPARNR. FOR AG
CLEAR G_EDIDD.
G_EDIDD-SEGNAM = 'E1BPPARNR'.
G_EDIDD-SEGNUM = '4'.

CLEAR G_E1BPPARNR.
G_E1BPPARNR-PARTN_ROLE = 'AG'.
G_E1BPPARNR-PARTN_NUMB = CUST_NUM.

MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
APPEND G_EDIDD.

* segment E1BPPARNR. FOR WE
CLEAR G_EDIDD.
G_EDIDD-SEGNAM = 'E1BPPARNR'.
G_EDIDD-SEGNUM = '5'.

CLEAR G_E1BPPARNR.
G_E1BPPARNR-PARTN_ROLE = 'WE'.
G_E1BPPARNR-PARTN_NUMB = CUST_NUM.
G_E1BPPARNR-CITY = CITY.
G_E1BPPARNR-STREET = STREET.
G_E1BPPARNR-COUNTRY = COUNTRY.
G_E1BPPARNR-NAME = CUST_NAME.
G_E1BPPARNR-REGION = REGION.

MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
APPEND G_EDIDD.


*SEGMENT E1BPSCHDL
CLEAR G_E1BPSCHDL.
G_EDIDD-SEGNAM = 'E1BPSCHDL'.
G_EDIDD-SEGNUM = '6'.

CLEAR G_E1BPSCHDL.
G_E1BPSCHDL-ITM_NUMBER = '000010'.
G_E1BPSCHDL-SCHED_LINE = '0001'.
G_E1BPSCHDL-REQ_QTY = q_line-QTY.
G_E1BPSCHDL-DLV_DATE = SY-DATUM.

MOVE G_E1BPSCHDL TO G_EDIDD-SDATA.
APPEND G_EDIDD.


call function 'IDOC_INBOUND_ASYNCHRONOUS'
    in background task as separate unit
    tables
      idoc_control_rec_40 = g_idoc_control_record
      idoc_data_rec_40    = g_edidd.

  commit work AND WAIT .

*  raise event
CALL FUNCTION 'BP_EVENT_RAISE'
  EXPORTING
    EVENTID                      = 'ZPO_CREATE_ATC_EVENT'
*   EVENTPARM                    = ' '
*   TARGET_INSTANCE              = ' '
*   TARGET_MODE                  = ' '
* EXCEPTIONS
*   BAD_EVENTID                  = 1
*   EVENTID_DOES_NOT_EXIST       = 2
*   EVENTID_MISSING              = 3
*   RAISE_FAILED                 = 4
*   OTHERS                       = 5
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.

*========================================================================================================================
*====================================================================================================================
*  WAIT UP TO '1.0' SECONDS .
*=====================================================================================================================
*===================================================================================================================*

data count_material type i.

describe table materials lines count_material.
salesdocparent = '1'.
if ( count_material = 1 and is_parent = 'X' ). ""then create
*  select  MAX( vbeln )  into salesdocparent  from VBAK where
**     BSTNK = PURCHNOC and
**    auart in ('ZDOR' , 'ZSOR').
*    AUART = PARENTTYPE AND BSTNK LIKE 'A_%'AND VKORG = SALES_ORG.

*add 1 to SALESDOCPARENT.

  if SALESDOCPARENT is not INITIAL. ""create child.
*  single material.
  loop at materials into material_line.

    endloop.

*  DETERMINE SPLIT
data loop_qty_m type table of ZPO_QUANTITIES.
data loop_qty_m_line like line of loop_qty_m.
data counter type i.
perform determine_split tables QUANTITIES  SPLIT_QTY  loop_qty_m using counter split_num.

DESCRIBE TABLE loop_qty_m lines ct.
move ct to split_num.
*SPLIT_NUM = counter.
*Create child ATC

*-----------------------*
*-Build Control Record -*
*-----------------------*
loop at loop_qty_m into loop_qty_m_line.
*  WAIT UP TO '0.7' SECONDS.

  clear: G_IDOC_CONTROL_RECORD[] , G_EDIDD[].

  clear: G_IDOC_CONTROL_RECORD , G_E1BPPARNR,
  G_E1BPSCHDL , G_E1BPSDHD1 , G_E1BPSDITM,G_E1BPSDITM1,
  G_E1SALESORDER_CREATEFROMDAT2                                                     .

  g_idoc_control_record-mestyp  = 'SALESORDER_CREATEFROMDAT2'.   "Message type
  g_idoc_control_record-idoctyp = 'SALESORDER_CREATEFROMDAT201'. "IDOC type
  g_idoc_control_record-direct  = '2'.              "Direction

* Receiver
  case sy-sysid.
    when 'DCD'.
      g_idoc_control_record-rcvpor = 'DCDCLNT200'.     "Port
      g_idoc_control_record-rcvprn = 'ISOP_E_DP'. "Partner number
  endcase.

  g_idoc_control_record-rcvprt = 'LS'.             "Partner type
  g_idoc_control_record-rcvpfc = ''.               "Partner function

* Sender
  g_idoc_control_record-sndpor = 'SAPDCD'.      "Port

  case sy-sysid.
    when 'DCD'.
      g_idoc_control_record-sndprn = 'ISOP_E_DP'. "Partner number
  endcase.
  g_idoc_control_record-sndprt = 'LS'.             "Partner type
  g_idoc_control_record-sndpfc = ''.               "Partner function
  g_idoc_control_record-refmes = 'ATC Child Creation'.
  APPEND G_IDOC_CONTROL_RECORD.

*prepare idoc for post.

*build idoc segment
* SEGMENT E1SALESORDER_CREATEFROMDAT2
  clear g_edidd.
  g_edidd-segnam = 'E1SALESORDER_CREATEFROMDAT2'.
  g_edidd-segnum = 1.

  clear g_E1SALESORDER_CREATEFROMDAT2.
  g_E1SALESORDER_CREATEFROMDAT2-INT_NUMBER_ASSIGNMENT = 'X'.
*g_E1SALESORDER_CREATEFROMDAT2-TESTRUN = 'X'.

  MOVE  G_E1SALESORDER_CREATEFROMDAT2 TO G_EDIDD-SDATA.
  APPEND G_EDIDD.



*SEGMENT E1BPSDHD1
  clear g_edidd.
  g_edidd-segnam = 'E1BPSDHD1'.
  g_edidd-segnum = 2.

  clear g_E1BPSDHD1.
  if ( DELIVERY_STATUS eq 'D' ).
    g_E1BPSDHD1-DOC_TYPE = 'YDOR'.
    g_E1BPSDHD1-REFDOCTYPE = 'ZDOR'.
    G_E1BPSDHD1-INCOTERMS1 = 'CFR'.
  ELSE.
    g_E1BPSDHD1-DOC_TYPE = 'YSOR'.
    g_E1BPSDHD1-REFDOCTYPE = 'ZSOR'.
    G_E1BPSDHD1-INCOTERMS1 = 'EXW'.
  ENDIF.

  g_E1BPSDHD1-SALES_ORG = SALES_ORG.
  g_E1BPSDHD1-DISTR_CHAN = '10'.
  G_E1BPSDHD1-DIVISION = DIVISION.
  G_E1BPSDHD1-SALES_GRP = '100'.
  G_E1BPSDHD1-SALES_OFF = '1050'.
  G_E1BPSDHD1-REQ_DATE_H = SY-DATUM.
  G_E1BPSDHD1-INCOTERMS2 = PLANT.
  G_E1BPSDHD1-PMNTTRMS = 'V001'.
  G_E1BPSDHD1-ORD_REASON = '100'.
  G_E1BPSDHD1-PURCH_NO_C = purchnoc.
*  G_E1BPSDHD1-REF_DOC = SALESDOCPARENT.
  G_E1BPSDHD1-REFDOC_CAT = 'C'.
  G_E1BPSDHD1-CREATED_BY = user.
*  G_E1BPSDHD1-SD_DOC_CAT = 'C'.

  MOVE G_E1BPSDHD1 to g_edidd-sdata.
  append g_edidd.


*loop at materials.

*segment E1BPSDITM
  clear g_edidd.
  g_edidd-segnam = 'E1BPSDITM'.
  g_edidd-segnum = 3.

  clear g_E1BPSDITM.
  g_E1BPSDITM-ITM_NUMBER = '000010'.
  g_E1BPSDITM-MATERIAL = material_line-MATERIAL_NUMBER.
  g_E1BPSDITM-PLANT = plant.
  g_E1BPSDITM-TARGET_QTY = loop_qty_m_line-QTY.
*  g_E1BPSDITM-REASON_REJ = '07'.

  move g_E1BPSDITM to g_edidd-sdata.
  append g_edidd.

clear g_edidd.
  g_edidd-segnam = 'E1BPSDITM1'.
  g_edidd-segnum = 8.

  CLEAR G_E1BPSDITM1.
*  G_E1BPSDITM1-REF_DOC = SALESDOCPARENT.
  G_E1BPSDITM1-REF_DOC_IT = '000010'.
  G_E1BPSDITM1-REF_DOC_CA = 'C'.

  MOVE G_E1BPSDITM1 to g_edidd-sdata.
 append g_edidd.

* segment E1BPPARNR. FOR AG
  CLEAR G_EDIDD.
  G_EDIDD-SEGNAM = 'E1BPPARNR'.
  G_EDIDD-SEGNUM = '4'.

  CLEAR G_E1BPPARNR.
  G_E1BPPARNR-PARTN_ROLE = 'AG'.
  G_E1BPPARNR-PARTN_NUMB = CUST_NUM.

  MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
  APPEND G_EDIDD.

* segment E1BPPARNR. FOR WE
  CLEAR G_EDIDD.
  G_EDIDD-SEGNAM = 'E1BPPARNR'.
  G_EDIDD-SEGNUM = '5'.

  CLEAR G_E1BPPARNR.
  G_E1BPPARNR-PARTN_ROLE = 'WE'.
  G_E1BPPARNR-PARTN_NUMB = CUST_NUM.
  G_E1BPPARNR-CITY = CITY.
  G_E1BPPARNR-STREET = STREET.
  G_E1BPPARNR-COUNTRY = COUNTRY.
  G_E1BPPARNR-NAME = CUST_NAME.
  G_E1BPPARNR-REGION = REGION.

  MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
  APPEND G_EDIDD.


*SEGMENT E1BPSCHDL
  CLEAR G_E1BPSCHDL.
  G_EDIDD-SEGNAM = 'E1BPSCHDL'.
  G_EDIDD-SEGNUM = '6'.

  CLEAR G_E1BPSCHDL.
  G_E1BPSCHDL-ITM_NUMBER = '000010'.
  G_E1BPSCHDL-SCHED_LINE = '0001'.
  G_E1BPSCHDL-REQ_QTY = LOOP_QTY_M_line-QTY.
  G_E1BPSCHDL-DLV_DATE = SY-DATUM.

  MOVE G_E1BPSCHDL TO G_EDIDD-SDATA.
  APPEND G_EDIDD.




*--------------*
*-Create idoc -*
*--------------*

*-Syncronous
  if mode = 'S'.
    CALL FUNCTION 'IDOC_INBOUND_SINGLE'
      EXPORTING
        pi_idoc_control_rec_40        = g_idoc_control_record
*       PI_DO_COMMIT                  = 'X'
      IMPORTING
        PE_IDOC_NUMBER                = PE_IDOC_NUMBER
        PE_ERROR_PRIOR_TO_APPLICATION = PE_ERROR_PRIOR_TO_APPLICATION
      TABLES
        pt_idoc_data_records_40       = g_edidd
      EXCEPTIONS
        idoc_not_saved                = 1
        others                        = 2.

    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
              with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

*-Asynchronus
  else.
    CALL FUNCTION 'IDOC_INBOUND_ASYNCHRONOUS'
      in background task as separate unit
      TABLES
        idoc_control_rec_40 = g_idoc_control_record
        idoc_data_rec_40    = g_edidd.

   .

commit work.

  endif.

endloop.

*raise event
CALL FUNCTION 'BP_EVENT_RAISE'
  EXPORTING
    EVENTID                      = 'ZPO_CREATE_ATC_EVENT'
*   EVENTPARM                    = ' '
*   TARGET_INSTANCE              = ' '
*   TARGET_MODE                  = ' '
* EXCEPTIONS
*   BAD_EVENTID                  = 1
*   EVENTID_DOES_NOT_EXIST       = 2
*   EVENTID_MISSING              = 3
*   RAISE_FAILED                 = 4
*   OTHERS                       = 5
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.

*  select   vbeln  into DOC_LIST_LINE-DOC_NUM  from vbak where BSTNK = PURCHNOC and auart in ('YDOR' , 'YSOR').
*    move 'YDOR' to doc_list_line-DOC_TYPE.
*   append doc_list_line to DOCUMENT_LIST.

*endselect.
endif.


else.

clear: G_IDOC_CONTROL_RECORD[] , G_EDIDD[].

  clear: G_IDOC_CONTROL_RECORD , G_E1BPPARNR,
  G_E1BPSCHDL , G_E1BPSDHD1 , G_E1BPSDITM,G_E1BPSDITM1,
  G_E1SALESORDER_CREATEFROMDAT2                                                     .

  g_idoc_control_record-mestyp  = 'SALESORDER_CREATEFROMDAT2'.   "Message type
  g_idoc_control_record-idoctyp = 'SALESORDER_CREATEFROMDAT201'. "IDOC type
  g_idoc_control_record-direct  = '2'.              "Direction

* Receiver
  case sy-sysid.
    when 'DCD'.
      g_idoc_control_record-rcvpor = 'DCDCLNT200'.     "Port
      g_idoc_control_record-rcvprn = 'ISOP_E_DP'. "Partner number
  endcase.

  g_idoc_control_record-rcvprt = 'LS'.             "Partner type
  g_idoc_control_record-rcvpfc = ''.               "Partner function

* Sender
  g_idoc_control_record-sndpor = 'SAPDCD'.      "Port

  case sy-sysid.
    when 'DCD'.
      g_idoc_control_record-sndprn = 'ISOP_E_DP'. "Partner number
  endcase.
  g_idoc_control_record-sndprt = 'LS'.             "Partner type
  g_idoc_control_record-sndpfc = ''.               "Partner function
  g_idoc_control_record-refmes = 'ATC Child Creation'.
  APPEND G_IDOC_CONTROL_RECORD.

*prepare idoc for post.

*build idoc segment
* SEGMENT E1SALESORDER_CREATEFROMDAT2
  clear g_edidd.
  g_edidd-segnam = 'E1SALESORDER_CREATEFROMDAT2'.
  g_edidd-segnum = 1.

  clear g_E1SALESORDER_CREATEFROMDAT2.
  g_E1SALESORDER_CREATEFROMDAT2-INT_NUMBER_ASSIGNMENT = 'X'.
*g_E1SALESORDER_CREATEFROMDAT2-TESTRUN = 'X'.

  MOVE  G_E1SALESORDER_CREATEFROMDAT2 TO G_EDIDD-SDATA.
  APPEND G_EDIDD.



*SEGMENT E1BPSDHD1
  clear g_edidd.
  g_edidd-segnam = 'E1BPSDHD1'.
  g_edidd-segnum = 2.

  clear g_E1BPSDHD1.
  if ( DELIVERY_STATUS eq 'D' ).
    g_E1BPSDHD1-DOC_TYPE = 'YDOR'.
    g_E1BPSDHD1-REFDOCTYPE = 'ZDOR'.
    G_E1BPSDHD1-INCOTERMS1 = 'CFR'.
  ELSE.
    g_E1BPSDHD1-DOC_TYPE = 'YSOR'.
    g_E1BPSDHD1-REFDOCTYPE = 'ZSOR'.
    G_E1BPSDHD1-INCOTERMS1 = 'EXW'.
  ENDIF.

  g_E1BPSDHD1-SALES_ORG = SALES_ORG.
  g_E1BPSDHD1-DISTR_CHAN = '10'.
  G_E1BPSDHD1-DIVISION = DIVISION.
  G_E1BPSDHD1-SALES_GRP = '100'.
  G_E1BPSDHD1-SALES_OFF = '1050'.
  G_E1BPSDHD1-REQ_DATE_H = SY-DATUM.
  G_E1BPSDHD1-INCOTERMS2 = PLANT.
  G_E1BPSDHD1-PMNTTRMS = 'V001'.
  G_E1BPSDHD1-ORD_REASON = '100'.
  G_E1BPSDHD1-PURCH_NO_C = purchnoc.
*  G_E1BPSDHD1-REF_DOC = SALESDOCPARENT.
  G_E1BPSDHD1-REFDOC_CAT = 'C'.
  G_E1BPSDHD1-CREATED_BY = user.
*  G_E1BPSDHD1-SD_DOC_CAT = 'C'.

  MOVE G_E1BPSDHD1 to g_edidd-sdata.
  append g_edidd.


*loop at materials.

*segment E1BPSDITM
  clear g_edidd.
  g_edidd-segnam = 'E1BPSDITM'.
  g_edidd-segnum = 3.

  clear g_E1BPSDITM.
  g_E1BPSDITM-ITM_NUMBER = '000010'.
  g_E1BPSDITM-MATERIAL = material_line-MATERIAL_NUMBER.
  g_E1BPSDITM-PLANT = plant.
  g_E1BPSDITM-TARGET_QTY = q_line-qty.
*  g_E1BPSDITM-REASON_REJ = '07'.

  move g_E1BPSDITM to g_edidd-sdata.
  append g_edidd.

clear g_edidd.
  g_edidd-segnam = 'E1BPSDITM1'.
  g_edidd-segnum = 8.

  CLEAR G_E1BPSDITM1.
*  G_E1BPSDITM1-REF_DOC = SALESDOCPARENT.
  G_E1BPSDITM1-REF_DOC_IT = '000010'.
  G_E1BPSDITM1-REF_DOC_CA = 'C'.

  MOVE G_E1BPSDITM1 to g_edidd-sdata.
 append g_edidd.

* segment E1BPPARNR. FOR AG
  CLEAR G_EDIDD.
  G_EDIDD-SEGNAM = 'E1BPPARNR'.
  G_EDIDD-SEGNUM = '4'.

  CLEAR G_E1BPPARNR.
  G_E1BPPARNR-PARTN_ROLE = 'AG'.
  G_E1BPPARNR-PARTN_NUMB = CUST_NUM.

  MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
  APPEND G_EDIDD.

* segment E1BPPARNR. FOR WE
  CLEAR G_EDIDD.
  G_EDIDD-SEGNAM = 'E1BPPARNR'.
  G_EDIDD-SEGNUM = '5'.

  CLEAR G_E1BPPARNR.
  G_E1BPPARNR-PARTN_ROLE = 'WE'.
  G_E1BPPARNR-PARTN_NUMB = CUST_NUM.
  G_E1BPPARNR-CITY = CITY.
  G_E1BPPARNR-STREET = STREET.
  G_E1BPPARNR-COUNTRY = COUNTRY.
  G_E1BPPARNR-NAME = CUST_NAME.
  G_E1BPPARNR-REGION = REGION.

  MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
  APPEND G_EDIDD.


*SEGMENT E1BPSCHDL
  CLEAR G_E1BPSCHDL.
  G_EDIDD-SEGNAM = 'E1BPSCHDL'.
  G_EDIDD-SEGNUM = '6'.

  CLEAR G_E1BPSCHDL.
  G_E1BPSCHDL-ITM_NUMBER = '000010'.
  G_E1BPSCHDL-SCHED_LINE = '0001'.
  G_E1BPSCHDL-REQ_QTY = q_line-QTY.
  G_E1BPSCHDL-DLV_DATE = SY-DATUM.

  MOVE G_E1BPSCHDL TO G_EDIDD-SDATA.
  APPEND G_EDIDD.




*--------------*
*-Create idoc -*
*--------------*

*-Syncronous
  if mode = 'S'.
    CALL FUNCTION 'IDOC_INBOUND_SINGLE'
      EXPORTING
        pi_idoc_control_rec_40        = g_idoc_control_record
*       PI_DO_COMMIT                  = 'X'
      IMPORTING
        PE_IDOC_NUMBER                = PE_IDOC_NUMBER
        PE_ERROR_PRIOR_TO_APPLICATION = PE_ERROR_PRIOR_TO_APPLICATION
      TABLES
        pt_idoc_data_records_40       = g_edidd
      EXCEPTIONS
        idoc_not_saved                = 1
        others                        = 2.

    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
              with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

*-Asynchronus
  else.
    CALL FUNCTION 'IDOC_INBOUND_ASYNCHRONOUS'
      in background task as separate unit
      TABLES
        idoc_control_rec_40 = g_idoc_control_record
        idoc_data_rec_40    = g_edidd.

   .

commit work.
endif.
endif.
ENDFUNCTION.
form determine_split tables qty STRUCTURE ZPO_QUANTITIES splittable STRUCTURE ZPO_QUANTITIES
   loop_qty STRUCTURE ZPO_QUANTITIES
  using loopsize type i split_num type string.

  data c type i.
  data rem type i.
  data q_index type i.
  data quotient type i.


  data qty_line like line of qty.
  data split_qty_line like line of splittable.
  data loop_qty_line like line of loop_qty.

  data qty_i type i.
  data splitqty_i type i.

  loop at qty into qty_line.
    move qty_line-qty to qty_i.
  endloop.

  describe table splittable lines c.
  if ( c eq 1 ).
    loop at splittable into split_qty_line.
      move split_qty_line-qty to splitqty_i.
    endloop.
    rem = qty_i mod  splitqty_i.
    quotient = qty_i DIV splitqty_i.
    clear: loop_qty_line , loop_qty , loop_qty[].
    if rem ne 0.
      loopsize = quotient + 1.
      q_index = 1.
      while q_index le loopsize .
        if ( q_index eq loopsize ).
          loop_qty_line-qty = rem.
        else.
          loop_qty_line-qty = splitqty_i.
        endif.
        append loop_qty_line to loop_qty.

        add 1 to q_index.
      endwhile.
    else. ""remainder is 0. even share.
      loopsize = quotient.
      q_index = 1.
      while q_index le loopsize.
        loop_qty_line-qty = splitqty_i.

        append loop_qty_line to loop_qty.

        add 1 to q_index.
      endwhile.
    endif.

  endif.

  if ( c > 1 ).
    clear: loop_qty, loop_qty[] , loop_qty_line.

    loop at SPLITTABLE into SPLIT_QTY_LINE.
      move split_qty_line-qty to qty_i.
      move qty_i to loop_qty_line-qty.
      append loop_qty_line to loop_qty.
    endloop.

  endif.
  move LOOPSIZE to split_num.
endform.