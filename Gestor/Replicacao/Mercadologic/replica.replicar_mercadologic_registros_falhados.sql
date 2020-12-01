--
-- PROCEDURE replica.replicar_mercadologic_registros_falhados
--
drop procedure if exists replica.replicar_mercadologic_registros_falhados
go
create procedure replica.replicar_mercadologic_registros_falhados (
    @cod_empresa int
  , @maximo_de_registros int = null
  -- Parâmetros opcionais de conectividade.
  -- Se omitidos os parâmetros são lidos da view replica.vw_empresa.
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
    -- min(*) é usado apenas para forçar um registro nulo caso a empresa não exista.
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

  declare @sql nvarchar(max)
  declare @id_evento int
  declare @tb_registro replica.tp_id
  declare @tabela varchar(100)
  declare @cod_registro int
  declare @contador int
  
  select @id_evento = min(id_evento) from replica.evento where evento.status = -1
  while @id_evento is not null begin

    select @tabela = concat(esquema.texto,'.',tabela.texto)
         , @cod_registro = evento.cod_registro
      from replica.evento
     inner join replica.texto as esquema on esquema.id = evento.id_esquema
     inner join replica.texto as tabela on tabela.id = evento.id_tabela
     where evento.id_evento = @id_evento

    raiserror(N'CHECANDO FALHA OCORRIDA NA REPLICAÇÃO DO REGISTRO: %s (id: %d)',10,1,@tabela,@cod_registro) with nowait

    delete from @tb_registro
    insert into @tb_registro (id) values (@cod_registro)

    begin try
      begin transaction tx

      exec replica.replicar_mercadologic_registros
           @cod_empresa=@cod_empresa
         , @tabela_mercadologic=@tabela
         , @tb_registro=@tb_registro
         -- Parâmetros opcionais de conectividade.
         -- Se omitidos os parâmetros são lidos da view replica.vw_empresa.
         , @provider=@provider
         , @driver=@driver
         , @servidor=@servidor
         , @porta=@porta
         , @database=@database
         , @usuario=@usuario
         , @senha=@senha

      update replica.evento
         set status = 1
           , falha = null
           , falha_detalhada = null
       where id_evento = @id_evento

      commit transaction tx
    end try
    begin catch
      if @@trancount > 0
        rollback transaction tx

      -- Marcando o registro com -2, significando registro falhado duas vezes.
      update replica.evento
         set status = -2
           , falha = concat(error_message(),' (linha ',error_line(),')')
           , falha_detalhada = null
       where id_evento = @id_evento

    end catch

    if @maximo_de_registros is not null begin
      set @contador = coalesce(@contador,0) + 1
      if @contador >= @maximo_de_registros begin
        return 0
      end
    end

    waitfor delay '00:00:01';
    select @id_evento = min(id_evento) from replica.evento
     where evento.status = -1 and id_evento > @id_evento
  end
end
go
