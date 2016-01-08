*&---------------------------------------------------------------------*
*& Report  ZPO_TOKEN_CHECK
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZPO_TOKEN_CHECK.
tables:
  zpo_users_auth.

data:
      _d type dats,
      _t2 like sy-uzeit,
      _t like sy-uzeit,
      _ts type string,


      user type username,



      user_line type zpo_users_auth,
      user_chck type zpo_users_auth.

move:
     sy-datum to _d,
     sy-uzeit to _t.

select * into user_line
  from zpo_users_auth
  where logged_on_date le _d
  and logged_on_time le _t.


_t2 = _t - user_line-logged_on_time.
move _t2 to _ts.
*  _t = _t - user_line-logged_on_time.

  if ( _ts ge '002000' ).
    delete from zpo_users_auth where username = user_line-username
    and access_token = user_line-access_token.

    clear user_chck.
    select single * into user_chck from zpo_users_auth where username = user_line-username.
      if ( user_chck is initial ).
          move '' to user_line-access_token.
          clear :
          user_line-PLANT, user_line-LOGGED_ON_DATE, user_line-LOGGED_ON_TIME,
          user_line-COMP_CODE , user_line-vkorg , user_line-cc_area, user_line-country_code,
          user_line-cbn.
          insert into zpo_users_auth values user_line.
      endif.

*     write:/ user_line-username.
*  write:' ', _t , ' ', user_line-logged_on_time , ' ' , _t2.

  endif.
endselect.