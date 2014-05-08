/*------   ------*/

SET TERM ~~~ ;
 create procedure USP_GETWAYBILLSHIPMODENAME(
    waybillshipmode_id integer
)

returns (
    WAYBILL_SHIPMODE_NAME varchar(100)
    )
as
begin
    waybill_shipmode_name = '';

    if(:waybillshipmode_id = 0  ) then waybill_shipmode_name = cast( 'Реализация'  as varchar(100) );
    if(:waybillshipmode_id = 9911  ) then waybill_shipmode_name = cast( 'Представительские нужды внешние'  as varchar(100) );
    if(:waybillshipmode_id = 9912  ) then waybill_shipmode_name = cast( 'Представительские нужды внутренние'  as varchar(100) );
    if(:waybillshipmode_id = 9921  ) then waybill_shipmode_name = cast( 'Для сертификации'  as varchar(100) );
    if(:waybillshipmode_id = 9711  ) then waybill_shipmode_name = cast( 'Образцы'  as varchar(100) );
    if(:waybillshipmode_id = 9721  ) then waybill_shipmode_name = cast( 'Тестеры'  as varchar(100) );
    if(:waybillshipmode_id = 9731  ) then waybill_shipmode_name = cast( 'Призы для анимации'  as varchar(100) );
    if(:waybillshipmode_id = 9741  ) then waybill_shipmode_name = cast( 'Реклама'  as varchar(100) );
    if(:waybillshipmode_id = 9751  ) then waybill_shipmode_name = cast( 'Отгрузка по нулевой цене'  as varchar(100) );

    suspend;
end
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
 create procedure SP_GETDOCFORPAYMENT (
    CUSTOMER_ID integer,
    COMPANY_ID integer,
    CURRENCY_CODE varchar(3),
    ONLY_WAYBILL_SHIPMODE0 integer)
returns (
    SRC integer,
    WAYBILL_ID integer,
    WAYBILL_NUM varchar(16),
    WAYBILL_BEGINDATE date,
    CUSTOMER_NAME varchar(100),
    WAYBILL_TOTALPRICE double precision,
    WAYBILL_ENDDATE date,
    WAYBILL_AMOUNTPAID double precision,
    WAYBILL_DATELASTPAID date,
    WAYBILL_SALDO double precision,
    STOCK_NAME varchar(32),
    WAYBILL_SHIPMODE integer,
    WAYBILL_SHIPMODE_NAME varchar(100))
as
BEGIN
 for SELECT CAST(2 as INTEGER), a.waybill_id, a.waybill_num, a.waybill_begindate,
  b.customer_name, a.waybill_totalprice, a.waybill_enddate,
  a.waybill_amountpaid, a.waybill_datelastpaid, a.waybill_saldo,
  cast( stock.stock_name as varchar(32) ) stock_name,
  a.waybill_shipmode
 FROM t_WAYBILL a, t_CUSTOMER b, t_stock stock
 WHERE a.CUSTOMER_ID=b.CUSTOMER_ID
and a.customer_id = :customer_id
and a.waybill_shipped = 1
and a.waybill_saldo<0
and a.currency_code = :currency_code
and a.waybill_bonus <> 1
and a.company_id = :company_id
and a.stock_id = stock.stock_id

union all

SELECT CAST(3 as INTEGER), a.customerdebt_id, a.customerdebt_srcdoc,
a.customerdebt_begindate,
b.customer_name, a.customerdebt_initialdebt, a.customerdebt_begindate,
a.customerdebt_amountpaid, a.customerdebt_datelastpaid, 
a.customerdebt_saldo,
cast( '' as varchar(32) ) stock_name,
cast( 0 as integer) waybill_shipmode
FROM t_customerdebt a, t_CUSTOMER b
WHERE a.CUSTOMER_ID=b.CUSTOMER_ID
and a.customer_id = :customer_id
and a.customerdebt_saldo<0
and a.currency_code = :currency_code
and a.company_id = :company_id

into :SRC, :waybill_id, :waybill_num, :waybill_begindate, :customer_name,
 :waybill_totalprice, :waybill_enddate, :waybill_amountpaid, :waybill_datelastpaid,
 :waybill_saldo, :stock_name, :waybill_shipmode
do
 begin
  waybill_shipmode_name = '';
  if( :SRC = 2 ) then
   select waybill_shipmode_name from USP_GETWAYBILLSHIPMODENAME( :waybill_shipmode )
   into :waybill_shipmode_name;

  if( :only_waybill_shipmode0 = 1 ) then
   begin
    if( :waybill_shipmode = 0 ) then
     suspend;
   end
  else
   suspend;
 end

