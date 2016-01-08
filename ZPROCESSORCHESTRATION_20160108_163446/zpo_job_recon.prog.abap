*&---------------------------------------------------------------------*
*& Report  ZPO_JOB_RECON
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZPO_JOB_RECON.


PARAMETERS:
bankname type ZPO_USERS_AUTH-USERNAME,
country type string,
validch type string.







************************************************************
** Declare Internal Table and Work Area  for Data Retrival
*DATA: it_recon TYPE STANDARD TABLE OF zsd_isop_recon INITIAL SIZE 0,
*      wa_recon TYPE zsd_isop_recon.
***********************************************************

*DATA: ld_file LIKE rlgrap-filename.
DATA: gd_file type salfile-longname.

data: gr_table   type ref to cl_salv_table.
data: p_file type localfile,
      lnNumber type string,
      custName type string,
      lnTxt type string.
TABLES: ZSD_ISOP_RECON,
        T012K.


*Internal tabe to store upload data
TYPES: BEGIN OF t_record,

itemNumber type string,
itemTxt type  string,
    END OF t_record.
DATA: it_record TYPE STANDARD TABLE OF t_record INITIAL SIZE 0,
      wa_record TYPE t_record.

*Internal table to upload data into
DATA: BEGIN OF it_datatab OCCURS 0,
  row(500) TYPE c,
 END OF it_datatab.

data: begin of itab occurs 0,
     rec(1000) type c,
     end of itab.
data: wa(1000) type c.


data: ifile type table of  salfldir with header line.
data:
      text type string,
      customer type string.



DATA: wa_string(255) type c.

*internal table for zpo_isop_recon
data: tb_isop type table of zsd_isop_recon,
      wa_isop type zsd_isop_recon,
      wa_isop2 type zsd_isop_recon,
      bankAccount type string,
      compCode type bukrs,
      fileDate like sy-datum.




data credval type p decimals 2.
data credString type string.

CONSTANTS: con_tab TYPE x VALUE '09'.

*
START-OF-SELECTION.

  "Declare the file path my Concatenating the default file path
  "with the country and the bank user name
  gd_file = '/usr/sap/trans/ISOP/IN/'.
  concatenate gd_file  country '/' bankname into gd_file.



  "Read the all files from the folder

  CALL FUNCTION 'RZL_READ_DIR_LOCAL'
    EXPORTING
      name           = gd_file
    TABLES
      file_tbl       = ifile
    EXCEPTIONS
      argument_error = 1
      not_found      = 2
      others         = 3.

  "Loop at the output to get file for yesterday
  loop at ifile.
    concatenate gd_file '/' ifile-name into p_file.


    if strlen( ifile-name ) < 5.

    else.

      split ifile-name at '_'  into   bankAccount fileDate.
      data todaysDate type sy-datum.
      todaysDate = sy-Datum.
      SUBTRACT 1 from TODAYSDATE.
      TODAYSDATE = '20151104'.


      if fileDate = todaysDate .
        "get the company code by Bankaccount number
        CONDENSE bankAccount NO-GAPS.

        select single bukrs into compCode from T012K client specified where BANKN = bankAccount.


        " Upload  the file

        OPEN DATASET p_file FOR INPUT IN TEXT MODE ENCODING DEFAULT.
        IF sy-subrc NE 0.

        ELSE.
          DO.
            READ DATASET p_file INTO wa_string.

            IF sy-subrc NE 0.
              EXIT.
            ELSE.
*            remove leading blank spaces
              condense wa_string NO-GAPS.

              concatenate '0123456789' sy-abcde into validch.

*            IF WA_STRING+0(1) eq ':'.
              data fc type string. "first character of string line
              move wa_string+0(1) to fc.
              IF not ( fc co validch ) .
                shift wa_string LEFT DELETING LEADING fc.
              endif.

              split wa_string  at ':'  into   lnNumber lnTxt.

              move lnNumber to WA_RECORD-ITEMNUMBER.
              move lnTxt to WA_RECORD-ITEMTXT.

              append wa_record to it_record.


            endif.
          ENDDO.

        ENDIF.

      ENDIF.
      perform Read_MT940_Generic tables it_record.


    endif.
  endloop.





