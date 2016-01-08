FUNCTION ZPO_ISOP_DP_VALIDATEBANKINPUT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(BANK_INPUT) TYPE  ZDTCUSTDETAILS OPTIONAL
*"     VALUE(COMP_CODE) TYPE  ZCOMP_CODE OPTIONAL
*"     VALUE(BANKN) TYPE  ZBANKN OPTIONAL
*"     VALUE(CUST_NUMBER) TYPE  KUNNR OPTIONAL
*"     VALUE(AMOUNT) TYPE  WRBTR OPTIONAL
*"     VALUE(TELLERNO) TYPE  ZTELLERNO OPTIONAL
*"     VALUE(TRAN_ID) TYPE  ZTRAN_ID OPTIONAL
*"     VALUE(CURRENCY) TYPE  WAERS OPTIONAL
*"     VALUE(INVOICE_AMOUNT) TYPE  WRBTR OPTIONAL
*"     VALUE(ACCESS_TOKEN) TYPE  STRING
*"  EXPORTING
*"     VALUE(VALIDATION_OUTPUT) TYPE  ZDTCUSTDETAILS
*"     VALUE(INVOICE_AMOUNT2) TYPE  WRBTR
*"     VALUE(OUTPUT_STRING1) TYPE  STRING
*"     VALUE(OUTPUT_STRING2) TYPE  STRING
*"     VALUE(DOCNUM) TYPE  STRING
*"     VALUE(FISCALYR) TYPE  STRING
*"     VALUE(COMPCODE) TYPE  STRING
*"  TABLES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"----------------------------------------------------------------------

* Write implementing code for validating bank input
  DATA USER TYPE USERNAME.
  data _logged_on_user1 type username.
  tables: zpo_comp_plant.

  data : zpo_comp_plant_line type zpo_comp_plant,
         error_log_line like line of error_log ,
         error_size type i,
         msg1 type string,
         msg2 type string,
         zxblnr like bkpf-xblnr ,
         zzuonr like bseg-zuonr,
         acc_no type hkont,
         amtstring type string ,
         invamtstring type string.
*  move
*  '$J5HO2XZME' to access_token.
  perform getUser using access_token _logged_on_user1.

  if ( _logged_on_user1 is not initial and access_token is not initial ).

    user = _logged_on_user1.

*    CHECK user field for company code and customer is not empty.
    if  bank_input-COMP_CODE is initial and COMP_CODE is initial.
      ERROR_LOG_LINE-ERROR_CODE = '101'.
      error_log_line-ERROR_TITLE = 'No company code'.
      error_log_line-ERROR_MESSAGE = 'Please provide a company code...'.

      append error_log_line to error_log.
    endif.

    if bank_input-CUST_NUMBER is initial and CUST_NUMBER is initial.
      error_log_line-error_Code  = '101'.
      error_log_line-error_title = 'No customer'.
      error_log_line-error_message = 'Please provide a customer number..'.

      append error_log_line to error_log.

    endif.

    if bank_input-bankn is initial and BANKN is initial .
      error_log_line-error_code = '101'.
      error_log_line-error_title = 'No House Bank'.
      error_log_line-error_message = 'Please provide a House bank number..'.

      append error_log_line to error_log.
    endif.


    move-CORRESPONDING bank_input to validation_output.
    if ( bank_input-AMOUNT is initial ). move amount to bank_input-amount. endif.
    if ( bank_input-BANKN is initial ). move bankn to bank_input-bankn. endif.
    if ( bank_input-comp_code is initial ). move comp_code to bank_input-comp_code. endif.
    if ( bank_input-CURRENCY is initial ). move currency to bank_input-currency. endif.
    if ( bank_input-CUST_NUMBER is initial ). move cust_number to bank_input-cust_number. endif.
    if ( bank_input-REF_DOC_NO is initial ). move tellerno to bank_input-ref_doc_no. endif.
    if ( bank_input-TRAN_ID is initial ). move tran_id to bank_input-tran_id. endif.
    if ( bank_input-USERNAME is initial ). move user to bank_input-username. endif.
    INVOICE_AMOUNT2 = INVOICE_AMOUNT.
*for nw...

    if bank_input-AMOUNT is initial  or not ( bank_input-amount gt 0 or bank_input-amount lt 0  ) .
      error_log_line-error_code = '101'.
      error_log_line-error_title = 'No amount / zero Amount'.
      error_log_line-error_message = 'Please ensure that an amount is provided'.

      append error_log_line to error_log.

    endif.

