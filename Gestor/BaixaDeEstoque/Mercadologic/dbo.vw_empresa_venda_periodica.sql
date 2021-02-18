-- drop view dbo.vw_empresa_venda_periodica
if object_id('dbo.vw_empresa_venda_periodica') is null begin
   exec sp_executesql N'
      create view dbo.vw_empresa_venda_periodica
      as
      select TBempresa.DFcod_empresa
           , case when TBempresa.DFdata_inativacao is null
                   and TBempresa_atacado_varejo.DFbaixa_online_mercadologic = 1
                then cast(1 as bit)
                else cast(0 as bit)
             end as DFvenda_periodica_ativada
           , coalesce(
                TBempresa_atacado_varejo.DFtime_baixa_online_mercadologic,
                cast(''03:00:00'' as time)
             ) as DFintervalo_processamento 
        from director.TBempresa with (nolock)
       inner join director.TBempresa_atacado_varejo (nolock)
               on TBempresa_atacado_varejo.DFcod_empresa = TBempresa.DFcod_empresa'

   exec sp_executesql N'
      create trigger dbo.TG_vw_empresa_venda_periodica
      on dbo.vw_empresa_venda_periodica
      instead of update
      as
      begin
       update director.TBempresa_atacado_varejo
          set DFbaixa_online_mercadologic = inserted.DFvenda_periodica_ativada
            , DFtime_baixa_online_mercadologic = inserted.DFintervalo_processamento
         from inserted
        where inserted.DFcod_empresa = TBempresa_atacado_varejo.DFcod_empresa
      end'
end
