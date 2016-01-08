FUNCTION ZPO_GETDOCUMENTS.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ACCESS_TOKEN) TYPE  STRING
*"     VALUE(TRANSACTION_ID) TYPE  STRING
*"     VALUE(SPLIT_TYPE) TYPE  STRING OPTIONAL
*"     VALUE(CHILD_COUNT) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(BARCODE_STRING1) TYPE  STRING
*"     VALUE(BARCODE_STRING2) TYPE  STRING
*"     VALUE(CREATED_CHILDREN) TYPE  STRING
*"  TABLES
*"      DOCUMENTS STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      PARENT STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      CHILD STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      PAYMENT STRUCTURE  ZPO_DP_PAYMENT OPTIONAL
*"      STATUS STRUCTURE  ZPO_STATUS OPTIONAL
*"----------------------------------------------------------------------
 data userDetailsLine like line of user_details.
 data user type username.
 data cbn like zpo_users_auth-cbn.
data doc_lines like line of DOCUMENTS.
DATA: CIAG(400) , usr01 like usr01.
data pay_line like line of PAYMENT.
data auart like vbak-auart.
data barcodestr type string.
data statusline like line of STATUS.
  data ci type i.
  data: c_child type i, c_parent type i, p_line type zpo_atc_docs, c_line type zpo_atc_docs, paycount type i.
data tranid like TRANSACTION_ID.
data tranid2 like TRANSACTION_ID.
data tranid3 like TRANSACTION_ID.

  perform getUser using access_token user.
  perform getUserDetails using access_token.

select single cbn into cbn from zpo_users_auth where access_token = access_token.
if user is not initial and access_token is not initial .
*  if transaction is not initial and REFERENCE_NO   is not initial.
CONCATENATE cbn '_E_' TRANSACTION_ID into TRANID.
CONCATENATE cbn '_A_' TRANSACTION_ID into TRANID2.
CONCATENATE cbn '_BG_' TRANSACTION_ID into TRANID3.
  select  vbeln auart   from vbak into (DOC_LINEs-DOC_NUM,auart) where BSTNK = TRANID2 and AUART in ('YDOR' , 'YSOR' , 'ZDOR' , 'ZSOR') order by vbeln ASCENDING.
    DOC_LINES-DOC_TYPE = auart.
    if auart eq 'YDOR' or auart eq 'YSOR'.
      append doc_lines to child.
      endif.
      if auart eq 'ZDOR' or auart eq 'ZSOR'.
      append doc_lines to PARENT.
      endif.

    append doc_lines to DOCUMENTS.
    CONCATENATE  DOC_LINES-DOC_NUM ',' BARCODESTR INTO BARCODESTR.

    add 1 to ci.
  endselect.

*translate tranid TO UPPER CASE.
clear pay_line.
  select single belnr gjahr bukrs into (pay_line-DOCUMENT,pay_line-FISCAL_YR,pay_line-COMP_CODE) from bsid where
    zuonr = TRANID.

CONCATENATE PAY_LINE-DOCUMENT ',' BARCODESTR INTO BARCODESTR.
APPEND PAY_LINE TO PAYMENT.
DESCRIBE TABLE parent lines C_PARENT.
DESCRIBE TABLE child lines C_CHILD.
describe table payment lines paycount.

*ASSIGN C_CHILD TO CREATED_CHILDREN
CREATED_CHILDREN = C_CHILD.

if pay_line-document is not initial.
  statusline-PAYMENT = 'Downpayment was successful!'.
*  correct the atc downpayment transaction id

  else.
   statusline-PAYMENT = 'Downpayment failed!'.
 endif.
*append statusline to status.

if c_parent eq 1.
  if ( SPLIT_TYPE eq 'X' ).
    data child_str type string.
    data child_str2 type string.
    move c_child to child_str.
    move child_count to child_str2.
*    concatenate 'ATC status: (' child_str ')/(' : child_str2 ')' into statusline-atc.

    concatenate child_str 'out of'  child_str2 ' atcs created!' into statusline-atc SEPARATED BY space.
    else.
       statusline-atc = '1 out of 1 atcs created!'.
    endif.
  append statusline to status.
  else.
    statusline-atc = 'ATC status: Failed!'.
  append statusline to status.
  endif.
if ( c_parent eq 1 and c_child > 0 ).

  loop at parent into p_line. endloop.
*  loop at child into c_line.
**    update vbfa
**    set vbelv = p_line-doc_num
**    where vbeln = c_line-doc_num.
**
**
**
**    update vbak
**    set VGBEL = P_LINE-DOC_NUM
**    WHERE VBELN = C_LINE-DOC_NUM.
**
**     update vbap
**    set VGBEL = P_LINE-DOC_NUM
**    WHERE VBELN = C_LINE-DOC_NUM.
**
**
**    COMMIT work.
*
*    endloop.

  endif.
  DATA L TYPE I.
  l = strlen( barcodestr ).
  if ( l > 0 ).
    l = l - 1.
      barcodestr = barcodestr+0(L).
    endif.

  SELECT SINGLE SPLD INTO USR01-SPLD FROM USR01 WHERE BNAME = SY-UNAME.
*  NEW-PAGE PRINT ON DESTINATION USR01-SPLD IMMEDIATELY 'X'
*           COPIES 2.
  CONCATENATE '^XA^LH20,20^FO60,80^B3,,250,N^FD' BARCODESTR
              '^FS^FO90,380^AE^FD' '*'  '*'
              '^FS^XZ' INTO CIAG.
  CONDENSE CIAG.
  WRITE: CIAG.
*  NEW-PAGE PRINT OFF.

  move ciag to BARCODE_STRING1.
  move ciag to BARCODE_STRING2.
*  MOVE 'ATC created in target system...' to OUTPUTSTRING1.

  else.

    statusline-ATC = 'Invalid token!'.
    statusline-payment = 'Invalid token!'.

  append statusline to status.
    endif.


ENDFUNCTION.