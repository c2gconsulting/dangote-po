
*&---------------------------------------------------------------------*
*& Report  ZPO_DAILY_COL_REPORT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZPO_DAILY_COL_REPORT.
SELECTION-SCREEN BEGIN OF BLOCK 1 with frame.
PARAMETERS: CompCode type bukrs.
Selection-screen end of block 1.
data: gr_table   type ref to cl_salv_table.

*Create Internal table to Store Report Data
TABLES: ZPO_DAILYCOL.

TYPES: BEGIN OF t_record,

USNAM type  BKPF-USNAM,
ATC_WRBTR type BSID-WRBTR,
EWALLET_WRBTR type BSID-WRBTR,
BUKRS type BKPF-BUKRS,
*ZUONR type BSID-ZUONR,

END OF t_record.

DATA: it_record TYPE STANDARD TABLE OF t_record INITIAL SIZE 0 with header line,
      wa_record_sum type t_record,
      wa_col type ZPO_DAILYCOL,
      tb_col type table of ZPO_DAILYCOL,
      lr_aggregations type ref to cl_salv_aggregations,
      wa_record TYPE t_record.


TYPES: BEGIN OF t_report,

USNAM type  BKPF-USNAM,
ATC_WRBTR type BSID-WRBTR,
EWALLET_WRBTR type BSID-WRBTR,
TOTAL_WRBTR type BSID-WRBTR,


END OF t_report.

DATA: it_report TYPE STANDARD TABLE OF t_report INITIAL SIZE 0 with header line,
      wa_report TYPE t_report.

Data: nowYear type BKPF-GJAHR,
      docType type BSID-BLART,
      transType type BKPF-AWTYP,
      txtcompcode type string,
      nowDate type BKPF-BUDAT.

nowYear = SY-DATUM(4).
docType = 'DZ'.
transType = 'BKPFF'.
nowDate = sy-Datum.



DATA: eATC_WRBTR type string,
      eEWALLET_WRBTR type string,
      eUSNAM type string,
      eTOTAL_WRBTR type string.


Select BUTXT into txtcompcode   from T001 client specified where BUKRS = compCode and MANDT = '200'.
  endselect.






clear it_record.
delete from ZPO_DAILYCOL.

    select  SUM( BSID~WRBTR ) as   EWALLET_WRBTR BKPF~USNAM BKPF~BUKRS  into corresponding fields of wa_record from BSID
inner join BKPF on BKPF~BELNR = BSID~BELNR and
BKPF~BUKRS = BSID~BUKRS and
BKPF~BUDAT = BSID~BUDAT Client Specified
where BKPF~MANDT = '200' and  BKPF~GJAHR = nowYear and BSID~BLART = docType and BKPF~BUKRS = COMPCODE
and BKPF~BUDAT = nowDate and BKPF~AWTYP = transType and  BSID~ZUONR like '%/_E/_%'  ESCAPE '/'
and BSID~MANDT = '200'
GROUP BY BKPF~USNAM  BSID~BUKRS  BKPF~WAERS BKPF~BUKRS  .
      append wa_record to it_record.
  endselect.
Clear wa_record.
      select  SUM( BSAD~WRBTR ) as   EWALLET_WRBTR BKPF~USNAM BKPF~BUKRS  into corresponding fields of wa_record from BSAD
inner join BKPF on BKPF~BELNR = BSAD~BELNR and
BKPF~BUKRS = BSAD~BUKRS and
BKPF~BUDAT = BSAD~BUDAT Client Specified
where BKPF~MANDT = '200' and  BKPF~GJAHR = nowYear and BSAD~BLART = docType and BKPF~BUKRS = CompCode
and BKPF~BUDAT = nowDate and BKPF~AWTYP = transType and  BSAD~ZUONR like '%/_E/_%'  ESCAPE '/'
and BSAD~MANDT = '200'
GROUP BY BKPF~USNAM  BSAD~BUKRS  BKPF~WAERS  BKPF~BUKRS.
      append wa_record to it_record.
  endselect.
Clear wa_record.
    select  SUM( BSID~WRBTR ) as   ATC_WRBTR BKPF~USNAM BKPF~BUKRS  into corresponding fields of wa_record from BSID
