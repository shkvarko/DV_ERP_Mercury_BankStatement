ALTER DOMAIN D_PAYMENTSCODE
DROP CONSTRAINT;

ALTER DOMAIN D_PAYMENTSCODE
ADD CHECK (VALUE in(0, 1, 2, 3, 4, 5, 6, 7, 8));

COMMIT WORK;

/*------ возврат средств клиенту  ------*/

SET TERM ~~~ ;
 create procedure USP_WRITEOFFEARNING_RETURNMONEYCUSTOMER (
    EARNING_ID integer,
    OPERATION_MONEY double precision,
    OPERATION_DATE date)
returns (
    WRITEOFF_MONEY double precision,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable EXISTS_EARNING_ID integer;
declare variable EXISTS_EARNING_EXPENSE double precision;
declare variable EXISTS_EARNING_VALUE double precision;
declare variable EXISTS_EARNING_SALDO double precision;
declare variable EXISTS_CUSTOMER_ID integer;
declare variable EXISTS_CURRENCY_CODE varchar(3);
BEGIN
  EXISTS_EARNING_ID = NULL;
  EXISTS_CUSTOMER_ID = NULL;
  EXISTS_CURRENCY_CODE = NULL;
  EXISTS_EARNING_EXPENSE = 0;
  EXISTS_EARNING_VALUE = 0;
  EXISTS_EARNING_SALDO = 0;
  WRITEOFF_MONEY = 0;
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  IF( :OPERATION_MONEY <= 0) THEN
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( ( 'Сумма возвращаемая клиенту должна быть больше нуля. Сумма к возврату: ' || cast( :OPERATION_MONEY as varchar(16))) as varchar(480));

    suspend;
    EXIT;
   end

  select earning.earning_id, earning.earning_expense, earning.earning_value,
   earning.earning_saldo, earning.customer_id, earning.currency_code
  from t_earning earning
  where earning.earning_id = :EARNING_ID
  into :EXISTS_EARNING_ID,  :EXISTS_EARNING_EXPENSE, :EXISTS_EARNING_VALUE,
   :EXISTS_EARNING_SALDO, :EXISTS_CUSTOMER_ID, :EXISTS_CURRENCY_CODE;

  if( :EXISTS_EARNING_ID is null ) then
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast(('Не найден платёж с указанным идентификатором: ' || cast( :EARNING_ID as varchar(8))) as varchar(480));

    suspend;
   end
  else
   begin
    if( :EXISTS_EARNING_SALDO < :OPERATION_MONEY  ) then
     begin
      ERROR_NUMBER = 1;
      ERROR_TEXT = cast( ( 'Сумма к возврату превышает остаток платежа. Сумма к возврату: ' || cast( :OPERATION_MONEY as varchar(16)) || ' Остаток: ' || cast( :EXISTS_EARNING_SALDO as varchar(16)) ) as varchar(480));

      suspend;
      EXIT;
     end
    else
     begin

      UPDATE t_EARNING  SET earning_expense = ( earning_expense + :OPERATION_MONEY )
      WHERE earning_id = :EARNING_ID;

      INSERT INTO t_PAYMENTS( customer_id, childcust_id, payments_paymentscode,
       payments_srcid, bankdate, payments_value,  currency_code, earning_id)
      VALUES( :EXISTS_CUSTOMER_ID, 0, 8,
       0, :OPERATION_DATE, -:OPERATION_MONEY, :EXISTS_CURRENCY_CODE, :EARNING_ID );

      WRITEOFF_MONEY = :OPERATION_MONEY;
      ERROR_NUMBER = 0;
      ERROR_TEXT = cast(('Успешное завершение операции. УИ платежа: ' || cast( :EARNING_ID as varchar(8))) as varchar(480));

      suspend;
     end

   end

  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось произвести возврат средств клиенту. Неизвестная ошибка, обратитесь к разработчикам.') as varchar(480));
    suspend;
  end

END
 ~~~
SET TERM ; ~~~
commit work;

SET TERM ^ ;

ALTER procedure SP_EARNINGHISTORY (
    EARNING_ID integer)
returns (
    WAYBILL_ID integer,
    WAYBILL_NUM varchar(16),
    WAYBILL_SHIPDATE date,
    WAYBILL_TOTALPRICE double precision,
    WAYBILL_SALDO double precision,
    PAYMENTS_VALUE double precision,
    WAYBILL_BONUS integer,
    WAYBILL_SHIPPED integer,
    CUSTOMER_ID integer,
    COMPANY_ID integer,
    CHILDCUST_ID integer,
    CURRENCY_CODE char(3),
    CUSTOMER_NAME varchar(100),
    COMPANY_ACRONYM varchar(3),
    COMPANY_NAME varchar(32),
    PAYMENTS_OPERDATE date,
    BANKDATE date,
    PAYMENTS_PAYMENTSCODE integer)
as
declare variable PAYMENTS_SRCID integer;
begin
 for select payments_srcid, payments_value, payments_paymentscode, payments_operdate, bankdate
 from t_payments
 where earning_id = :earning_id
 into :payments_srcid, :payments_value, :payments_paymentscode, :payments_operdate, :bankdate
 do
  begin

  waybill_id = 0;

  if( :payments_paymentscode = 2 ) then /* оплата и сторно по накладным */
   begin
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
   end
  else if( :payments_paymentscode = 7 ) then /* списание суммы */
   begin
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
  else if( :payments_paymentscode = 8 ) then /* возврат средств клиенту */
   begin
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
  else if( :payments_paymentscode = 5 ) then /* оплата начального долга */
   begin
     select customerdebt.customerdebt_begindate, customerdebt.customerdebt_initialdebt, customerdebt.customerdebt_saldo,
     0, 1, customerdebt.customer_id, customerdebt.company_id, 0, customerdebt.currency_code,
     customer.customer_name, company.company_acronym, company.company_name
     from t_customerdebt customerdebt, t_customer customer, t_company company
     where customerdebt.customerdebt_id =  :payments_srcid
      and customerdebt.customer_id = customer.customer_id
      and customerdebt.company_id = company.company_id

     into :waybill_shipdate, :waybill_totalprice, :waybill_saldo,
      :waybill_bonus, :waybill_shipped, :customer_id, :company_id, :childcust_id, :currency_code,
      :customer_name, :company_acronym, :company_name;
   end

   suspend;
 end
end^

SET TERM ; ^

CREATE INDEX T_PAYMENTS_IDX_PAYMENTSCODE
ON T_PAYMENTS (PAYMENTS_PAYMENTSCODE);

COMMIT WORK;

/*------   ------*/

SET TERM ~~~ ;
 alter procedure SP_ALLCUSTOMERTURNOVER2 (
    COMPANY_ID integer,
    CUSTOMER_ID integer,
    BEGINDATE date,
    ENDDATE date)
returns (
    CURRENCY_CODE char(3),
    DEPART_CODE varchar(3),
    CUSTOMER_NAME varchar(100),
    INITIAL_DEBT double precision,
    OUT_SUM double precision,
    IN_SUM double precision,
    EARNING_AMOUNT double precision)
as
BEGIN
  IF ((:customer_id is NULL) or (:customer_id = 0)) THEN
  BEGIN
    FOR SELECT b.currency_code, b.depart_code, a.customer_name,
        CAST(0 as DOUBLE PRECISION),
        -CAST(b.waybill_totalprice as DOUBLE PRECISION),
        CAST(0  as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM t_customer a, t_waybill b
    where a.customer_id=b.customer_id
     and b.waybill_shipdate between :begindate and :enddate
     and b.waybill_shipped = 1
     and b.waybill_bonus = 0
     and b.currency_code = 'BYB'
     and b.company_id = :company_id
    union all
    Select b.currency_code, b.depart_code, a.customer_name, CAST(0 as DOUBLE PRECISION),
           CAST(0 as DOUBLE PRECISION),
           CAST(b.backwaybill_allprice as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    from t_customer a, t_backwaybill b, t_waybill waybill
    where a.customer_id=b.customer_id
      and b.backwaybill_shipdate between :begindate and :enddate
      and b.currency_code = 'BYB'
      and b.company_id = :company_id
      and b.backwaybill_shipped = 1
      and b.waybill_id = waybill.waybill_id
      and waybill.waybill_bonus = 0
    union all
    SELECT c.currency_code, c.depart_code, a.CUSTOMER_NAME, CAST(-c.WAYBILL_TOTALPRICE as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_WAYBILL c
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
      AND c.WAYBILL_SHIPPED=1
      and c.waybill_shipdate<:begindate
      and c.waybill_bonus = 0
      and c.currency_code = 'BYB'
      and c.company_id = :company_id
    union all
    SELECT c.currency_code, c.depart_code, a.CUSTOMER_NAME, CAST(c.backWAYBILL_ALlPRICE as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_backWAYBILL c, t_waybill waybill
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
      and c.backwaybill_begindate<:begindate
      and c.currency_code = 'BYB'
      and c.company_id = :company_id
      and c.backwaybill_shipped = 1
      and c.waybill_id = waybill.waybill_id
      and waybill.waybill_bonus = 0
   union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(-c.customerdebt_initialdebt as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_CUSTOMERDEBT c
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
          and c.customerdebt_begindate<:begindate
          and c.currency_code = 'BYB'
          and c.company_id = :company_id
    union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(0 as DOUBLE PRECISION),
       CAST(-c.customerdebt_initialdebt as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_CUSTOMERDEBT c
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
          and c.customerdebt_begindate between :begindate and :enddate
          and c.currency_code = 'BYB'
          and c.company_id = :company_id
    union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(c.earning_value as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_EARNING c
    WHERE c.earning_date<:begindate
          and c.customer_id=a.customer_id
          and c.earning_code = 0
          and c.currency_code = 'BYB'
          and c.company_id = :company_id
    union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(0 as DOUBLE PRECISION),CAST(0 as DOUBLE PRECISION),
           CAST(0 as DOUBLE PRECISION), CAST(c.earning_value as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_EARNING c
    WHERE c.earning_date between :begindate and :enddate
          and c.customer_id=a.customer_id
          and c.earning_code = 0
          and c.currency_code = 'BYB'
          and c.company_id = :company_id

    /* возврат средств клиенту */
    union all
    SELECT earning.currency_code, customer.depart_code, customer.CUSTOMER_NAME, CAST(payments.payments_value as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM t_payments payments, t_earning earning, T_CUSTOMER customer
    WHERE payments.payments_paymentscode = 8
      and payments.payments_operdate < :begindate
      and payments.earning_id <> 0
      and payments.earning_id = earning.earning_id
      and earning.earning_code = 0
      and earning.currency_code = 'BYB'
      and earning.customer_id = customer.customer_id
      and earning.company_id =  :company_id

    union all
    SELECT earning.currency_code, customer.depart_code, customer.CUSTOMER_NAME, CAST(payments.payments_value as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM t_payments payments, t_earning earning, T_CUSTOMER customer
    WHERE payments.payments_paymentscode = 8
      and payments.payments_operdate between :begindate and :enddate
      and payments.earning_id <> 0
      and payments.earning_id = earning.earning_id
      and earning.earning_code = 0
      and earning.currency_code = 'BYB'
      and earning.customer_id = customer.customer_id
      and earning.company_id = :company_id

    INTO :currency_code, :depart_code, :customer_name, :initial_debt, :out_sum, :in_sum, :earning_amount
    DO
        begin
            if ( :initial_debt is null ) then
                initial_debt = 0;
            if ( :in_sum is null ) then
                in_sum = 0;
            if ( :out_sum is null ) then
                out_sum = 0;
            if ( :earning_amount is null ) then
                earning_amount = 0;
            SUSPEND;
        end
  END
  ELSE
  BEGIN
    FOR SELECT b.currency_code, b.depart_code, a.customer_name,
        CAST(0 as DOUBLE PRECISION),-CAST(b.waybill_totalprice as DOUBLE PRECISION),
        CAST(0  as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM t_customer a, t_waybill b
    where a.customer_id=b.customer_id
     and a.customer_id = :customer_id
     and b.waybill_shipdate between :begindate and :enddate
     and b.waybill_bonus = 0
     and b.waybill_shipped = 1
     and b.currency_code = 'BYB'
     and b.company_id = :company_id
    union all
    Select b.currency_code, b.depart_code, a.customer_name, CAST(0 as DOUBLE PRECISION),
           CAST(0 as DOUBLE PRECISION), CAST(b.backwaybill_allprice as DOUBLE PRECISION),
           CAST(0  as DOUBLE PRECISION)
    from t_customer a, t_backwaybill b, t_waybill waybill
    where a.customer_id=b.customer_id
     and a.customer_id = :customer_id
      and b.backwaybill_shipdate between :begindate and :enddate
      and b.currency_code = 'BYB'
      and b.company_id = :company_id
      and b.backwaybill_shipped = 1
      and b.waybill_id = waybill.waybill_id
      and waybill.waybill_bonus = 0
   union all
    SELECT c.currency_code, c.depart_code, a.CUSTOMER_NAME, CAST(-c.WAYBILL_TOTALPRICE as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_WAYBILL c
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
      AND c.WAYBILL_SHIPPED=1
      and c.waybill_bonus = 0
      and c.waybill_shipdate<:begindate
      and a.customer_id = :customer_id
      and c.currency_code = 'BYB'
      and c.company_id = :company_id
    union all
    SELECT c.currency_code, c.depart_code, a.CUSTOMER_NAME, CAST(c.backWAYBILL_ALlPRICE as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_backWAYBILL c, t_waybill waybill
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
      and c.backwaybill_begindate<:begindate
      and a.customer_id = :customer_id
      and c.currency_code = 'BYB'
      and c.company_id = :company_id
      and c.backwaybill_shipped = 1
      and c.waybill_id = waybill.waybill_id
      and waybill.waybill_bonus = 0
    union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(-c.customerdebt_initialdebt as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_CUSTOMERDEBT c
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
          and c.customerdebt_begindate<:begindate
          and a.customer_id = :customer_id
          and c.currency_code = 'BYB'
          and c.company_id = :company_id
    union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(0 as DOUBLE PRECISION),
       CAST(-c.customerdebt_initialdebt as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_CUSTOMERDEBT c
    WHERE c.CUSTOMER_ID = a.CUSTOMER_ID
          and c.customerdebt_begindate between :begindate and :enddate
          and c.currency_code = 'BYB'
          and c.company_id = :company_id
          and a.customer_id = :customer_id
    union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(c.earning_value as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_EARNING c
    WHERE c.earning_date<:begindate
          and c.customer_id=a.customer_id
          and a.customer_id = :customer_id
          and c.earning_code = 0
          and c.currency_code = 'BYB'
          and c.company_id = :company_id
   union all
    SELECT c.currency_code, a.depart_code, a.CUSTOMER_NAME, CAST(0 as DOUBLE PRECISION),CAST(0 as DOUBLE PRECISION),
           CAST(0 as DOUBLE PRECISION), CAST(c.earning_value as DOUBLE PRECISION)
    FROM T_CUSTOMER a, T_EARNING c
    WHERE c.earning_date between :begindate and :enddate
          and c.customer_id=a.customer_id
          and c.earning_code = 0
          and a.customer_id = :customer_id
          and c.currency_code = 'BYB'
          and c.company_id = :company_id

    /* возврат средств клиенту */
    union all
    SELECT earning.currency_code, customer.depart_code, customer.CUSTOMER_NAME, CAST(payments.payments_value as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM t_payments payments, t_earning earning, T_CUSTOMER customer
    WHERE payments.payments_paymentscode = 8
      and payments.payments_operdate < :begindate
      and payments.earning_id <> 0
      and payments.earning_id = earning.earning_id
      and earning.earning_code = 0
      and earning.currency_code = 'BYB'
      and earning.customer_id = customer.customer_id
      and customer.customer_id = :customer_id
      and earning.company_id =  :company_id

    union all
    SELECT earning.currency_code, customer.depart_code, customer.CUSTOMER_NAME, CAST(payments.payments_value as DOUBLE PRECISION),
       CAST(0 as DOUBLE PRECISION), CAST(0 as DOUBLE PRECISION), CAST(0  as DOUBLE PRECISION)
    FROM t_payments payments, t_earning earning, T_CUSTOMER customer
    WHERE payments.payments_paymentscode = 8
      and payments.payments_operdate between :begindate and :enddate
      and payments.earning_id <> 0
      and payments.earning_id = earning.earning_id
      and earning.earning_code = 0
      and earning.currency_code = 'BYB'
      and earning.customer_id = customer.customer_id
      and customer.customer_id = :customer_id
      and earning.company_id = :company_id
  INTO :currency_code, :depart_code, :customer_name, :initial_debt, :out_sum, :in_sum, :earning_amount
  DO
        begin
            if ( :initial_debt is null ) then
                initial_debt = 0;
            if ( :in_sum is null ) then
                in_sum = 0;
            if ( :out_sum is null ) then
                out_sum = 0;
            if ( :earning_amount is null ) then
                earning_amount = 0;
            SUSPEND;
        end
  END
END
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
 alter procedure SP_CUSTOMERTURNOVER2 (
    COMPANY_ID integer,
    CUSTOMER_ID integer,
    BEGINDATE date,
    ENDDATE date)
returns (
    CURRENCY_CODE char(3),
    DEPART_CODE varchar(3),
    CUSTOMER_NAME varchar(100),
    INITIAL_DEBT double precision,
    OUT_SUM double precision,
    IN_SUM double precision,
    EARNING_AMOUNT double precision,
    SALDO double precision)
as
BEGIN
  FOR SELECT currency_code, depart_code, customer_name, sum(initial_debt), sum(out_sum),
       sum(in_sum), sum(earning_amount), sum(initial_debt+out_sum+in_sum+earning_amount)
  FROM sp_allcustomerturnover2(:company_id, :customer_id, :begindate, :enddate)
  GROUP BY currency_code, depart_code COLLATE PXW_CYRL, customer_name COLLATE PXW_CYRL
  INTO :currency_code, :depart_code, :customer_name, :initial_debt, :out_sum, :in_sum, :earning_amount, :saldo
  DO
    begin
        if ( :currency_code is null ) then
            currency_code = '';
        if ( :depart_code is null ) then
            depart_code = '';
        if ( :customer_name is null ) then
            customer_name = '';
        if ( :initial_debt is null ) then
            initial_debt = 0;
        if ( :out_sum is null ) then
            out_sum = 0;
        if ( :in_sum is null ) then
            in_sum = 0;
        if ( :earning_amount is null ) then
            earning_amount = 0;
        if ( :saldo is null ) then
            saldo = 0;
        SUSPEND;
    end
END
 ~~~
SET TERM ; ~~~
commit work;
