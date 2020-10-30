--
-- PROCEDURE replica.clonar_tabelas_monitoradas_mercadologic
--
drop procedure if exists replica.clonar_tabelas_monitoradas_mercadologic
go
create procedure replica.clonar_tabelas_monitoradas_mercadologic (
    @cod_empresa int
	, @provider nvarchar(50) = 'MSDASQL'
	, @driver nvarchar(50) = '{PostgreSQL 64-Bit ODBC Drivers}'
	, @servidor nvarchar(30) = null
	, @porta nvarchar(10) = '5432'
	, @database nvarchar(50) = 'DBMercadologic'
	, @usuario nvarchar(50) = 'postgres'
	, @senha nvarchar(50) = 'local'
) as
begin
  declare @sql nvarchar(max)
  declare @tb_tabela table (
    esquema varchar(100),
    tabela varchar(100)
  )

  set @sql = '
    select *
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select esquema, tabela from replica.vw_tabela_monitorada;''
           ) as t'

--  insert into @tb_tabela (esquema, tabela)
  exec sp_executesql @sql

  --select * from @tb_tabela

  raiserror(N'TABELAS DE REPLICAÇÃO ATUALIZADAS.',10,1) with nowait
end
go

exec replica.clonar_tabelas_monitoradas_mercadologic 7, @servidor='172.27.1.153', @database='DBConcentradorMac7-13.2.0'
