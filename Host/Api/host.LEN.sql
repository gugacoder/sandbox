--
-- FUNCTION host.LEN
--
drop function if exists host.LEN  
go
create function host.LEN(@string nvarchar(max))
returns int
as
-- Função LEN melhorada.
--
-- A função LEN do SQLSERVER ignora os últimos espaços de uma string.
-- Portanto, a string 'xx  ' tem o tamanho de 2 caracteres segundo o LEN do SQLSERVER.
-- Esta função, api.LEN, corrige este problema e retorna a quantidade total de caracters.
-- Portanto, a string 'xx  ' tem o tamanho de 4 caracteres segundo a api.LEN.
begin
  return LEN(concat(@string,'-')) -1
end
go