inner join BKPF on BKPF~BELNR = BSID~BELNR and
BKPF~BUKRS = BSID~BUKRS and
BKPF~BUDAT = BSID~BUDAT Client Specified
where BKPF~MANDT = '200' and  BKPF~GJAHR = nowYear  and BSID~BLART = docType and BKPF~BUKRS = compcode
and BKPF~BUDAT = nowDate and BKPF~AWTYP = transType  and  BSID~ZUONR like '%/_A/_%'  ESCAPE '/'
and BSID~MANDT = '200'
GROUP BY BKPF~USNAM  BSID~BUKRS  BKPF~WAERS  BKPF~BUKRS.
       append wa_record to it_record.
  endselect.

Clear wa_record.

    select  SUM( BSAD~WRBTR ) as   ATC_WRBTR BKPF~USNAM BKPF~BUKRS   into corresponding fields of wa_record from BSAD
inner join BKPF on BKPF~BELNR = BSAD~BELNR and
BKPF~BUKRS = BSAD~BUKRS and
BKPF~BUDAT = BSAD~BUDAT Client Specified
where BKPF~MANDT = '200' and  BKPF~GJAHR = nowYear  and BSAD~BLART = docType and BKPF~BUKRS = compcode
and BKPF~BUDAT = nowDate and BKPF~AWTYP = transType  and  BSAD~ZUONR like '%/_A/_%'  ESCAPE '/'
and BSAD~MANDT = '200'
GROUP BY BKPF~USNAM  BSAD~BUKRS  BKPF~WAERS  BKPF~BUKRS.
       append wa_record to it_record.
  endselect.
  Clear wa_record.




  data id type i.
loop at it_record.

if wa_col is  initial.
              move 1 to id.
            endif.
move id to wa_col-TRANS_ID.
   move it_record-ATC_WRBTR to wa_col-ATC_WRBTR.
   move it_record-BUKRS to wa_col-BUKRS.
   move it_record-EWALLET_WRBTR to wa_col-EWALLET_WRBTR.
   move it_record-USNAM to wa_col-USNAM.
   move sy-datum to wa_col-BUDAT.

   append wa_col to tb_col.
add 1 to id.
   endloop.

data dat_len type i.
describe table tb_col lines dat_len.

 if ( dat_len is not initial ).

*modify ZPO_DAILYCOL from table tb_col.
INSERT ZPO_DAILYCOL
FROM TABLE tb_col ACCEPTING DUPLICATE KEYS .

   if sy-subrc eq 0.
     commit work and wait.
   endif.
 endif.


*  select sum( ATC_WRBTR ) as ATC_WRBTR sum( EWALLET_WRBTR ) as EWALLET_WRBTR
*    USNAM  into corresponding fields of wa_report
*      from ZPO_DAILYCOL group by USNAM.
*    append wa_report to it_report.
*    endselect.
select sum( ATC_WRBTR ) as ATC_WRBTR sum( EWALLET_WRBTR ) as EWALLET_WRBTR
    USNAM  into corresponding fields of wa_report
      from ZPO_DAILYCOL group by USNAM.
append wa_report to it_report.
  endselect.


    loop at it_report.
     compute it_report-TOTAL_WRBTR = it_report-ATC_WRBTR + it_report-EWALLET_WRBTR.
     modify it_report.

endloop.




*    PERFORM displayalv USING it_report[].
    Perform call_alv using it_report[].
    Perform SENDMAIL.





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


form call_alv using table type standard table.

  data: ifc type slis_t_fieldcat_alv.
  data: xfc type slis_fieldcat_alv.
  data: repid type sy-repid.

  repid = sy-repid.

  clear xfc. refresh ifc.


  clear xfc.
  xfc-reptext_ddic = 'Username'.
  xfc-fieldname    = 'USNAM'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

clear xfc.
  xfc-reptext_ddic = 'ATC Amount'.
  xfc-fieldname    = 'ATC_WRBTR'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

       clear xfc.
  xfc-reptext_ddic = 'E Wallet Amount'.
  xfc-fieldname    = 'EWALLET_WRBTR'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

   clear xfc.

  xfc-reptext_ddic = 'Total Amount'.
  xfc-fieldname    = 'TOTAL_WRBTR'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '40'.
  append xfc to ifc.








