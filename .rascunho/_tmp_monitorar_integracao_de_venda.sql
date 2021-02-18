use DBmercadologic;

/*
create index ix__replica_cupomfiscal__dataabertura
    on replica.cupomfiscal (dataabertura)

create index ix__replica_cupomfiscal__id
    on replica.cupomfiscal (id)

create index ix__replica_itemcupomfiscal__idcupomfiscal
    on replica.itemcupomfiscal (idcupomfiscal)
*/

drop procedure if exists replica._tmp_monitorar_integracao_de_venda_por_empresa
go
create procedure replica._tmp_monitorar_integracao_de_venda_por_empresa (
    @cod_empresa int
  , @data_inicial date
  -- Parâmetros opcionais de conectividade.
  -- Se omitidos os parâmetros são lidos da view replica.vw_empresa.
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
    -- min(*) é usado apenas para forçar um registro nulo caso a empresa não exista.
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

  set @sql = '
    select '+convert(varchar(100),@cod_empresa)+' as cod_empresa
         , dia
         , id_cupom
         , id_item_cupom
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select * from (
               select cast(public.cupomfiscal.dataabertura as date) as dia
                    , public.cupomfiscal.id as id_cupom
                    , public.itemcupomfiscal.id as id_item_cupom
                 from public.cupomfiscal
                 left join public.itemcupomfiscal
                        on itemcupomfiscal.idcupomfiscal = public.cupomfiscal.id
                where public.cupomfiscal.dataabertura >= '''''+convert(varchar(100),@data_inicial,120)+'''''
             ) as t;''
         ) as t'

  exec sp_executesql @sql
  
end
go

drop procedure if exists replica._tmp_monitorar_integracao_de_venda
go
create procedure replica._tmp_monitorar_integracao_de_venda (
    @cod_empresas varchar(100) = null
  , @data_inicial date = null
  -- Parâmetros opcionais de conectividade.
  -- Se omitidos os parâmetros são lidos da view replica.vw_empresa.
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
    dia date,
    id_cupom int,
    id_item_cupom int
  )

  -- Elencando as empresas
  if @cod_empresas is not null
    insert into @tb_empresa select valor from api.SPLIT(@cod_empresas,',')
  else
    insert into @tb_empresa select DFcod_empresa from replica.vw_empresa

  -- Corrigindo a data se necessario
  select @data_inicial = cast(coalesce(@data_inicial, min(data), current_timestamp) as date)
    from replica.evento
   where cod_empresa in (select cod_empresa from @tb_empresa)

  select @cod_empresa = min(cod_empresa) from @tb_empresa
  while @cod_empresa is not null begin
    
    insert into @tb_remoto
      exec replica._tmp_monitorar_integracao_de_venda_por_empresa @cod_empresa, @data_inicial
    
    select @cod_empresa = min(cod_empresa) from @tb_empresa where cod_empresa > @cod_empresa
  end

  ; with
  tb_total_remoto as (
    select cod_empresa
         , dia
         , count(distinct id_cupom) as cupom
         , count(distinct id_item_cupom) as item_cupom
      from @tb_remoto
     group by cod_empresa, dia
  ),
  tb_total_local as (
    select replica.cupomfiscal.cod_empresa
         , cast(replica.cupomfiscal.dataabertura as date) as dia
         , count(distinct replica.cupomfiscal.id) as cupom
         , count(distinct replica.itemcupomfiscal.id) as item_cupom
      from replica.cupomfiscal
      left join replica.itemcupomfiscal
             on itemcupomfiscal.idcupomfiscal = replica.cupomfiscal.id
     where replica.cupomfiscal.dataabertura >= @data_inicial
     group by replica.cupomfiscal.cod_empresa
            , cast(replica.cupomfiscal.dataabertura as date)
  ),
  tb_total as (
  select tb_total_local.cod_empresa
       , tb_total_local.dia
       , tb_total_local.cupom as cupom_director
       , tb_total_remoto.cupom as cupom_concentrador
       , tb_total_local.item_cupom as item_cupom_director
       , tb_total_remoto.item_cupom as item_cupom_concentrador
    from tb_total_local
    full join tb_total_remoto
           on tb_total_remoto.cod_empresa = tb_total_local.cod_empresa
          and tb_total_remoto.dia = tb_total_local.dia
  )
  select tb_empresa.cod_empresa
       , tb_total.dia
       , tb_total.cupom_director
       , tb_total.cupom_concentrador
       , tb_total.item_cupom_director
       , tb_total.item_cupom_concentrador
       , cast(case when tb_total.item_cupom_director = tb_total.item_cupom_concentrador
           then 1 else 0
         end as bit) as ok
    from @tb_empresa as tb_empresa
    left join tb_total
           on tb_total.cod_empresa = tb_empresa.cod_empresa
/*
  select @cod_empresa as cod_empresa, 'director' as origem, * from tb_total_local
  union
  select @cod_empresa as cod_empresa, 'concentrador' as origem, * from tb_total_remoto
*/
end
go

exec replica._tmp_monitorar_integracao_de_venda -- '1,4' --@data_inicial='2020-11-20'

