FUNCTION ZPO_GET_MATERIALS.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ACCESS_TOKEN) TYPE  STRING OPTIONAL
*"     VALUE(SALES_ORG) TYPE  VKORG OPTIONAL
*"     VALUE(PLANT) TYPE  WERKS_D OPTIONAL
*"  EXPORTING
*"     VALUE(VKORG) TYPE  VKORG
*"     VALUE(WERKS) TYPE  WERKS_D
*"  TABLES
*"      MATERIALS STRUCTURE  ZMATERIALS OPTIONAL
*"      ERROR_LOG STRUCTURE  ZERROR_TYPE
*"----------------------------------------------------------------------
  data materials_line like line of materials.
  data m_l type i .
  data error_line like line of error_log.
  data mtart type mtart.
  data user type username.
  data division type spart.


  perform getUser using ACCESS_TOKEN user.

  if user is not initial and access_token is not initial.
    move sales_org to vkorg.
    move plant to werks.

  if ( sales_org is  initial and plant is  initial ).
PERFORM getMaterials using access_token materials[].
else.
   select mv~matnr into materials_line-MATERIAL_NUMBER from mvke as mv INNER JOIN marc as ma  on
      ( mv~matnr = ma~matnr ) where
      mv~vkorg = sales_org and
      ma~werks = plant.

     materials_line-plant = plant.
     materials_line-sales_org = sales_org.

      select single maktx into materials_line-material_text from makt
         where matnr = materials_line-material_number.
      if ( sy-subrc eq 0 and materials_line-material_text is not initial ).
        select single mtart into  mtart from mara where matnr = materials_line-material_number.
        if ( SY-SUBRC eq 0 and  mtart eq 'FERT' ).
            append materials_line to materials.
          endif.

      endif.




    endselect.

    sort materials.
    delete ADJACENT DUPLICATES FROM materials.



endif.

clear m_l.
describe table materials lines m_l.

if ( m_l is initial ).
    error_line-error_code = '101'.
    error_line-error_title = 'Invalid sales org/plant.'.
    error_line-error_message = 'Please enter a valid sales org / plant!'.

    append error_line to error_log.

  endif.

else.
  error_line-error_code = '101'.
    error_line-error_title = 'Invalid or no token'.
    error_line-error_message = 'Please provide a valid token!'.

    append error_line to error_log.
  endif.


ENDFUNCTION.