FUNCTION ZPO_GET_PRICE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(DELIVERY_STAT) TYPE  STRING OPTIONAL
*"     VALUE(TRANSACTION_ID) TYPE  STRING OPTIONAL
*"     VALUE(SALES_ORG) TYPE  VKORG OPTIONAL
*"     VALUE(DIVISION) TYPE  SPART OPTIONAL
*"     VALUE(PLANT) TYPE  WERKS_D OPTIONAL
*"     VALUE(CUST_NUM) TYPE  KUNNR OPTIONAL
*"     VALUE(CITY) TYPE  STRING OPTIONAL
*"     VALUE(STREET) TYPE  STRING OPTIONAL
*"     VALUE(COUNTRY) TYPE  STRING OPTIONAL
*"     VALUE(CUST_NAME) TYPE  STRING OPTIONAL
*"     VALUE(REGION) TYPE  REGIO OPTIONAL
*"     VALUE(IS_PARENT) TYPE  BOOLEAN OPTIONAL
*"     VALUE(REF_DOC_NO) TYPE  VBELN_VA OPTIONAL
*"     VALUE(ACCESS_TOKEN) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(BASE_PRICE) TYPE  KZWI1BAPI
*"     VALUE(DELIVERY_PRICE) TYPE  KZWI4BAPI
*"  TABLES
*"      MATERIALS STRUCTURE  ZMATERIALS OPTIONAL
*"      QUANTITIES STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"----------------------------------------------------------------------

  data error_line like line of error_log.
  data err_l type i.
  data mat_l type i.
  data quan_l type i.
  data user type username.
   data:
        material_lne like line of materials,
        qty_lne like line of quantities,
        qty_type type boolean.
* CHECK to ensure that these fields are provided


  perform getUser using access_token user.

  if user is not initial and access_token is not initial.


  if ( delivery_stat is initial or delivery_stat eq '?' ).
    perform displayerror tables error_log using 'No Delivery status' 'Please provide delivery status ( D - Delivery collection or S - Self collection )'.
  endif.
  if ( transaction_id is initial or transaction_id eq '?' ).
    perform displayerror tables  error_log using 'No transaction id' 'Provide a transaction id for transaction'.
  endif.
  if ( sales_org is initial or sales_org eq '?' ) .
    perform displayerror tables  error_log using 'No Sales org' 'Provide a sales org for transaction'.
    endif.
    if ( division is initial or division eq '?' ) .
    perform displayerror tables  error_log using 'No division' 'Provide a division for transaction'.
    endif.
    if ( plant is initial or plant eq '?' ).
    perform displayerror tables  error_log using 'No Plant' 'Provide a plant for transaction'.
    endif.
  if ( CUST_NUM is initial or cust_num eq  '?' ) .
    perform displayerror tables  error_log using 'No Customer number' 'Provide a Customer number for transaction'.
    endif.
    if ( region is initial or region eq  '?' ) .
    perform displayerror tables  error_log using 'No Region' 'Provide a Region for transaction'.
    endif.

    describe table materials lines mat_l.
    describe table quantities lines quan_l.

    if ( mat_l is initial  ).
        perform displayerror tables error_log using 'No Materials' 'Provide materials for transaction'.
        else.
          loop at materials into material_lne.
              if ( material_lne-material_number is initial or material_lne-MATERIAL_NUMBER eq '?' ).
                  perform displayerror tables error_log using 'Invalid material number' 'Provide a valid material number'.


                endif.
            endloop.
      endif.
      if quan_l is initial .
          perform displayerror tables error_log using 'No Quantities' 'Provide quantities for materials'.
          else.

            data str_qty type string.
            data strqty type string.

            loop at quantities into qty_lne.
              move qty_lne-qty to strqty.

                if ( STRQTY is initial or strqty cs '?' ).
                    perform displayerror tables error_log using 'Invalid quantity' 'Provide a quantity!'.
                  endif.

              endloop.
        endif.

        if mat_l is not initial and ( mat_l eq quan_l ).

            else.
              perform displayerror tables error_log using 'Invalid Quantity for material'
                     'Ensure the number of quantities matches with the number of materials and in same order!'.

          endif.



    describe table error_log lines err_l.

if err_l is initial.
*perform POST_ATC_IDOC.

  data: orderhead type table of BAPISDHEAD,
        orderline like line of orderhead,
        orderitemsin type table of BAPIITEMIN,
        orderpartner type table of BAPIPARTNR,
        orderitemsout type table of BAPIITEMEX,
        orderitemsline like line of orderitemsin,
        orderitemsexline like line of orderitemsout,
        orderpartnerline like line of orderpartner,
        materials_line like line of materials,
        quantities_line like line of QUANTITIES,
        qty_line like line of QUANTITIES.

  data:
        SALESDOCUMENT LIKE  BAPIVBELN-VBELN,
        SOLD_TO_PARTY LIKE  BAPISOLDTO,
        SHIP_TO_PARTY LIKE  BAPISHIPTO,
        BILLING_PARTY LIKE  BAPIPAYER,
        RETURN  LIKE  BAPIRETURN.


