FUNCTION ZPO_ISOP_ATC_VALIDATEINPUT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(COMP_CODE) TYPE  ZCOMP_CODE OPTIONAL
*"     VALUE(BANKN) TYPE  ZBANKN OPTIONAL
*"     VALUE(CUST_NUMBER) TYPE  KUNNR OPTIONAL
*"     VALUE(AMOUNT) TYPE  WRBTR OPTIONAL
*"     VALUE(TELLERNO) TYPE  ZTELLERNO OPTIONAL
*"     VALUE(TRAN_ID) TYPE  ZTRAN_ID OPTIONAL
*"     VALUE(CURRENCY) TYPE  WAERS OPTIONAL
*"     VALUE(INVOICE_AMOUNT) TYPE  WRBTR OPTIONAL
*"     VALUE(ACCESS_TOKEN) TYPE  STRING OPTIONAL
*"     VALUE(SPLIT_INDICATOR) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(VALID) TYPE  BOOLEAN
*"     VALUE(DOC_STRING) TYPE  STRING
*"  TABLES
*"      MATERIALS STRUCTURE  ZMATERIALS OPTIONAL
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"      QTY STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"      SPLIT_QTY STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"      PARENT STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      CHILD STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"----------------------------------------------------------------------

* Write implementing code for validating bank input
  DATA USER TYPE USERNAME.
  data _logged_on_user1 type username.
  data _ccarea type kkber.
  data exposure like RF02L-OBLIG.
  data showpost type c VALUE  'X'.
  data: it_vbak type STANDARD TABLE OF vbak WITH HEADER LINE,
        wa_vbak type vbak.

*  'FWC%I2S RV' to access_token.
  perform getUser using access_token _logged_on_user1.

  if ( _logged_on_user1 is not initial and access_token is not initial ) .

    user = _logged_on_user1.
    select single cc_area into _ccarea from zpo_users_auth   where access_token = access_token.
    if ( sy-subrc eq 0 and _ccarea is not initial ).
    endif.
*for nw...

    tables: zpo_comp_plant.

    data : zpo_comp_plant_line type zpo_comp_plant,
            zpo_comp_plant_tab type table of zpo_comp_plant,
           error_log_line like line of error_log ,
           error_size type i,
           msg1 type string,
           msg2 type string,
           zxblnr like bkpf-xblnr ,
           zzuonr like bseg-zuonr,
           acc_no type hkont,
           amtstring type string ,
           wa_bsid type bsid,
           invamtstring type string.


* validate users and company codes. get every user information frm the users
    select * from zpo_comp_plant into zpo_comp_plant_line where bankuser = user and comp_code = comp_code.
      append zpo_comp_plant_line to zpo_comp_plant_tab.
    endselect.

    data count_tab type i.
    describe table zpo_comp_plant_tab lines count_tab.

    if ( count_tab is not initial ).
*        this user is a valid user
    else.
      valid = '-'.
      concatenate 'User' user ' is not authorized to post in company code ' comp_code into msg1 SEPARATED BY space.
      error_log_line-ERROR_CODE = '101'.
      error_log_line-ERROR_TITLE = 'Unauthorized Company code'.
      error_log_line-ERROR_MESSAGE = msg1.

      append error_log_line to ERROR_LOG.
    endif.

data cbn like ZPO_USERS_AUTH-cbn.
select single cbn into cbn from zpo_users_auth where access_token = access_token.
  data c_tellerno like tellerno.
  data: c_tranid like tran_id, d_tranid like tran_id.


