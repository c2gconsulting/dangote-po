FUNCTION ZPO_ISOP_DP_GETACCTDETAILS.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(BANKN) TYPE  BANKN
*"     VALUE(BUKRS) TYPE  BUKRS
*"     VALUE(UMSKZ) TYPE  UMSKZ
*"     VALUE(TELLER_NO) TYPE  STRING
*"     VALUE(CUST_NAME) TYPE  NAME1
*"     VALUE(CUSTOMERDETAILS_OUT) TYPE  ZDTCUSTDETAILS_OUT
*"     VALUE(ACCESS_TOKEN) TYPE  STRING
*"  EXPORTING
*"     VALUE(HKONT) TYPE  HKONT
*"     VALUE(FISCAL_YEAR) TYPE  GJAHR
*"     VALUE(FISCAL_PERIOD) TYPE  MONAT
*"     VALUE(TRANSACTION_DATE) LIKE  SY-DATUM
*"     VALUE(NARRATION_TEXT) TYPE  STRING
*"     VALUE(DOCUMENT_TYPE) TYPE  STRING
*"     VALUE(CUSTACCTDETAILS) TYPE  ZDTCUSTACCTDETAILS
*"     VALUE(CURRENCY) TYPE  WAERS
*"     VALUE(CBN) TYPE  CHAR3
*"  TABLES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE
*"----------------------------------------------------------------------

data acc_no type hkont.
data year(4) type c.
data l type i.
data _logged_on_user type username.
data msg1 type string.
data error_log_line like line of error_log.
data ___hknt type string.
data kunnr type kunnr.
* customer number was passed as customer name... therefore use the customer number to get
* get customer name
* this is done as a quickfix to Cyrils initial Implementation of using the Get customer details
* services which at the end is not neccessary.

perform getUser using access_token _logged_on_user.

if ( _logged_on_user is not initial  and ACCESS_TOKEN is not initial ).
select single hkont waers into (acc_no,currency) from T012K where bukrs = bukrs and bankn = bankn.
  if sy-subrc = 0 and acc_no is not initial.
*    add 2 to acc_no.
    CONCATENATE acc_no '_ek' into ___hknt.
    replace '0_ek' in ___hknt with '2'.
    move ___hknt to acc_no.
    move acc_no to hkont.
    "GET CBN NUMBER OF LOG ON USER
    TRANSLATE ACCESS_TOKEN TO UPPER CASE.
    select single CBN into CBN from zpo_users_auth where access_token = access_token.


else.
  error_log_line-ERROR_CODE = '101'.
  error_log_line-error_title = 'No GL account found'.
  error_log_line-ERROR_MESSAGE = 'No GL account found for company code'.

  append error_log_line to error_log.
     endif.

  CALL FUNCTION 'GM_GET_FISCAL_YEAR'
    EXPORTING
     I_DATE                           = SY-DATUM
      I_FYV                            = 'K0'
   IMPORTING
     E_FY                             = year
   EXCEPTIONS
     FISCAL_YEAR_DOES_NOT_EXIST       = 1
     NOT_DEFINED_FOR_DATE             = 2
     OTHERS                           = 3
            .
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
    else.
      fiscal_year = year.
  ENDIF.

*  assign transaction date
  move sy-datum to transaction_date.

*  assign period
  move sy-datum+4(2) to fiscal_period.
*
  kunnr = cust_name.
  "clear cust_name.
  clear cust_name.
  "get customer name from kna1
  select single name1 from kna1 into cust_name where kunnr = kunnr.
*  narration text
  CONCATENATE teller_no transaction_date cust_name into narration_text SEPARATED BY '-'.

*  document type
  move 'DZ' to document_type.


  MOVE-CORRESPONDING CUSTOMERDETAILS_OUT TO CUSTACCTDETAILS.
  CUSTACCTDETAILS-HKONT = HKONT.
  CUSTACCTDETAILS-FISCAL_PERIOD = FISCAL_PERIOD.
  CUSTACCTDETAILS-TRANSACTION_DATE = TRANSACTION_DATE.
  CUSTACCTDETAILS-NARRATION_TEXT = NARRATION_TEXT.
  CUSTACCTDETAILS-DOC_TYPE = DOCUMENT_TYPE.

else.
    error_log_line-ERROR_CODE = '101'.
    error_log_line-ERROR_TITLE = 'Invalid token'.
    error_log_line-ERROR_MESSAGE = 'Invalid token, cannot authenticate user for this call'.

    append error_log_line to error_log.
  endif.

ENDFUNCTION.