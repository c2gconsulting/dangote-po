FUNCTION-POOL ZPO_ISOP_ATC_CREATION_V2.     "MESSAGE-ID ..

* INCLUDE LZPO_ISOP_ATC_CREATION_V2D...      " Local class definition

data:
      user_details type table of zpo_users_auth,
      t005u_line type t005u.
data: itab_child type TABLE OF zpo_atc_docs WITH HEADER LINE.
DATA PROCESSED TYPE I VALUE  0.


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