*prepare the header
  if ( DELIVERY_STAT = 'D' ).
    move 'ZDOR' to orderline-doc_type.
    MOVE 'CFR' TO orderline-INCOTERMS1.
  elseif ( DELIVERY_STAT = 'S' ).
    move 'ZSOR' to orderline-doc_type.
    MOVE 'EXW' TO orderline-INCOTERMS1.
  ENDIF.

  move SALES_ORG to orderline-sales_org.
  move '10' to orderline-DISTR_CHAN.
  move division to orderline-DIVISION.
  move '100' to orderline-SALES_GRP.
  move '1050' to orderline-sales_off.
  move sy-datum to orderline-REQ_DATE_H.
  move 'V001' to orderline-PMNTTRMS.
  move PLANT to orderline-INCOTERMS2.
  move '100' to orderline-ORD_REASON.

  data purch_ord_num type string.
  concatenate 'A_' TRANSACTION_ID into purch_ord_num.
  move purch_ord_num to orderline-PURCH_NO_C.


  append orderline to ORDERHEAD.

  data no_o_mat type i.
  describe table MATERIALS lines no_o_mat.

  data count type i value 0.
  data l_tabix type sy-tabix.


  while count   <  no_o_mat.
    add 1 to count.
    l_tabix = count.
    orderitemsline-ITM_NUMBER = count * 10.

    read  table materials INDEX l_tabix into materials_line.
    move materials_line-MATERIAL_NUMBER to orderitemsline-MATERIAL.
    move plant to orderitemsline-PLANT.

    read  table quantities INDEX l_tabix into QUANTITIES_LINE.
    move    QUANTITIES_line-QTY   to orderitemsline-TARGET_QTY  .
    MULTIPLY orderitemsline-TARGET_QTY by 1000.

    MOVE QUANTITIES_line-QTY to orderitemsline-REQ_QTY.
    MULTIPLY orderitemsline-REQ_qty by 1000.
*    add reason for rejection if there is split quantity.

    append orderitemsline to ORDERITEMSIN.

  endwhile.

  orderpartnerline-PARTN_ROLE = 'AG'.
  orderpartnerline-PARTN_NUMB = CUST_NUM.

  append orderpartnerline to orderpartner.

  orderpartnerline-partn_role = 'WE'.
  orderpartnerline-partn_numb = cust_num.
  orderpartnerline-NAME = cust_name.
  orderpartnerline-CITY = CITY.
  orderpartnerline-street = street.
  orderpartnerline-country = country.
  orderpartnerline-REGION = REGION.


  append orderpartnerline to orderpartner.

  CALL FUNCTION 'BAPI_SALESORDER_SIMULATE'
    EXPORTING
      ORDER_HEADER_IN     = orderline
*     CONVERT_PARVW_AUART = ' '
    IMPORTING
      SALESDOCUMENT       = salesdocument
      SOLD_TO_PARTY       = sold_to_party
      SHIP_TO_PARTY       = ship_to_party
      BILLING_PARTY       = billing_party
      RETURN              = return
    TABLES
      ORDER_ITEMS_IN      = orderitemsin
      ORDER_PARTNERS      = orderpartner
*     ORDER_SCHEDULE_IN   =
      ORDER_ITEMS_OUT     = orderitemsout
*     ORDER_CFGS_REF      =
*     ORDER_CFGS_INST     =
*     ORDER_CFGS_PART_OF  =
*     ORDER_CFGS_VALUE    =
*     ORDER_CFGS_BLOB     =
*     ORDER_CCARD         =
*     ORDER_CCARD_EX      =
*     ORDER_SCHEDULE_EX   =
*     ORDER_CONDITION_EX  =
*     ORDER_INCOMPLETE    =
*     MESSAGETABLE        =
*     EXTENSIONIN         =
*     PARTNERADDRESSES    =
    .

  loop at orderitemsout into ORDERITEMSEXLINE.
*    divide orderitemsexline-subtotal1 by 100.
    add ORDERITEMSEXLINE-SUBTOTAL1 to base_price.

*    divide orderitemsexline-subtotal4 by 100.
    add orderitemsexline-subtotal4 to delivery_price.
  endloop.
*  base_price = '800.00'.
*  delivery_price = '70.00'.

  if return is not initial.
    error_line-ERROR_CODE = return-CODE.
    error_line-ERROR_TITLE = return-MESSAGE.
    concatenate return-message ',' return-MESSAGE_V1 ','
    return-MESSAGE_V2 ',' return-MESSAGE_V3 ',' return-MESSAGE_V4
    into error_line-ERROR_MESSAGE SEPARATED BY space.

    APPEND error_line to error_log.




  endif.

  endif.
  else.

    perform displayerror tables error_log using 'Invalid token' 'Invalid token entered....' .
    endif.
ENDFUNCTION.

form displayerror tables error_log STRUCTURE zerror_type using title type string message type string .
  data error_line like line of error_log.
  error_line-ERROR_CODE = '101'.
  error_line-ERROR_TITLE = title.
  error_line-error_message = message.

  append error_line to error_log.
endform.
form isQtyNumber using qty type string matched type boolean.
    data match type REF TO cl_abap_matcher.
    data c type i.
*
*    match = cl_abap_matcher=>create(
*          pattern = `([1-9][0-9]*[.][0-9]*)`
*          text = qty
*          ).
*
*    matched = match->match( ).
*
    FIND FIRST OCCURRENCE OF REGEX `^[1-9][0-9]*.[0-9][0-9]$` IN QTY match COUNT  c .

    if c > 0 .
      matched = abap_true.
      else.
        matched = abap_false.
      endif.

  endform.