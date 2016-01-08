FUNCTION ZPO_FM_FULL_AUTH.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(USERNAME) TYPE  STRING
*"     VALUE(PASSWORD) TYPE  STRING
*"     VALUE(FULL_SYNCH) TYPE  BOOLEAN OPTIONAL
*"  EXPORTING
*"     VALUE(ACCESS_TOKEN) TYPE  STRING
*"     VALUE(LOGGED_ON) TYPE  STRING
*"  TABLES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"      RECORDS STRUCTURE  ZMAT_RECORDS OPTIONAL
*"      REGIONS STRUCTURE  ZPO_REGIONS_FULL OPTIONAL
*"      CREDIT_AREAS STRUCTURE  ZPO_CREDIT_AREAS OPTIONAL
*"----------------------------------------------------------------------

  DATA :  lv_password TYPE char40,
          lv_pass_chars(80),
   lv_len TYPE I,
   checkuser like username
  ,user_inf type zpo_users_auth,
  user_inf_tab type STANDARD TABLE OF zpo_users_auth WITH HEADER LINE,
  user_comp_plant_inf type zpo_comp_plant,
  logged_on_timer like sy-uzeit , logged_on_dater like sy-datum,
  error_line like line of error_log,
  wa_records type ZMAT_RECORDS,
  check_user_info_tab type char1,
  mtart type mtart,
  a_region type zpo_regions_full,
  t005u_line type t005u,
  wa_ca type ZPO_CREDIT_AREAS,
  BUTXT TYPE BUTXT, "COMPANY CODE DESCRIPTION
  VTEXT TYPE VTEXT "SALES ORGANISATION TEXT.



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

        append user_inf to user_inf_tab.
* My logic goes here using cyrils authenticate method.


      endselect.

*update zpo_users_auth
*set:
*access_token = access_token
*logged_on_time = logged_on_timer
*logged_on_date = logged_on_dater
*where
*username = username and password = password .

      data lines type i.
      DESCRIBE TABLE USER_INF_TAB LINES lines.
      IF ( lines >= 1 ).
        check_user_info_tab = 'X'.
*        delete  from zpo_users_auth
*        where
*        username = username and password = password.
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
* check if full synch is requested.
  case full_synch.
    when '1'.
*     populate tables for full data retrieval .. continued from catalyst initial design
      if check_user_info_tab = 'X'.
        loop at USER_INF_TAB.
* Get region of the first record since
          if ( sy-tabix = 1 ).
            select * from t005u into t005u_line where land1 = USER_INF_TAB-country_code AND SPRAS = USER_INF_TAB-LANGUAGE.
              a_region-regio = t005u_line-bland.
              a_region-description = t005u_line-bezei.
              a_region-country = USER_INF_TAB-COUNTRY_CODE.
              append a_region to regions.
            endselect.
          endif.
* get credit areas.
          wa_ca-ccode = USER_INF_TAB-COMP_CODE.
          wa_ca-cbn_code = USER_INF_TAB-CBN.
          wa_ca-credit_area = USER_INF_TAB-CC_AREA.
          APPEND WA_CA TO CREDIT_AREAS.
* get all plants and materials

*          select mv~matnr into wa_records-MATERIAL from mvke as mv INNER JOIN marc as ma  on
*            ( mv~matnr = ma~matnr ) where
*            mv~vkorg = USER_INF_TAB-vkorg and
*            ma~werks = USER_INF_TAB-plant.
*            select single maktx into wa_records-MATERIAL_DESC from makt
*               where matnr = wa_records-MATERIAL.
*            if ( sy-subrc eq 0 and wa_records-MATERIAL_DESC is not initial ).
*              select single mtart into  mtart from mara where matnr = wa_records-MATERIAL.
*              if ( SY-SUBRC eq 0 and  mtart eq 'FERT' ).
*                set other attributes and append..
*                MOVE USER_INF_TAB-COMP_CODE TO WA_RECORDS-CCODE.
*                SELECT SINGLE BUTXT INTO WA_RECORDS-CCODE_DESC FROM T001 WHERE BUKRS = WA_RECORDS-CCODE.
*                MOVE USER_INF_TAB-VKORG TO WA_RECORDS-SORG.
*                SELECT SINGLE VTEXT INTO WA_RECORDS-SORG_DESC FROM TVKOT WHERE VKORG = WA_RECORDS-SORG.
*                MOVE USER_INF_TAB-PLANT TO WA_RECORDS-PLANT.
*                select single name1 into WA_RECORDS-PLANT_DESC from t001w where werks = WA_RECORDS-PLANT.
*                append wa_records to RECORDS.
*              endif.
*            endif.
*            CLEAR: wa_ca, wa_records.
*          endselect.
*gGET MATERIALS FOR CURRENT SALES ORGANISATION USING DEFAULT DIVISION 10 AS DESCRIBED BY THE FS

*but first get sales organisation and companycode sales org description
          SELECT SINGLE VTEXT INTO VTEXT FROM TVKOT WHERE VKORG = USER_INF_TAB-VKORG AND SPRAS = USER_INF_TAB-LANGUAGE.
          SELECT SINGLE BUTXT INTO BUTXT FROM T001 WHERE BUKRS = USER_INF_TAB-COMP_CODE AND LAND1 = USER_INF_TAB-COUNTRY_CODE.
          SELECT M~MATNR M~VRKME M~VKORG
                 R~MEINS R~SPART
                 T~MAKTX
                 C~WERKS
                 N~NAME1
            INTO CORRESPONDING FIELDS OF TABLE RECORDS
            FROM MVKE AS M
            INNER JOIN MARA AS R ON M~MATNR = R~MATNR
            INNER JOIN MAKT AS T ON R~MATNR = T~MATNR
            INNER JOIN MARC AS C ON T~MATNR = C~MATNR
            INNER JOIN T001W AS N ON C~WERKS = N~WERKS
            WHERE M~VKORG = USER_INF_TAB-VKORG
            AND M~VTWEG = 10 AND R~MTART = 'FERT'
            AND T~SPRAS = USER_INF_TAB-LANGUAGE
            AND N~LAND1 = USER_INF_TAB-COUNTRY_CODE.
          sort RECORDS BY VKORG WERKS.
          loop at RECORDS where vkorg = USER_INF_TAB-vkorg.
            records-vtext = vtext.
            RECORDS-CCODE = USER_INF_TAB-COMP_CODE.
            RECORDS-CCODE_DESC = BUTXT.
            MODIFY RECORDS.
          ENDLOOP.
        ENDLOOP.

      ENDIF.
  ENDCASE.

ENDFUNCTION.