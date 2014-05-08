/*------   ------*/

SET TERM ~~~ ;
 ALTER procedure SP_ADD_CEARNING_FROMSQL (
    CEARNING_CODE integer,
    CHILDCUST_ID integer,
    CUSTOMER_ID integer,
    CURRENCY_CODE char(3),
    CEARNING_DATE date,
    CEARNING_VALUE double precision,
    CEARNING_EXPENSE double precision,
    CEARNING_USDVALUE double precision,
    CEARNING_MODE integer,
    CEARNING_CURRENCYRATE double precision,
    CEARNING_CURRENCYVALUE double precision,
    CEARNING_COMISPERCENT double precision,
    COMPANY_ID integer)
returns (
    CEARNING_ID integer,
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
 declare variable NEW_CEARNING_ID integer;
 declare variable MAIN_CURRENCY_CODE char(3); /* код валюты учета */
 declare variable RECALC_CURRENCY_CODE char(3);
 declare variable RECALC_CEARNING_VALUE double precision;
 declare variable RECALC_CEARNING_CURRENCYRATE double precision;
 declare variable RECALC_CEARNING_CURRENCYVALUE double precision;
begin
  CEARNING_ID = null;

  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  RECALC_CEARNING_VALUE = :CEARNING_VALUE;
  RECALC_CEARNING_CURRENCYRATE = :CEARNING_CURRENCYRATE;
  RECALC_CEARNING_CURRENCYVALUE = :CEARNING_CURRENCYVALUE;
  RECALC_CURRENCY_CODE = :CURRENCY_CODE;

  select CURRENCY_CODE from  SP_GETCURRENCYCODEMAIN( :CEARNING_DATE ) into :MAIN_CURRENCY_CODE;
  if( :CURRENCY_CODE <> :MAIN_CURRENCY_CODE ) then
   begin
    RECALC_CEARNING_VALUE = ( :CEARNING_VALUE / :CEARNING_CURRENCYRATE );
    RECALC_CEARNING_CURRENCYRATE = 1;
    RECALC_CEARNING_CURRENCYVALUE = :RECALC_CEARNING_VALUE;
    RECALC_CURRENCY_CODE = :MAIN_CURRENCY_CODE;
   end

  /*добавляем запись в таблицу T_CEarning*/
  select cearning_id from sp_getcearningid into :new_cearning_id;

  insert into t_cearning( CEARNING_ID, CEARNING_CODE, CHILDCUST_ID, CUSTOMER_ID,
    CURRENCY_CODE, CEARNING_DATE, CEARNING_VALUE,
    CEARNING_EXPENSE, CEARNING_USDVALUE, CEARNING_MODE, CEARNING_CURRENCYRATE,
    CEARNING_CURRENCYVALUE, CEARNING_COMISPERCENT, COMPANY_ID )
  values( :new_cearning_id, :CEARNING_CODE, :CHILDCUST_ID, :CUSTOMER_ID,
    :RECALC_CURRENCY_CODE, :CEARNING_DATE, :RECALC_CEARNING_VALUE,
    :CEARNING_EXPENSE, :CEARNING_USDVALUE, :CEARNING_MODE, :RECALC_CEARNING_CURRENCYRATE,
    :RECALC_CEARNING_CURRENCYVALUE, :CEARNING_COMISPERCENT, :COMPANY_ID );

  CEARNING_ID = :new_cearning_id;
  ERROR_NUMBER = 0;
  ERROR_TEXT = cast(('Успешное завершение операции. Идентификатор платежа: ' || cast( :CEARNING_ID as varchar(8))) as varchar(480));
  suspend;

  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось зарегистрировать платёж. Неизвестная ошибка, т.к не удается вернуть SQLCODE.') as varchar(480));
    suspend;
  end
end
 ~~~
SET TERM ; ~~~
commit work;

/*------   ------*/

SET TERM ~~~ ;
 ALTER procedure SP_EDIT_CEARNING_FROMSQL (
    CEARNING_ID integer,
    CEARNING_CODE integer,
    CHILDCUST_ID integer,
    CUSTOMER_ID integer,
    CURRENCY_CODE char(3),
    CEARNING_DATE date,
    CEARNING_VALUE double precision,
    CEARNING_EXPENSE double precision,
    CEARNING_USDVALUE double precision,
    CEARNING_MODE integer,
    CEARNING_CURRENCYRATE double precision,
    CEARNING_CURRENCYVALUE double precision,
    CEARNING_COMISPERCENT double precision,
    COMPANY_ID integer)
returns (
    ERROR_NUMBER integer,
    ERROR_TEXT varchar(480))
as
declare variable EXISTS_CEARNING_ID integer;
declare variable EXISTS_CUSTOMER_ID integer;
declare variable EXISTS_CHILDCUST_ID integer;
declare variable EXISTS_CEARNING_EXPENSE double precision;
declare variable EXISTS_CEARNING_VALUE double precision;
declare variable EXISTS_PAYMENTS_HISTORY integer;

 declare variable MAIN_CURRENCY_CODE char(3); /* код валюты учета */
 declare variable RECALC_CURRENCY_CODE char(3);
 declare variable RECALC_CEARNING_VALUE double precision;
 declare variable RECALC_CEARNING_CURRENCYRATE double precision;
 declare variable RECALC_CEARNING_CURRENCYVALUE double precision;

begin

  EXISTS_CEARNING_ID = NULL;
  EXISTS_CUSTOMER_ID = NULL;
  EXISTS_CHILDCUST_ID = NULL;
  EXISTS_CEARNING_EXPENSE = 0;
  EXISTS_CEARNING_VALUE = 0;
  EXISTS_PAYMENTS_HISTORY = 0;

  ERROR_NUMBER = -1;
  ERROR_TEXT = '';

  RECALC_CEARNING_VALUE = :CEARNING_VALUE;
  RECALC_CEARNING_CURRENCYRATE = :CEARNING_CURRENCYRATE;
  RECALC_CEARNING_CURRENCYVALUE = :CEARNING_CURRENCYVALUE;
  RECALC_CURRENCY_CODE = :CURRENCY_CODE;

  select CURRENCY_CODE from  SP_GETCURRENCYCODEMAIN( :CEARNING_DATE ) into :MAIN_CURRENCY_CODE;

  if( :CURRENCY_CODE <> :MAIN_CURRENCY_CODE ) then
   begin
    RECALC_CEARNING_VALUE = ( :CEARNING_VALUE / :CEARNING_CURRENCYRATE );
    RECALC_CEARNING_CURRENCYRATE = 1;
    RECALC_CEARNING_CURRENCYVALUE = :RECALC_CEARNING_VALUE;
    RECALC_CURRENCY_CODE = :MAIN_CURRENCY_CODE;
   end

  select cearning.cearning_id, cearning.childcust_id, cearning.customer_id, cearning.cearning_expense, cearning.cearning_value
  from t_cearning cearning
  where cearning.cearning_id = :CEARNING_ID
  into :EXISTS_CEARNING_ID, :EXISTS_CHILDCUST_ID, :EXISTS_CUSTOMER_ID, :EXISTS_CEARNING_EXPENSE, :EXISTS_CEARNING_VALUE;

  if( :EXISTS_CEARNING_ID is null ) then
   begin
    ERROR_NUMBER = 1;
    ERROR_TEXT = cast(('Не найден платёж с указанным идентификатором: ' || cast( :CEARNING_ID as varchar(8))) as varchar(480));

    suspend;
   end
  else
   begin

    select count( payments.payments_id )
    from t_payments payments
    where payments.cearning_id = :EXISTS_CEARNING_ID
    into :EXISTS_PAYMENTS_HISTORY;

    if( :EXISTS_CHILDCUST_ID <> :CHILDCUST_ID ) then
     begin
      if( ( :EXISTS_CEARNING_EXPENSE > 0 ) OR ( :EXISTS_PAYMENTS_HISTORY > 0 ) ) then
       begin
        ERROR_NUMBER = 2;
        ERROR_TEXT = cast(('В платеже нельзя менять дочернего клиента, т.к. сумма разносилась по долгам.') as varchar(480));

        suspend;
        exit;
       end
     end

    if( :EXISTS_CEARNING_VALUE <> :CEARNING_VALUE ) then
     begin
      if( :CEARNING_VALUE < :EXISTS_CEARNING_EXPENSE ) then
       begin
        ERROR_NUMBER = 4;
        ERROR_TEXT = cast(('Новая сумма платежа не должна быть меньше его расхода. Новая сумма: ' || cast( :CEARNING_VALUE as varchar(8)) || ' Расход: ' || cast( :EXISTS_CEARNING_EXPENSE as varchar(8))) as varchar(480));

        suspend;
        exit;
       end

     end

    update t_cearning cearning
    set cearning.childcust_id = :childcust_id, cearning.customer_id = :customer_id,
     cearning.currency_code = :RECALC_CURRENCY_CODE, cearning.cearning_date = :cearning_date,
     cearning.cearning_value = :RECALC_CEARNING_VALUE, cearning.cearning_usdvalue = :cearning_usdvalue,
     cearning.cearning_mode = :cearning_mode, cearning.cearning_currencyrate = :RECALC_CEARNING_CURRENCYRATE,
     cearning.cearning_currencyvalue = :RECALC_CEARNING_CURRENCYVALUE, cearning.cearning_comispercent = :cearning_comispercent
    where cearning.cearning_id = :cearning_id;

    ERROR_NUMBER = 0;
    ERROR_TEXT = cast(('Успешное завершение операции. УИ платежа: ' || cast( :CEARNING_ID as varchar(8))) as varchar(480));

    suspend;

   end


  when any do
  begin
    ERROR_NUMBER = -1;
    ERROR_TEXT = cast((:ERROR_TEXT || ' Не удалось внести изменения в платёж. Неизвестная ошибка, обратитесь к разработчикам.') as varchar(480));
    suspend;
  end
end
 ~~~
SET TERM ; ~~~
commit work;





