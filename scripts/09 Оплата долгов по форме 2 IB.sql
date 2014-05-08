/*------   ------*/

SET TERM ~~~ ;
create procedure USP_DECCWAYBILLPAID_FROMSQL (
    WAYBILL_ID integer,
    AMOUNT double precision,
    DATELASTPAID date)
returns (
    DEC_AMOUNT double precision,
    WAYBILL_CURRENCYAMOUNTPAID double precision,
    WAYBILL_CURRENCYSALDO double precision,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
 declare variable     CURRENCY_CODE varchar(3);
BEGIN
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  DEC_AMOUNT = 0;
  WAYBILL_CURRENCYAMOUNTPAID = 0;
  WAYBILL_CURRENCYSALDO = 0;


  IF( NOT EXISTS ( SELECT waybill_id from t_waybill where waybill_id = :waybill_id ) )  then
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( ( 'не найдена накланая с указанным кодом. Идентификатор накладной: ' || cast( :WAYBILL_ID as varchar(16))) as varchar(480));

    suspend;
    EXIT;
   end

  IF (:AMOUNT <= 0) THEN
   begin
    ERROR_NUMBER = 2;
    ERROR_TEXT = cast( ( 'Сумма Сторно должна быть больше нуля. Сумма к возврату: ' || cast( :AMOUNT as varchar(16))) as varchar(480));

    suspend;
    EXIT;
   end

  select CURRENCY_CODE from t_waybill where waybill_id = :waybill_id into :CURRENCY_CODE;


  EXECUTE PROCEDURE SP_DECCWAYBILLPAID( :WAYBILL_ID, :CURRENCY_CODE, :AMOUNT, :DATELASTPAID )  RETURNING_VALUES :DEC_AMOUNT;

  select WAYBILL_CURRENCYAMOUNTPAID,  WAYBILL_CURRENCYSALDO
  from t_waybill
  where waybill_id = :WAYBILL_ID
  into :WAYBILL_CURRENCYAMOUNTPAID, :WAYBILL_CURRENCYSALDO;

  if( :DEC_AMOUNT > 0 ) then
   begin
    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. Произведено Сторно на сумму: ' || cast( :DEC_AMOUNT as varchar(16))) as varchar(480));
    suspend;
   end

  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось произвести Сторно. Неизвестная ошибка, обратитесь к разработчикам.') as varchar(480));
    suspend;
  end

END ~~~
SET TERM ; ~~~
COMMIT WORK;

/*------   ------*/

SET TERM ~~~ ;
alter procedure SP_GETWAYBILL (
    BEGINDATE date,
    ENDDATE date,
    IN_COMPANY_ID integer,
    IN_CUSTOMER_ID integer,
    IN_CHILDCUST_CODE varchar(8),
    IN_WAYBILL_NUM varchar(16),
    IN_PAYMENTFORM_ID integer)
returns (
    CURRENCY_CODE varchar(3),
    WAYBILL_ID integer,
    WAYBILL_SHIPPED integer,
    WAYBILL_NUM varchar(16),
    CUSTOMER_ID integer,
    DEPART_CODE varchar(8),
    CUSTOMER_NAME varchar(100),
    WAYBILL_BEGINDATE date,
    WAYBILL_SHIPDATE date,
    WAYBILL_ALLPRICE double precision,
    WAYBILL_TOTALPRICE double precision,
    WAYBILL_RETALLPRICE double precision,
    WAYBILL_AMOUNTPAID double precision,
    WAYBILL_DATELASTPAID date,
    WAYBILL_SALDO double precision,
    WAYBILL_CURRENCYALLPRICE double precision,
    WAYBILL_CURRENCYTOTALPRICE double precision,
    WAYBILL_CURRENCYAMOUNTPAID double precision,
    WAYBILL_CURRENCYSALDO double precision,
    STOCK_ID integer,
    CHILDCUST_ID integer,
    QUANTITY integer,
    COMPANY_ID integer,
    PAYMENTFORM_ID integer,
    WAYBILL_EXPORTMODE integer,
    WAYBILL_RETURN integer,
    WAYBILL_USDRATE double precision,
    WAYBILL_MONEYBONUS integer,
    WAYBILL_SHIPMODE integer,
    WAYBILL_SHIPMODE_NAME varchar(100),
    STOCK_NAME varchar(32),
    COMPANY_ACRONYM varchar(3),
    CHILDCUST_NAME varchar(32)
    )
as
declare variable CURRENCYNATIONAL_CODE varchar(3);
BEGIN
 currencynational_code = 'BYB'; /* национальная валюта по умолчанию */

 if( :IN_CUSTOMER_ID = 0 ) then
  begin
     for select b.currency_code, b.waybill_id, b.waybill_shipped, b.Waybill_num, b.customer_id,
      CAST(b.depart_code as VARCHAR (8)), a.customer_name, b.waybill_begindate, b.waybill_shipdate,
      b.waybill_AllPrice, b.waybill_totAlPrice, b.waybill_AmountPaid, b.waybill_datelastPaid, b.waybill_saldo, b.stock_id,
      b.childcust_id, b.company_id, b.waybill_exportmode, b.waybill_return,
      b.waybill_usdrate, b.waybill_moneybonus, b.waybill_shipmode,
      stock.stock_name, company.company_acronym,
      b.waybill_CURRENCYAllPrice, b.waybill_CURRENCYtotAlPrice, b.waybill_CURRENCYAmountPaid,
      b.waybill_CURRENCYsaldo, b.waybill_retallprice
     from t_customer a, t_waybill b,   t_stock stock, t_company company
     where b.waybill_begindate between :BEGINDATE and :ENDDATE
       and b.company_id = :in_company_id
       and upper( b.waybill_num ) containing upper( :in_waybill_num)
       and b.stock_id = stock.stock_id
       and b.company_id = company.company_id
       and b.customer_id = a.customer_id
      into :currency_code, :waybill_id, :waybill_shipped, :Waybill_num, :customer_id,
       :depart_code, :customer_name, :waybill_begindate, :waybill_shipdate,
       :waybill_AllPrice, :waybill_totAlPrice, :waybill_AmountPaid, :waybill_datelastPaid, :waybill_saldo,
       :stock_id, :childcust_id, :company_id, :waybill_exportmode, :waybill_return,
       :waybill_usdrate, :waybill_moneybonus, :waybill_shipmode,
       :stock_name, :company_acronym, :waybill_CURRENCYAllPrice, :waybill_CURRENCYtotAlPrice,
       :waybill_CURRENCYAmountPaid,  :waybill_CURRENCYsaldo, waybill_retallprice
     do
      begin
       waybill_shipmode_name = '';
       childcust_name = '';

       select waybill_shipmode_name from USP_GETWAYBILLSHIPMODENAME( :waybill_shipmode )
       into :waybill_shipmode_name;

       select sum( waybitms.waybitms_quantity )
       from t_waybitms waybitms where waybitms.waybill_id = :waybill_id
       into :Quantity;

       if( ( :childcust_id is not null ) and ( :childcust_id <> 0 ) ) then
        paymentform_id = 2;
       else
        paymentform_id = 1;

       if( :paymentform_id = :in_PAYMENTFORM_ID ) then
        begin
         if( :in_PAYMENTFORM_ID = 2 ) then
          begin
           if( :paymentform_id = 2 ) then
            begin
             waybill_AllPrice = :waybill_CURRENCYAllPrice;
             waybill_totAlPrice = :waybill_CURRENCYtotAlPrice;
             waybill_AmountPaid = :waybill_CURRENCYAmountPaid;
             waybill_saldo = :waybill_CURRENCYsaldo;

             select childcust.childcust_code, childcust.childcust_name
             from t_childcust childcust
             where childcust.childcust_id = :childcust_id
             into :depart_code, :childcust_name;

             if( :IN_CHILDCUST_CODE <> 0 ) then
              begin
               if( :IN_CHILDCUST_CODE = :depart_code ) then
                suspend;
              end
             else
              suspend;
            end
          end
         else
           suspend;
       end
      end
  end
 else
  begin
     for select b.currency_code, b.waybill_id, b.waybill_shipped, b.Waybill_num, b.customer_id,
      CAST(b.depart_code as VARCHAR (8)), a.customer_name, b.waybill_begindate, b.waybill_shipdate,
      b.waybill_AllPrice, b.waybill_totAlPrice, b.waybill_AmountPaid, b.waybill_datelastPaid, b.waybill_saldo, b.stock_id,
      b.childcust_id, b.company_id, b.waybill_exportmode, b.waybill_return,
      b.waybill_usdrate, b.waybill_moneybonus, b.waybill_shipmode,
      stock.stock_name, company.company_acronym,
      b.waybill_CURRENCYAllPrice, b.waybill_CURRENCYtotAlPrice, b.waybill_CURRENCYAmountPaid,
      b.waybill_CURRENCYsaldo, b.waybill_retallprice
     from t_customer a, t_waybill b,   t_stock stock, t_company company
     where b.waybill_begindate between :BEGINDATE and :ENDDATE
       and b.company_id = :in_company_id
       and b.customer_id = :in_customer_id
       and upper( b.waybill_num ) containing upper( :in_waybill_num)
       and b.stock_id = stock.stock_id
       and b.company_id = company.company_id
       and b.customer_id = a.customer_id
      into :currency_code, :waybill_id, :waybill_shipped, :Waybill_num, :customer_id,
       :depart_code, :customer_name, :waybill_begindate, :waybill_shipdate,
       :waybill_AllPrice, :waybill_totAlPrice, :waybill_AmountPaid, :waybill_datelastPaid, :waybill_saldo,
       :stock_id, :childcust_id, :company_id, :waybill_exportmode, :waybill_return,
       :waybill_usdrate, :waybill_moneybonus, :waybill_shipmode,
       :stock_name, :company_acronym, :waybill_CURRENCYAllPrice, :waybill_CURRENCYtotAlPrice,
       :waybill_CURRENCYAmountPaid,  :waybill_CURRENCYsaldo, waybill_retallprice
     do
      begin
       waybill_shipmode_name = '';
       childcust_name = '';
       select waybill_shipmode_name from USP_GETWAYBILLSHIPMODENAME( :waybill_shipmode )
       into :waybill_shipmode_name;

       select sum( waybitms.waybitms_quantity )
       from t_waybitms waybitms where waybitms.waybill_id = :waybill_id
       into :Quantity;

       if( ( :childcust_id is not null ) and ( :childcust_id <> 0 ) ) then
        paymentform_id = 2;
       else
        paymentform_id = 1;

       if( :paymentform_id = :in_PAYMENTFORM_ID ) then
        begin
         if( :in_PAYMENTFORM_ID = 2 ) then
          begin
           if( :paymentform_id = 2 ) then
            begin
             waybill_AllPrice = :waybill_CURRENCYAllPrice;
             waybill_totAlPrice = :waybill_CURRENCYtotAlPrice;
             waybill_AmountPaid = :waybill_CURRENCYAmountPaid;
             waybill_saldo = :waybill_CURRENCYsaldo;

             select childcust.childcust_code, childcust.childcust_name
             from t_childcust childcust
             where childcust.childcust_id = :childcust_id
             into :depart_code, :childcust_name;

             if( :IN_CHILDCUST_CODE <> 0 ) then
              begin
               if( :IN_CHILDCUST_CODE = :depart_code ) then
                suspend;
              end
             else
              suspend;

            end
          end
         else
           suspend;
       end
      end
  end
END
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
create procedure SP_GETDOCFORPAYMENT2 (
    CUSTOMER_ID integer,
    IN_CHILDCUST_CODE varchar(8),
    COMPANY_ID integer,
    BEGIN_DATE date,
    END_DATE date
    )
returns (
    SRC integer,
    WAYBILL_ID integer,
    WAYBILL_NUM varchar(16),
    WAYBILL_BEGINDATE date,
    WAYBILL_SHIPDATE date,
    CUSTOMER_NAME varchar(100),
    WAYBILL_TOTALPRICE double precision,
    WAYBILL_ENDDATE date,
    WAYBILL_AMOUNTPAID double precision,
    WAYBILL_DATELASTPAID date,
    WAYBILL_SALDO double precision,
    STOCK_NAME varchar(32),
    WAYBILL_SHIPMODE integer,
    WAYBILL_SHIPMODE_NAME varchar(100),
    WAYBILL_MONEYBONUS integer,
    CHILDCUST_ID integer,
    CHILDCUST_CODE varchar(8),
    CHILDCUST_NAME varchar(32),
    WAYBILL_QUANTITY integer
)
as
BEGIN
 for select waybill.waybill_id, waybill.waybill_num, waybill.waybill_begindate,  waybill.waybill_shipdate,
  customer.customer_name, waybill.waybill_currencytotalprice, waybill.waybill_enddate,
  waybill.waybill_currencyamountpaid, waybill.waybill_datelastpaid, waybill.waybill_currencysaldo,
  stock.stock_name, waybill.waybill_shipmode, waybill.waybill_moneybonus,
  waybill.childcust_id
 FROM t_waybill waybill, t_customer customer, t_stock stock, t_childcust childcust
 WHERE waybill.waybill_shipped = 1
   and waybill.waybill_shipdate between :BEGIN_DATE and :END_DATE
   and waybill.company_id = :COMPANY_ID
   and waybill.customer_id = :CUSTOMER_ID
   and waybill.waybill_currencysaldo < 0
   and waybill.childcust_id = childcust.childcust_id
   and childcust.childcust_code = :IN_CHILDCUST_CODE
   and waybill.customer_id = customer.customer_id
   and waybill.stock_id = stock.stock_id
 into :waybill_id, :waybill_num, :waybill_begindate, :waybill_shipdate,
  :customer_name, :waybill_totalprice, :waybill_enddate, :waybill_amountpaid, :waybill_datelastpaid,
  :waybill_saldo, :stock_name, :waybill_shipmode, :waybill_moneybonus, :childcust_id
 do
  begin
   waybill_shipmode_name = '';
   src = 2;
   select waybill_shipmode_name from usp_getwaybillshipmodename( :waybill_shipmode )
   into :waybill_shipmode_name;

   select  childcust_code, childcust_name from t_childcust
   where childcust_id = :childcust_id
   into :childcust_code, :childcust_name;

   select sum( waybitms_quantity ) from t_waybitms
   where waybill_id = :waybill_id
   into :waybill_quantity;

   suspend;

  end


END
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
 create procedure USP_SETTLECUSTOMERCWAYBILLS_FROMSQL (
    CEARNING_ID integer
    )
returns (
    ID_START integer,
    ID_END integer,
    EARNING_SALDO double precision,
    EARNING_EXPENSE double precision,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable TMP_EARNING_EXPENSE double precision;
declare variable PAYMENT_SUM double precision;
BEGIN
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';
  ID_START = 0;
  ID_END = 0;
  PAYMENT_SUM = 0;

  IF( NOT EXISTS( select cearning_id from t_cearning
      where cearning_id = :cearning_id )  ) THEN
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( ( 'не найден платёж с указанным кодом: '  || cast( :cearning_id as varchar(16))) as varchar(480));
    suspend;
    EXIT;
   end

  select cearning.cearning_expense, cearning.cearning_saldo
  from t_cearning cearning
  where cearning.cearning_id = :cearning_id
  into :EARNING_EXPENSE, :EARNING_SALDO;

  IF (:EARNING_SALDO <= 0) THEN
   begin
    ERROR_NUMBER = 2;
    ERROR_TEXT = cast( 'Остаток платежа меньше либо равен нулю' as varchar(480));

    suspend;
    EXIT;
   end

  TMP_EARNING_EXPENSE = :EARNING_EXPENSE;

  EXECUTE PROCEDURE SP_SETTLECUSTOMERCWAYBILLSNEW( :CEARNING_ID )
  RETURNING_VALUES :ID_START, :ID_END;

  select cearning.cearning_expense, cearning.cearning_saldo
  from t_cearning cearning
  where cearning.cearning_id = :cearning_id
  into :EARNING_EXPENSE, :EARNING_SALDO;

  PAYMENT_SUM = ( :EARNING_EXPENSE - TMP_EARNING_EXPENSE );

  ERROR_NUMBER = 0;
  ERROR_TEXT = cast('Успешное завершение операции. Оплачено накладных на сумму: ' || cast( :PAYMENT_SUM as varchar(16)) as varchar(480));
  suspend;

  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось разнести сумму по долгам. Неизвестная ошибка, обратитесь к разработчикам.') as varchar(480));
    suspend;
  end

END
 ~~~
SET TERM ; ~~~
commit work;


/*------   ------*/

SET TERM ~~~ ;
create procedure USP_SETTLECWAYBILL_FROMSQL (
    WAYBILL_ID integer,
    CHILDCUST_CODE varchar(8)
    )
returns (
    FINDED_MONEY double precision,
    DOCUMENT_NUM varchar(16),
    DOCUMENT_DATE date,
    DOCUMENT_CURRENCYSALDO double precision,
    DOCUMENT_CURRENCYAMOUNTPAID double precision,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable CURRENCY_CODE char(3);
declare variable WAYBILL_MONEYBONUS integer;
declare variable CHILDCUST_ID integer;
BEGIN
  FINDED_MONEY = 0;
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  DOCUMENT_NUM = '';
  DOCUMENT_CURRENCYSALDO = 0;
  DOCUMENT_CURRENCYAMOUNTPAID = 0;
  CHILDCUST_ID = NULL;


  IF( NOT EXISTS( select waybill_id from t_waybill
      where waybill_id = :waybill_id )  ) THEN
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( ( 'Не найдена накладная с указанным кодом: '  || cast( :WAYBILL_ID as varchar(16))) as varchar(480));
    suspend;
    EXIT;
   end

  select WAYBILL_MONEYBONUS, CURRENCY_CODE
  from t_waybill  where waybill_id = :waybill_id
  into :WAYBILL_MONEYBONUS, :CURRENCY_CODE;

  IF( NOT EXISTS( select childcust_id from t_childcust
      where CHILDCUST_CODE = :CHILDCUST_CODE )  ) THEN
   begin
    ERROR_NUMBER = 2;
    ERROR_TEXT = cast( ( 'Не найден дочерний клиент с указанным кодом: '  || cast( :CHILDCUST_CODE as varchar(8))) as varchar(480));
    suspend;
    EXIT;
   end

   select childcust_id
   from t_childcust  where CHILDCUST_CODE = :CHILDCUST_CODE
   into :CHILDCUST_ID;

  EXECUTE PROCEDURE SP_SETTLECWAYBILLNEW ( :WAYBILL_ID, :CURRENCY_CODE, :CHILDCUST_ID,
    :WAYBILL_MONEYBONUS)
  RETURNING_VALUES :FINDED_MONEY;

  IF (:FINDED_MONEY > 0) THEN
   BEGIN
    ERROR_NUMBER = 0;
    ERROR_TEXT = cast('Успешное завершение операции. Оплачена накладная на сумму: ' || cast( :FINDED_MONEY as varchar(16)) as varchar(480));
   END

   select  waybill_num, waybill_begindate, waybill_currencysaldo, waybill_currencyamountpaid
   from t_waybill
   where waybill_id = :waybill_id
   into :document_num, :document_date, :document_currencysaldo, :document_currencyamountpaid;

  suspend;

  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось оплатить документ. Неизвестная ошибка, обратитесь к разработчикам.') as varchar(480));
    suspend;
  end

END
 ~~~
SET TERM ; ~~~
commit work;







