FUNCTION ZPO_BAPI_CREATE_ATC.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(DELIVERY_STATUS) TYPE  STRING OPTIONAL
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
*"     VALUE(TRAN_ID) TYPE  STRING
*"     VALUE(SPLIT_NUM) TYPE  STRING
*"     VALUE(CONCAT_STRING) TYPE  STRING
*"  TABLES
*"      MATERIALS STRUCTURE  ZMATERIALS OPTIONAL
*"      QUANTITIES STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"      PARENT STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      CHILD STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE OPTIONAL
*"      SPLIT_QTY STRUCTURE  ZPO_QUANTITIES OPTIONAL
*"----------------------------------------------------------------------
**"----------------------------------------------------------------------
  DATA USER TYPE USERNAME.
  data: parenttype type string,
        childtype type string,
        salesdocument type BAPIVBELN-VBELN,
        childsalesdocument type BAPIVBELN-VBELN.
  data: ct type i,
        TID TYPE STRING,
        INDEX TYPE STRING,
        doc_item type int1.

  DATA: header type BAPISDHD1,
        item type BAPISDITM,
        partner type BAPIPARNR,
        schedule type BAPISCHDL,
        wa_parent type zpo_atc_docs,
        wa_child type zpo_atc_docs,
        info type string VALUE ''.


  DATA: t_item type STANDARD TABLE OF BAPISDITM with HEADER LINE,
        t_partner type STANDARD TABLE OF BAPIPARNR WITH HEADER LINE,
        t_schedule type STANDARD TABLE OF BAPISCHDL WITH HEADER LINE,
        t_return type STANDARD TABLE OF BAPIRET2 WITH HEADER LINE.

  data mode type c value 'A'.

  data cbn like zpo_users_auth-cbn.
  select single cbn into cbn from zpo_users_auth where access_token = access_token.
  data salesdocparent type vbak-vbeln.
  data purchnoc type string.
  concatenate cbn '_A_' TRANSACTION_ID into purchnoc.
  data material_line like line of MATERIALS.
  data q_line like line of QUANTITIES.
  data: doc_list_line like line of PARENT.


  move TRANSACTION_ID to tran_id.
  perform getUser using access_token user.

  loop at materials into material_line.

  endloop.

  loop at quantities into q_line.

  endloop.

*  Create parent ATC.                                              .
* Adopting earlier implementation change g_e1bpsdhd1 tp header

  if ( DELIVERY_STATUS eq 'D' ).
    header-DOC_TYPE = 'ZDOR'.
    PARENTTYPE = 'ZDOR'.
    header-INCOTERMS1 = 'CFR'.
  else.
    PARENTTYPE = 'ZSOR'.
    header-DOC_TYPE = 'ZSOR'.
    header-INCOTERMS1 = 'EXW'.

  endif.
*header-DOC_TYPE = 'ZDOR'.
  header-SALES_ORG = SALES_ORG.
  header-DISTR_CHAN = '10'.
  header-DIVISION = DIVISION.
  header-SALES_GRP = '100'.
  header-SALES_OFF = '1050'.
  header-REQ_DATE_H = SY-DATUM.
  header-NAME = CUST_NAME.
*header-INCOTERMS1 = 'EXW'.
  header-INCOTERMS2 = PLANT.
  header-PMNTTRMS = 'V001'.
  header-ORD_REASON = '100'.
  header-PURCH_NO_C = PURCHNOC.
  header-SD_DOC_CAT = 'C'.

  header-CREATED_BY =  user.


* fill parent item
  item-ITM_NUMBER = '000010'.
  item-MATERIAL =  MATERIAL_LINE-MATERIAL_NUMBER.
  item-PLANT = PLANT.
  item-TARGET_QTY = Q_LINE-QTY.
*if is_parent = 'X'. " There should be rejection if the split indicator is checked
  item-REASON_REJ = '07'.
*endif.
  append item to t_item.

* fill patner structure. FOR AG

  CLEAR partner.
  partner-PARTN_ROLE = 'AG'.
  partner-PARTN_NUMB = CUST_NUM.
  append partner to t_partner.

* fill partner structure. FOR WE

  CLEAR partner.
  partner-PARTN_ROLE = 'WE'.
  partner-PARTN_NUMB = CUST_NUM.
  partner-CITY = CITY.
  partner-STREET = STREET.
  partner-COUNTRY = COUNTRY.
  partner-NAME = CUST_NAME.
  partner-REGION = REGION.
  append partner to t_partner.