* validates teller no and tran id
* bkpf xblnr tellerno bseg zuonr tran id
*    if ( tellerno is not initial ).
*      concatenate cbn '_' tellerno into c_tellerno.
*      TRANSLATE c_tellerno to UPPER CASE.
*      select single xblnr into zxblnr from bkpf where xblnr = c_tellerno and bukrs = comp_code .
*      if ( sy-subrc eq 0  and zxblnr is not initial ).
*        valid = '-'.
**      this teller has been processed
*        concatenate 'A transaction with teller number ' tellerno 'has already been posted!' into msg1 SEPARATED BY space.
*        error_log_line-ERROR_CODE = '101'.
*        error_log_line-ERROR_TITLE = 'Transaction already posted'.
*        error_log_line-ERROR_MESSAGE = msg1.
*
*        append error_log_line to ERROR_LOG.
*        clear msg1.
**      clear validation_output.
*      ELSE.
*
*      endif.
*    endif.


    if ( tran_id is not initial and tellerno is not initial ).
      CONCATENATE cbn '_E_' tran_id into d_tranid.
      CONCATENATE cbn '_A_' tran_id into c_tranid.
      concatenate cbn '_' tellerno into c_tellerno.
      TRANSLATE c_tellerno to UPPER CASE.
      select single * into wa_bsid from bsid where ( ( xblnr = c_tellerno ) and bukrs = comp_code ).
      if sy-subrc eq 0 and wa_bsid-zuonr is not initial.
        "check if transaction id and teller number matches
        if wa_bsid-zuonr <> c_tranid.
          clear showpost. "since there's a transaction mismatch, no need to return doc info
        valid = '-'.
*    this transaction id has been posted.
        concatenate 'payment for teller ' tellerno 'belongs to a different transaction' into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'Transaction mismatch'.
        error_log_line-ERROR_MESSAGE = msg1.

        append error_log_line to ERROR_LOG.

        clear msg1.
        endif.
*      clear validation_output.
      ELSE.

      endif.
    endif.

    if ( tran_id is not initial ).
        data vbeln like vbak-vbeln.

        CONCATENATE cbn '_A_' tran_id into c_tranid.
        select  single vbeln  into vbeln from vbak where BSTNK = c_TRANID and AUART in ('YDOR' , 'YSOR') .
          if ( vbeln is not initial ).
            error_log_line-ERROR_CODE = '101'.
            error_log_line-error_title = 'Transaction already posted'.
            error_log_line-error_message = 'Transaction already posted'.

            valid = '-'.
            append error_log_line to error_log.
            data cstring type string.
            if showpost = 'X'. "show posted documents
                select * from vbak into TABLE it_vbak
                 where bstnk = c_tranid.
                  if sy-subrc = 0.
                    loop at it_vbak into wa_vbak.
                      if ( wa_vbak-auart = 'ZDOR' or wa_vbak-auart = 'ZSOR' ).
                        parent-doc_num = wa_vbak-vbeln.
                        parent-doc_type = wa_vbak-auart.
                        append parent.
                        CONCATENATE wa_vbak-vbeln '->' into doc_string.
                      else.
                        child-doc_num = wa_vbak-vbeln.
                        child-doc_type = wa_vbak-auart.
                        append child.
                        CONCATENATE cstring wa_vbak-vbeln ';' into cstring.
                      endif.
                    endloop.
                    CONCATENATE doc_string cstring into doc_string.
                  endif.
            endif.
            else.

              endif.
      endif.
*
*  validate bankn
    if ( bankn is not initial ).
      clear acc_no.
      select single hkont into acc_no from T012K where bukrs = comp_code and bankn = bankn.
      if sy-subrc eq 0 and acc_no is not initial.

      else.
*      there is no matching gl account for this house bank number
        concatenate 'There is no corresponding GL Account for house bank account' bankn ' , maintain with transaction FI12 IN SAP SYSTEM' into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'GL Account not found!'.
        error_log_line-ERROR_MESSAGE = msg1.

        valid = '-'.
        append error_log_line to ERROR_LOG.

        clear msg1.
*      clear validation_output.

      endif.
    endif.

*validate customer number
    if ( cust_number is not initial ).
      data valid_customer type kunnr.
      select single kunnr into valid_customer from knb1 where kunnr = cust_number
        and bukrs = comp_code .
      if ( sy-subrc eq 0 and valid_customer is not initial ).

      else.
        valid = '-'.
        concatenate 'Customer ' cust_number ' is not defined in company code' comp_code  into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'Customer not defined in company'.
        error_log_line-ERROR_MESSAGE = msg1.

        append error_log_line to ERROR_LOG.

        clear msg1.
