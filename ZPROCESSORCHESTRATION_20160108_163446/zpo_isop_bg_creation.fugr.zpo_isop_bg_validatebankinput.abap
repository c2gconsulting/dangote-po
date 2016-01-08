FUNCTION ZPO_ISOP_BG_VALIDATEBANKINPUT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(COMP_CODE) TYPE  ZCOMP_CODE OPTIONAL
*"     VALUE(CUST_NUMBER) TYPE  KUNNR OPTIONAL
*"     VALUE(AMOUNT) TYPE  WRBTR OPTIONAL
*"     VALUE(TRAN_ID) TYPE  ZTRAN_ID OPTIONAL
*"     VALUE(CURRENCY) TYPE  WAERS OPTIONAL
*"     VALUE(ACCESS_TOKEN) TYPE  STRING OPTIONAL
*"     VALUE(BG_NUMBER) TYPE  BELNR_D OPTIONAL
*"  EXPORTING
*"     VALUE(VALID) TYPE  BOOLEAN
*"     VALUE(AWKEY) TYPE  AWKEY
*"  TABLES
*"      MATERIALS STRUCTURE  ZMATERIALS OPTIONAL
*"      QUANTITIES STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"      SPLIT_QTY STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"----------------------------------------------------------------------

data validcust type  kunnr.
data bg_line type zsd_isop_bg_t.
data error_line like line of error_log.
DATA USER TYPE USERNAME.
  data _logged_on_user1 type username.
  data _ccarea type kkber.
  data exposure like RF02L-OBLIG.
  data zpo_comp_plant_tab type table of zpo_comp_plant.
  data zpo_comp_plant_line type zpo_comp_plant.
  data: msg1 type string , msg2 type string.
  data error_log_line like line of error_log.


perform getUser using access_token _logged_on_user1.

if ( _logged_on_user1 is not initial and access_token is not initial ) .

    user = _logged_on_user1.
    select single cc_area into _ccarea from zpo_users_auth   where access_token = access_token.
    if ( sy-subrc eq 0 and _ccarea is not initial ).
    endif.

* validate users and company codes. get every user information frm the users
    select * from zpo_comp_plant into zpo_comp_plant_line where bankuser = user and comp_code = comp_code.
      append zpo_comp_plant_line to zpo_comp_plant_tab.
    endselect.

    data count_tab type i.
    describe table zpo_comp_plant_tab lines count_tab.

    if ( count_tab is not initial ).
*        this user is a valid user
    else.
      valid = '-'.
      concatenate 'User' user ' is not authorized to post in company code ' comp_code into msg1 SEPARATED BY space.
      error_log_line-ERROR_CODE = '101'.
      error_log_line-ERROR_TITLE = 'Unauthorized Company code'.
      error_log_line-ERROR_MESSAGE = msg1.

      append error_log_line to ERROR_LOG.
    endif.





*added check for bg approval amount check.
select single * from zsd_isop_bg_t into bg_line where kunnr = cust_number.
  if sy-subrc eq 0 and bg_line is not initial.
*      customer exist.
    move bg_line-kunnr to validcust.
      if ( amount ge bg_line-WRBTR_M and amount le bg_line-WRBTR_MAX and
        sy-datum  le bg_line-BG_EXPIRE ).
*           every thing is fine
          else.

            valid = '-'.
            error_line-ERROR_CODE = '101'.
            concatenate 'Ínvalid Approved BG for customer' validcust into error_line-error_title.
            concatenate 'Invalid approved Bank Guarantee for customer ' validcust ' in specified date '
            sy-datum '. BG already expired on ' bg_line-bg_expire into error_line-error_message SEPARATED BY space.

            append error_line to error_log.
        endif.
        else.
          valid = '-'.
          error_line-error_code = '101'.
          concatenate 'Customer ' cust_number ' does not have a BG' into error_line-error_title separated by space.
          concatenate 'Customer ' cust_number 'does not have a Bank Guarantee' into error_line-ERROR_MESSAGE
          SEPARATED BY space.

          append error_line to error_log.
    endif.


*    check for bg details.
DATA AMOUNT2 TYPE WRBTR.

IF ( BG_NUMBER is not initial ).
select single wrbtr from bsid into amount2 where
   belnr = BG_NUMBER
  and gjahr = '2015'
  and bukrs = comp_code .

  if ( amount ne amount2 ).
    valid = '-'.
       error_line-error_code = '101'.
       error_line-error_title = 'Amount mismatch'.
       error_line-error_message = 'Reversal Amount does not match BG amount'.

       append error_line to error_log.
    endif.
ENDIF.


* get awkey for the bg note created.
IF ( BG_NUMBER is not initial ).
  data awkey_tem type awkey.
  data yr type dats.
  yr = sy-datum+0(4).
select single awkey into awkey_tem from bkpf where bukrs = COMP_CODE and belnr = bg_number and gjahr = yr .
  if ( sy-subrc eq 0 and awkey_tem is not initial ).
      move awkey_tem to awkey.

      else.
        valid = '-'.
       error_line-error_code = '101'.
       error_line-error_title = 'The BG number does not exist! Enter a valid BG note number'.
       error_line-error_message = 'The BG note number does not exist...'.

       append error_line to error_log.
    endif.
endif.


ELSE.
  valid = '-'.
  error_line-error_code = '101'.
  error_line-error_title = 'Invalid token'.
  concatenate  'Invalid token'  access_token into error_line-error_message SEPARATED BY space.
*  error_line-error_message = 'Invalid token'.

  append error_line to error_log.

  ENDIF.

ENDFUNCTION.