* Call ABAP List Viewer (ALV)
  call function 'REUSE_ALV_GRID_DISPLAY'
       exporting
            i_callback_program      = repid
            i_callback_user_command = 'HANDLE_USER_COMMAND'
            I_CALLBACK_TOP_OF_PAGE = 'TOP-OF-PAGE' "see FORM
            I_SAVE                 = 'X'
         it_fieldcat             = ifc
       tables
            t_outtab                = table.

endform.

FORM TOP-OF-PAGE.
*ALV Header declarations
DATA: T_HEADER TYPE SLIS_T_LISTHEADER,
WA_HEADER TYPE SLIS_LISTHEADER,
T_LINE LIKE WA_HEADER-INFO,
LD_LINES TYPE I,
LD_LINESC(10) TYPE C.

*TITLE
WA_HEADER-TYP = 'H'.
WA_HEADER-INFO = 'DAILY COLLECTIONS REPORT'.
APPEND WA_HEADER TO T_HEADER.
CLEAR WA_HEADER.

*COMPANY CODE
WA_HEADER-TYP = 'S'.
WA_HEADER-KEY = 'Company Code: '.
 WA_HEADER-INFO = compCode. "todays date
APPEND WA_HEADER TO T_HEADER.
CLEAR: WA_HEADER.



*DATE
WA_HEADER-TYP = 'S'.
WA_HEADER-KEY = 'Date: '.
CONCATENATE SY-DATUM+6(2) '.'
SY-DATUM+4(2) '.'
SY-DATUM(4)   INTO WA_HEADER-INFO. "todays date
APPEND WA_HEADER TO T_HEADER.
CLEAR: WA_HEADER.

**TOTAL NO. OF RECORDS SELECTED
*DESCRIBE TABLE it_report[] LINES LD_LINES.
*LD_LINESC = LD_LINES.
*CONCATENATE 'Total No. of Records Selected: ' LD_LINESC
*INTO T_LINE SEPARATED BY SPACE.
*WA_HEADER-TYP = 'A'.
*WA_HEADER-INFO = T_LINE.
*APPEND WA_HEADER TO T_HEADER.
*CLEAR: WA_HEADER, T_LINE.



CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
  EXPORTING
    IT_LIST_COMMENTARY = T_HEADER.
ENDFORM.                    "APPLICATION_SERVER



FORM SENDMAIL  .
  DATA: send_request       TYPE REF TO cl_bcs.
 DATA: document           TYPE REF TO cl_document_bcs.
 DATA: sender             TYPE REF TO cl_sapuser_bcs.
 DATA: recipient          TYPE REF TO if_recipient_bcs.
 DATA: exception_info     TYPE REF TO if_os_exception_info,
 bcs_exception      TYPE REF TO cx_bcs,
 v_subj(50),
 t_hex TYPE solix_tab,
 html_string TYPE string,
 xhtml_string TYPE xstring,
 v_message(100),
 v_mail TYPE  sza5_d0700-smtp_addr.
 v_subj = 'Dangote Daily Collections Report'.
Data: ATC_AMOUNT(20) type c,
      EWALLET_AMOUNT(20) type c,
      TOTAL_AMOUNT(20) type c.
 CONCATENATE '<html><head><title>End of Day Reconciliation Report</title><style type="text/css">body{ width: 100%; background-color: #e8e8e8; margin:0; padding:0; -webkit-font-smoothing: antialiased; mso-margin-top-alt:0px; mso-margin-bottom-alt:0px;'
'mso-padding-alt: 0px 0px 0px 0px;}'
 'p,h1,h2,h3,h4{ margin-top:0;margin-bottom:0;padding-top:0;padding-bottom:0;}'
 'span.preheader{display: none; font-size: 1px;}'
 ' html{width: 100%;} table{font-size: 14px;border: 0;}'
 '@media only screen and (max-width: 640px){body[yahoo] .show{display: block !important;} body[yahoo] .hide{display: none !important;}'
 'body[yahoo] .main-image img{width: 440px !important; height: auto !important;}'
 'body[yahoo] .divider img{width: 440px !important;}'
 'body[yahoo] .banner img{width: 440px !important; height: auto !important;}'
 'body[yahoo] .container590{width: 440px !important;}'
 'body[yahoo] .container580{width: 400px !important;}'
 'body[yahoo] .container1{width: 420px !important;}'
 'body[yahoo] .container2{width: 400px !important;}'
 'body[yahoo] .container3{width: 380px !important;}'
 'body[yahoo] .section-item{width: 440px !important;}'
 'body[yahoo] .section-img img{width: 440px !important; height: auto !important;}}'
 '@media only screen and (max-width: 479px){'
 'body[yahoo] .main-header{font-size: 24px !important;}'
 'body[yahoo] .resize-text{font-size: 14px !important;}'
 'body[yahoo] .main-image img{width: 280px !important; height: auto !important;}'
 'body[yahoo] .divider img{width: 280px !important;}'
