*&---------------------------------------------------------------------*
*& Report  ZPO_CUST_REC_REPORT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZPO_CUST_REC_REPORT LINE-SIZE 132 MESSAGE-ID F7
                            NO STANDARD PAGE HEADING.


SELECTION-SCREEN BEGIN OF BLOCK 1 with frame.
PARAMETERS:  TranDate type BSAD-BUDAT,
             bankname type ZPO_USERS_AUTH-USERNAME,
             CompCode type Bukrs.
Selection-screen end of block 1.


**********************************************************************************


************************************************************************************
TYPES: BEGIN OF t_report,

TRANS_ID type zsd_isop_recon-TRANS_ID,
UNIQUEREF type zsd_isop_recon-UNIQUEREF,
CUST_CODE type zsd_isop_recon-CUST_CODE,
CREDIT_VALUE Type zsd_isop_recon-CREDIT_VALUE,
SAP_AMOUNT Type zsd_isop_recon-SAP_AMOUNT,
DIFF_WRBTR type BSID-WRBTR,

 END OF t_report.
DATA: wa_report TYPE t_report,
      it_report type standard table of t_report with header line.

TYPES: BEGIN OF t_report2,

TRANS_ID type zsd_isop_recon-TRANS_ID,
UNIQUEREF type zsd_isop_recon-UNIQUEREF,
CUST_CODE type zsd_isop_recon-CUST_CODE,
CREDIT_VALUE Type zsd_isop_recon-CREDIT_VALUE,
SAP_AMOUNT Type zsd_isop_recon-SAP_AMOUNT,
DIFF_WRBTR type BSID-WRBTR,
BANK_CODE type ZSD_ISOP_RECON-BANK_CODE,

 END OF t_report2.
DATA: wa_report2 TYPE t_report2,
      it_report2 type standard table of t_report2 with header line.

*ALV data declarations

DATA : TRANS_ID type string,
UNIQUEREF type string,
CUST_CODE type string,
CREDIT_VALUE(20) Type c,
SAP_AMOUNT(20) Type c,
DIFF_WRBTR(20) Type c,
txtcompcode type string,
BANK_CODE type string.


Select BUTXT into txtcompcode   from T001 client specified where BUKRS = compCode and MANDT = '200'.
  endselect.
if TranDate is Initial.
  TranDate = sy-Datum - 1.
  endif.

  if bankname is initial.
   select TRANS_ID  CUST_CODE  CREDIT_VALUE SAP_AMOUNT BANK_CODE UNIQUEREF  into corresponding fields of  wa_report2 from
   ZSD_ISOP_RECON CLIENT SPECIFIED
   where TRANS_DATE = TranDate.
   append wa_report2 to it_report2.

   endselect.
   loop at it_report2.
     compute it_report2-DIFF_WRBTR = it_report2-SAP_AMOUNT - it_report2-CREDIT_VALUE.
     modify it_report2.

endloop.
Perform call_alv2 using it_report2[].
Perform SENDMAIL2.
  else.
   select TRANS_ID  CUST_CODE  CREDIT_VALUE SAP_AMOUNT UNIQUEREF into corresponding fields of  wa_report from
   ZSD_ISOP_RECON CLIENT SPECIFIED
   where TRANS_DATE = TranDate and BANK_CODE = bankname.
   append wa_report to it_report.

   endselect.
   loop at it_report.
      compute it_report-DIFF_WRBTR  =  it_report-SAP_AMOUNT - it_report-CREDIT_VALUE.

     modify it_report.

endloop.
Perform call_alv using it_report[].
Perform SENDMAIL.
  endif.


*PERFORM displayalv USING it_report[].




form call_alv using table type standard table.

  data: ifc type slis_t_fieldcat_alv.
  data: xfc type slis_fieldcat_alv.
  data: repid type sy-repid.

  repid = sy-repid.

  clear xfc. refresh ifc.



  clear xfc.
  xfc-reptext_ddic = 'Customer'.
  xfc-fieldname    = 'CUST_CODE'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

    clear xfc.
  xfc-reptext_ddic = 'Customer Name'.
  xfc-fieldname    = 'UNIQUEREF'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

