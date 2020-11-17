--
-- PROCEDURE dbo.monitorar_integracao
--

/*
create index ix__replica_cupomfiscal__dataabertura
    on replica.cupomfiscal (dataabertura)

create index ix__replica_cupomfiscal__id
    on replica.cupomfiscal (id)

create index ix__replica_itemcupomfiscal__idcupomfiscal
    on replica.itemcupomfiscal (idcupomfiscal)
*/

drop procedure if exists dbo.monitorar_integracao_empresa
go
create procedure dbo.monitorar_integracao_empresa (
    @cod_empresa int
  , @data_inicial date = null
  -- Par�metros opcionais de conectividade.
  -- Se omitidos os par�metros s�o lidos da view replica.vw_empresa.
  , @provider nvarchar(50) = null
  , @driver nvarchar(50) = null
  , @servidor nvarchar(30) = null
  , @porta nvarchar(10) = null
  , @database nvarchar(50) = null
  , @usuario nvarchar(50) = null
  , @senha nvarchar(50) = null
) as
begin
  if @provider is null
  or @driver   is null
  or @servidor is null
  or @porta    is null
  or @database is null
  or @usuario  is null
  or @senha    is null
  begin
    -- min(*) � usado apenas para for�ar um registro nulo caso a empresa n�o exista.
    select @provider = coalesce(@provider, min(DFprovider), 'MSDASQL')
         , @driver   = coalesce(@driver  , min(DFdriver)  , '{PostgreSQL 64-Bit ODBC Drivers}')
         , @servidor = coalesce(@servidor, min(DFservidor))
         , @porta    = coalesce(@porta   , min(DFporta)   , '5432')
         , @database = coalesce(@database, min(DFdatabase), 'DBMercadologic')
         , @usuario  = coalesce(@usuario , min(DFusuario) , 'postgres')
         , @senha    = coalesce(@senha   , min(DFsenha)   , 'local')
      from replica.vw_empresa
     where DFcod_empresa = @cod_empresa
  end

  declare @sql nvarchar(max)

  set @data_inicial = cast(coalesce(@data_inicial, current_timestamp) as date)

  set @sql = '
    select '+convert(varchar(100),@cod_empresa)+' as cod_empresa
         , id_cupom
         , id_item_cupom
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select public.cupomfiscal.id as id_cupom
                  , public.itemcupomfiscal.id as id_item_cupom
               from public.cupomfiscal
               left join public.itemcupomfiscal
                      on itemcupomfiscal.idcupomfiscal = public.cupomfiscal.id
              where public.cupomfiscal.dataabertura >= '''''+convert(varchar(100),@data_inicial,120)+''''';''
         ) as t'

  exec sp_executesql @sql
  
end
go

drop procedure if exists dbo.monitorar_integracao
go
create procedure dbo.monitorar_integracao (
    @cod_empresas varchar(100) = null
  , @data_inicial date = null
  -- Par�metros opcionais de conectividade.
  -- Se omitidos os par�metros s�o lidos da view replica.vw_empresa.
  , @provider nvarchar(50) = null
  , @driver nvarchar(50) = null
  , @servidor nvarchar(30) = null
  , @porta nvarchar(10) = null
  , @database nvarchar(50) = null
  , @usuario nvarchar(50) = null
  , @senha nvarchar(50) = null
) as
begin
  declare @tb_empresa table (cod_empresa int)
  declare @cod_empresa int
  declare @tb_remoto table (
    cod_empresa int,
    id_cupom int,
    id_item_cupom int
  )

  if @cod_empresas is not null
    insert into @tb_empresa select valor from replica.SPLIT(@cod_empresas,',')
  else
    insert into @tb_empresa select DFcod_empresa from replica.vw_empresa

  select @cod_empresa = min(cod_empresa) from @tb_empresa
  while @cod_empresa is not null begin
    
    insert into @tb_remoto
      exec dbo.monitorar_integracao_empresa @cod_empresa
    
    select @cod_empresa = min(cod_empresa) from @tb_empresa where cod_empresa > @cod_empresa
  end

  ; with
  tb_total_remoto as (
    select count(distinct id_cupom) as cupom
         , count(distinct id_item_cupom) as item_cupom
      from @tb_remoto
  ),
  tb_total_local as (
    select count(distinct replica.cupomfiscal.id) as cupom
         , count(distinct replica.itemcupomfiscal.id) as item_cupom
      from replica.cupomfiscal
      left join replica.itemcupomfiscal
             on itemcupomfiscal.idcupomfiscal = replica.cupomfiscal.id
     where replica.cupomfiscal.dataabertura >= cast(current_timestamp as date)
  )
  select @cod_empresa as cod_empresa, 'director' as origem, * from tb_total_local
  union
  select @cod_empresa as cod_empresa, 'concentrador' as origem, * from tb_total_remoto

end
go

exec dbo.monitorar_integracao '4'

/*

  ; with
  tb_total_remoto as (
    select count(distinct id_cupom) as cupom
         , count(distinct id_item_cupom) as item_cupom
      from @tb_remoto
  ),
  tb_total_local as (
    select count(distinct replica.cupomfiscal.id) as cupom
         , count(distinct replica.itemcupomfiscal.id) as item_cupom
      from replica.cupomfiscal
      left join replica.itemcupomfiscal
             on itemcupomfiscal.idcupomfiscal = replica.cupomfiscal.id
     where replica.cupomfiscal.dataabertura >= cast(current_timestamp as date)
  )
  select @cod_empresa as cod_empresa, 'director' as origem, * from tb_total_local
  union
  select @cod_empresa as cod_empresa, 'concentrador' as origem, * from tb_total_remoto
  */
