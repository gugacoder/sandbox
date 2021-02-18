--
-- Esquema de mapeamento dos objetos do DIRECTOR.
--
if not exists (select 1 from sys.schemas where name = 'api')
  exec('create schema api')
go
