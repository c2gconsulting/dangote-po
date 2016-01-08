FUNCTION-POOL ZPO_ISOP_ATC_CREATION.        "MESSAGE-ID ..

* INCLUDE LZPO_ISOP_ATC_CREATIOND...         " Local class definition

data:
      user_details type table of zpo_users_auth,
      t005u_line type t005u.

form getUser using access_token type string user type username.
  TRANSLATE access_token to UPPER CASE.
  select single username into user from zpo_users_auth where access_token = access_token.
endform.

form getUserDetails using access_token.
  data users_details_line like line of user_details.
  select * from zpo_users_auth into users_details_line where access_token = access_token.
    append users_details_line to user_details.
  endselect.
endform.

form getRegions using access_token type string region type standard table.
  perform  getUserDetails using access_token.
  data user_details_line like line of user_details.
  data a_region type zpo_regions.
  data landx like t005t-landx.
  loop at user_details into user_details_line.
    if ( sy-tabix = 1    ).
      select single landx from t005t into landx where spras = 'E' and land1 = user_details_line-country_code.
      select * from t005u into t005u_line where land1 = user_details_line-country_code.

        a_region-regio = t005u_line-bland.
        a_region-description = t005u_line-bezei.
        a_region-country = user_details_line-country_code.
        append a_region to region.
      endselect.
    endif.
  endloop.

  sort region.
  delete ADJACENT DUPLICATES FROM region.



endform.

form getMaterials using access_token type string materials type standard table.
  data materials_line type zmaterials.
  data user_details_line like line of user_details.
  data aWerks type werks_d.
  data mtart type mtart.
  perform getUserDetails using access_token.
  loop at user_details into user_details_line.
*                move user_details_line-vkorg to materials_line-saleg_org.
*                select werks into aWerks from v_tvkwz_assign where vkorg = user_details-vkorg.
    move user_details_line-vkorg to materials_line-sales_org.
*                    move aWerks to materials_line-sales_org.
    move user_details_line-plant to materials_line-plant.

    select mv~matnr into materials_line-MATERIAL_NUMBER from mvke as mv INNER JOIN marc as ma  on
      ( mv~matnr = ma~matnr ) where
      mv~vkorg = user_details_line-vkorg and
      ma~werks = user_details_line-plant.
      select single maktx into materials_line-material_text from makt
         where matnr = materials_line-material_number.
      if ( sy-subrc eq 0 and materials_line-material_text is not initial ).
        select single mtart into  mtart from mara where matnr = materials_line-material_number.
        if ( SY-SUBRC eq 0 and  mtart eq 'FERT' ).
            append materials_line to materials.
          endif.
      endif.

    endselect.

    sort materials.
    delete ADJACENT DUPLICATES FROM materials.


  endloop.
endform.




form post_atc_idoc.
  data: g_idoc_control_record like edi_dc40 occurs 0 with header line.
data: g_edidd like edi_dd40 occurs 0 with header line.

data:
      g_E1SALESORDER_CREATEFROMDAT2 like E1SALESORDER_CREATEFROMDAT2,
      g_E1BPSDHD1 like E1BPSDHD1,
      g_E1BPSDITM like E1BPSDITM,
      g_E1BPPARNR like E1BPPARNR,
      g_E1BPSCHDL like E1BPSCHDL.

data mode type c value 'A'.
DATA:
PE_IDOC_NUMBER  LIKE  EDIDC-DOCNUM,
PE_ERROR_PRIOR_TO_APPLICATION LIKE  EDI_HELP-ERROR_FLAG.

refresh: g_idoc_control_record, g_edidd.
clear:   g_idoc_control_record, g_edidd.

