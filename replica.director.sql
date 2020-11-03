/*
  drop table if exists replica.texto
  drop table if exists replica.evento
  drop view if exists replica.vw_evento
  drop function if exists replica.SPLIT
  drop function if exists replica.SPLIT_PART
  drop procedure if exists replica.clonar_tabela_mercadologic
*/

--
-- SCHEMA replica
--
if not exists (select 1 from sys.schemas where name = 'replica')
  exec('create schema replica')
go

--
-- VIEW replica.vw_empresa
--
create or alter view replica.vw_empresa
as 
select * from DBdirector_mac_29.dbo.TBempresa_mercadologic
go

--
-- TABLE replica.texto
--
drop table if exists replica.texto
go
create table replica.texto (
  cod_empresa int not null,
  id int not null,
  texto varchar(max) not null,
  constraint PK_replica_texto
     primary key (cod_empresa, id)
)
go

--
-- TABLE replica.evento
--
drop table if exists replica.evento
go
create table replica.evento (
  cod_empresa int not null,
  id int not null,
  id_esquema int not null,
  id_tabela int not null,
  chave int not null,
  acao char(1) not null,
  data datetime not null,
  versao int not null,
  id_origem int not null,
  constraint PK_replica_evento
     primary key (cod_empresa, id)
)
go

--
-- VIEW replica.vw_evento
--
drop view if exists replica.vw_evento
go
create view replica.vw_evento as 
select evento.cod_empresa
     , evento.id
     , esquema.texto as esquema
     , tabela.texto as tabela
     , evento.chave
     , case evento.acao
         when 'I' then 'INSERT'
         when 'U' then 'UPDATE'
         when 'D' then 'DELETE'
         when 'T' then 'TRUNCATE'
       end as acao
     , evento.data
     , evento.versao
     , origem.texto as origem
  from replica.evento
 inner join replica.texto as esquema on esquema.id = evento.id_esquema
 inner join replica.texto as tabela  on tabela .id = evento.id_tabela
 inner join replica.texto as origem  on origem .id = evento.id_origem
go

--
-- FUNCTION replica.SPLIT
--
drop function if exists replica.SPLIT  
go
create function replica.SPLIT(
    @string nvarchar(max)
  , @delimitador char(1))
returns @itens table (indice int identity(1,1), valor nvarchar(max))
as
begin
  if @string is null return

  declare @indice int = 1
  declare @fracao nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @fracao = left(@string, @indice - 1)
    else
      set @fracao = @string
    
    insert into @itens (valor) values (@fracao)

    set @string = right(@string, len(@string) - @indice)
    if len(@string) = 0
      break
  end
  return
end
go

--
-- FUNCTION replica.SPLIT_PART
--
drop function if exists replica.SPLIT_PART  
go
create function replica.SPLIT_PART(
    @string nvarchar(max)
  , @delimitador char(1)
  , @posicao_desejada int)
returns nvarchar(max)
as
begin
  if @string is null return null

  declare @posicao int = 0
  declare @indice int = 1
  declare @fracao nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @fracao = left(@string, @indice - 1)
    else
      set @fracao = @string
    
    if @posicao = @posicao_desejada
      return @fracao

    set @string = right(@string, len(@string) - @indice)
    if len(@string) = 0
      break

    set @posicao = @posicao + 1
  end
  return null
end
go

--
-- PROCEDURE replica.clonar_tabela_mercadologic
--
drop procedure if exists replica.clonar_tabela_mercadologic
go
create procedure replica.clonar_tabela_mercadologic (
    @cod_empresa int
  , @tabela_mercadologic varchar(100)
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
  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @tabela_replica varchar(100)
  declare @sql nvarchar(max)
  declare @tb_campo table (
    nome varchar(100),
    tipo_pgsql varchar(100),
    tipo_mssql varchar(100),
    tamanho int,
    aceita_nulo bit,
    posicao int
  )

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

  if @tabela_mercadologic like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela_mercadologic, '.', 0)
    set @tabela = replica.SPLIT_PART(@tabela_mercadologic, '.', 1)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  if @esquema = 'public' begin
    set @tabela_replica = concat('replica.',@tabela)
  end else begin
    set @tabela_replica = concat('replica.',@esquema,'_',@tabela)
  end

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
     set tipo_mssql = case when campo.tamanho is not null
           then concat(tipo.tipo_sqlserver, '(', campo.tamanho, ')') 
           else tipo.tipo_sqlserver
         end
    from @tb_campo as campo
   inner join tipo
           on tipo.tipo_postgres = campo.tipo_pgsql

  --
  -- Construindo a tabela de replica...
  --
  if object_id(@tabela_replica) is null begin
    set @sql = concat('create table ',@tabela_replica,' (cod_empresa int not null)')
    exec sp_executesql @sql
  end

  set @sql = ''
  select @sql = @sql + concat(
        'alter table ', @tabela_replica
      , ' add ', nome, ' ', tipo_mssql, ' ', (case aceita_nulo when 1 then '' else 'not null ' end)
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

  raiserror(N'TABELA DE RÉPLICA ATUALIZADA: %s',10,1,@tabela_replica) with nowait
end
go
