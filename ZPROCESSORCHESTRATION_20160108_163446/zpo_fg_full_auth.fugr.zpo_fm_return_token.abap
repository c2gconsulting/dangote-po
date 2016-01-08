FUNCTION ZPO_FM_RETURN_TOKEN.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(TOKEN) TYPE  STRING
*"  EXPORTING
*"     VALUE(ACCESS_TOKEN) TYPE  STRING
*"  TABLES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"----------------------------------------------------------------------

  DATA: lv_pass_chars(80),
        lv_token TYPE char40,
        user type USERNAME,
        ERROR_LINE like line of ERROR_LOG,
        lv_len TYPE I.
*check if token is valid
  TRANSLATE token to UPPER CASE.
  select single * from zpo_users_auth where access_token = token.
  IF SY-SUBRC = 0.
    CONCATENATE 'ABCDEFGHJKLMNPQRSTUVWXYZ'
                'abcdefghijklmnopqrstuvwxyz'
*              '123456789@$%/\()=+-#~[]{}'
                '123456789@$%'
                INTO lv_pass_chars.

    lv_len = 12.            "

* Function module which generates the token
    CALL FUNCTION 'RSEC_GENERATE_PASSWORD'
      EXPORTING
        alphabet             = lv_pass_chars
        alphabet_length      = 0
        force_init           = ' '
        output_length        = lv_len
        downwards_compatible = ' '
      IMPORTING
        output               = lv_token
      EXCEPTIONS
        some_error           = 1.
    IF sy-subrc NE 0.
* Trigger some message, as required.
    ENDIF.
    TRANSLATE LV_TOKEN TO UPPER CASE.
* set last request time
    "ZPO_USERS_AUTH-LAST_REQUEST = SY-UZEIT.
    "ZPO_USERS_AUTH-ACCESS_TOKEN = LV_TOKEN.
    update ZPO_USERS_AUTH set last_request = sy-uzeit access_token = lv_token WHERE access_token = token.
    MOVE LV_TOKEN TO ACCESS_TOKEN.
  ELSE.
*    HANDLE ERRORS
    error_line-ERROR_CODE = '101'.
      error_line-ERROR_TITLE = 'Invalid logon details'.
      error_line-ERROR_MESSAGE = 'Token validity check failed'.
      append error_line to error_log.
  ENDIF.


ENDFUNCTION.