*fill schedule structure

  CLEAR schedule.
  schedule-ITM_NUMBER = '000010'.
  schedule-SCHED_LINE = '0001'.
  schedule-REQ_QTY = q_line-QTY.
  schedule-DLV_DATE = SY-DATUM.
  append schedule to t_schedule.



* AFTER PROCESSING BAPI STRUCTURES, PROCESS THE PARENT AND USE PARENT SALESDOCUMENT NUMBER
* TO PROCESS CHILDREN ATC.
* CONSIDER IF PARENT FAILS AND HANDLE FAILURE ACCORDINGLY.
* If parent fails, do not process child atcs and return error accordinly

  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      ORDER_HEADER_IN       = header
      INT_NUMBER_ASSIGNMENT = 'X'
    IMPORTING
      SALESDOCUMENT         = salesdocument
    TABLES
      RETURN                = t_return
      ORDER_ITEMS_IN        = t_item
      ORDER_PARTNERS        = t_partner
      ORDER_SCHEDULES_IN    = t_schedule.
  "apppend error and exit
  loop at t_return.
    CONCATENATE INFO t_return-message INTO INFO .
  endloop.
  wa_parent-info = info.
  wa_parent-DOC_NUM = SALESDOCUMENT.
  wa_parent-DOC_TYPE = PARENTTYPE.
  APPEND wa_parent to PARENT.

  commit work.
  if salesdocument is initial.
    exit.
  endif.


  data count_material type i.
  data:  pdoc type string,
         cdoc type string.

  describe table materials lines count_material.
  salesdocparent = salesdocument.
  pdoc = SALESDOCPARENT.

  if ( count_material = 1 and is_parent = 'X' ).

    if SALESDOCPARENT is not INITIAL. ""create child.
*  single material.
      loop at materials into material_line.

      endloop.

*  DETERMINE SPLIT
      data loop_qty_m type table of ZPO_QUANTITIES.
      data loop_qty_m_line like line of loop_qty_m.
      data: counter type i,
            TCCOUNT TYPE I VALUE 1.
      perform determine_split tables QUANTITIES  SPLIT_QTY  loop_qty_m using counter split_num.

      DESCRIBE TABLE loop_qty_m lines ct.
      move ct to split_num.

*Create child ATC

*-------------------------*
*-Build child structures -*
*-------------------------*
      loop at loop_qty_m into loop_qty_m_line.

        clear: header, item, partner, schedule.
        clear: t_item, t_partner, t_schedule,
               t_item[], t_partner[], t_schedule[].                                                    .


*Structure header

        clear header.
        if ( DELIVERY_STATUS eq 'D' ).
          header-DOC_TYPE = 'YDOR'.
          childtype = 'YDOR'.
          header-REFDOCTYPE = 'ZDOR'.
          header-INCOTERMS1 = 'CFR'.
        ELSE.
          childtype = 'YSOR'.
          header-DOC_TYPE = 'YSOR'.
          header-REFDOCTYPE = 'ZSOR'.
          header-INCOTERMS1 = 'EXW'.
        ENDIF.

        header-SALES_ORG = SALES_ORG.
        header-DISTR_CHAN = '10'.
        header-DIVISION = DIVISION.
        header-SALES_GRP = '100'.
        header-SALES_OFF = '1050'.
        header-REQ_DATE_H = SY-DATUM.
        header-INCOTERMS2 = PLANT.
        header-PMNTTRMS = 'V001'.
        header-ORD_REASON = '100'.
        header-PURCH_NO_C = purchnoc.
        header-REF_DOC = SALESDOCPARENT.
        header-REFDOC_CAT = 'C'.
        header-CREATED_BY = user.
        header-SD_DOC_CAT = 'C'.



*loop at materials.

*structure item

        clear item.
        item-ITM_NUMBER = '000010'.
        item-MATERIAL = material_line-MATERIAL_NUMBER.
        item-PLANT = plant.
        item-TARGET_QTY = loop_qty_m_line-QTY.
*  item-REASON_REJ = '07'.
        item-REF_DOC = SALESDOCPARENT.
        item-REF_DOC_IT = '000010'.
        item-REF_DOC_CA = 'C'.
        append item to t_item.


* structure partner. FOR AG
        CLEAR partner.
        partner-PARTN_ROLE = 'AG'.
        partner-PARTN_NUMB = CUST_NUM.

        append partner TO t_partner.