'body[yahoo] .align-center{text-align: center !important;}'
'body[yahoo] .container590{width: 280px !important;}'
'body[yahoo] .container580{width: 250px !important;}'
'body[yahoo] .container1{width: 260px !important;}'
'body[yahoo] .container2{width: 240px !important;}'
'body[yahoo] .container3{width: 220px !important;}'
'body[yahoo] .cta-button{width: 200px !important;}'
'body[yahoo] .cta-text{font-size: 14px !important;}} </style></head>'
'<body yahoo="fix" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0"><table border="0" width="100%" cellpadding="0" cellspacing="0" bgcolor="e8e8e8">'
'<tr><td height="100" style="font-size: 100px; line-height: 100px;">&nbsp;</td></tr>'
'<tr><td><table border="0" align="center" width="590" cellpadding="0" cellspacing="0" bgcolor="ffffff" class="container590 bodybg_color" style="border: solid 1px #d5d5d5;">'
'<tr><td><table border="0" align="center" width="480" cellpadding="0" cellspacing="0" class="container590 bodybg_color">'
'<tr><td height="50" style="font-size: 50px; line-height: 50px;">&nbsp;</td></tr>'
'<tr><td><table border="0" align="left" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
'<tr><td align="center"><div style="line-height: 24px;"><h2> DAILY COLLECTIONS REPORT -' nowDate '</h2></div></td></tr></table>'
'<table border="0" align="left" width="5" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
'</table>'
'<table border="0" align="right" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'

'<tr><td align="left" style="color: #222222; font-size: 20px; font-family: "Montserrat", sans-serif; font-weight: 700; mso-line-height-rule: exactly; line-height: 24px;" class="title_color main-header">'
'</td></tr></table>	</td></tr><tr><td height="40" style="font-size: 40px; line-height: 40px;">&nbsp;</td></tr>'
'<tr><td><table align="center" width="250" border="0" cellpadding="0" cellspacing="0" bgcolor="ededed"><tr><td height="1" style="font-size: 1px; line-height: 1px;">&nbsp;</td></tr>'
'</table> </td></tr>  <tr><td height="40" style="font-size: 40px; line-height: 40px;">&nbsp;</td></tr>'
'<tr> <td>  <table border="0" width="5" align="left" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
  '<tr><td width="5" height="30" style="font-size: 30px; line-height: 30px;">&nbsp;</td></tr></table>'
  '<table border="0" width="250" align="right" cellpadding="0" cellspacing="0" bgcolor="39b8d3" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="section-item">'
'<tr><td><table border="0" width="220" align="center" cellpadding="0" cellspacing="0" bgcolor="39b8d3" class="section-item">'
'<tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr>	<tr>'
'<td align="left" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;"> Company Code  </div>  </td> <td align="center" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;">'  txtcompcode '</div>  </td></tr><tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr>'
'</table>	</td>	</tr><tr><td colspan="2"><table align="center" width="250" border="0" cellpadding="0" cellspacing="0" bgcolor="84d3e4">'
'<tr><td height="1" style="font-size: 1px; line-height: 1px;">&nbsp;</td></tr>  </table>'
'</td>  </tr><tr><td><table border="0" width="220" align="center" cellpadding="0" cellspacing="0" bgcolor="39b8d3" class="section-item">'
'<tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr><tr>'
'<td align="left" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;">Currency	</div></td><td align="center" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;"> NGN</div></td></tr>'
'<tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr>	</table></td>	</tr></table>'
'</td></tr><tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr>'
'<tr> <td>   <table border="0" width="480" align="0" cellpadding="0" cellspacing="0" bgcolor="e8e8e8">'
'<tr bgcolor="39b8d3">  <td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Bank Name  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Ewallet Amount	</td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'ATC Amount	</td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px;">'
'Total Amount	</td></tr>'

