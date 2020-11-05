--
-- PROCEDURE replica.replicar_tabela_mercadologic
--
drop procedure if exists replica.replicar_tabela_mercadologic
go
create procedure replica.replicar_tabela_mercadologic (
    @cod_empresa int
  , @tabela_mercadologic varchar(100)
  , @chave_tabela_mercadologic int
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

  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @esquema_replica varchar(100)
  declare @tabela_replica varchar(100)
  declare @campo_id varchar(100)
  declare @campos varchar(1000) = ''
  declare @campos_remotos varchar(1000) = ''
  declare @set_campos varchar(1000) = ''
  declare @sql nvarchar(max)

  if @tabela_mercadologic like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela_mercadologic, '.', 0)
    set @tabela = replica.SPLIT_PART(@tabela_mercadologic, '.', 1)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  set @esquema_replica = 'replica'
  if @esquema = 'public' begin
    set @tabela_replica = @tabela
  end else begin
    set @tabela_replica = concat(@esquema,'_',@tabela)
  end

  select @campo_id = coalesce(min(sys.columns.name), 'id...')
    from sys.objects
   inner join sys.schemas
           on sys.schemas.schema_id = sys.objects.schema_id
   inner join sys.columns
           on sys.columns.object_id = sys.objects.object_id
          and sys.columns.column_id = 2
   where sys.schemas.name = 'replica'
     and sys.objects.name = @tabela_replica

  select @campos = concat(@campos,',',sys.columns.name)
       , @campos_remotos = concat(@campos_remotos,',tabela_remota.',sys.columns.name)
       , @set_campos = concat(@set_campos,',',sys.columns.name,'=tabela_remota.',sys.columns.name)
    from sys.objects
   inner join sys.schemas
           on sys.schemas.schema_id = sys.objects.schema_id
   inner join sys.columns
           on sys.columns.object_id = sys.objects.object_id
   where sys.schemas.name = 'replica'
     and sys.objects.name = @tabela_replica
   order by sys.columns.column_id

  set @campos = substring(@campos,2,len(@campos))
  set @campos_remotos = substring(@campos_remotos,2,len(@campos_remotos))
  set @set_campos = substring(@set_campos,2,len(@set_campos))

  set @sql = '
    with tabela_remota as (
      select '+cast(@cod_empresa as varchar(100))+' as cod_empresa
           , *
        from openrowset(
             '''+@provider+'''
           , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
           , ''select *
                 from '+@esquema+'.'+@tabela+'
                where '+@campo_id+' = '+cast(@chave_tabela_mercadologic as varchar(100))+';''
             ) as t
    )
    merge '+@esquema_replica+'.'+@tabela_replica+' as tabela
    using tabela_remota
       on tabela_remota.cod_empresa = tabela.cod_empresa
      and tabela_remota.'+@campo_id+' = tabela.'+@campo_id+'
     when matched then
          update set '+@set_campos+'
     when not matched by target then
          insert ('+@campos+')
          values ('+@campos_remotos+');'
  
  exec sp_executesql @sql

  raiserror(N'REGISTRO DO CONCENTRADOR REPLICADO NO GESTOR: %s.%s=%i',10,1,
    @tabela_replica,@campo_id,@chave_tabela_mercadologic) with nowait
end
go

exec replica.replicar_tabela_mercadologic 7, 'cupomfiscal', 517057






