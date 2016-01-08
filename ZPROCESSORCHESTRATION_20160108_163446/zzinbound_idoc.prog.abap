report  zzinbound_idoc.

data: g_idoc_control_record like edi_dc40 occurs 0 with header line.
data: g_edidd like edi_dd40 occurs 0 with header line.
data: g_e1bpache09 like e1bpache09.
data: g_e1bpacar09 like e1bpacar09.
data: g_e1bpaccr09 like e1bpaccr09.
data: g_e1bpacgl09 like e1bpacgl09.

parameter: mode type c default 'A'.

refresh: g_idoc_control_record, g_edidd.
clear:   g_idoc_control_record, g_edidd.

*-----------------------*
*-Build Control Record -*
*-----------------------*
g_idoc_control_record-mestyp  = 'ACC_DOCUMENT'.   "Message type
g_idoc_control_record-idoctyp = 'ACC_DOCUMENT03'. "IDOC type
g_idoc_control_record-direct  = '2'.              "Direction

* Receiver
case sy-sysid.
  when 'DCD'.
    g_idoc_control_record-rcvpor = 'DCDCLNT200'.     "Port
    g_idoc_control_record-rcvprn = 'ISOP_E_DP'. "Partner number
endcase.

g_idoc_control_record-rcvprt = 'LS'.             "Partner type
g_idoc_control_record-rcvpfc = ''.               "Partner function

* Sender
g_idoc_control_record-sndpor = 'SAPDCD'.      "Port

case sy-sysid.
  when 'DCD'.
    g_idoc_control_record-sndprn = 'ISOP_E_DP'. "Partner number
endcase.

g_idoc_control_record-sndprt = 'LS'.             "Partner type
g_idoc_control_record-sndpfc = ''.               "Partner function
g_idoc_control_record-refmes = 'Customer clearing'.
append g_idoc_control_record.


*----------------------*
*-Build Idoc Segments -*
*----------------------*

*-------E1BPACHE09 (HEADER)
clear g_edidd.
g_edidd-segnam = 'E1BPACHE09'.
g_edidd-segnum = 1.

clear g_e1bpache09.
g_e1bpache09-bus_act    = 'RFBU'.
g_e1bpache09-doc_date   = sy-datum.
g_e1bpache09-doc_type   = 'DZ'.
g_e1bpache09-comp_code  = '1000'.
g_e1bpache09-pstng_date = sy-datum.
g_e1bpache09-username   = sy-uname.
g_e1bpache09-ref_doc_no = 'OECO/1420911'.
move g_e1bpache09 to g_edidd-sdata.
append g_edidd.


*-------E1BPACGL09 (ACCOUNT GL) (Debit) (Factoring Partner)
clear g_edidd.
g_edidd-segnam = 'E1BPACGL09'.
g_edidd-segnum = 2.

clear g_e1bpacgl09.
g_e1bpacgl09-itemno_acc = '0000000002'.
g_e1bpacgl09-gl_account = '0000160390'.
g_e1bpacgl09-customer   = '0001000008'.
g_e1bpacgl09-acct_type  = 'D'.
*g_e1bpacgl09-sp_gl_ind = 'A'
g_e1bpacgl09-comp_code  = '1000'.
g_e1bpacgl09-ALLOC_NMBR  = '0010235761'.


*g_e1bpacgl09-costcenter = '0000001602'.
move g_e1bpacgl09 to g_edidd-sdata.
append g_edidd.


*-------E1BPACAR09 (ACCOUNT RECIEVABLE) (Credit) (Customer)
clear g_edidd.
g_edidd-segnam = 'E1BPACAR09'.
g_edidd-segnum = 3.

clear g_e1bpacar09.
g_e1bpacar09-itemno_acc = '0000000001'.
g_e1bpacar09-customer  = '0001000008'.
g_e1bpacar09-comp_code  = '1000'.

*g_e1bpacar09-sp_gl_ind = 'A'.



move g_e1bpacar09 to g_edidd-sdata.
append g_edidd.

*clear g_e1bpacar09.
*g_e1bpacar09-itemno_acc = '0000000002'.
*g_e1bpacar09-alloc_nmbr = '0010235761'. "BSEG-ZUONR ?
*
*move g_e1bpacar09 to g_edidd-sdata.
*append g_edidd.

*-------E1BPACCR09 (CURRENCY AMOUNT)
clear g_edidd.
g_edidd-segnam = 'E1BPACCR09'.
g_edidd-segnum = 4.

clear g_e1bpaccr09.
g_e1bpaccr09-itemno_acc = '0000000001'.
g_e1bpaccr09-curr_type  = '00'.
g_e1bpaccr09-currency   = 'NGN'.
g_e1bpaccr09-amt_doccur = '1513800.00-'.
move g_e1bpaccr09 to g_edidd-sdata.
append g_edidd.

g_e1bpaccr09-itemno_acc = '0000000002'.
g_e1bpaccr09-curr_type  = '00'.
g_e1bpaccr09-currency   = 'NGN'.
g_e1bpaccr09-amt_doccur = '1513800.00'.
move g_e1bpaccr09 to g_edidd-sdata.
append g_edidd.

*--------------*
*-Create idoc -*
*--------------*

*-Syncronous
if mode = 'S'.
  call function 'IDOC_INBOUND_SINGLE'
    exporting
      pi_idoc_control_rec_40              = g_idoc_control_record
*     PI_DO_COMMIT                        = 'X'
*   IMPORTING
*     PE_IDOC_NUMBER                      =
*     PE_ERROR_PRIOR_TO_APPLICATION       =
    tables
      pt_idoc_data_records_40             = g_edidd
    exceptions
      idoc_not_saved                      = 1
      others                              = 2.

  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

*-Asynchronus
else.
  call function 'IDOC_INBOUND_ASYNCHRONOUS'
    in background task as separate unit
    tables
      idoc_control_rec_40 = g_idoc_control_record
      idoc_data_rec_40    = g_edidd.

  commit work.

endif.

write: / 'Goto transaction WE05'.