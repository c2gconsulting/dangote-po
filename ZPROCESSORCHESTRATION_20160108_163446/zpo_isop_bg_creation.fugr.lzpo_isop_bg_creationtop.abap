FUNCTION-POOL ZPO_ISOP_BG_CREATION.         "MESSAGE-ID ..

* INCLUDE LZPO_ISOP_BG_CREATIOND...          " Local class definition

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
  ENDFORM.