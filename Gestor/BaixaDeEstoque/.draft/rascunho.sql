
  declare @encargos decimal(18,4) = 0
  declare @tipo_estoque int
  declare @deve_recalcular_custo as bit
  declare @ramo_prestador_servico as int

  select @encargos = replace(replace(DFvalor,'.',''),',','.')
    from TBopcoes with (nolock)
   where DFcodigo = 551;

  select @tipo_estoque = DFvalor
    from TBopcoes with (nolock)
   where DFcodigo = 420;

  select @deve_recalcular_custo = case DFvalor when 'SIM' then 1 else 0 end
    from TBopcoes with (nolock)
   where DFcodigo = 995;

  select @ramo_prestador_servico = DFvalor
    from TBopcoes with (nolock)
   where DFcodigo = 337;