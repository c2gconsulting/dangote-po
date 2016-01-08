FUNCTION ZPO_ISOP_DP_CUSTOMERDETAIL_1.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(COMP_CODE) TYPE  BUKRS OPTIONAL
*"     VALUE(CUST_NUMBER) TYPE  KUNNR OPTIONAL
*"     VALUE(CC_AREA) LIKE  T014-KKBER OPTIONAL
*"     VALUE(SALES_ORG) TYPE  VKORG OPTIONAL
*"     VALUE(ACCESS_TOKEN) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(CUST_NAME) TYPE  NAME1
*"     VALUE(ADDRESS) TYPE  STRAS_GP
*"     VALUE(COUNTRY) TYPE  LAND1_GP
*"     VALUE(REGION) TYPE  REGIO
*"     VALUE(EXPOSURE) TYPE  RF02L-OBLIG
*"     VALUE(DIVISION) TYPE  SPART
*"  TABLES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"----------------------------------------------------------------------
  clear cust_name.
data error_line like line of ERROR_LOG.
data checkuser type username.
data cc_area2 like cc_area.
data:
      credlim like knkk-klimk,
      sum_opens like RF02L-OBLIG.

if ( access_token is initial ).
   error_line-ERROR_CODE = '101'.
   error_line-ERROR_TITLE = 'No token provided!'.
   error_line-ERROR_MESSAGE = 'Please provide a token!'.

   append error_line to error_log.
  else.

perform  getUser using access_token checkuser.

if checkuser is initial .
    error_line-ERROR_CODE = '101'.
    error_line-ERROR_TITLE = 'Invalid token'.
    error_line-ERROR_MESSAGE = 'Token provided is not valid.'.

    append error_line to error_log.
  else.

if ( cc_area is initial ).
    select single cc_area into cc_area from zpo_users_auth where access_token = access_token.
      if ( sy-subrc ne 0 and cc_area is initial ).
          error_line-ERROR_CODE = '101'.
          error_line-ERROR_TITLE = 'Failed to retrieve credit control area'.
          error_line-ERROR_MESSAGE = 'Failure to retrieve credit control area for user, please provide manually!'.

          append error_line to error_log.
        endif.
  endif.

* get customer name , address , country , region
if ( comp_code is not initial and cust_number is not initial ). ""A company code and customer number is entered.

select single kunnr  into cust_number from knb1 where bukrs = comp_code and kunnr = cust_number.
if sy-subrc eq 0 and cust_number is not initial.
  select single name1 stras land1 regio from kna1 into (cust_name,address,country,region) where kunnr = cust_number.
    if ( sy-subrc eq 0 and cust_name is not initial ).
       else.
          error_line-ERROR_CODE = '101'.
          error_line-ERROR_MESSAGE = 'Customer does not exist in company code'.
          error_line-ERROR_TITLE = 'Customer does not exist!'.

          append error_line to error_log.

      endif.

      ELSE.

        error_line-ERROR_CODE = '101'.
          error_line-ERROR_MESSAGE = 'Customer does not exist in company code'.
          error_line-ERROR_TITLE = 'Customer does not exist!'.

          append error_line to error_log.

endif.
else.
  error_line-ERROR_CODE = '101'.
          error_line-ERROR_TITLE = 'No Customer/Company code'.
          error_line-ERROR_MESSAGE = 'Please ensure you provide a customer and company code.'.

          append error_line to error_log.

endif.

if COMP_CODE is not initial.
*
* get credit exposure
  clear cc_area2.
  select single cc_area into cc_area2 from zpo_users_auth where access_token = access_token and cc_area = cc_area.
  if ( cc_area2 is not initial ).
CALL FUNCTION 'CREDIT_EXPOSURE'
  EXPORTING
    KKBER                      = CC_AREA
    KUNNR                      = cust_number
   DATE_CREDIT_EXPOSURE       = '99991231'
 IMPORTING
*   CREDITLIMIT                =
*   DELTA_TO_LIMIT             =
*   E_KNKK                     =
*   KNKLI                      =
*   OPEN_DELIVERY              =
*   OPEN_INVOICE               =
*   OPEN_ITEMS                 =
*   OPEN_ORDER                 =
*   OPEN_SPECIALS              =
*   PERCENTAGE                 =
   SUM_OPENS                  = sum_opens
*   OPEN_ORDER_SECURE          =
*   OPEN_DELIVERY_SECURE       =
*   OPEN_INVOICE_SECURE        =
*   CMWAE                      =
          .

move sum_opens to exposure.
else.
  ERROR_LINE-ERROR_CODE = '101'.
      error_line-error_title = 'Invalid control area'.
      error_line-ERROR_MESSAGE = 'Please enter a valid control area..'.

      append error_line to error_log.
  endif.
else.
  ERROR_LINE-ERROR_CODE = '101'.
      error_line-error_title = 'No company code'.
      error_line-ERROR_MESSAGE = 'Please provide a company code.'.

      append error_line to error_log.

  endif.
* get the divsion
if sales_org is not initial .
select single spart into division from knvv where kunnr = cust_number and
  vtweg = '10'
   and vkorg = sales_org.
  if ( sy-subrc eq 0 and division is not initial ).

    else.
      ERROR_LINE-ERROR_CODE = '101'.
      error_line-error_title = 'No division found!'.
      error_line-ERROR_MESSAGE = 'Customer does not belong to any division!'.

      append error_line to error_log.

    endif.
    endif.
    endif.
    endif.
ENDFUNCTION.