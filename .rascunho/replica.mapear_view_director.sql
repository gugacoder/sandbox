
drop procedure if exists replica.mapear_view_director
go
create procedure replica.mapear_view_director (
    @cod_empresa int
  , @tabela_mercadologic varchar(100)
) as
begin
  declare @DBdirector varchar(100) = '{ScriptPack.Director}'
  declare @DBmercadologic varchar(100) = '{ScriptPack.Mercadologic}'
  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @tabela_replica varchar(100)
  declare @view_replica varchar(100)
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
    set @view_replica = concat('mlogic.vw_replica_',@tabela)
  end else begin
    set @tabela_replica = concat('replica.',@esquema,'_',@tabela)
    set @view_replica = concat('mlogic.vw_replica_',@esquema,'_',@tabela)
  end

  if object_id(@DBdirector+'.'+@view_replica) is null begin
    set @sql = '
      use '+@DBdirector+'
      exec sp_executesql N''
        create view '+@view_replica+'
        as select * from '+@DBmercadologic+'.'+@tabela_replica+' where tp_evento != ''D'''''
    exec sp_executesql @sql
    raiserror(N'VIEW DE R�PLICA CRIADA: %s.%s',10,1,@DBdirector,@view_replica) with nowait
  end

end
go
exec replica.mapear_view_director  5, 'cupomfiscal'