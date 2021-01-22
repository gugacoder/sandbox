--
-- SCHEMA rascunho
--
if not exists (select 1 from sys.schemas where name = 'rascunho')
  exec('create schema rascunho')
go
