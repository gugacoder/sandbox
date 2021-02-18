


CASE WHEN TBempresa_atacado_varejo.DFcodigo_regimetributario <> 1  &
  THEN DFvaloricms  &
ELSE CASE WHEN DFvalor_icms <> 0 THEN ROUND(TBempresa_atacado_varejo.DFaliq_simples_nacional * TBtrab.DFvalor_vendabruta / 100,2)  &
  ELSE ROUND(TBempresa_atacado_varejo.DFaliq_simples_nacional_st_isenta * TBtrab.DFvalor_vendabruta / 100,2) END  &
END AS DFvaloricms, &

CASE WHEN DFpis = 1 THEN TBtrab.DFvalor_venda_bruta * TBempresa_atacado_varejo.DFpercentual_pis / 100 ELSE 0 END AS DFvalorpis



,  &
CASE WHEN DFcofins = 1 THEN TBtrab.DFvalor_venda_bruta * TBempresa_atacado_varejo.DFpercentual_cofins / 100 ELSE 0 END AS DFvalorcofins,  &
TBtrab.DFvalor_venda_bruta * @ENCARGOS / 100 AS DFvalorencargos,  &
0 AS DFestoqueatualizado,  &
CAST(0 AS DECIMAL(18,4)) AS DFvalordesconto  &
