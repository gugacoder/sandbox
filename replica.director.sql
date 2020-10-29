if not exists (select 1 from sys.schemas where name = 'replica')
  exec('create schema replica')
go

drop table if exists replica.TBtexto
go
create table replica.TBtexto (
  DFcod_empresa int not null,
  DFid_texto int not null,
  DFtexto varchar(max) not null,
  constraint PK_replica_TBtexto
     primary key (DFcod_empresa, DFid_texto)
)
go

drop table if exists replica.TBevento
go
create table replica.TBevento (
  DFcod_empresa int not null,
  DFid_evento int not null,
  DFid_esquema int not null,
  DFid_tabela int not null,
  DFchave int not null,
  DFacao char(1) not null,
  DFdata datetime not null,
  DFversao int not null,
  DFid_origem int not null,
  constraint PK_replica_TBevento
     primary key (DFcod_empresa, DFid_evento)
)
go

drop view if exists replica.vw_evento
go
create view replica.vw_evento as 
select TBevento.DFid_evento
     , TBesquema.DFtexto as DFesquema
     , TBtabela.DFtexto as DFtabela
     , TBevento.DFchave
     , case TBevento.DFacao
         when 'I' then 'INSERT'
         when 'U' then 'UPDATE'
         when 'D' then 'DELETE'
         when 'T' then 'TRUNCATE'
       end as DFacao
     , TBevento.DFdata
     , TBevento.DFversao
     , TBorigem.DFtexto as DForigem
  from replica.TBevento
 inner join replica.TBtexto as TBesquema on TBesquema.DFid_texto = TBevento.DFid_esquema
 inner join replica.TBtexto as TBtabela  on TBtabela .DFid_texto = TBevento.DFid_tabela
 inner join replica.TBtexto as TBorigem  on TBorigem .DFid_texto = TBevento.DFid_origem
go

drop function if exists replica.SPLIT  
go
create function replica.SPLIT(
    @string nvarchar(max)
  , @delimitador char(1))
returns @itens table (DFindice int identity(1,1), DFvalor nvarchar(max))
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
    
    insert into @itens (DFvalor) values (@fracao)

    set @string = right(@string, len(@string) - @indice)
    if len(@string) = 0
      break
  end
  return
end
go

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


select * from replica.vw_evento
