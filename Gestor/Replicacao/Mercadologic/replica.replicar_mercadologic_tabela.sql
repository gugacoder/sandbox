--
-- PROCEDURE replica.replicar_mercadologic_tabela
--
drop procedure if exists replica.replicar_mercadologic_tabela
go
create procedure replica.replicar_mercadologic_tabela (
    @cod_empresa int
  , @tabela_mercadologic varchar(100)
  , @chaves replica.tp_id readonly
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
  if not exists (select 1 from @chaves)
    return

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

  -- variaveis de controle
  declare @status int = -1
  declare @message nvarchar(max)
  declare @severity int
  declare @state int

  --
  -- AJUSTANDO OS NOMES DAS TABELAS DO MERCADOLOGIC E DE REPLICA
  --
  declare @esquema varchar(100)         -- contem o esquema da tabela no mercadologic
  declare @tabela varchar(100)          -- contem o nome da tabela no mercadologic, sem esquema
  declare @esquema_replica varchar(100) -- contem o esquema da tabela de replica
  declare @tabela_replica varchar(100)  -- contem o nome da tabela de replica

  if @tabela_mercadologic like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela_mercadologic, '.', 1)
    set @tabela = replica.SPLIT_PART(@tabela_mercadologic, '.', 2)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
    set @tabela_mercadologic = concat(@esquema,'.',@tabela)
  end

  if @esquema = 'public' begin
    set @esquema_replica = 'replica'
    set @tabela_replica = @tabela
  end else begin
    set @esquema_replica = 'replica'
    set @tabela_replica = concat(@esquema,'_',@tabela)
  end

  raiserror(N'REPLICANDO: %s.%s',10,1,@esquema_replica,@tabela_replica) with nowait

  --
  -- MONTANDO OS NOMES DE CAMPOS E CONVERSOES PARA A CONSULTA DINAMICA
  --
  declare @castings varchar(max) = ''
  declare @selecting varchar(max) = ''
  declare @campo_chave varchar(100)
  declare @valores_chave varchar(max) = ''
  declare @campos varchar(max) = ''
  declare @campos_remotos varchar(max) = ''
  declare @set_campos varchar(max) = ''

  select @valores_chave = concat(@valores_chave,',',id) from @chaves
  -- Removendo a vírgula no início dos campos
  set @valores_chave = substring(@valores_chave,2,len(@valores_chave))

  --
  -- O campo `cod_empresa` não é importado mas sim inserido arbitrariamente.
  -- Os campos antes de `cod_empresa` são considerados campos de cabeçalho da replicação
  -- e por isso são saltados na montagem da SQL dinamica.
  --
  ; with
  todas_as_colunas as (
    select sys.columns.column_id
         , sys.columns.name
         , type_name(sys.columns.user_type_id) as [type]
      from sys.objects
     inner join sys.schemas
             on sys.schemas.schema_id = sys.objects.schema_id
     inner join sys.columns
             on sys.columns.object_id = sys.objects.object_id
     where sys.schemas.name = @esquema_replica
       and sys.objects.name = @tabela_replica
  ),
  colunas as (
    select column_id, name, [type]
      from todas_as_colunas
     where column_id >= (select column_id from todas_as_colunas where name = 'cod_empresa')
  )
  select @castings = case when name != 'cod_empresa' then
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
       , @selecting = case when name != 'cod_empresa' then
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
       , @campo_chave = case when name != 'cod_empresa' then coalesce(@campo_chave, name) end
       , @campos = concat(@campos,',', name)
       , @campos_remotos = concat(@campos_remotos,',',name)
       , @set_campos = concat(@set_campos,',',name,'=tabela_origem.',name)
       -- Determinando o campo chave.
       -- O campo chave é o campo logo depois do `cod_empresa`.
    from colunas
   order by column_id

  -- Removendo a vírgula no início dos campos
  set @castings = substring(@castings,2,len(@castings))
  set @selecting = substring(@selecting,2,len(@selecting))
  set @campos = substring(@campos,2,len(@campos))
  set @campos_remotos = substring(@campos_remotos,2,len(@campos_remotos))
  set @set_campos = substring(@set_campos,2,len(@set_campos))

  --
  -- REPLICANDO OS DADOS DA TABELA
  --
  declare @sql nvarchar(max)
  declare @contador int

  set @sql = concat(
   'select ',@cod_empresa,' as cod_empresa
         , ',@castings,'
      into #tb_registro
      from openrowset(
           ''',@provider,'''
         , ''Driver=',@driver,';Server=',@servidor,';Port=5432;Database=',@database,';Uid=',@usuario,';Pwd=',@senha,';''
         , ''select * from (
               select ',@selecting,'
                 from ',@esquema,'.',@tabela,'
                where ',@campo_chave,' in (',@valores_chave,')
             ) as t;''
           ) as t
    ;
    update ',@esquema_replica,'.',@tabela_replica,'
       set excluido = 1
     where cod_empresa = ',@cod_empresa,'
       and ',@campo_chave,' in (',@valores_chave,')
       and ',@campo_chave,' not in (select ',@campo_chave,' from #tb_registro)
    ;
    merge ',@esquema_replica,'.',@tabela_replica,' as tabela_replica
    using #tb_registro as tabela_origem
       on tabela_replica.cod_empresa = tabela_origem.cod_empresa
      and tabela_replica.',@campo_chave,' = tabela_origem.',@campo_chave,'
     when matched then
          update set ',@set_campos,'
     when not matched then
          insert (',@campos,')
          values (',@campos_remotos,');')

  begin try

    exec @status = sp_executesql @sql
    set @contador = @@rowcount
    
    if @status != 0 begin
      raiserror(N'FALHOU A TENTATIVA DE REPLICAR UM REGISTRO DO CONCENTRADOR NO GESTOR: %s.%s',16,1,
        @esquema_replica,@tabela_replica) with nowait
    end else if @contador = 1 begin
      raiserror(N'1 REGISTRO DO CONCENTRADOR REPLICADO NO GESTOR: %s.%s',10,1,
        @esquema_replica,@tabela_replica) with nowait
    end else begin
      raiserror(N'%d REGISTROS DO CONCENTRADOR REPLICADOS NO GESTOR: %s.%s',10,1,
        @contador,@esquema_replica,@tabela_replica) with nowait
    end

  end try
  begin catch
    set @status = -1
    
    set @message = concat(error_message(),' (linha ',error_line(),')')
    set @severity = error_severity()
    set @state = error_state()
    raiserror (@message, @severity, @state) with nowait

  end catch
  
  return @status
end
go
