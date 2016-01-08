FUNCTION ZPO_GENBARCODE_1.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(TRANSACTION) TYPE  STRING OPTIONAL
*"     VALUE(REFERENCE_NO) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(OUTPUTSTRING1) TYPE  STRING
*"  TABLES
*"      DOCUMENTS STRUCTURE  ZPO_ATC_DOCS OPTIONAL
*"      BARCODES STRUCTURE  ZBARCODES OPTIONAL
*"----------------------------------------------------------------------

  DATA: CIAG(400) , usr01 like usr01.
  data docnum like vbak-VBELN.
  data docstring type string.
  data docTEMP type string.
  data l type i.

  data doc_lines like line of DOCUMENTS.
  data ci type i.

*  if transaction is not initial and REFERENCE_NO   is not initial.
*CONCATENATE 'A_' REFERENCE_NO into REFERENCE_NO.
*  select  vbeln  into DOC_LINEs-DOC_NUM  from vbak where bstnk = reference_no and auart in ('YDOR' , 'YSOR') order by vbeln DESCENDING.
*
*
*    append doc_lines to DOCUMENTS.
*
*    add 1 to ci.
*  endselect.
*endif.

  if (  DOCUMENTS is not initial ).
    loop at documents into doc_lines.
      concatenate doc_lines-DOC_NUM ',' into doctemp.
      concatenate docstring doctemp into docstring SEPARATED BY space.
    endloop.

    l = strlen( docstring ).
    subtract 1 from l.
    docstring = docstring+0(l).
  endif.



  SELECT SINGLE SPLD INTO USR01-SPLD FROM USR01 WHERE BNAME = SY-UNAME.
*  NEW-PAGE PRINT ON DESTINATION USR01-SPLD IMMEDIATELY 'X'
*           COPIES 2.
  CONCATENATE '^XA^LH20,20^FO60,80^B3,,250,N^FD' docstring
              '^FS^FO90,380^AE^FD' '*' docstring  '*'
              '^FS^XZ' INTO CIAG.
  CONDENSE CIAG.
  WRITE: CIAG.
*  NEW-PAGE PRINT OFF.

  move ciag to outputstring1.
  MOVE 'ATC created in target system...' to OUTPUTSTRING1.


ENDFUNCTION.