END
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
create procedure USP_NEWSETTLEDOC_FROMSQL (
    DOC_CODE integer,
    DOC_ID integer,
    EARNING_ID integer,
    SETTLE_VALUE double precision,
    CURRENCY_CODE char(3))
returns (
    FINDED_MONEY double precision,
    DOCUMENT_NUM varchar(16),
    DOCUMENT_DATE date,
    DOCUMENT_SALDO double precision,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
 declare variable CUSTOMER_ID integer;
 declare variable DOC_SALDO double precision;
 declare variable PAY_VALUE double precision;
 declare variable BANKDATE date;
 declare variable BANKVALUE double precision;
 declare variable TMP_AMOUNT double precision;
BEGIN
  FINDED_MONEY = 0;
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';
  PAY_VALUE = 0;
  DOCUMENT_NUM = '';
  DOCUMENT_SALDO = -1;

  select earning_saldo, earning_date, customer_id
  from t_earning
  where earning_id = :earning_id
  into :settle_value, :bankdate, :customer_id;

  IF (:settle_value <= 0) THEN
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( 'Остаток платежа меньше либо равен нулю' as varchar(480));

    suspend;
    EXIT;
   end

  IF (:doc_code = 1) THEN
  BEGIN
    select  -suppl_saldo
    from t_suppl
    where suppl_id=:doc_id
    into :doc_saldo;

    if (:settle_value > :doc_saldo) then
      pay_value = :doc_saldo;
    else
      pay_value = :settle_value;

    finded_money = :pay_value;

    UPDATE t_EARNING
      SET earning_expense = earning_expense+:pay_value
    WHERE earning_id = :earning_id;

    update t_SUPPL
      set suppl_amountpaid = suppl_amountpaid + :pay_value,
          suppl_datelastpaid = :bankdate
    where suppl_id = :doc_id;

    EXECUTE PROCEDURE sp_SETTLESPLITMS (:doc_id, :pay_value, :bankdate);
    INSERT INTO t_PAYMENTS (customer_id, payments_paymentscode,
                            payments_srcid, bankdate, payments_value,
                            currency_code, earning_id)
    VALUES (:customer_id,1,:doc_id,:bankdate,:pay_value,
            :currency_code, :earning_id);
  END

  IF (:doc_code = 2) THEN
   BEGIN
    select -waybill_saldo, waybill_num, waybill_begindate
    from t_waybill  where waybill_id = :doc_id
    into :doc_saldo, :document_num, :document_date;

    if (:settle_value > :doc_saldo) then
      pay_value = :doc_saldo;
    else
      pay_value = :settle_value;

    finded_money = :pay_value;

    UPDATE t_EARNING SET earning_expense = ( earning_expense + :pay_value )
    WHERE earning_id = :earning_id;

    update t_waybill  set waybill_amountpaid = waybill_amountpaid + :pay_value,
          waybill_datelastpaid = :bankdate
    where waybill_id = :doc_id;

    EXECUTE PROCEDURE sp_SETTLEWAYBITMS (:doc_id, :pay_value, :bankdate);
    INSERT INTO t_PAYMENTS (customer_id, payments_paymentscode,
      payments_srcid, bankdate, payments_value, currency_code, earning_id)
    VALUES( :customer_id, 2,
      :doc_id,:bankdate, :pay_value, :currency_code, :earning_id );

    select waybill_saldo from t_waybill where waybill_id = :doc_id
    into :document_saldo;

    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. Сумма разноски: ' || cast( :finded_money as varchar(16))) as varchar(480));
    suspend;

   END

  IF (:doc_code = 3) THEN
  BEGIN
    select  -customerdebt_saldo, customerdebt_srcdoc, customerdebt_begindate
    from t_customerdebt
    where customerdebt_id=:doc_id
    into :doc_saldo, :document_num, :document_date;

    if (:settle_value > :doc_saldo) then
      pay_value = :doc_saldo;
    else
      pay_value = :settle_value;

    finded_money = :pay_value;

    UPDATE t_EARNING
      SET earning_expense = earning_expense+:pay_value
    WHERE earning_id = :earning_id;

    UPDATE T_CUSTOMERDEBT
     SET customerdebt_amountpaid = customerdebt_amountpaid + :pay_value,
         customerdebt_datelastpaid = :bankdate
     WHERE customerdebt_id = :doc_id;

    INSERT INTO t_PAYMENTS( customer_id, payments_paymentscode,
      payments_srcid, bankdate, payments_value, currency_code, earning_id )
    VALUES (:customer_id, 5,
     :doc_id,:bankdate,:pay_value, :currency_code, :earning_id);

    select CUSTOMERDEBT_SALDO from t_customerdebt where customerdebt_id = :doc_id
    into :document_saldo;

    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. Сумма разноски: ' || cast( :finded_money as varchar(16))) as varchar(480));
    suspend;

  END

  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось оплатить документ. Неизвестная ошибка, обратитесь к разработчикам.') as varchar(480));
    suspend;
  end

END ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
CREATE PROCEDURE SP_EARNINGHISTORY (
    earning_id integer)
returns (
    waybill_id integer,
    waybill_num varchar(16),
    waybill_shipdate date,
    waybill_totalprice double precision,
    waybill_saldo double precision,
    payments_value double precision,
    waybill_bonus integer,
    waybill_shipped integer,
    customer_id integer,
    company_id integer,
    childcust_id integer,
    currency_code char(3),
    customer_name varchar(100),
    company_acronym varchar(3),
    company_name varchar(32),
    payments_operdate date,
    bankdate date)
as
declare variable payments_srcid integer;
declare variable payments_paymentscode integer;
begin
 for select payments_srcid, payments_value, payments_paymentscode, payments_operdate, bankdate
 from t_payments
 where earning_id = :earning_id
 into :payments_srcid, :payments_value, :payments_paymentscode, :payments_operdate, :bankdate
 do
  begin

  waybill_id = 0;

  select waybill.waybill_id, waybill.waybill_num, waybill.waybill_shipdate,
    waybill.waybill_totalprice, waybill.waybill_saldo,
    waybill.waybill_bonus, waybill.waybill_shipped, waybill.customer_id,
    waybill.company_id, waybill.childcust_id, waybill.currency_code,
    customer.customer_name, company.company_acronym, company.company_name
  from t_waybill waybill, t_customer customer, t_company company
  where waybill.waybill_id = :payments_srcid
    and waybill.customer_id = customer.customer_id
    and waybill.company_id = company.company_id
  into :waybill_id, :waybill_num, :waybill_shipdate, :waybill_totalprice, :waybill_saldo,
   :waybill_bonus, :waybill_shipped, :CUSTOMER_ID, :company_id, :childcust_id, :currency_code,
   :customer_name, :company_acronym, :company_name;

   if( ( :waybill_id is null ) or ( :waybill_id = 0 ) ) then
    begin
     if( :payments_paymentscode = 7 ) then
      waybill_num = cast( 'списание суммы  ' as varchar(16) );

     select earning.earning_date, earning.earning_value, earning.earning_saldo,
     0, 1, earning.customer_id, earning.company_id, 0, earning.currency_code,
     customer.customer_name, company.company_acronym, company.company_name
     from t_earning earning, t_customer customer, t_company company
     where earning.earning_id = :earning_id
      and earning.customer_id = customer.customer_id
      and earning.company_id = company.company_id

     into :waybill_shipdate, :waybill_totalprice, :waybill_saldo,
      :waybill_bonus, :waybill_shipped, :customer_id, :company_id, :childcust_id, :currency_code,
      :customer_name, :company_acronym, :company_name;
    end

   suspend;
 end
end
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
 alter procedure USP_NEWSETTLEDOC_FROMSQL (
    DOC_CODE integer,
    DOC_ID integer,
    EARNING_ID integer,
    SETTLE_VALUE double precision,
    CURRENCY_CODE char(3))
returns (
    FINDED_MONEY double precision,
    DOCUMENT_NUM varchar(16),
    DOCUMENT_DATE date,
    DOCUMENT_SALDO double precision,
    EARNING_SALDO double precision,
    EARNING_EXPENSE double precision,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable CUSTOMER_ID integer;
declare variable DOC_SALDO double precision;
declare variable PAY_VALUE double precision;
declare variable BANKDATE date;
declare variable BANKVALUE double precision;
declare variable TMP_AMOUNT double precision;
BEGIN
  FINDED_MONEY = 0;
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';
  PAY_VALUE = 0;
  DOCUMENT_NUM = '';
  DOCUMENT_SALDO = -1;

  select earning_saldo, earning_date, customer_id, earning_saldo, earning_expense
  from t_earning
  where earning_id = :earning_id
  into :settle_value, :bankdate, :customer_id, :earning_saldo, :earning_expense;

  IF (:settle_value <= 0) THEN
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( 'Остаток платежа меньше либо равен нулю' as varchar(480));

    suspend;
    EXIT;
   end

  IF (:doc_code = 1) THEN
  BEGIN
    select  -suppl_saldo
    from t_suppl
    where suppl_id=:doc_id
    into :doc_saldo;

    if (:settle_value > :doc_saldo) then
      pay_value = :doc_saldo;
    else
      pay_value = :settle_value;

    finded_money = :pay_value;

    UPDATE t_EARNING
      SET earning_expense = earning_expense+:pay_value
    WHERE earning_id = :earning_id;

    update t_SUPPL
      set suppl_amountpaid = suppl_amountpaid + :pay_value,
          suppl_datelastpaid = :bankdate
    where suppl_id = :doc_id;

    EXECUTE PROCEDURE sp_SETTLESPLITMS (:doc_id, :pay_value, :bankdate);
    INSERT INTO t_PAYMENTS (customer_id, payments_paymentscode,
                            payments_srcid, bankdate, payments_value,
                            currency_code, earning_id)
    VALUES (:customer_id,1,:doc_id,:bankdate,:pay_value,
            :currency_code, :earning_id);
  END

  IF (:doc_code = 2) THEN
   BEGIN
    select -waybill_saldo, waybill_num, waybill_begindate
    from t_waybill  where waybill_id = :doc_id
    into :doc_saldo, :document_num, :document_date;

    if (:settle_value > :doc_saldo) then
      pay_value = :doc_saldo;
    else
      pay_value = :settle_value;

    finded_money = :pay_value;

    UPDATE t_EARNING SET earning_expense = ( earning_expense + :pay_value )
    WHERE earning_id = :earning_id;

    update t_waybill  set waybill_amountpaid = waybill_amountpaid + :pay_value,
          waybill_datelastpaid = :bankdate
    where waybill_id = :doc_id;

    EXECUTE PROCEDURE sp_SETTLEWAYBITMS (:doc_id, :pay_value, :bankdate);
    INSERT INTO t_PAYMENTS (customer_id, payments_paymentscode,
      payments_srcid, bankdate, payments_value, currency_code, earning_id)
    VALUES( :customer_id, 2,
      :doc_id,:bankdate, :pay_value, :currency_code, :earning_id );

    select waybill_saldo from t_waybill where waybill_id = :doc_id
    into :document_saldo;

    select earning_saldo, earning_expense from t_earning
    where earning_id = :earning_id
    into :earning_saldo, :earning_expense;

    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. Сумма разноски: ' || cast( :finded_money as varchar(16))) as varchar(480));
    suspend;

   END

  IF (:doc_code = 3) THEN
  BEGIN
    select  -customerdebt_saldo, customerdebt_srcdoc, customerdebt_begindate
    from t_customerdebt
    where customerdebt_id=:doc_id
    into :doc_saldo, :document_num, :document_date;

    if (:settle_value > :doc_saldo) then
      pay_value = :doc_saldo;
    else
      pay_value = :settle_value;

    finded_money = :pay_value;

    UPDATE t_EARNING
      SET earning_expense = earning_expense+:pay_value
    WHERE earning_id = :earning_id;

    UPDATE T_CUSTOMERDEBT
     SET customerdebt_amountpaid = customerdebt_amountpaid + :pay_value,
         customerdebt_datelastpaid = :bankdate
     WHERE customerdebt_id = :doc_id;

    INSERT INTO t_PAYMENTS( customer_id, payments_paymentscode,
      payments_srcid, bankdate, payments_value, currency_code, earning_id )
    VALUES (:customer_id, 5,
     :doc_id,:bankdate,:pay_value, :currency_code, :earning_id);

    select CUSTOMERDEBT_SALDO from t_customerdebt where customerdebt_id = :doc_id
    into :document_saldo;

    select earning_saldo, earning_expense from t_earning
    where earning_id = :earning_id
    into :earning_saldo, :earning_expense;

    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. Сумма разноски: ' || cast( :finded_money as varchar(16))) as varchar(480));
    suspend;

  END

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

/*------   ------*/

SET TERM ~~~ ;
 create procedure USP_DECWAYBILLPAID_FROMSQL (
    WAYBILL_ID          integer,
    AMOUNT              double precision,
    DATELASTPAID        date
    )
returns (
    DEC_AMOUNT          double precision,
    WAYBILL_AMOUNTPAID  double precision,
    WAYBILL_SALDO       double precision,
    ERROR_NUMBER        integer,
    ERROR_TEXT          varchar(480)
    )
as
BEGIN
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  DEC_AMOUNT = 0;
  WAYBILL_AMOUNTPAID = 0;
  WAYBILL_SALDO = 0;

  IF (:AMOUNT <= 0) THEN
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( ( 'Сумма Сторно должна быть больше нуля. Сумма к возврату: ' || cast( :AMOUNT as varchar(16))) as varchar(480));

    suspend;
    EXIT;
   end

  EXECUTE PROCEDURE SP_DECWAYBILLPAID( :WAYBILL_ID, :AMOUNT, :DATELASTPAID )  RETURNING_VALUES :DEC_AMOUNT;

  select WAYBILL_AMOUNTPAID,  WAYBILL_SALDO
  from t_waybill
  where waybill_id = :WAYBILL_ID
  into :WAYBILL_AMOUNTPAID, :WAYBILL_SALDO;

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

END
 ~~~
SET TERM ; ~~~
commit work;



