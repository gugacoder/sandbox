--
-- Esquema dos objetos de integração entre bases de dados.
--
if not exists (select 1 from sys.schemas where name = 'ponte')
  exec('create schema ponte')
go

--
-- Esquema de mapeamento dos objetos do DIRECTOR.
--
if not exists (select 1 from sys.schemas where name = 'director')
  exec('create schema director')
go
