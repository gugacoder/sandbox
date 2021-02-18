--
-- PROCEDURE replica.clonar_tabela_mercadologic
--
drop procedure if exists replica.clonar_tabela_mercadologic
go
create procedure replica.clonar_tabela_mercadologic (
    @cod_empresa int
  , @tabela_mercadologic varchar(100)
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

  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @tabela_replica varchar(100)
  declare @view_replica varchar(100)
  declare @view_replica_director varchar(100)
  declare @sql nvarchar(max)
  declare @tb_campo table (
    nome varchar(100),
    tipo_pgsql varchar(100),
    tipo_mssql varchar(100),
    tamanho int,
    aceita_nulo bit,
    posicao int
  )

  if @tabela_mercadologic like '%.%' begin
    set @esquema = api.SPLIT_PART(@tabela_mercadologic, '.', 1)
    set @tabela = api.SPLIT_PART(@tabela_mercadologic, '.', 2)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  --
  -- CONSTRUINDO A TABELA DE REPLICA SE NECESSARIO
  --
  exec replica.criar_cabecalho_tabela_mercadologic
    @tabela_mercadologic,
    @tabela_replica output,
    @view_replica output,
    @view_replica_director output

  --
  -- OBTENDO OS CAMPOS DA TABELA NO MERCADOLOGIC
  --
  set @sql = '
    select *
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select column_name
                  , data_type
                  , character_maximum_length
                  , case is_nullable when ''''YES'''' then true else false end is_nullable
                  , ordinal_position
               from information_schema.columns
              where table_schema = '''''+@esquema+'''''
                and table_name = '''''+@tabela+''''';''
           ) as t'

  insert into @tb_campo (nome, tipo_pgsql, tamanho, aceita_nulo, posicao)
    exec sp_executesql @sql

  ; with tipo as (
    select * from ( values 
      ('boolean', 'bit'),
      ('timestamp', 'datetime'),
      ('timestamp without time zone', 'datetime'),
      ('date', 'date'),
      ('time', 'time'),
      ('character varying', 'nvarchar'),
      ('varchar', 'nvarchar'),
      ('character', 'char'),
      ('char', 'char'),
      ('text', 'nvarchar'),
      ('money', 'decimal'),
      ('smallint', 'smallint'),
      ('integer', 'int'),
      ('bigint', 'bigint'),
      ('decimal', 'decimal(18,4)'),
      ('numeric', 'decimal(18,4)'),
      ('real', 'decimal(18,4)'),
      ('double precision', 'decimal(18,4)'),
      ('serial', 'int'),
      ('bigserial', 'bigint')
    ) as t(tipo_postgres, tipo_sqlserver)
  )
  update campo
     set tipo_mssql =
         case
           when campo.nome like 'xml[_]%'
             then 'xml'
           when tipo.tipo_sqlserver like '%varchar'
             then concat(tipo.tipo_sqlserver, '(max)') 
           when campo.tamanho is not null
             then concat(tipo.tipo_sqlserver, '(', campo.tamanho, ')') 
           else tipo.tipo_sqlserver
         end
    from @tb_campo as campo
   inner join tipo
           on tipo.tipo_postgres = campo.tipo_pgsql

  --
  -- ACRESCENTANDO OS CAMPOS DA TABELA DE REPLICA
  -- Com base nos campos obtidos da tabela no Mercadologic.
  --
  set @sql = ''
  select @sql = @sql + concat(
        'alter table ', @tabela_replica
      , ' add ', nome, ' ', tipo_mssql, ' null '
      , ';')
    from @tb_campo as campo
   where nome != 'cod_empresa'
     and not exists (
      select * from sys.columns
       where object_id = object_id(@tabela_replica)
         and name = campo.nome
   )
   order by posicao

  exec sp_executesql @sql
  raiserror(N'TABELA DE R�PLICA CLONADA: %s',10,1,@tabela_replica) with nowait

  --
  -- ATUALIZANDO A ESTRUTURA DAS VIEWS
  --
  exec sp_refreshview @view_replica

  set @sql = concat('use {ScriptPack.Director}; exec sp_refreshview ''',@view_replica_director,'''')
  exec (@sql)

end
go
