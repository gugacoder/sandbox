--
-- PROCEDURE replica.criar_cabecalho_tabela_mercadologic
--
drop procedure if exists replica.criar_cabecalho_tabela_mercadologic
go
create procedure replica.criar_cabecalho_tabela_mercadologic (
  @tabela_mercadologic varchar(100),
  @tabela_replica varchar(100) = null output,
  @view_replica varchar(100) = null output,
  @view_replica_director varchar(100) = null output
) as
begin
  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @objeto varchar(100)
  declare @sql nvarchar(max)

  if @tabela_mercadologic like '%.%' begin
    set @esquema = api.SPLIT_PART(@tabela_mercadologic, '.', 1)
    set @tabela = api.SPLIT_PART(@tabela_mercadologic, '.', 2)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  if @esquema = 'public' begin
    set @tabela_replica = concat('replica.',@tabela)
    set @view_replica = concat('replica.vw_',@tabela)
    set @view_replica_director = concat('mlogic.vw_replica_',@tabela)
  end else begin
    set @tabela_replica = concat('replica.',@esquema,'_',@tabela)
    set @view_replica = concat('replica.vw_',@esquema,'_',@tabela)
    set @view_replica_director = concat('mlogic.vw_replica_',@esquema,'_',@tabela)
  end

  --