* structure partner. FOR WE

        CLEAR partner.
        partner-PARTN_ROLE = 'WE'.
        partner-PARTN_NUMB = CUST_NUM.
        partner-CITY = CITY.
        partner-STREET = STREET.
        partner-COUNTRY = COUNTRY.
        partner-NAME = CUST_NAME.
        partner-REGION = REGION.

        append partner to t_partner.


*Structure Schedule.


        CLEAR schedule.
        schedule-ITM_NUMBER = '000010'.
        schedule-SCHED_LINE = '0001'.
        schedule-REQ_QTY = LOOP_QTY_M_line-QTY.
        schedule-DLV_DATE = SY-DATUM.

        append schedule to t_schedule.



        CLEAR: TID, doc_item.
        TID = 'CHILD '.
        INDEX = TCCOUNT.
        doc_item = tccount.
        CONCATENATE TID  PDOC INDEX INTO TID RESPECTING BLANKS.
*--------------*
*-Create child -*
*--------------*


        CALL FUNCTION 'ZPO_PROC_ATC_WITH_PROXY_RESP'
          STARTING NEW TASK TID
          DESTINATION 'NONE'
          PERFORMING INCREMENT_COUNT ON END OF TASK
          EXPORTING
            TRANSID            = TRANSACTION_ID
            doc_item           = doc_item
            DOC_TYPE           = CHILDTYPE
            ORDER_HEADER_IN    = header
          TABLES
            ORDER_ITEMS_IN     = t_item
            ORDER_PARTNERS     = t_partner
            ORDER_SCHEDULES_IN = t_schedule.
        ADD 1 TO TCCOUNT.
      endloop.

* check no of processed children.
      WAIT UNTIL PROCESSED >= CT.
      PERFORM getDocs USING pdoc CT TRANSACTION_ID CHANGING child[] concat_string.


    endif.


  else.


*prepare bapi structure for post.

    clear: header, item, partner, schedule, info.
    REFRESH: t_item, t_partner, t_schedule.                                                    .


*Structure header

    clear header.
    if ( DELIVERY_STATUS eq 'D' ).
      childtype = 'YDOR'.
      header-DOC_TYPE = 'YDOR'.
      header-REFDOCTYPE = 'ZDOR'.
      header-INCOTERMS1 = 'CFR'.
    ELSE.
      childtype = 'YSOR'.
      header-DOC_TYPE = 'YSOR'.
      header-REFDOCTYPE = 'ZSOR'.
      header-INCOTERMS1 = 'EXW'.
    ENDIF.

    header-SALES_ORG = SALES_ORG.
    header-DISTR_CHAN = '10'.
    header-DIVISION = DIVISION.
    header-SALES_GRP = '100'.
    header-SALES_OFF = '1050'.
    header-REQ_DATE_H = SY-DATUM.
    header-INCOTERMS2 = PLANT.
    header-PMNTTRMS = 'V001'.
    header-ORD_REASON = '100'.
    header-PURCH_NO_C = purchnoc.
    header-REF_DOC = SALESDOCPARENT.
    header-REFDOC_CAT = 'C'.
    header-CREATED_BY = user.
    header-SD_DOC_CAT = 'C'.


*loop at materials.

*structure item

    clear item.
    item-ITM_NUMBER = '000010'.
    item-MATERIAL = material_line-MATERIAL_NUMBER.
    item-PLANT = plant.
    item-TARGET_QTY = Q_LINE-QTY.
*  item-REASON_REJ = '07'.
    item-REF_DOC = SALESDOCPARENT.
    item-REF_DOC_IT = '000010'.
    item-REF_DOC_CA = 'C'.
    append item to t_item.


* structure partner. FOR AG
    CLEAR partner.
    partner-PARTN_ROLE = 'AG'.
    partner-PARTN_NUMB = CUST_NUM.

    append partner TO t_partner.


* structure partner. FOR WE

    CLEAR partner.
    partner-PARTN_ROLE = 'WE'.
    partner-PARTN_NUMB = CUST_NUM.
    partner-CITY = CITY.
    partner-STREET = STREET.
    partner-COUNTRY = COUNTRY.
    partner-NAME = CUST_NAME.
    partner-REGION = REGION.

    append partner to t_partner.


*Structure Schedule.


    CLEAR schedule.
    schedule-ITM_NUMBER = '000010'.
    schedule-SCHED_LINE = '0001'.
    schedule-REQ_QTY = Q_LINE-QTY.
    schedule-DLV_DATE = SY-DATUM.

    append schedule to t_schedule.




