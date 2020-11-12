--
-- FUNCTION host.SPLIT
--
drop function if exists host.SPLIT  
go
create function host.SPLIT(
    @string nvarchar(max)
  , @delimitador nvarchar(max)
  )
returns @termos table ([indice] int identity(1,1), [valor] nvarchar(max))
as
begin
  if @string is null return

  declare @indice int = 1
  declare @termo nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @termo = left(@string, @indice - 1)
    else
      set @termo = @string
    
    insert into @termos ([valor]) values (@termo)

    set @string = right(@string, len(@string) - @indice - len(@delimitador) + 1)
    if len(@string) = 0
      break
  end
  return
end
go
