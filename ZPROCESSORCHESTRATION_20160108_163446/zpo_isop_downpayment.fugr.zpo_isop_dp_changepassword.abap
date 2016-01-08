FUNCTION ZPO_ISOP_DP_CHANGEPASSWORD.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(USERNAME) TYPE  USERNAME
*"     VALUE(PASSWORD) TYPE  STRING
*"     VALUE(NEWPASSWORD) TYPE  STRING
*"     VALUE(CONFIRMNEWPASSWORD) TYPE  STRING
*"  EXPORTING
*"     VALUE(PASSWORD_CHANGED) TYPE  CHAR255
*"----------------------------------------------------------------------

data: checkuser like username.
PERFORM:
encryptpass USING password,
encryptpass using newpassword,
encryptpass using confirmnewpassword.

if ( username is not initial and password is not initial ).
select single username into checkuser from ZPO_USERS_AUTH WHERE username = username and password = password.
  if sy-subrc eq 0 and checkuser is not initial.
      if newpassword eq confirmnewpassword.
          update ZPO_USERS_AUTH
          set password = newpassword
          where username = username.

          commit WORK.
          move 'Password update was successful!' to PASSWORD_CHANGED.


          else.
            move 'Password update failed due to password mismatch!' to password_changed.
        endif.
    endif.

    ELSE.
      move 'One or more of your input field is not provided! Please check' to password_changed.
endif.


ENDFUNCTION.