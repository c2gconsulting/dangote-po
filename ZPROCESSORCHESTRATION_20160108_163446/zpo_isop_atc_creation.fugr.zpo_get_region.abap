FUNCTION ZPO_GET_REGION.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ACCESS_TOKEN) TYPE  STRING OPTIONAL
*"     VALUE(COUNTRY) TYPE  LAND1 OPTIONAL
*"  EXPORTING
*"     VALUE(LAND1) TYPE  LAND1
*"  TABLES
*"      REGIONS STRUCTURE  ZPO_REGIONS OPTIONAL
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE
*"----------------------------------------------------------------------
  data userDetailsLine like line of user_details.
  data:
        t005u_line type t005u,
        a_region type zpo_regions,
        user type username,
        error_line like line of error_log,
        landx like t005t-landx.


  perform getUser using access_token user.
  perform getUserDetails using access_token.


  if user is not initial and access_token is not initial.
    move country to land1.
    if ( country is initial ).
      perform getRegions using access_token regions[].
    else.
      select single landx from t005t into landx where spras = 'E' and land1 = country.
      select * from t005u into t005u_line where land1 = country.
        if sy-subrc eq 0 and t005u_line is not initial.
          a_region-regio = t005u_line-bland.
          a_region-description = t005u_line-bezei.
          a_region-country = country.
          append a_region to regions.

        else.
          error_line-error_code = '101'.
          error_line-error_title = 'Invalid country code'.
          error_line-ERROR_MESSAGE  = 'Please provide a valid country code!'.

          append error_line to error_log.

        endif.
      endselect.
    endif.

    sort regions by REGIO.
    delete ADJACENT DUPLICATES FROM regions.

  else.

    error_line-error_code = '101'.
    error_line-error_title = 'Invalid token'.
    error_line-ERROR_MESSAGE  = 'Please provide a valid token'.

    append error_line to error_log.

  endif.



ENDFUNCTION.