if object_id('replica.sp_clonar_tabela_mercadologic') is not null
  drop procedure replica.sp_clonar_tabela_mercadologic
go
create procedure replica.sp_clonar_tabela_mercadologic (
    @cod_empresa_mercadologic int
  , @tabela_mercadologic varchar(100)
) as
begin
  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @tabela_replica varchar(100)
  declare @sql nvarchar(max)
  declare @TBcampo table (
    DFnome varchar(100),
    DFtipo varchar(100),
    DFtamanho int,
    DFaceita_nulo bit,
    DFposicao int
  )

  if @tabela_mercadologic like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela_mercadologic, '.', 0)
    set @tabela = replica.SPLIT_PART(@tabela_mercadologic, '.', 1)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  if @esquema = 'public' begin
    set @tabela_replica = concat('mlogic.TBreplica_',@tabela)
  end else begin
    set @tabela_replica = concat('mlogic.TBreplica_',@esquema,'_',@tabela)
  end

  select @sql = '
    select *
      from openrowset(
           '''+DFprovider+'''
         , ''Driver='+DFdriver+';Server='+DFservidor+';Port=5432;Database='+DFdatabase+';Uid='+DFusuario+';Pwd='+DFsenha+';''
         , ''select column_name
                  , data_type
                  , character_maximum_length
                  , case is_nullable when ''''YES'''' then true else false end is_nullable
                  , ordinal_position
               from information_schema.columns
              where table_schema = '''''+@esquema+'''''
                and table_name = '''''+@tabela+''''';''
           ) as t'
    from TBempresa_mercadologic
   where DFcod_empresa = @cod_empresa_mercadologic

  insert into @TBcampo (DFnome, DFtipo, DFtamanho, DFaceita_nulo, DFposicao)
  exec sp_executesql @sql

  ; with TBtipo as (
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
    ) as t(DFtipo_postgres, DFtipo_sqlserver)
  )
  update TBcampo
     set DFtipo = case when TBcampo.DFtamanho is not null
           then concat(TBtipo.DFtipo_sqlserver, '(', TBcampo.DFtamanho, ')') 
           else TBtipo.DFtipo_sqlserver
         end
    from @TBcampo as TBcampo
   inner join TBtipo
           on TBtipo.DFtipo_postgres = TBcampo.DFtipo

  --
  -- Construindo a tabela de replica...
  --
  if object_id(@tabela_replica) is null begin
    set @sql = concat('create table ',@tabela_replica,' (DFcod_empresa_mercadologic int not null)')
    exec sp_executesql @sql
  end

  set @sql = ''
  select @sql = @sql + concat(
        'alter table '
      , @tabela_replica
      , ' add DF'
      , case DFnome when 'id' then concat(DFnome,'_',@tabela) else DFnome end
      , ' '
      , DFtipo
      , ' '
      , case DFaceita_nulo when 1 then '' else 'not null' end
      , '; ',char(13),char(10))
    from @TBcampo as TBcampo
   where not exists (
      select * from sys.columns
       where object_id = object_id(@tabela_replica)
         and name = TBcampo.DFnome
   )
   order by DFposicao

  exec sp_executesql @sql

  raiserror(N'TABELA DE RÉPLICA ATUALIZADA: %s',10,1,@tabela_replica) with nowait
end
go

drop table if exists mlogic.TBreplica_caixa
exec replica.sp_clonar_tabela_mercadologic 7, 'caixa'

select * from  mlogic.TBreplica_caixa
/*
select *
  from openrowset(
      'MSDASQL'
    , 'Driver={PostgreSQL 64-Bit ODBC Drivers};Server=172.27.1.153;Port=5432;Database=DBConcentradorMac7-13.2.0;Uid=postgres;Pwd=local;'
    , '
      select * from pdv
    ') as t


end
go

exec replica.sp_clonar_tabela_mercadologic 'replica.TBevento', '255.255.255.255'

IF NOT EXISTS ( SELECT  * FROM    sys.schemas  WHERE   name = N'app' ) 

    EXEC('CREATE SCHEMA [app] AUTHORIZATION [DBO]');
GO

*/
