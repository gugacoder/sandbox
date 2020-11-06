--
-- FUNCTION replica.SPLIT_PART
--
drop function if exists replica.SPLIT_PART
go
create function replica.SPLIT_PART(
    @string nvarchar(max)
  , @delimitador char(1)
  , @posicao_desejada int)
returns nvarchar(max)
as
begin
  if @string is null return null

  declare @posicao int = 0
  declare @indice int = 1
  declare @fracao nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @fracao = left(@string, @indice - 1)
    else
      set @fracao = @string
    
    if @posicao = @posicao_desejada
      return @fracao

    set @string = right(@string, len(@string) - @indice)
    if len(@string) = 0
      break

    set @posicao = @posicao + 1
  end
  return null
end
go
