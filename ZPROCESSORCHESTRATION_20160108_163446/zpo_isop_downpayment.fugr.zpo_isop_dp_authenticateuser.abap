FUNCTION ZPO_ISOP_DP_AUTHENTICATEUSER.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(USERNAME) TYPE  STRING
*"     VALUE(PASSWORD) TYPE  STRING
*"  EXPORTING
*"     VALUE(ACCESS_TOKEN) TYPE  STRING
*"     VALUE(LOGGED_ON) TYPE  STRING
*"     VALUE(CCAREA) TYPE  STRING
*"     VALUE(COUNTRY) TYPE  STRING
*"  TABLES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"      PLANTS STRUCTURE  ZPO_PLANTS OPTIONAL
*"      CCODES STRUCTURE  ZPO_CCODE OPTIONAL
*"      SALES_ORGS STRUCTURE  ZPO_SALESORGS OPTIONAL
*"----------------------------------------------------------------------
TABLES:
  ZPO_USERS_AUTH.

DATA :  lv_password TYPE char40,
        lv_pass_chars(80),
 lv_len TYPE I,
 checkuser like username
,user_inf type zpo_users_auth,
user_inf_tab type table of zpo_users_auth,
user_comp_plant_inf type zpo_comp_plant,
logged_on_timer like sy-uzeit , logged_on_dater like sy-datum,
error_line like line of error_log,
PLANTS_line like line of plants,
CCODES_line like line of ccodes,
SALES_ORGS_line like line of sales_orgs



....


  CONCATENATE 'ABCDEFGHJKLMNPQRSTUVWXYZ'
              'abcdefghijklmnopqrstuvwxyz'
*              '123456789@$%/\()=+-#~[]{}'
              '123456789@$%'
              INTO lv_pass_chars.

    lv_len = 12.            "

* Function module which generates the password
  CALL FUNCTION 'RSEC_GENERATE_PASSWORD'
    EXPORTING
      alphabet             = lv_pass_chars
      alphabet_length      = 0
      force_init           = ' '
      output_length        = lv_len
      downwards_compatible = ' '
    IMPORTING
      output               = lv_password
    EXCEPTIONS
      some_error           = 1.
  IF sy-subrc NE 0.
* Trigger some message, as required.
  ENDIF.

clear checkuser.
if ( username is not initial and password is not initial ).
  perform ENCRYPTPASS using password.
  select single * into user_inf from ZPO_USERS_AUTH where username = username and password = password.
    if  sy-SUBRC eq 0    and user_inf is not initial.
move user_inf-USERNAME to checkuser.
move lv_password to access_token.
translate access_token TO UPPER CASE.
logged_on_timer = sy-uzeit.
logged_on_dater = sy-datum.


select * from zpo_comp_plant into user_comp_plant_inf where bankuser = checkuser.
  user_inf-username = checkuser.
  user_inf-password = password.
  user_inf-access_token = access_token.
  user_inf-logged_on_time = logged_on_timer.
  user_inf-logged_on_date = logged_on_dater.

  move-corresponding user_comp_plant_inf to user_inf.

*  user_inf-comp_code = user_comp_plant_inf-comp_code.
*  user_inf-plant = user_comp_plant_inf-plant.
*  user_inf-vkorg = user_comp_plant_inf-vkorg.
*  user_inf-cc_area = user_comp_plant_inf-cc_area.

    move user_inf-CC_AREA to CCAREA.
    move user_inf-COUNTRY_CODE to COUNTRY.
  append user_inf to user_inf_tab.

  move user_inf-PLANT to PLANTS_LINE-WERKS.
  select single NAME1 INTO PLANTS_LINE-DESCRIPTION from T001W WHERE WERKS = PLANTS_LINE-WERKS.

    APPEND PLANTS_LINE TO PLANTS.

    MOVE USER_INF-COMP_CODE TO CCODES_LINE-BUKRS.
    SELECT SINGLE BUTXT INTO CCODES_LINE-BUTXT FROM T001 WHERE BUKRS = CCODES_LINE-BUKRS.

      APPEND CCODES_LINE TO CCODES.


      MOVE USER_INF-VKORG TO SALES_ORGS_LINE-VKORG.
      SELECT SINGLE VTEXT INTO SALES_ORGS_LINE-VTEXT FROM TVKOT WHERE VKORG = SALES_ORGS_LINE-VKORG.

        APPEND SALES_ORGS_LINE TO SALES_ORGS.


endselect.
DELETE ADJACENT DUPLICATES FROM CCODES.
DELETE ADJACENT DUPLICATES FROM PLANTS.
DELETE ADJACENT DUPLICATES FROM SALES_ORGS.

*update zpo_users_auth
*set:
*access_token = access_token
*logged_on_time = logged_on_timer
*logged_on_date = logged_on_dater
*where
*username = username and password = password .


IF ( USER_INF_TAB IS NOT INITIAL ).
delete  from zpo_users_auth
where
username = username and password = password "(no need to compare)and access_token = access_token.
.

insert zpo_users_auth from table user_inf_tab.

commit work.

ENDIF.
LOGGED_ON = 'TRUE'.
ELSE.
  LOGGED_ON = 'FALSE'.
  error_line-ERROR_CODE = '101'.
  error_line-ERROR_TITLE = 'Invalid logon details'.
  error_line-ERROR_MESSAGE = 'Invalid logon details'.


  append error_line to error_log.
endif.

else.
  if ( username is initial ).
      error_line-error_code = '101'.
      error_line-error_title = 'Username field is empty!'.
      error_line-ERROR_MESSAGE = 'Please provide a username...'.

      append error_line to error_log.
    endif.

    if ( password is initial ).
        error_line-error_code = '101'.
        error_line-error_title = 'Password field is empty!'.
        error_line-error_message = 'Please provide a password'.

        append error_line to error_log.

      endif.

endif.
ENDFUNCTION.