clear xfc.
  xfc-reptext_ddic = 'Bank Amount'.
  xfc-fieldname    = 'CREDIT_VALUE'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

       clear xfc.
  xfc-reptext_ddic = 'SAP Amount'.
  xfc-fieldname    = 'SAP_AMOUNT'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

   clear xfc.

  xfc-reptext_ddic = 'Result Variance'.
  xfc-fieldname    = 'DIFF_WRBTR'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
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
WA_HEADER-INFO = 'END OF DAY RECONCILIATION REPORT'.
APPEND WA_HEADER TO T_HEADER.
CLEAR WA_HEADER.

*COMPANY CODE
WA_HEADER-TYP = 'S'.
WA_HEADER-KEY = 'Company Code: '.
 WA_HEADER-INFO = compCode. "todays date
APPEND WA_HEADER TO T_HEADER.
CLEAR: WA_HEADER.

*BANKNAME
WA_HEADER-TYP = 'S'.
WA_HEADER-KEY = 'Bank: '.
WA_HEADER-INFO = bankname. "todays date
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


form call_alv2 using table type standard table.

  data: ifc type slis_t_fieldcat_alv.
  data: xfc type slis_fieldcat_alv.
  data: repid type sy-repid.

  repid = sy-repid.

  clear xfc. refresh ifc.

clear xfc.
  xfc-reptext_ddic = 'Bank'.
  xfc-fieldname    = 'BANK_CODE'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

  clear xfc.
  xfc-reptext_ddic = 'Customer'.
  xfc-fieldname    = 'CUST_CODE'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

clear xfc.
  xfc-reptext_ddic = 'Bank Amount'.
  xfc-fieldname    = 'CREDIT_VALUE'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

       clear xfc.
  xfc-reptext_ddic = 'SAP Amount'.
  xfc-fieldname    = 'SAP_AMOUNT'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
  append xfc to ifc.

   clear xfc.

  xfc-reptext_ddic = 'Result Variance'.
  xfc-fieldname    = 'DIFF_WRBTR'.
  xfc-tabname      = 'table'.
  xfc-outputlen    = '20'.
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
 v_subj = 'Dangote End of Day Reconciliation Report'.
Data: ATC_AMOUNT type string,
      EWALLET_AMOUNT type string,
      TOTAL_AMOUNT type string.
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
'<tr><td align="center"><div style="line-height: 24px;"><h2> END OF DAY RECONCILIATION REPORT -' TranDate '</h2></div></td></tr></table>'
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
'<tr> <td>  <table border="0" width="480" align="0" cellpadding="0" cellspacing="0" bgcolor="e8e8e8">'
'<tr bgcolor="39b8d3">  <td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Customer Code  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Customer Name  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Bank Amount  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'SAP Amount	</td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px;">'
'Variance	</td></tr>'

INTO html_string .



 LOOP AT it_report .  "some html data
   move it_report-CUST_CODE  to CUST_CODE.

******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report-CREDIT_VALUE
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = CREDIT_VALUE
.
CONDENSE CREDIT_VALUE.
**********************************************

******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report-DIFF_WRBTR
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = DIFF_WRBTR
.
CONDENSE DIFF_WRBTR.
**********************************************


******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report-SAP_AMOUNT
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = SAP_AMOUNT
.
CONDENSE DIFF_WRBTR.
**********************************************



   move it_report-TRANS_ID to TRANS_ID.
   move it_report-UNIQUEREF to UNIQUEREF .
 CONCATENATE html_string    '<tr> <td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                         CUST_CODE
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                           UNIQUEREF
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          CREDIT_VALUE
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          SAP_AMOUNT
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          DIFF_WRBTR
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
                  '<div style=" line-height: 22px;"> © 2015 End of Day Reconciliation Report.</div></td></tr></table>'
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

  FORM SENDMAIL2  .
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
Data: ATC_AMOUNT type string,
      EWALLET_AMOUNT type string,
      TOTAL_AMOUNT type string.
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
'<tr><td align="center"><div style="line-height: 24px;"><h2> END OF DAY RECONCILIATION REPORT -' TranDate '</h2>''</div></td></tr></table>'
'<table border="0" align="left" width="5" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
'<tr><td height="20" width="5" style="font-size: 20px; line-height: 20px;">&nbsp;</td></tr></table>'
'<table border="0" align="right" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
'<tr><td align="left" style="color: #686b74; font-size: 10px; font-family: "Montserrat", sans-serif; font-weight: 700; mso-line-height-rule: exactly; line-height: 24px;" class="title_color main-header">'
'</td>  </tr>'
'<tr><td align="left" style="color: #222222; font-size: 20px; font-family: "Montserrat", sans-serif; font-weight: 700; mso-line-height-rule: exactly; line-height: 24px;" class="title_color main-header">'
'></td></tr></table>  </td></tr><tr><td height="40" style="font-size: 40px; line-height: 40px;">&nbsp;</td></tr>'
'<tr><td><table align="center" width="250" border="0" cellpadding="0" cellspacing="0" bgcolor="ededed"><tr><td height="1" style="font-size: 1px; line-height: 1px;">&nbsp;</td></tr>'
'</table> </td></tr>  <tr><td height="40" style="font-size: 40px; line-height: 40px;">&nbsp;</td></tr>'
'<tr> <td>  <table border="0" width="5" align="left" cellpadding="0" cellspacing="0" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="container590">'
  '<tr><td width="5" height="30" style="font-size: 30px; line-height: 30px;">&nbsp;</td></tr></table>'
  '<table border="0" width="250" align="right" cellpadding="0" cellspacing="0" bgcolor="39b8d3" style="border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;" class="section-item">'
