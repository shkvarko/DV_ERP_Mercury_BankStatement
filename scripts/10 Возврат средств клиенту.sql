
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


