--
-- SCHEMA replica
--
if not exists (select 1 from sys.schemas where name = 'replica')
  exec('create schema replica')
go
