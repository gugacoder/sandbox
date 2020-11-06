--
-- SCHEMA mlogic
--
if not exists (select 1 from sys.schemas where name = 'mlogic')
  exec('create schema mlogic')
go
