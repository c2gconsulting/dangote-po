FUNCTION-POOL ZPO_ISOP_DOWNPAYMENT.         "MESSAGE-ID ..

* INCLUDE LZPO_ISOP_DOWNPAYMENTD...          " Local class definition
data _salt type string value 'CataLYSt'.
data _salt1 type i value '19900622'.
data _i type i.
data access_token_global type string.

form encryptPass using pass type string.
  DATA:
        pass1 type FIEB_DECRYPTED_PASSWD,
        pass2 type FIEB_ENCRYPTED_PASSWD,
        pass3(20) type c.

*  pass3 = pass.
*  concatenate _salt pass into pass.
  pass3 = pass.
*
*  CALL FUNCTION 'FIEB_PASSWORD_ENCRYPT'
*    EXPORTING
*      IM_DECRYPTED_PASSWORD = pass1
*    IMPORTING
*      EX_ENCRYPTED_PASSWORD = pass2.
*
*  pass = pass2+0(32).
*  REPLACE ' ' IN PASS WITH ''.
*  REPLACE '|' IN PASS WITH ''.
*
   _i = strlen( pass3 ).

  CALL FUNCTION 'HTTP_SCRAMBLE'
    EXPORTING
      SOURCE            = pass3
      SOURCELEN         = _i
      KEY               = _salt1
   IMPORTING
     DESTINATION       = pass3
            .

  move pass3 to pass.
  translate pass TO UPPER CASE.
endform.



form getUser using access_token type string user type username.
  TRANSLATE access_token to UPPER CASE.
    select single username into user from zpo_users_auth where access_token = access_token.
    endform.