--
-- FUNCTION api.SPLIT_PART
--
drop function if exists api.SPLIT_PART
go
create function api.SPLIT_PART(
    @string nvarchar(max)
  , @delimitador nvarchar(max)
  , @posicao_do_termo_desejado int)
returns nvarchar(max)
as
begin
  if @string is null return null

  declare @posicao int = 1
  declare @indice int = 1
  declare @termo nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @termo = left(@string, @indice - 1)
    else
      set @termo = @string
    
    if @posicao = @posicao_do_termo_desejado
      return @termo

    if api.LEN(@string) = 0
      break

    set @string = right(@string, api.LEN(@string) - @indice - api.LEN(@delimitador) + 1)
    set @posicao = @posicao + 1
  end
  return null
end
go