*--------------*
*-Create child -*
*--------------*
    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        ORDER_HEADER_IN       = header
        INT_NUMBER_ASSIGNMENT = 'X'
      IMPORTING
        SALESDOCUMENT         = childsalesdocument
      TABLES
        RETURN                = t_return
        ORDER_ITEMS_IN        = t_item
        ORDER_PARTNERS        = t_partner
        ORDER_SCHEDULES_IN    = t_schedule.
    if CHILDSALESDOCUMENT is INITIAL.
      clear t_return.
      wait UP TO 1 SECONDS.
      CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
        EXPORTING
          ORDER_HEADER_IN       = header
          INT_NUMBER_ASSIGNMENT = 'X'
        IMPORTING
          SALESDOCUMENT         = childsalesdocument
        TABLES
          RETURN                = t_return
          ORDER_ITEMS_IN        = t_item
          ORDER_PARTNERS        = t_partner
          ORDER_SCHEDULES_IN    = t_schedule.
      if sy-subrc = 0.
        COMMIT WORK.
      endif.
    endif.
    cdoc = CHILDSALESDOCUMENT.
    loop at t_return.
      CONCATENATE INFO t_return-message INTO INFO.
    endloop.
    wa_child-info = info.
    wa_child-DOC_NUM = CHILDSALESDOCUMENT.
    wa_child-DOC_TYPE = childtype.
    APPEND wa_child to CHILD.
    "concatenate parent and child doc no
    CONCATENATE pdoc '->' cdoc ';' into concat_string.
    commit work.


  endif.
ENDFUNCTION.
form determine_split tables qty STRUCTURE ZPO_QUANTITIES splittable STRUCTURE ZPO_QUANTITIES
   loop_qty STRUCTURE ZPO_QUANTITIES
  using loopsize type i split_num type string.

  data c type i.
  data rem type i.
  data q_index type i.
  data quotient type i.


  data qty_line like line of qty.
  data split_qty_line like line of splittable.
  data loop_qty_line like line of loop_qty.

  data qty_i type i.
  data splitqty_i type i.

  loop at qty into qty_line.
    move qty_line-qty to qty_i.
  endloop.

  describe table splittable lines c.
  if ( c eq 1 ).
    loop at splittable into split_qty_line.
      move split_qty_line-qty to splitqty_i.
    endloop.
    rem = qty_i mod  splitqty_i.
    quotient = qty_i DIV splitqty_i.
    clear: loop_qty_line , loop_qty , loop_qty[].
    if rem ne 0.
      loopsize = quotient + 1.
      q_index = 1.
      while q_index le loopsize .
        if ( q_index eq loopsize ).
          loop_qty_line-qty = rem.
        else.
          loop_qty_line-qty = splitqty_i.
        endif.
        append loop_qty_line to loop_qty.

        add 1 to q_index.
      endwhile.
    else. ""remainder is 0. even share.
      loopsize = quotient.
      q_index = 1.
      while q_index le loopsize.
        loop_qty_line-qty = splitqty_i.

        append loop_qty_line to loop_qty.

        add 1 to q_index.
      endwhile.
    endif.

  endif.

  if ( c > 1 ).
    clear: loop_qty, loop_qty[] , loop_qty_line.

    loop at SPLITTABLE into SPLIT_QTY_LINE.
      move split_qty_line-qty to qty_i.
      move qty_i to loop_qty_line-qty.
      append loop_qty_line to loop_qty.
    endloop.

  endif.

endform.
form getDocs using parent_doc type string count type i trans_id type string CHANGING childtab like itab_child[] cstring type string.
  data: tlen type i VALUE 0,
        wa_itab type zchildatc,
        itab type STANDARD TABLE OF zchildatc WITH HEADER LINE,
        wa_child type ZPO_ATC_DOCS.

  CONCATENATE parent_doc '->' into cstring.
  select * from zchildatc into CORRESPONDING FIELDS OF TABLE itab
    where transid eq trans_id.
  if sy-subrc = 0.
    LOOP AT ITAB INTO WA_ITAB.
      CONCATENATE cstring wa_itab-doc_num ';' into cstring.
      wa_child-DOC_NUM = wa_itab-doc_num.
      wa_child-doc_type = wa_itab-doc_type.
      wa_child-info = wa_itab-message.
      APPEND wa_child TO childtab.
      clear wa_itab.
    ENDLOOP.
    delete zchildatc from table itab.
  endif.
endform.
FORM INCREMENT_COUNT USING TID.
  ADD 1 TO PROCESSED.
ENDFORM.