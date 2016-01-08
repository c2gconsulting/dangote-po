*&---------------------------------------------------------------------*
*& Report  ZPO_COMP_PLANT_UPLOAD
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZPO_COMP_PLANT_UPLOAD.

* Type definition
types: begin of initial_upload,
  bankuser type string,
  comp_code type string,
  plant type string,
  vkorg type string,
  cc_area type string,
  country_code type string,
  cbn type string,
  end of initial_upload.


types: begin of cp_upload,
        bankuser type username,
  comp_code type bukrs,
  plant type werks_d,
  vkorg type vkorg,
  cc_area type kkber,
  country_code type land1,
  cbn type char40,
end of cp_upload.

*Data declaration
data: cp_tab type table of cp_upload,
      cp_tab_line like line of cp_tab,
      initial_tab type table of initial_upload,
      initial_tab_line like line of initial_tab,
      cptable_tab type table of zpo_comp_plant,
      cptable_line like line of cptable_tab,
*      client type MANDT value sy-MANDT,
      filenam type string,
      initial_l type i ,
      users_l type i,
      cindex like sy-tabix,
      gr_table   type ref to cl_salv_table..
SELECTION-SCREEN begin of block b1 with frame title text-000.
*  list of parameters
PARAMETERS:

filename type ibipparms-path memory id filemem,
test type checkbox memory id testmem,
update type checkbox memory id updatemem,
up_date type sy-datum default sy-datum memory id up_datemem ,
clnt type sy-mandt default sy-mandt memory id up_clientmem.

selection-screen end of block b1.
*   Process file upload
at selection-screen on value-request for filename.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      FILE_NAME = filename.

  move filename to filenam.



START-OF-SELECTION.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      FILENAME                      = filenam
     FILETYPE                      = 'ASC'
     HAS_FIELD_SEPARATOR           = 'X'
*     HEADER_LENGTH                 = 0
*     READ_BY_LINE                  = 'X'
*     DAT_MODE                      = ' '
*     CODEPAGE                      = ' '
*     IGNORE_CERR                   = ABAP_TRUE
*     REPLACEMENT                   = '#'
*     CHECK_BOM                     = ' '
*     VIRUS_SCAN_PROFILE            =
*     NO_AUTH_CHECK                 = ' '
*     ISDOWNLOAD                    = ' '
   IMPORTING
     FILELENGTH                    = initial_l
*     HEADER                        =
    TABLES
      DATA_TAB                      = initial_tab
*   CHANGING
*     ISSCANPERFORMED               = ' '
*   EXCEPTIONS
*     FILE_OPEN_ERROR               = 1
*     FILE_READ_ERROR               = 2
*     NO_BATCH                      = 3
*     GUI_REFUSE_FILETRANSFER       = 4
*     INVALID_TYPE                  = 5
*     NO_AUTHORITY                  = 6
*     UNKNOWN_ERROR                 = 7
*     BAD_DATA_FORMAT               = 8
*     HEADER_NOT_ALLOWED            = 9
*     SEPARATOR_NOT_ALLOWED         = 10
*     HEADER_TOO_LONG               = 11
*     UNKNOWN_DP_ERROR              = 12
*     ACCESS_DENIED                 = 13
*     DP_OUT_OF_MEMORY              = 14
*     DISK_FULL                     = 15
*     DP_TIMEOUT                    = 16
*     OTHERS                        = 17
            .
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
  else.
*     start the proper upload process
    perform uploadcomp_plant using initial_tab.
  ENDIF.


form uploadcomp_plant using table type standard table .
  loop at table into initial_tab_line.
    if sy-tabix gt 1.
      MOVE-CORRESPONDING initial_tab_line to cp_tab_line.

      append cp_tab_line to cp_tab.
    endif.
  endloop.

*  load the users comp plant mapping
  loop at cp_tab into cp_tab_line.

    MOVE-CORRESPONDING cp_tab_line to cptable_line.
    append cptable_line to cptable_tab.

  endloop.

  if ( test eq 'X' ).
*    Process the upload in a test / simulation mde

  endif.
  if ( update eq 'X' ).
    insert zpo_comp_plant from table cptable_tab.

    if ( sy-SUBRC = 0 ).

      COMMIT work.
      perform displayalv2 using cptable_tab.
    else.

    endif.
  endif.
endform.

form displayalv2 using table type standard table.

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