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
  -- CONSTRUINDO A TABELA COM SEUS CAMPOS DE CABEÇALHO
  --
  if object_id(@tabela_replica) is null begin
    set @sql = concat(
      'create table ',@tabela_replica,' (
         id_replica bigint not null identity(1,1) primary key,
         excluido bit not null default (0),
         cod_empresa int not null
       )')
    exec sp_executesql @sql
    raiserror(N'TABELA DE RÉPLICA CRIADA: %s',10,1,@tabela_replica) with nowait
  end

  set @objeto = concat('IX__',replace(@tabela_replica,'.','_'),'__excluido') 
  if not exists (select 1 from sys.indexes where name = @objeto) begin
    set @sql = concat('create index ',@objeto,' on ',@tabela_replica,' (excluido)')
    exec sp_executesql @sql
    raiserror(N'ÍNDICE CRIADO: %s',10,1,@objeto) with nowait
  end

  set @objeto = concat('IX__',replace(@tabela_replica,'.','_'),'__cod_empresa') 
  if not exists (select 1 from sys.indexes where name = @objeto) begin
    set @sql = concat('create index ',@objeto,' on ',@tabela_replica,' (cod_empresa)')
    exec sp_executesql @sql
    raiserror(N'ÍNDICE CRIADO: %s',10,1,@objeto) with nowait
  end

  --
  -- CADASTRANDO UMA VIEW PARA EXIBIR APENAS OS CAMPOS NAO-EXCLUIDOS
  --
  if object_id(@view_replica) is null begin
    set @sql = concat('
      create view ',@view_replica,' as select * from ',@tabela_replica,' where excluido = 0')
    exec sp_executesql @sql
    raiserror(N'VIEW DE RÉPLICA CRIADA: %s',10,1,@view_replica) with nowait
  end

  --
  -- CADASTRANDO UMA VIEW NA BASE DO DIRECTOR
  --
  set @objeto = concat('{ScriptPack.Director}.',@view_replica_director)
  if object_id(@objeto) is null begin
    set @sql = concat('
      use {ScriptPack.Director};
      exec (''
        create view ',@view_replica_director,'
        as select * from {ScriptPack.Mercadologic}.',@tabela_replica,' where excluido = 0
      '')')
    exec sp_executesql @sql
    raiserror(N'VIEW DE RÉPLICA CRIADA NO DBDIRECTOR: %s',10,1,@view_replica_director) with nowait
  end
  
end
go