*      clear validation_output.

      endif.
    endif.

*validate customer dp payment amount against invoice amount

    amtstring = amount.
    invamtstring = invoice_amount.
    if amount is not initial and invoice_amount is not initial.
      if ( amount eq invoice_amount ).

      else.
        valid = '-'.
        concatenate 'Payment Amount' amtstring ' does not match order amount' invamtstring ', !' into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'Invalid Payment amount for clearing invoice'.
        error_log_line-ERROR_MESSAGE = msg1.

        append error_log_line to ERROR_LOG.

        clear msg1.
*        clear validation_output.
      endif.
    endif.

    describe table error_log lines error_size.
    if ( error_size is not initial ).
*      clear invoice_amount2.
    endif.
    if ( error_size = 0 ).
*      MOVE-CORRESPONDING bank_input to VALIDATION_OUTPUT.
    endif.

*  customer credit exposure validation

  if ( TELLERNO is initial ).
    CALL FUNCTION 'CREDIT_EXPOSURE'
      EXPORTING
        KKBER                = _ccarea
        KUNNR                = cust_number
        DATE_CREDIT_EXPOSURE = '99991231'
      IMPORTING
*       CREDITLIMIT          =
*       DELTA_TO_LIMIT       =
*       E_KNKK               =
*       KNKLI                =
*       OPEN_DELIVERY        =
*       OPEN_INVOICE         =
*       OPEN_ITEMS           =
*       OPEN_ORDER           =
*       OPEN_SPECIALS        =
*       PERCENTAGE           =
        SUM_OPENS            = exposure
*       OPEN_ORDER_SECURE    =
*       OPEN_DELIVERY_SECURE =
*       OPEN_INVOICE_SECURE  =
*       CMWAE                =
      .
    MULTIPLY exposure by -1.
    if ( exposure >= amount ).
    else.
      concatenate 'Customer with number ' cust_number ' has insufficient exposure' into msg1 separated by space.
      valid = '-'.
      error_log_line-error_code = '101'.
      error_log_line-error_title = 'Insufficient Exposure'.
      error_log_line-error_message = msg1.

      append error_log_line to error_log.

    endif.
    endif.
*  split validation
    data count_materials type i.
    describe table materials lines count_materials.

    if ( count_materials > 0 ).
      if split_indicator = 'X'.
      if ( SPLIT_INDICATOR = 'X' and count_materials = 1 ).

*    then split can be done
      data totalqty type string.
      data tq type p DECIMALS 2.
      data cq type p DECIMALS 2.
      data s_i type i.
      data split_line like line of split_qty.
      data qt_line like line of split_qty.


      loop at qty into qt_line.

        endloop.
      DESCRIBE TABLE SPLIT_QTY lines s_i.

      if ( s_i > 1 ).
        loop at split_qty into split_line.
          cq = split_line-QTY.
          add cq to tq.

          endloop.

          if ( tq eq qt_line-qty ).
            else.
              valid = '-'.
        msg1 = 'Total split quantity must equal order quantity.'.
        error_log_line-error_code = '101'.
        error_log_line-error_title = 'Split quantity error'.
        error_log_line-error_message = msg1.

        append error_log_line to error_log.
              endif.

        endif.

      else.
        valid = '-'.
        msg1 = 'Split cannot be done on multiple materials.'.
        error_log_line-error_code = '101'.
        error_log_line-error_title = 'Error with split indicator'.
        error_log_line-error_message = msg1.

        append error_log_line to error_log.

      endif.

      endif.
    endif.

  else.
    valid = '-'.
    DATA MSG3 TYPE STRING.
    CONCATENATE 'INVALID TOKEN ' ACCESS_TOKEN INTO MSG3 SEPARATED BY space.
    error_log_line-ERROR_CODE = '101'.
    error_log_line-ERROR_TITLE = MSG3.
    error_log_line-ERROR_MESSAGE = 'Invalid token, cannot authenticate user for this call'.

    append error_log_line to error_log.


  endif.
ENDFUNCTION.