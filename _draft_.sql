
--
-- PROCEDURE replica.clonar_tabela_mercadologic
--
if object_id('replica.clonar_tabela_mercadologic') is not null
  drop procedure replica.clonar_tabela_mercadologic
go
create procedure replica.clonar_tabela_mercadologic (
    @cod_empresa int
  , @tabela varchar(100)
	, @provider nvarchar(50) = 'MSDASQL'
	, @driver nvarchar(50) = '{PostgreSQL 64-Bit ODBC Drivers}'
	, @servidor nvarchar(30) = null
	, @porta nvarchar(10) = '5432'
	, @database nvarchar(50) = 'DBMercadologic'
	, @usuario nvarchar(50) = 'postgres'
	, @senha nvarchar(50) = 'local'
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

  if @tabela like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela, '.', 0)
    set @tabela = replica.SPLIT_PART(@tabela, '.', 1)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela
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

  if not exists(select 1 from @tb_campo) begin
    raiserror(N'A TABELA NÃO FOI ENCONTRADA NA BASE DO MERCADOLOGIC: %s.%s',10,1,@esquema,@tabela) with nowait
    return
  end

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

declare @servidor varchar(100), @database varchar(100)
 select @servidor = DFservidor, @database = DFdatabase
   from DBdirector_MAC_29.dbo.TBempresa_mercadologic where DFcod_empresa = 7

--drop table if exists replica.caixa
exec replica.clonar_tabela_mercadologic 7, 'usuario', @servidor, @database

