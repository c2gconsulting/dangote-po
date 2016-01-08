*&---------------------------------------------------------------------*
*& Report  ZPO_TEST
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZPO_TEST.

data loop_qty_m type table of ZPO_QUANTITIES.
data quantities type table of ZPO_QUANTITIES.
data loop_qty_m_line like line of loop_qty_m.
data quantities_line like line of quantities.
data split_qty type table of  ZPO_QUANTITIES.
data split_qty_line like line of split_qty.
data counter type i.


START-OF-SELECTION.
QUANTITIES_LINE-QTY = '500'.
append quantities_line to QUANTITIES.

SPLIT_QTY_LINE-QTY = '100'.
APPEND SPLIT_QTY_LINE TO SPLIT_QTY.
SPLIT_QTY_LINE-QTY = '150'.
APPEND SPLIT_QTY_LINE TO SPLIT_QTY.
SPLIT_QTY_LINE-QTY = '50'.
APPEND SPLIT_QTY_LINE TO SPLIT_QTY.
SPLIT_QTY_LINE-QTY = '200'.
APPEND SPLIT_QTY_LINE TO SPLIT_QTY.



perform determine_split tables QUANTITIES  SPLIT_QTY  loop_qty_m using counter..

form determine_split tables qty STRUCTURE ZPO_QUANTITIES splittable STRUCTURE ZPO_QUANTITIES
   loop_qty STRUCTURE ZPO_QUANTITIES
  using loopsize type i .

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