--
-- PROCEDURE replica.replicar_mercadologic_tabela
--
drop procedure if exists replica.replicar_mercadologic_tabela
go
create procedure replica.replicar_mercadologic_tabela (
    @cod_empresa int
  , @id_evento bigint
  , @tabela_mercadologic varchar(100)
  , @chave_tabela_mercadologic int
  -- Par�metros opcionais de conectividade.
  -- Se omitidos os par�metros s�o lidos da view replica.vw_empresa.
  , @provider nvarchar(50) = null
  , @driver nvarchar(50) = null
  , @servidor nvarchar(30) = null
  , @porta nvarchar(10) = null
  , @database nvarchar(50) = null
  , @usuario nvarchar(50) = null
  , @senha nvarchar(50) = null
) as
begin
  if @provider is null
  or @driver   is null
  or @servidor is null
  or @porta    is null
  or @database is null
  or @usuario  is null
  or @senha    is null
  begin
    -- min(*) � usado apenas para for�ar um registro nulo caso a empresa n�o exista.
    select @provider = coalesce(@provider, min(DFprovider), 'MSDASQL')
         , @driver   = coalesce(@driver  , min(DFdriver)  , '{PostgreSQL 64-Bit ODBC Drivers}')
         , @servidor = coalesce(@servidor, min(DFservidor))
         , @porta    = coalesce(@porta   , min(DFporta)   , '5432')
         , @database = coalesce(@database, min(DFdatabase), 'DBMercadologic')
         , @usuario  = coalesce(@usuario , min(DFusuario) , 'postgres')
         , @senha    = coalesce(@senha   , min(DFsenha)   , 'local')
      from replica.vw_empresa
     where DFcod_empresa = @cod_empresa
  end

  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @esquema_replica varchar(100)
  declare @tabela_replica varchar(100)
  declare @campo_chave varchar(100)
  declare @campos varchar(max) = ''
  declare @campos_remotos varchar(max) = ''
  declare @set_campos varchar(max) = ''
  declare @campo_anterior varchar(100)
  declare @sql nvarchar(max)
  declare @status int

  if @tabela_mercadologic like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela_mercadologic, '.', 0)
    set @tabela = replica.SPLIT_PART(@tabela_mercadologic, '.', 1)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  set @esquema_replica = 'replica'
  if @esquema = 'public' begin
    set @tabela_replica = @tabela
  end else begin
    set @tabela_replica = concat(@esquema,'_',@tabela)
  end

  ; with colunas as (
    select sys.columns.column_id
         , sys.columns.name
      from sys.objects
     inner join sys.schemas
             on sys.schemas.schema_id = sys.objects.schema_id
     inner join sys.columns
             on sys.columns.object_id = sys.objects.object_id
     where sys.schemas.name = 'replica'
       and sys.objects.name = @tabela_replica
  )
  select @campos = concat(@campos,',',name)
       , @campos_remotos = concat(@campos_remotos,',',name)
       , @set_campos = concat(@set_campos,',',name,'=tabela_remota.',name)
       , @campo_chave = case @campo_anterior
           when 'historico' then name
           else @campo_chave
         end
       , @campo_anterior = name
    from colunas
   order by column_id

  set @campos = substring(@campos,2,len(@campos))
  set @campos_remotos = substring(@campos_remotos,2,len(@campos_remotos))
  set @set_campos = substring(@set_campos,2,len(@set_campos))
  
  raiserror(N'REPLICANDO: %s.%s=%i',10,1,
    @tabela_replica,@campo_chave,@chave_tabela_mercadologic) with nowait
      
  set @sql = '
    select '+cast(@id_evento as varchar(100))+' as id_evento
         , '+cast(@cod_empresa as varchar(100))+' as cod_empresa
         , 0 as historico
         , *
      into #tb_registro
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select *
               from '+@esquema+'.'+@tabela+'
              where '+@campo_chave+' = '+cast(@chave_tabela_mercadologic as varchar(100))+';''
           ) as t
    ;
    update '+@esquema_replica+'.'+@tabela_replica+'
       set historico = case when exists (select 1 from #tb_registro)
             then  1  /* registro substitu�do por um mais novo na origem. */
             else -1  /* registro apagado na origem */
           end
     where cod_empresa = '+cast(@cod_empresa as varchar(100))+'
       and '+@campo_chave+' = '+cast(@chave_tabela_mercadologic as varchar(100))+'
    ;
    merge '+@esquema_replica+'.'+@tabela_replica+' as tabela
    using #tb_registro as tabela_remota
       on tabela.id_evento = '+cast(@id_evento as varchar(100))+'
     when matched then
          update set '+@set_campos+'
     when not matched by target then
          insert ('+@campos+')
          values ('+@campos_remotos+');'

  exec @status = sp_executesql @sql
  
  if @status = 0 begin
    raiserror(N'REGISTRO DO CONCENTRADOR REPLICADO NO GESTOR: %s.%s=%i',10,1,
      @tabela_replica,@campo_chave,@chave_tabela_mercadologic) with nowait
  end
  
  return @status
end
go