*-----------------------*
*-Build Control Record -*
*-----------------------*
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
g_idoc_control_record-refmes = 'ATC Creation'.
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
g_E1BPSDHD1-DOC_TYPE = 'ZDOR'.
g_E1BPSDHD1-SALES_ORG = '1000'.
g_E1BPSDHD1-DISTR_CHAN = '10'.
G_E1BPSDHD1-DIVISION = '10'.
G_E1BPSDHD1-SALES_GRP = '100'.
G_E1BPSDHD1-SALES_OFF = '1050'.
G_E1BPSDHD1-REQ_DATE_H = SY-DATUM.
G_E1BPSDHD1-INCOTERMS1 = 'EXW'.
G_E1BPSDHD1-INCOTERMS2 = 'PLANT NAME'.
G_E1BPSDHD1-PMNTTRMS = 'V001'.
G_E1BPSDHD1-ORD_REASON = '100'.
G_E1BPSDHD1-PURCH_NO_C = 'A_TRANSACTION_ID2'.

MOVE G_E1BPSDHD1 to g_edidd-sdata.
append g_edidd.


*loop at materials.

*segment E1BPSDITM
clear g_edidd.
g_edidd-segnam = 'E1BPSDITM'.
g_edidd-segnum = 3.

clear g_E1BPSDITM.
g_E1BPSDITM-ITM_NUMBER = '000010'.
g_E1BPSDITM-MATERIAL = 'BAG1_OBA'.
g_E1BPSDITM-PLANT = '1000'.
g_E1BPSDITM-TARGET_QTY = '10'.
g_E1BPSDITM-REASON_REJ = '07'.

move g_E1BPSDITM to g_edidd-sdata.
append g_edidd.


* segment E1BPPARNR. FOR AG
CLEAR G_EDIDD.
G_EDIDD-SEGNAM = 'E1BPPARNR'.
G_EDIDD-SEGNUM = '4'.

CLEAR G_E1BPPARNR.
G_E1BPPARNR-PARTN_ROLE = 'AG'.
G_E1BPPARNR-PARTN_NUMB = '0001002887'.

MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
APPEND G_EDIDD.

* segment E1BPPARNR. FOR WE
CLEAR G_EDIDD.
G_EDIDD-SEGNAM = 'E1BPPARNR'.
G_EDIDD-SEGNUM = '5'.

CLEAR G_E1BPPARNR.
G_E1BPPARNR-PARTN_ROLE = 'WE'.
G_E1BPPARNR-PARTN_NUMB = '0001002887'.
G_E1BPPARNR-CITY = 'CITY'.
G_E1BPPARNR-STREET = 'STREET 1'.
G_E1BPPARNR-COUNTRY = 'NG'.
G_E1BPPARNR-NAME = 'NAME1'.
G_E1BPPARNR-REGION = '01'.

MOVE G_E1BPPARNR TO G_EDIDD-SDATA.
APPEND G_EDIDD.


*SEGMENT E1BPSCHDL
CLEAR G_E1BPSCHDL.
G_EDIDD-SEGNAM = 'E1BPSCHDL'.
G_EDIDD-SEGNUM = '6'.

CLEAR G_E1BPSCHDL.
G_E1BPSCHDL-ITM_NUMBER = '000010'.
G_E1BPSCHDL-SCHED_LINE = '0001'.
G_E1BPSCHDL-REQ_QTY = '10'.
G_E1BPSCHDL-DLV_DATE = SY-DATUM.

MOVE G_E1BPSCHDL TO G_EDIDD-SDATA.
APPEND G_EDIDD.












*--------------*
*-Create idoc -*
*--------------*

*-Syncronous
if mode = 'S'.
  call function 'IDOC_INBOUND_SINGLE'
    exporting
      pi_idoc_control_rec_40              = g_idoc_control_record
*     PI_DO_COMMIT                        = 'X'
   IMPORTING
     PE_IDOC_NUMBER                      = PE_IDOC_NUMBER
     PE_ERROR_PRIOR_TO_APPLICATION       = PE_ERROR_PRIOR_TO_APPLICATION
    tables
      pt_idoc_data_records_40             = g_edidd
    exceptions
      idoc_not_saved                      = 1
      others                              = 2.

  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

*-Asynchronus
else.
  call function 'IDOC_INBOUND_ASYNCHRONOUS'
    in background task as separate unit
    tables
      idoc_control_rec_40 = g_idoc_control_record
      idoc_data_rec_40    = g_edidd.

  commit work.



endif.
  endform.