--
-- VIEW mlogic.fn_base_mercadologic
--
if object_id('mlogic.fn_base_mercadologic') is null begin
  exec sp_executesql N'
    create function mlogic.fn_base_mercadologic ()
    returns varchar(100)
    as begin
      return ''{ScriptPack.Mercadologic}''
    end'
end else begin
  exec sp_executesql N'
    alter function mlogic.fn_base_mercadologic ()
    returns varchar(100)
    as begin
      return ''{ScriptPack.Mercadologic}''
    end'
end
go
