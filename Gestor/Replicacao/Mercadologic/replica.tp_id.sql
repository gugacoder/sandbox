--
-- PROCEDURE replica.tp_id
--
if type_id('[replica].[tp_id]') is null begin
  create type [replica].[tp_id] as table (
    [id] bigint primary key
  )
end
go