'<tr><td><table border="0" width="220" align="center" cellpadding="0" cellspacing="0" bgcolor="39b8d3" class="section-item">'
'<tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr>	<tr>'
'<td align="left" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;"> Company Code  </div>  </td> <td align="center" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;">' txtcompcode '</div>  </td></tr><tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr>'
'</table>	</td>	</tr><tr><td colspan="2"><table align="center" width="250" border="0" cellpadding="0" cellspacing="0" bgcolor="84d3e4">'
'<tr><td height="1" style="font-size: 1px; line-height: 1px;">&nbsp;</td></tr>  </table>'
'</td>  </tr><tr><td><table border="0" width="220" align="center" cellpadding="0" cellspacing="0" bgcolor="39b8d3" class="section-item">'
'<tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr><tr>'
'<td align="left" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;">Currency	</div></td><td align="center" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 24px;" class="main-header title_color">'
'<div style="line-height: 24px;"> NGN</div></td></tr>'
'<tr><td height="13" style="font-size: 13px; line-height: 13px;">&nbsp;</td></tr>	</table></td>	</tr></table>'
'</td></tr>'
'<tr> <td>  <table border="0" width="480" align="0" cellpadding="0" cellspacing="0" bgcolor="e8e8e8">'
'<tr bgcolor="39b8d3">  <td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Customer Code  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Customer Name  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Bank Name  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'Bank Amount  </td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #84d3e4;">'
'SAP Amount	</td><td align="center" height="50" valign="middle" style="color: #ffffff; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px;">'
'Variance	</td></tr>'

INTO html_string .



 LOOP AT it_report2 .  "some html data

   move it_report-CUST_CODE  to CUST_CODE.
    move it_report-CUST_CODE  to CUST_CODE.

******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report2-CREDIT_VALUE
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = CREDIT_VALUE
.
CONDENSE CREDIT_VALUE.
**********************************************

******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report2-DIFF_WRBTR
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = DIFF_WRBTR
.
CONDENSE DIFF_WRBTR.
**********************************************


******************************************
*Converting Amount to dot and comma seperated
   CALL FUNCTION 'HRCM_AMOUNT_TO_STRING_CONVERT'
  EXPORTING
    BETRG = it_report2-SAP_AMOUNT
*   WAERS = ' '
    NEW_DECIMAL_SEPARATOR = '.'
    NEW_THOUSANDS_SEPARATOR = ','
    IMPORTING
    STRING = SAP_AMOUNT
.
CONDENSE DIFF_WRBTR.
**********************************************

   move it_report-TRANS_ID to TRANS_ID.
   move it_report-UNIQUEREF to UNIQUEREF .
   move it_report2-BANK_CODE to BANK_CODE.
 CONCATENATE html_string    '<tr> <td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                         CUST_CODE
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                           UNIQUEREF
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          CREDIT_VALUE
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          CREDIT_VALUE
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          SAP_AMOUNT
                        '</td><td align="center" height="50" valign="middle" style="color: #686b74; font-size: 14px; font-family: "Montserrat", sans-serif; mso-line-height-rule: exactly; line-height: 26px; border-right: solid 1px #f1f1f1;">'
                          DIFF_WRBTR
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
                  '<div style=" line-height: 22px;"> © 2015 End of Day Reconciliation Report.</div></td></tr></table>'
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