************************************************************************
*END-OF-SELECTION
END-OF-SELECTION.



*display table in alv

  " perform recon_mani tables it_record.

form Read_MT940_Generic tables table type STANDARD TABLE .
  delete from zsd_isop_recon.

  data it_line like line of it_record.

  data id type i.


  select * from zsd_isop_recon into wa_isop.

  ENDSELECT.
  if wa_isop is not initial.
    select count( distinct trans_id ) into id from zsd_isop_recon.
  else.
    move 1 to id.
  endif.
  clear tb_isop.

  data: i1 type i , i2 type i , i3 type i, l type i,amtholder type string, amtNum type float,amtholder2 type string,lcount type i,
         i4 type i,i5 type i,itmlenght type i, sixtyonechecker type i .

  loop at table into it_line.
    if it_line-ITEMNUMBER = '61' or it_line-ITEMNUMBER = '86'.

      case it_line-ITEMNUMBER.
        when '61'.
          if it_line-ITEMTXT+6(1)  = 'C' or it_line-ITEMTXT+10(1) = 'C'.


            move id to wa_isop-TRANS_ID.





            clear i1.
            clear i2.
            clear i3.
            clear l.
            clear i4.
            clear i5.
            clear itmlenght.
            clear amtholder.
            clear amtholder2.
            clear amtNum.
            clear sixtyonechecker.
            move it_line-ITEMTXT+0(6) to wa_isop-TRANS_DATE.
            concatenate '20' wa_isop-TRANS_DATE into wa_isop-TRANS_DATE.

            data : fiscyear type string,
                  period type string,
                  transdate type string.

            move wa_isop-TRANS_DATE to transdate.

            move transdate+0(4) to fiscyear.
            move transdate+4(2) to period.


            find FIRST OCCURRENCE OF 'CN' IN it_line-itemtxt match offset i1.
            if i1 <= 0.
              find FIRST OCCURRENCE OF 'C' IN it_line-itemtxt match offset i1.
              i3 = i1 + 1.
            else.
              i1 = i1 + 1.
              i3 = i1 + 1.
            endif.

            itmlenght = strlen( it_line-itemtxt ).
*          if sy-subrc = 0.
*
*          i1 = sy-fdpos + 1. "index of C
*endif.


* Look for Comma in the string to get amount with Decimal Number and
* When you get that amount with Decimal Number do your transform
            find first occurrence of ',' in it_line-itemtxt match offset i2.
* If the Amount does not have a Comma
            if i2 <= 0.

              i4 = i3 + 11.
              if i4 > itmlenght.
                i5 = itmlenght - i3.
              else.
                i5 = 11.
              endif.
              move it_line-itemtxt+i3(i5) to amtholder.
              lCount = strlen( amtholder ).
********************************************************************************

* The Variable amtholder now contains the amount and some string
* So we have to loop and remove all Non Numberic
              DO lCount  TIMES.
                IF amtholder(1) CA '0123456789'.
                  CONCATENATE amtholder2 amtholder(1) INTO amtholder2.
                  CONDENSE amtholder2 NO-GAPS.
                ENDIF.
                SHIFT amtholder LEFT CIRCULAR.
              ENDDO.

              amtnum = amtholder2 * 1.
***************************************************************************
* Now if the amount does have a comma we need to find out if it is a one
* Decimal Amount or a 2 Decimal Amount
            else.
              i2 = i2 + 1.
              move it_line-itemtxt+i2(1) to fc.
              IF not ( fc co validch ) .
                i2 = i2 .
              else.
                i2 = i2 + 1.
              endif.
              l = i2 - i1.
              i4 = i3 + l.
              if i4 > itmlenght.
                l = itmlenght - i3.
              else.
                l = l.
              endif.
              move it_line-itemtxt+i3(l) to amtholder.
              replace all occurrences of ',' in amtholder with '.'.
              AMTNUM = AMTHOLDER * 1.
            endif.


