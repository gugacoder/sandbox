--
-- PROCEDURE replica.replicar_mercadologic_tabela
--
drop procedure if exists replica.replicar_mercadologic_tabela
go
create procedure replica.replicar_mercadologic_tabela (
    @id_evento bigint
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
  declare @cod_empresa int
  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @valor_chave int = null

  select @cod_empresa = cod_empresa
       , @esquema = esquema
       , @tabela = tabela
       , @valor_chave = chave
    from replica.vw_evento with (nolock)
   where id_evento = @id_evento

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

  declare @esquema_replica varchar(100)
  declare @tabela_replica varchar(100)
  declare @campo_chave varchar(100)
  declare @castings varchar(max) = ''
  declare @selecting varchar(max) = ''
  declare @campos varchar(max) = ''
  declare @campos_remotos varchar(max) = ''
  declare @set_campos varchar(max) = ''
  declare @campo_anterior varchar(100)
  declare @sql nvarchar(max)
  declare @status int

  set @esquema_replica = 'replica'
  if @esquema = 'public' begin
    set @tabela_replica = @tabela
  end else begin
    set @tabela_replica = concat(@esquema,'_',@tabela)
  end

  ; with colunas as (
    select sys.columns.column_id
         , sys.columns.name
         , type_name(sys.columns.user_type_id) as [type]
      from sys.objects
     inner join sys.schemas
             on sys.schemas.schema_id = sys.objects.schema_id
     inner join sys.columns
             on sys.columns.object_id = sys.objects.object_id
     where sys.schemas.name = 'replica'
       and sys.objects.name = @tabela_replica
  )
  select @castings = case when column_id > (select column_id from colunas where name = 'historico') then
           concat(@castings,',',
             case [type] when 'xml'
               then concat('concat(',
                 'cast(',name,'_01 as nvarchar(max)),',
                 'cast(',name,'_02 as nvarchar(max)),',
                 'cast(',name,'_03 as nvarchar(max)),',
                 'cast(',name,'_04 as nvarchar(max)),',
                 'cast(',name,'_05 as nvarchar(max)),',
                 'cast(',name,'_06 as nvarchar(max)),',
                 'cast(',name,'_07 as nvarchar(max)),',
                 'cast(',name,'_08 as nvarchar(max)),',
                 'cast(',name,'_09 as nvarchar(max)),',
                 'cast(',name,'_10 as nvarchar(max)),',
                 'cast(',name,'_11 as nvarchar(max)),',
                 'cast(',name,'_12 as nvarchar(max)),',
                 'cast(',name,'_13 as nvarchar(max)),',
                 'cast(',name,'_14 as nvarchar(max)),',
                 'cast(',name,'_15 as nvarchar(max)),',
                 'cast(',name,'_16 as nvarchar(max)),',
                 'cast(',name,'_17 as nvarchar(max)),',
                 'cast(',name,'_18 as nvarchar(max)),',
                 'cast(',name,'_19 as nvarchar(max)),',
                 'cast(',name,'_20 as nvarchar(max))',
               ') as ',name)
               else name
             end
           )
         end
       , @selecting = case when column_id > (select column_id from colunas where name = 'historico') then
           concat(@selecting,',',
             case
               when [type] = 'xml'
                 then concat(
                     'substring(',name,', 0*4000,4000) as ',name,'_01,'
                   , 'substring(',name,', 1*4000,4000) as ',name,'_02,'
                   , 'substring(',name,', 2*4000,4000) as ',name,'_03,'
                   , 'substring(',name,', 3*4000,4000) as ',name,'_04,'
                   , 'substring(',name,', 4*4000,4000) as ',name,'_05,'
                   , 'substring(',name,', 5*4000,4000) as ',name,'_06,'
                   , 'substring(',name,', 6*4000,4000) as ',name,'_07,'
                   , 'substring(',name,', 7*4000,4000) as ',name,'_08,'
                   , 'substring(',name,', 8*4000,4000) as ',name,'_09,'
                   , 'substring(',name,', 9*4000,4000) as ',name,'_10,'
                   , 'substring(',name,',10*4000,4000) as ',name,'_11,'
                   , 'substring(',name,',11*4000,4000) as ',name,'_12,'
                   , 'substring(',name,',12*4000,4000) as ',name,'_13,'
                   , 'substring(',name,',13*4000,4000) as ',name,'_14,'
                   , 'substring(',name,',14*4000,4000) as ',name,'_15,'
                   , 'substring(',name,',15*4000,4000) as ',name,'_16,'
                   , 'substring(',name,',16*4000,4000) as ',name,'_17,'
                   , 'substring(',name,',17*4000,4000) as ',name,'_18,'
                   , 'substring(',name,',18*4000,4000) as ',name,'_19,'
                   , 'substring(',name,',19*4000,4000) as ',name,'_20'
                 )
               when [type] like '%varchar'
                 then concat('cast(',name,' as text)')
               else name
             end
           )
         end
       , @campos = concat(@campos,',', name)
       , @campos_remotos = concat(@campos_remotos,',',name)
       , @set_campos = concat(@set_campos,',',name,'=tabela_remota.',name)
       , @campo_chave = case @campo_anterior
           when 'historico' then name
           else @campo_chave
         end
       , @campo_anterior = name
    from colunas
   order by column_id

  set @castings = substring(@castings,2,len(@castings))
  set @selecting = substring(@selecting,2,len(@selecting))
  set @campos = substring(@campos,2,len(@campos))
  set @campos_remotos = substring(@campos_remotos,2,len(@campos_remotos))
  set @set_campos = substring(@set_campos,2,len(@set_campos))

  raiserror(N'REPLICANDO: %s.%s=%i',10,1,
    @tabela_replica,@campo_chave,@valor_chave) with nowait
      
  set @sql = concat(
   'select ',cast(@id_evento as varchar(100)),' as id_evento
         , ',cast(@cod_empresa as varchar(100)),' as cod_empresa
         , 0 as historico
         , ',@castings,'
      into #tb_registro
      from openrowset(
           ''',@provider,'''
         , ''Driver=',@driver,';Server=',@servidor,';Port=5432;Database=',@database,';Uid=',@usuario,';Pwd=',@senha,';''
         , ''select * from (
               select ',@selecting,'
                 from ',@esquema,'.',@tabela,'
                where ',@campo_chave,' = ',cast(@valor_chave as varchar(100)),'
             ) as t;''
           ) as t
    ;
    update ',@esquema_replica,'.',@tabela_replica,'
       set historico = case when exists (select 1 from #tb_registro)
             then  1  /* registro substituído por um mais novo na origem. */
             else -1  /* registro apagado na origem */
           end
     where cod_empresa = ',cast(@cod_empresa as varchar(100)),'
       and ',@campo_chave,' = ',cast(@valor_chave as varchar(100)),'
    ;
    merge ',@esquema_replica,'.',@tabela_replica,' as tabela
    using #tb_registro as tabela_remota
       on tabela.id_evento = ',cast(@id_evento as varchar(100)),'
     when matched then
          update set ',@set_campos,'
     when not matched by target then
          insert (',@campos,')
          values (',@campos_remotos,');')

  exec @status = sp_executesql @sql
  
  if @status = 0 begin
    raiserror(N'REGISTRO DO CONCENTRADOR REPLICADO NO GESTOR: %s.%s=%i',10,1,
      @tabela_replica,@campo_chave,@valor_chave) with nowait
  end
  
  return @status
end
go
