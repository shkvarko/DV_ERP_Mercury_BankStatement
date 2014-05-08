
/*------   ------*/

SET TERM ~~~ ;
ALTER procedure USP_ADD_CUSTOMERDEBT_FROMSQL (
    CUSTOMER_ID                INTEGER,
    CURRENCY_CODE              CHAR(3),
    COMPANY_ID                 INTEGER,
    CHILDCUST_ID               INTEGER,

    CUSTOMERDEBT_SRCDOC        VARCHAR(16),
    CUSTOMERDEBT_BEGINDATE     DATE,
    CUSTOMERDEBT_INITIALDEBT   DOUBLE PRECISION,
    PAYMENTTYPE_ID             INTEGER
    )
returns (
    CUSTOMERDEBT_ID integer,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable NEW_CUSTOMERDEBT_ID integer;
declare variable NEW_CHILDCUST_ID integer;
begin
  CUSTOMERDEBT_ID = null;

  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  /* проверка на наличие клиента с указанным кодом */
  if( not exists ( select customer_id from t_customer where customer_id = :customer_id ) ) then
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast(('В базе данных не найден клиент с указанным кодом: ' || cast( :customer_id as varchar(8))) as varchar(480));
    suspend;

    exit;
   end

  /* проверка на наличие компании с указанным кодом */
  if( not exists ( select company_id from t_company where company_id = :company_id ) ) then
   begin
    ERROR_NUMBER = 2;
    ERROR_TEXT = cast(('В базе данных не найдена компания с указанным кодом: ' || cast( :company_id as varchar(8))) as varchar(480));
    suspend;

    exit;
   end

  /* проверка на наличие валюты с указанным кодом */
  if( not exists ( select currency_code from t_currency where currency_code = :currency_code ) ) then
   begin
    ERROR_NUMBER = 3;
    ERROR_TEXT = cast(('В базе данных не найдена валюта с указанным кодом: ' || cast( :currency_code as varchar(3))) as varchar(480));
    suspend;

    exit;
   end

  /* проверка на наличие дочернего клиента с указанным кодом */
  if( ( :PAYMENTTYPE_ID = 2 ) and ( :CHILDCUST_ID is not null ) and ( :CHILDCUST_ID <> 0 ) ) then
   if( not exists ( select childcust_id from t_childcust where childcust_id = :childcust_id ) ) then
    begin
     ERROR_NUMBER = 4;
     ERROR_TEXT = cast(('В базе данных не найдена дочерний с указанным кодом: ' || cast( :childcust_id as varchar(8))) as varchar(480));
     suspend;

     exit;
    end

  if( :CHILDCUST_ID is null ) then
   NEW_CHILDCUST_ID = 0;
  else
   NEW_CHILDCUST_ID = :CHILDCUST_ID;

  /* вставка записи в таблицу */
  NEW_CUSTOMERDEBT_ID = GEN_ID(g_CUSTOMERDEBTID, 1);

  INSERT INTO T_CUSTOMERDEBT( CUSTOMERDEBT_ID, CUSTOMER_ID, CUSTOMERDEBT_SRCDOC, CUSTOMERDEBT_BEGINDATE,
   CUSTOMERDEBT_INITIALDEBT,  CUSTOMERDEBT_DATELASTPAID,  CUSTOMERDEBT_AMOUNTPAID,  CURRENCY_CODE,
   CHILDCUST_ID, COMPANY_ID  )
  VALUES( :NEW_CUSTOMERDEBT_ID, :CUSTOMER_ID, :CUSTOMERDEBT_SRCDOC, :CUSTOMERDEBT_BEGINDATE,
   :CUSTOMERDEBT_INITIALDEBT, NULL, 0, :CURRENCY_CODE, :NEW_CHILDCUST_ID, :COMPANY_ID );

  CUSTOMERDEBT_ID = :NEW_CUSTOMERDEBT_ID;

  ERROR_NUMBER = 0;
  ERROR_TEXT = cast(('Успешное завершение операции. Код записи: ' || cast( :CUSTOMERDEBT_ID as varchar(8))) as varchar(480));

  suspend;

  when any do
   begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось создать выписку. Неизвестная ошибка, т.к не удается вернуть SQLCODE.') as varchar(480));

    suspend;
   end
end
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
ALTER procedure USP_EDIT_CUSTOMERDEBT_FROMSQL (
    CUSTOMERDEBT_ID            INTEGER,
    CUSTOMER_ID                INTEGER,
    CURRENCY_CODE              CHAR(3),
    COMPANY_ID                 INTEGER,
    CHILDCUST_ID               INTEGER,

    CUSTOMERDEBT_SRCDOC        VARCHAR(16),
    CUSTOMERDEBT_BEGINDATE     DATE,
    CUSTOMERDEBT_INITIALDEBT   DOUBLE PRECISION,
    PAYMENTTYPE_ID             INTEGER
    )
returns (
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable EXISTS_CUSTOMERDEBT_ID integer;
declare variable EXISTS_CUSTOMER_ID integer;
declare variable EXISTS_CHILDCUST_ID integer;
declare variable EXISTS_COMPANY_ID integer;
declare variable EXISTS_CUSTOMERDEBT_INITIALDEBT double precision;
declare variable EXISTS_CUSTOMERDEBT_AMOUNTPAID double precision;
declare variable EXISTS_PAYMENTS_HISTORY integer;
begin

  EXISTS_CUSTOMERDEBT_ID = NULL;
  EXISTS_CUSTOMER_ID = NULL;
  EXISTS_COMPANY_ID = NULL;
  EXISTS_CUSTOMERDEBT_INITIALDEBT = 0;
  EXISTS_CUSTOMERDEBT_AMOUNTPAID = 0;
  EXISTS_PAYMENTS_HISTORY = 0;

  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  select customerdebt.customerdebt_id, customerdebt.company_id, customerdebt.customer_id, customerdebt.childcust_id,
   customerdebt.customerdebt_initialdebt, customerdebt.customerdebt_amountpaid
  from t_customerdebt customerdebt
  where customerdebt.customerdebt_id = :CUSTOMERDEBT_ID
  into :EXISTS_CUSTOMERDEBT_ID, :EXISTS_COMPANY_ID, :EXISTS_CUSTOMER_ID, :EXISTS_CHILDCUST_ID,
   :EXISTS_CUSTOMERDEBT_INITIALDEBT, :EXISTS_CUSTOMERDEBT_AMOUNTPAID;

  IF( :EXISTS_CHILDCUST_ID IS NULL ) then EXISTS_CHILDCUST_ID = 0;

  if( :EXISTS_CUSTOMERDEBT_ID is null ) then
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast(('Не найдена сумма с указанным идентификатором: ' || cast( :CUSTOMERDEBT_ID as varchar(8))) as varchar(480));

    suspend;
   end
  else
   begin

    select count( payments.payments_id )
    from t_payments payments
    where payments.payments_srcid = :EXISTS_CUSTOMERDEBT_ID
      and payments.payments_paymentscode = 5
    into :EXISTS_PAYMENTS_HISTORY;

    if( :PAYMENTTYPE_ID = 1 ) then
     begin
      if( :EXISTS_CUSTOMER_ID <> :CUSTOMER_ID ) then
       begin
        if( :EXISTS_CUSTOMERDEBT_AMOUNTPAID > 0 ) then
         begin
          ERROR_NUMBER = 2;
          ERROR_TEXT = cast(('В сумме нельзя менять клиента, т.к. по задолженности производилась оплата.') as varchar(480));

          suspend;
          exit;
         end
       end
     end
    else if( ( :PAYMENTTYPE_ID = 2 ) AND ( :CHILDCUST_ID is not null ) AND ( :CHILDCUST_ID <> 0 ) ) then
     begin
      if( :EXISTS_CHILDCUST_ID <> :CHILDCUST_ID ) then
       begin
        if( :EXISTS_CUSTOMERDEBT_AMOUNTPAID > 0 ) then
         begin
          ERROR_NUMBER = 2;
          ERROR_TEXT = cast(('В сумме нельзя менять клиента, т.к. по задолженности производилась оплата.') as varchar(480));

          suspend;
          exit;
         end
       end
     end

    if( :EXISTS_COMPANY_ID <> :COMPANY_ID ) then
     begin
      if( ( :EXISTS_CUSTOMERDEBT_AMOUNTPAID > 0 ) OR ( :EXISTS_PAYMENTS_HISTORY > 0 ) ) then
       begin
        ERROR_NUMBER = 3;
        ERROR_TEXT = cast(('В сумме нельзя менять компанию, т.к. по задолженности производилась оплата.') as varchar(480));

        suspend;
        exit;
       end
     end

    if( :EXISTS_CUSTOMERDEBT_INITIALDEBT <> :CUSTOMERDEBT_INITIALDEBT ) then
     begin
      if( :CUSTOMERDEBT_INITIALDEBT < :EXISTS_CUSTOMERDEBT_AMOUNTPAID ) then
       begin
        ERROR_NUMBER = 4;
        ERROR_TEXT = cast(('Новая сумма задолженности не должна быть меньше оплаты по ней. Новая сумма: ' || cast( :CUSTOMERDEBT_INITIALDEBT as varchar(8)) || ' Оплата: ' || cast( :EXISTS_CUSTOMERDEBT_AMOUNTPAID as varchar(8))) as varchar(480));

        suspend;
        exit;
       end

     end

    update t_customerdebt customerdebt
    set customerdebt.customer_id = :customer_id, customerdebt.company_id = :company_id, customerdebt.childcust_id = :childcust_id,
     customerdebt.customerdebt_srcdoc = :customerdebt_srcdoc, customerdebt.customerdebt_begindate = :customerdebt_begindate,
     customerdebt.customerdebt_initialdebt = :customerdebt_initialdebt
    where customerdebt.customerdebt_id = :customerdebt_id ;

    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. УИ задолженности: ' || cast( :CUSTOMERDEBT_ID as varchar(8))) as varchar(480));

    suspend;

   end


  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось внести изменения в задолженность. Неизвестная ошибка, обратитесь к разработчикам.') as varchar(480));
    suspend;
  end
end
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
 ALTER procedure USP_DELETE_CUSTOMERDEBT_FROMSQL (
    CUSTOMERDEBT_ID integer)
returns (
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable EXISTS_CUSTOMERDEBT_ID integer;
declare variable EXISTS_CUSTOMERDEBT_AMOUNTPAID double precision;
declare variable EXISTS_PAYMENTS_HISTORY integer;
BEGIN
 ERROR_NUMBER = -1;
 ERROR_TEXT = '';

 /*проверка на наличие записи с заданным кодом*/

  EXISTS_CUSTOMERDEBT_ID = NULL;
  EXISTS_CUSTOMERDEBT_AMOUNTPAID = 0;
  EXISTS_PAYMENTS_HISTORY = 0;

  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  select customerdebt.customerdebt_id, customerdebt.customerdebt_amountpaid
  from t_customerdebt customerdebt
  where customerdebt.customerdebt_id = :CUSTOMERDEBT_ID
  into :EXISTS_CUSTOMERDEBT_ID, :EXISTS_CUSTOMERDEBT_AMOUNTPAID;

  if( :EXISTS_CUSTOMERDEBT_ID is null ) then
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast(('Не найдена задолженность с указанным идентификатором: ' || cast( :CUSTOMERDEBT_ID as varchar(8))) as varchar(480));

    suspend;
   end
  else
   begin
    select count( payments.payments_id )
    from t_payments payments
    where payments.payments_srcid = :EXISTS_CUSTOMERDEBT_ID
      and payments.payments_paymentscode = 5
    into :EXISTS_PAYMENTS_HISTORY;

    if( :EXISTS_CUSTOMERDEBT_AMOUNTPAID > 0 ) then
     begin
      ERROR_NUMBER = 2;
      ERROR_TEXT = cast(('Задолженность оплачивалась. Отсторнируйте, пожалуйста, оплаты и повторите операцию. Сумма оплаты: ' || cast( :EXISTS_CUSTOMERDEBT_AMOUNTPAID as varchar(8))) as varchar(480));

      suspend;
      exit;
     end
    else
     begin
      if( :EXISTS_PAYMENTS_HISTORY > 0 ) then
       delete from t_payments payments
       where payments.payments_srcid = :EXISTS_CUSTOMERDEBT_ID
         and payments.payments_paymentscode = 5;

      delete from t_customerdebt customerdebt
      where customerdebt.customerdebt_id = :CUSTOMERDEBT_ID;

      ERROR_NUMBER = 0;
      ERROR_TEXT = cast( ( 'Задолженность удалёна. УИ суммы: ' ) || cast( :CUSTOMERDEBT_ID as varchar(8)) as varchar(480));
      suspend;
     end

   end


 WHEN ANY DO
  BEGIN
   ERROR_NUMBER = -1;
   ERROR_TEXT = 'Не удалось удалить платёж. Неизвестная ошибка, обратитесь к разработчикам.';

   suspend;
  END

END
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
ALTER procedure USP_UNSETTLEINITIALDEBT_FROMSQL (
    CUSTOMERDEBT_ID integer
    )
returns (
    FINDED_MONEY double precision,
    CUSTOMERINITALDEBT_AMOUNTPAID double precision,
    CUSTOMERINITALDEBT_SALDO double precision,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480)
    )
as
 declare variable DEC_AMOUNT double precision;
BEGIN
  ERROR_NUMBER = -1;
  ERROR_TEXT = '';
  FINDED_MONEY = 0;
  DEC_AMOUNT = 0;
  CUSTOMERINITALDEBT_AMOUNTPAID = 0;
  CUSTOMERINITALDEBT_SALDO = 0;

  select customerdebt.customerdebt_amountpaid
  from t_customerdebt  customerdebt
  where customerdebt.customerdebt_id = :CUSTOMERDEBT_ID
  into :DEC_AMOUNT;

  if( :DEC_AMOUNT is null ) then DEC_AMOUNT = 0;

  IF (:DEC_AMOUNT <= 0) THEN
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast( ( 'Сумма Сторно должна быть больше нуля. Сумма к возврату: ' || cast( :DEC_AMOUNT as varchar(16))) as varchar(480));

    suspend;
    EXIT;
   end

  EXECUTE PROCEDURE SP_UNSETTLEINITIALDEBT( :CUSTOMERDEBT_ID )  RETURNING_VALUES :FINDED_MONEY;

  select customerdebt.customerdebt_amountpaid, customerdebt.customerdebt_saldo
  from t_customerdebt  customerdebt
  where customerdebt.customerdebt_id = :CUSTOMERDEBT_ID
  into :CUSTOMERINITALDEBT_AMOUNTPAID, :CUSTOMERINITALDEBT_SALDO;

  if( :FINDED_MONEY > 0 ) then
   begin
    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. Произведено Сторно на сумму: ' || cast( :FINDED_MONEY as varchar(16))) as varchar(480));
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