*          if sy-subrc = 0
*          i2 = sy-fdpos - 1. "index of NTFR



            move amtnum to wa_isop-credit_value.
            move sy-uzeit to wa_isop-TIMESTAMP.
            move BANKNAME to wa_isop-BANK_CODE.
            sixtyonechecker = 1 .
          endif.


        when '86'.
          clear CUSTNAME.
          if sixtyonechecker = 1.

            if wa_isop is initial.

            else.

              if strlen( it_line-itemtxt ) > 7.


                split it_line-itemtxt at '-' into TEXT customer.


                CONDENSE customer NO-GAPS.
                if strlen( customer ) gt 6.
                  select NAME1 into CUSTNAME from kna1 client specified where kunnr = customer and mandt = '200'.
                  endselect.
                  if CUSTNAME is initial.
                   CUSTNAME = 'CUSTOMER NOT FOUND'.
                   endif.

                    move customer to wa_isop-CUST_CODE.
                    move TEXT to wa_isop-NARRATION.
                    move CUSTNAME to wa_isop-UNIQUEREF.
                    "Query the Table to get data
                    data: Amount1 like bsad-wrbtr,
                          Amount2 like bsid-wrbtr.
                    Clear Amount1.
                    Clear Amount2.


                    select  SUM( BSAD~WRBTR )  into Amount1  from BSAD
                   inner join BKPF  on BKPF~BELNR = BSAD~BELNR and
                   BKPF~BUKRS = BSAD~BUKRS and
                   BKPF~BUDAT = BSAD~BUDAT CLIENT SPECIFIED
                   where BKPF~MANDT = '200' and BKPF~GJAHR = fiscyear and BSAD~KUNNR = CUSTOMER and BSAD~BLART = 'DZ' and BSAD~MONAT = period
                   and BKPF~BUDAT = transdate and BKPF~USNAM = bankname .



                    select  SUM( BSID~WRBTR )  into Amount2  from BSID
                   inner join BKPF on BKPF~BELNR = BSID~BELNR and
                   BKPF~BUKRS = BSID~BUKRS and
                   BKPF~BUDAT = BSID~BUDAT CLIENT SPECIFIED
                   where BKPF~MANDT = '200' and BKPF~GJAHR = fiscyear and BSID~KUNNR = customer and BSID~BLART = 'DZ' and BSID~MONAT = period
                   and BKPF~BUDAT = transdate and BKPF~USNAM = bankname.

                    Add Amount1 to Amount2.

                    move Amount2 to wa_isop-SAP_AMOUNT.

                    move compCode to wa_isop-COMP_CODE.
                    move ifile-NAME to wa_isop-SOURCE_FILENAME.



                    data i_index type sy-tabix.
                    CLEAR wa_isop2.
                    loop at tb_isop into wa_isop2 where cust_code = wa_isop-CUST_CODE.
                      i_index = sy-tabix.
                      add wa_isop-CREDIT_VALUE to wa_isop2-CREDIT_VALUE.
                      exit.
                    endloop.
                    if wa_isop2 is not initial .
                      modify tb_isop from wa_isop2 index i_index.
                    else.
                      append wa_isop to tb_isop.
                    endif.


                    add 1 to id.
                    clear sixtyonechecker.
                  endif.


              endif.

***********
            endif.
          endif.
      ENDCASE.

    endif.


  ENDLOOP.

  data dat_len type i.
  describe table tb_isop lines dat_len.

  if ( dat_len is not initial ).
    modify zsd_isop_recon from table tb_isop.

    if sy-subrc eq 0.
      commit work and wait.
    endif.
  endif.






  " PERFORM displayalv USING it_report[].

*********************************************************


endform.

form displayalv using table type standard table.

  try.
      cl_salv_table=>factory(
        importing
          r_salv_table = gr_table
        changing
          t_table      = table ).
    catch cx_salv_msg.                                  "#EC NO_HANDLER
  endtry.
  gr_table->display( ).
endform.