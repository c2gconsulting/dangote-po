FUNCTION ZPO_ISOP_DP_GETCUSTOMERDETAILS.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(CUSTOMERDETAILS_IN) TYPE  ZDTCUSTDETAILS
*"  EXPORTING
*"     VALUE(CUSTOMERDETAILS_OUT) TYPE  ZDTCUSTDETAILS_OUT
*"  TABLES
*"      KNA1_TAB STRUCTURE  KNA1
*"      KNB1_TAB STRUCTURE  KNB1
*"----------------------------------------------------------------------


data:
      kna1_line like line of kna1_tab,
      knb1_line like line of knb1_tab,
      kna1_count type i value 0,
      knb1_count type i value 0,
      kunnr type kunnr,
      bukrs type bukrs,
      user type username,
      token type string.

kunnr = customerdetails_in-cust_number.
bukrs = customerdetails_in-comp_code.
token = customerdetails_in-access_token.
perform getUser using token user.
if user is not INITIAL.
* select plant from zpo_comp_plant if plant is initial.

*move src to trg
MOVE-CORRESPONDING customerdetails_in to customerdetails_out.
move user to customerdetails_out-username.
 if customerdetails_in-plant is initial.
  select single plant from zpo_comp_plant into customerdetails_out-plant
    where bankuser eq user.
 endif.
clear: kna1_line , knb1_line.
select * from kna1 into kna1_line where kunnr = kunnr.
  if kna1_line is not initial.
    move kna1_line-name1 to customerdetails_out-cust_name.
    append kna1_line to kna1_tab.
    else.
*      handle error properly.
    endif.
  endselect.

  describe table kna1_tab lines kna1_count.
  if kna1_count is not initial .

    endif.

    select * from knb1 into knb1_line where kunnr = kunnr and bukrs = bukrs.
      append knb1_line to knb1_tab.
      endselect.

      describe table knb1_tab lines knb1_count.
      if knb1_count is not initial.

        endif.
endif.
ENDFUNCTION.