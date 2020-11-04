--
-- FUNCTION replica.SPLIT
--
drop function if exists replica.SPLIT  
go
create function replica.SPLIT(
    @string nvarchar(max)
  , @delimitador char(1))
returns @itens table (indice int identity(1,1), valor nvarchar(max))
as
begin
  if @string is null return

  declare @indice int = 1
  declare @fracao nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @fracao = left(@string, @indice - 1)
    else
      set @fracao = @string
    
    insert into @itens (valor) values (@fracao)

    set @string = right(@string, len(@string) - @indice)
    if len(@string) = 0
      break
  end
  return
end
go
