--
-- SCHEMA rascunho
--
if not exists (select 1 from sys.schemas where name = 'rascunho')
  exec('create schema rascunho')
go


select top 0 * 
into rascunho.TBvenda_diaria
from TBvenda_diaria