INTO html_string .



 LOOP AT it_report .  "some html data
   move it_report-ATC_WRBTR to ATC_AMOUNT.
   move it_report-EWALLET_WRBTR  to EWALLET_AMOUNT.
   move it_report-TOTAL_WRBTR to TOTAL_AMOUNT.

******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report-ATC_WRBTR
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = ATC_AMOUNT
.
CONDENSE ATC_AMOUNT.
**********************************************

******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report-EWALLET_WRBTR
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = EWALLET_AMOUNT
.
CONDENSE EWALLET_AMOUNT.
**********************************************


******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report-TOTAL_WRBTR
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = TOTAL_AMOUNT
.
CONDENSE TOTAL_AMOUNT.
**********************************************



 CONCATENATE html_string    '<tr> <td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          it_report-USNAM
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                           EWALLET_AMOUNT
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          ATC_AMOUNT
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          TOTAL_AMOUNT
                        '</td></tr>'

  INTO html_string.

 ENDLOOP.


 CONCATENATE html_string '</table></td></tr><tr><td height="50" style="font-size: 50px; line-height: 50px;">&nbsp;</td></tr>'
                '<tr><td colspan="2"><table align="center" width="250" border="0" cellpadding="0" cellspacing="0" bgcolor="ededed">'
                '<tr><td height="1" style="font-size: 1px; line-height: 1px;">&nbsp;</td></tr></table></td></tr>'
                  '<tr><td height="30" style="font-size: 30px; line-height: 30px;">&nbsp;</td></tr><tr>'
                  '<td><table border="0" align="center" width="480" cellpadding="0" cellspacing="0" class="container590 bodybg_color">'
                  '<tr><td><table border="0" align="left" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
                  '<tr><td align="center" class="copyright" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; line-height: 22px;">'
                  '<div style=" line-height: 22px;"> © 2015 Daily Collections Report.</div></td></tr></table>'
                  '<table border="0" align="left" width="5" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
                  '<tr><td height="20" width="5" style="font-size: 20px; line-height: 20px;">&nbsp;</td></tr>'
                  '</table><table border="0" align="right" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
                    '<tr><td align="center" class="footer-nav" style="color: #8e8e8e; font-size: 14px; font-family: "Montserrat", sans-serif; line-height: 22px;">'
                   '<a href="" style="color: #686b74; text-decoration: none;">Unsubscribe</a></td></tr> </table>'
                  '</td></tr></table></td></tr> </table></td></tr><tr><td height="30" style="font-size: 30px; line-height: 30px;">&nbsp;</td></tr>'
          '</table></td></tr><tr><td height="50" style="font-size: 50px; line-height: 50px;">&nbsp;</td></tr>'
    '</table></body></html>' INTO html_string.

TRY.

 send_request = cl_bcs=>create_persistent( ).

 CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
 EXPORTING
 text           = html_string


 IMPORTING
 buffer         = xhtml_string
 EXCEPTIONS
 failed         = 1
 OTHERS         = 2.

 CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
 EXPORTING
 buffer                = xhtml_string


 TABLES
 binary_tab            = t_hex.

 document = cl_document_bcs=>create_document(
 i_type    = 'HTM'
 i_hex    = t_hex
 i_subject = v_subj ).


 CALL METHOD send_request->set_document( document ).


 sender = cl_sapuser_bcs=>create( sy-uname ).


 CALL METHOD send_request->set_sender
 EXPORTING
 i_sender = sender.

 v_mail = 'obalogun@c2gconsulting.com'.

 recipient = cl_cam_address_bcs=>create_internet_address( v_mail ).

 CALL METHOD send_request->add_recipient
 EXPORTING
 i_recipient = recipient.


 DATA: status_mail TYPE bcs_stml.
 status_mail = 'N'.
 CALL METHOD send_request->set_status_attributes
 EXPORTING
 i_requested_status = status_mail
 i_status_mail      = status_mail.


 send_request->set_send_immediately( 'X' ).


 CALL METHOD send_request->send( ).

 COMMIT WORK.

 CATCH cx_bcs INTO bcs_exception.
 v_message = bcs_exception->get_text( ).
 MESSAGE e000(su) WITH v_message.
 ENDTRY.
  endform.