*      teller number

    if bank_input-REF_DOC_NO is initial  .
      error_log_line-error_code = '101'.
      error_log_line-error_title = 'No teller number'.
      error_log_line-error_message = 'Please provide the teller number for this transaction!'.

      append error_log_line to error_log.

    endif.


*      transaction id

    if bank_input-TRAN_ID is initial   .
      error_log_line-error_code = '101'.
      error_log_line-error_title = 'No transaction id'.
      error_log_line-error_message = 'Please provide a transaction id for this transaction'.

      append error_log_line to error_log.

    endif.
*      currency
    if bank_input-CURRENCY is initial .
      error_log_line-error_code = '101'.
      error_log_line-error_title = 'No currency'.
      error_log_line-error_message = 'Please provide a currency for this transaction'.

      append error_log_line to error_log.

    endif.

    data c_i type i.
    describe table error_log lines c_i.


    if ( c_i eq 0 ).
* validate users and company codes.
      select single * from zpo_comp_plant into zpo_comp_plant_line where bankuser = user and comp_code = comp_code.

      if ( sy-subrc eq 0 and zpo_comp_plant_line is not initial ).

      else.
        concatenate 'User' user ' is not authorized to post in company code ' comp_code into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'Unauthorized Company code'.
        error_log_line-ERROR_MESSAGE = msg1.

        append error_log_line to ERROR_LOG.
        clear msg1.
        clear VALIDATION_OUTPUT.
      endif.


* validates teller no and tran id
* bkpf xblnr tellerno bseg zuonr tran id
*get cbn of user from token and validate the token
      data: cbn type char3,
            wa_bkpf type bkpf,
            c_tellerno type ZTELLERNO,
            c_tranid like tran_id,
            d_tranid like tran_id,
            tran_id_dp like tran_id,
            tran_id_atc like tran_id.
      move tellerno to c_tellerno.
      TRANSLATE access_token to UPPER CASE.
      select single cbn into cbn from zpo_users_auth where access_token = access_token.
      if sy-subrc = 0.
        translate tellerno to upper case.
        CONCATENATE CBN tellerno INTO TELLERNO SEPARATED BY '_'.
        select single * into wa_bkpf from bkpf where xblnr = TELLERNO and bukrs = comp_code .
        if ( sy-subrc eq 0  and wa_bkpf-xblnr is not initial ).
*      RETURN DOC NUMBER FISCAL YEAR AND COMP-CODE WHERE DOCUMENT IS POSTED TO
          DOCNUM = wa_bkpf-belnr.
          FISCALYR = wa_bkpf-gjahr.
          COMPCODE  = wa_bkpf-bukrs.
*      this teller has been processed
          concatenate 'A transaction with teller number ' tellerno 'has already been posted!' into msg1 SEPARATED BY space.
          error_log_line-ERROR_CODE = '101'.
          error_log_line-ERROR_TITLE = 'Transaction already posted'.
          error_log_line-ERROR_MESSAGE = msg1.

          append error_log_line to ERROR_LOG.
          clear msg1.
          clear validation_output.
        ELSE.

        endif.
      endif.
      data wa_bsid type bsid.
      concatenate 'A_' TRAN_ID into tran_id_atc.
      concatenate 'E_' TRAN_ID into tran_id_dp.
      concatenate cbn '_' tran_id_dp into c_tranid.
      concatenate cbn '_' tran_id_atc into d_tranid.
      select single * into wa_bsid from bsid where ( zuonr = c_TRANID or zuonr = d_tranid ) and bukrs = comp_code.
      if sy-subrc eq 0 and wa_bsid-zuonr is not initial.
*     get wa_bsid-belnr bukrs and gjahr will have to enhace this mehtod to append the details and not to overwrite
        DOCNUM  = wa_bsid-belnr.
        FISCALYR  = wa_bsid-gjahr.
        COMPCODE = wa_bsid-bukrs.

*    this transaction id has been posted.
        concatenate 'A transaction with transaction id ' wa_bsid-zuonr 'has already been posted!' into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'Transaction already posted'.
        error_log_line-ERROR_MESSAGE = msg1.

        append error_log_line to ERROR_LOG.

        clear msg1.
        clear validation_output.
      ELSE.

      endif.

