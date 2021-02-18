drop function if exists [host].[SPLIT]  
go
create function [host].[SPLIT](
    @string nvarchar(max)
  , @delimiter nvarchar(max)
  )
returns @terms table ([index] int identity(1,1), [value] nvarchar(max))
as
begin
  if @string is null return

  declare @index int = 1
  declare @term nvarchar(max)

  while @index != 0
  begin
    set @index = charindex(@delimiter, @string)
    if @index != 0
      set @term = left(@string, @index - 1)
    else
      set @term = @string
    
    insert into @terms ([value]) values (@term)

    if host.LEN(@string) = 0
      break
      
    set @string = right(@string, host.LEN(@string) - @index - host.LEN(@delimiter) + 1)
  end
  return
end
go
