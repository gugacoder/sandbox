drop function if exists [host].[SPLIT_PART]
go
create function [host].[SPLIT_PART](
    @string nvarchar(max)
  , @delimiter nvarchar(max)
  , @wanted_position int)
returns nvarchar(max)
as
begin
  if @string is null return null

  declare @position int = 1
  declare @index int = 1
  declare @term nvarchar(max)

  while @index != 0
  begin
    set @index = charindex(@delimiter, @string)
    if @index != 0
      set @term = left(@string, @index - 1)
    else
      set @term = @string
    
    if @position = @wanted_position
      return @term

    set @string = right(@string, len(@string) - @index - len(@delimiter) + 1)
    if len(@string) = 0
      break

    set @position = @position + 1
  end
  return null
end
go