*   if doc num and ghajr and bukrs is not empty ... generate barcode
      if ( docnum is not initial and fiscalyr is not initial and compcode is not initial ).
        CONCATENATE docnum COMPCODE FISCALYR into output_string1.
        output_string2 = output_string1.
*        DATA: CIAG(200).
*        CONCATENATE '^XA^LH20,20^FO60,80^B3,,250,N^FD' docnum COMPCODE FISCALYR
*            '^FS^FO90,380^AE^FD' '*' docnum COMPCODE FISCALYR   '*'
*            '^FS^XZ' INTO CIAG.
*        CONDENSE CIAG.
**  NEW-PAGE PRINT OFF.
*
*        move ciag to output_string1.
*
*        data: begin of precom9, "command for  printer language PRESCRIBE
*         con1(59) value
*      '!R!SCF;SCCS;SCU;SCP;FONT62;UNITD;MRP0,-36;BARC21,N,''1234567890''',
*          con3(55) value
*         ',40,40,2,7,7,7,4,9,9,9;MRP0,36;RPP;RPU;RPCS;RPF;EXIT,E;',
*            end of precom9.
*        ...................
*
**replace 123456 of precom9+52(06) with the actual material number..
*        REPLACE '1234567890' in precom9-con1 with C_TELLERNO.
*        .....................
**new-page print off.
*
*        move precom9 to output_string2.
      endif.
*
*  validate bankn
      clear acc_no. data validcurrency type waers.
      select single hkont waers into (acc_no,validcurrency) from T012K where bukrs = comp_code and bankn = bankn.
      if sy-subrc eq 0 and acc_no is not initial.

        if ( VALIDCURRENCY eq CURRENCY ).

        else.
          concatenate 'The transaction currency should be ' VALIDCURRENCY into msg1 SEPARATED BY space .
          error_log_line-ERROR_CODE = '101'.
          error_log_line-ERROR_TITLE = 'Wrong transaction currency'.
          error_log_line-ERROR_MESSAGE = msg1.

          append error_log_line to ERROR_LOG.
        endif.
      else.
*      there is no matching gl account for this house bank number
        concatenate 'There is no corresponding GL Account for house bank account' bankn ' , maintain with transaction FI12 IN SAP SYSTEM' into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'GL Account not found!'.
        error_log_line-ERROR_MESSAGE = msg1.

        append error_log_line to ERROR_LOG.

        clear msg1.
        clear validation_output.

      endif.

*validate customer number
      data valid_customer type kunnr.
      select single kunnr into valid_customer from knb1 where kunnr = cust_number
        and bukrs = comp_code .
      if ( sy-subrc eq 0 and valid_customer is not initial ).

      else.
        concatenate 'Customer ' cust_number ' is not defined in company code' comp_code  into msg1 SEPARATED BY space.
        error_log_line-ERROR_CODE = '101'.
        error_log_line-ERROR_TITLE = 'Customer not defined in company'.
        error_log_line-ERROR_MESSAGE = msg1.

        append error_log_line to ERROR_LOG.

        clear msg1.
        clear validation_output.

      endif.

*validate customer dp payment amount against invoice amount
      amtstring = amount.
      invamtstring = invoice_amount.
      if amount is not initial and invoice_amount is not initial.
        if ( amount eq invoice_amount ).

        else.
          concatenate 'Payment Amount' amtstring ' does not match Invoice amount' invamtstring ', hence this invoices cannot be cleared!' into msg1 SEPARATED BY space.
          error_log_line-ERROR_CODE = '101'.
          error_log_line-ERROR_TITLE = 'Invalid Payment amount for clearing invoice'.
          error_log_line-ERROR_MESSAGE = msg1.

          append error_log_line to ERROR_LOG.

          clear msg1.
          clear validation_output.
        endif.
      endif.

      describe table error_log lines error_size.
      if ( error_size is not initial ).
        clear invoice_amount2.
      endif.
      if ( error_size = 0 ).
        MOVE-CORRESPONDING bank_input to VALIDATION_OUTPUT.
      endif.

    endif.
  else.
    DATA MSG3 TYPE STRING.
    CONCATENATE 'INVALID TOKEN ' ACCESS_TOKEN INTO MSG3 SEPARATED BY space.
    error_log_line-ERROR_CODE = '101'.
    error_log_line-ERROR_TITLE = MSG3.
    error_log_line-ERROR_MESSAGE = 'Invalid token, cannot authenticate user for this call'.

    append error_log_line to error_log.


  endif.




ENDFUNCTION.