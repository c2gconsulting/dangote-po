FUNCTION ZPO_ISOP_DP_FETCHOPENINVOICE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(CUST_NUMBER) TYPE  KUNNR
*"     VALUE(COMP_CODE) TYPE  BUKRS
*"     VALUE(FISCAL_YEAR) TYPE  GJAHR
*"     VALUE(ACCESS_TOKEN) TYPE  STRING
*"  TABLES
*"      OPEN_INVOICES STRUCTURE  ZOPENINVOICES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE
*"----------------------------------------------------------------------
*Developed by Catalyst.

* get the list of all open invoices
  tables: bsid.

  data open_inv_line like line of open_invoices.
  data count_inv type i .
  data total_amt like bsid-wrbtr.
  data current_belnr type belnr_d.
  data currency type waers.
  data error_line like line of error_log.
  data user type username.


  perform getUser using access_token user.

  if user is not initial and access_token is not initial.


  if cust_number is not initial and comp_code is not initial.
  if FISCAL_YEAR is not initial.
    clear :
    current_belnr, currency , total_amt.

  select belnr waers sum( wrbtr ) from bsid into (current_belnr, currency, total_amt) where kunnr = cust_number and bukrs = comp_code and gjahr = fiscal_year
    and
    blart =  'RV'
    and shkzg = 'S'

    group by belnr waers

    order by belnr.


    move current_belnr to OPEN_INV_LINE-BELNR.
    move total_amt to open_inv_line-WRBRTR.
    move currency to open_inv_line-waers.

    append open_inv_line to open_invoices.


  endselect.

  describe table open_invoices lines count_inv.
  if ( count_inv > 0 ).
*    every thing is fine
  else.
      error_line-ERROR_CODE = '101'.
      concatenate 'Customer ' CUST_NUMBER ' does not have any open invoice(s)' into error_line-ERROR_MESSAGE.
      error_line-ERROR_TITLE = 'Customer does not have open invoice(s)'.
      append error_line to error_log.
  endif.

else.
*  do this if fiscal year is not provided
  select belnr waers sum( wrbtr ) from bsid into (current_belnr, currency, total_amt) where kunnr = cust_number and bukrs = comp_code
    and
    blart =  'RV'
    and shkzg = 'S'

    group by belnr waers

    order by belnr
     .


    move current_belnr to OPEN_INV_LINE-BELNR.
    move total_amt to open_inv_line-WRBRTR.
    move currency to open_inv_line-waers.

    append open_inv_line to open_invoices.
  endselect.

  describe table open_invoices lines count_inv.
  if ( count_inv > 0 ).
*    every thing is fine
  else.
      error_line-ERROR_CODE = '101'.
      concatenate 'Customer ' CUST_NUMBER ' does not have any open invoice(s)'
      into error_line-ERROR_MESSAGE separated by space.
      error_line-ERROR_TITLE = 'No Open invoice(s)'.
      append error_line to error_log.
  endif.

  endif.

  else.
    error_line-ERROR_CODE = '101'.
    error_line-ERROR_TITLE = 'No customer/compancycode'.
    error_line-ERROR_MESSAGE = 'Please check to ensure that company code / customer is provided.'.

    append error_line to error_log.
  endif.

else.
  error_line-error_code = '101'.
  error_line-error_title = 'Invalid token'.
  error_line-error_message = 'Please provide a valid token!'.

  append error_line to error_log.
endif.
ENDFUNCTION.