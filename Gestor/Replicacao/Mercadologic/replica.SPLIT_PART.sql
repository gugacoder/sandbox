--
-- FUNCTION replica.SPLIT_PART
--
drop function if exists replica.SPLIT_PART
go
create function replica.SPLIT_PART(
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

    set @string = right(@string, len(@string) - @indice - len(@delimitador) + 1)
    if len(@string) = 0
      break

    set @posicao = @posicao + 1
  end
  return null
end
go
