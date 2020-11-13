--
-- SCHEMA host
--
if not exists (select 1 from sys.schemas where name = 'host')
  exec('create schema [host]')
go
