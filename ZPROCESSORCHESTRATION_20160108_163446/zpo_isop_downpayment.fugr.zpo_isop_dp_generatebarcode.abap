FUNCTION ZPO_ISOP_DP_GENERATEBARCODE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(STRING) TYPE  STRING
*"  EXPORTING
*"     VALUE(OUTPUT_STRING1) TYPE  STRING
*"     VALUE(OUTPUT_STRING2) TYPE  STRING
*"     VALUE(DOCNUM) TYPE  STRING
*"     VALUE(FISCALYR) TYPE  STRING
*"     VALUE(COMPCODE) TYPE  STRING
*"  TABLES
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE
*"----------------------------------------------------------------------


DATA: CIAG(200) , usr01 like usr01.
data error_line like line of error_log.
*data docnum like bkpf-belnr.
data bkpf_line type bkpf.
data edidc_line type edidc.
data edids_line type edids.
data idocnum type edi_docnum.


data i type i.

select  MAX( belnr )  into docnum  from bkpf where blart = 'DZ' AND GJAHR = '2015'.
  docnum = docnum + 1.

*  wait up to '5' SECONDS.
*  select max( docnum ) into idocnum from edidc where SNDPRN = 'ISOP_E_DP' AND IDOCTP = 'ACC_DOCUMENT03' .
*
*    if (  idocnum is not INITIAL ).
*      select single * into edidc_line from edidc where docnum = idocnum.
*        case edidc_line-status.
*          when '53'.
*            select single * into edids_line from edids where docnum = idocnum and countr = '3' and status = '53'.
*              move edids_line-stapa2+0(10) to docnum.
*              move edids_line-stapa2+10(4) to compcode.
*              move edids_line-stapa2+14(4) to fiscalyr.
*           when others.
*
*          endcase.
*
*      endif.
*  MOVE docnum to string.

*  concatenate 'E_' string into string.

*wait up to 60 SECONDS .
  TRANSLATE string TO UPPER CASE.
*  select single * into bkpf_line from bkpf where blart = 'DZ' and xblnr = string.

    if ( DOCNUM is not initial ).
*        move bkpf_line-belnr  to docnum.
        move sy-datum+0(4) to FISCALYR.
        move '1000' to COMPCODE.

*  order by belnr DESCENDING.
*  i = sy-tabix.
*if ( i = 1 ).
*  add 1 to docnum.
*    move docnum to string.
*
*  endif.
*
*endselect.




  SELECT SINGLE SPLD INTO USR01-SPLD FROM USR01 WHERE BNAME = SY-UNAME.
*  NEW-PAGE PRINT ON DESTINATION USR01-SPLD IMMEDIATELY 'X'
*           COPIES 2.
  CONCATENATE '^XA^LH20,20^FO60,80^B3,,250,N^FD' docnum COMPCODE FISCALYR
              '^FS^FO90,380^AE^FD' '*' docnum COMPCODE FISCALYR   '*'
              '^FS^XZ' INTO CIAG.
  CONDENSE CIAG.
  WRITE: CIAG.
*  NEW-PAGE PRINT OFF.

  move ciag to output_string1.

  data: begin of precom9, "command for  printer language PRESCRIBE
   con1(59) value
'!R!SCF;SCCS;SCU;SCP;FONT62;UNITD;MRP0,-36;BARC21,N,''1234567890''',
    con3(55) value
   ',40,40,2,7,7,7,4,9,9,9;MRP0,36;RPP;RPU;RPCS;RPF;EXIT,E;',
      end of precom9.
...................

*replace 123456 of precom9+52(06) with the actual material number..
REPLACE '1234567890' in precom9-con1 with string.
.....................
*new-page print on.    "barcode printer
Write: 'document number: ', precom9.      "barcode for belnr
*new-page print off.

move precom9 to output_string2.
else.
error_line-ERROR_CODE = '101'.
error_line-ERROR_TITLE = 'Document not posted'.
error_line-ERROR_MESSAGE = 'Document was not posted. Check your log.'.


append error_line to ERROR_Log.
endif.
ENDFUNCTION.