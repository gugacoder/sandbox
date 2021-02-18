--
-- FUNCTION api.SPLIT
--
drop function if exists api.SPLIT  
go
create function api.SPLIT(
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

    if api.LEN(@string) = 0
      break
      
    set @string = right(@string, api.LEN(@string) - @indice - api.LEN(@delimitador) + 1)
  end
  return
end
go
