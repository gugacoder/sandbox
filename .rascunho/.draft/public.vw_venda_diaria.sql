-- View: public.vw_venda_diaria

-- DROP VIEW public.vw_venda_diaria;

CREATE OR REPLACE VIEW public.vw_venda_diaria AS
 SELECT caixa.numeroloja AS dfnumero_loja,
    caixa.datamovimento AS dfdata_movimento,
    itemcupomfiscal.iditem AS dfcodigo_item,
    sum(itemcupomfiscal.quantidade) AS dfquantidade_venda,
    sum(itemcupomfiscal.totalliquido) AS dfvalor_venda_liquido,
    sum(round(itemcupomfiscal.precocusto * itemcupomfiscal.quantidade, 2)) AS dfvalor_custo_bruto,
        CASE
            WHEN ecf.tipo::text <> 'NFCE'::text THEN round(sum(itemcupomfiscal.totalliquido) * aliquota.percentual / 100::numeric, 2)
            ELSE round(sum(itemcupomfiscal.totalliquido) * (1::numeric - round(item.percentual_reducao / 100::numeric, 4)) * round(aliquota.percentual / 100::numeric, 4), 2)
        END AS dfvalor_icms
   FROM itemcupomfiscal
     JOIN item ON item.id = itemcupomfiscal.iditem
     JOIN aliquota ON itemcupomfiscal.tributacao::text = aliquota.id::text
     JOIN cupomfiscal ON cupomfiscal.id = itemcupomfiscal.idcupomfiscal
     JOIN sessao ON sessao.id = cupomfiscal.idsessao
     JOIN caixa ON sessao.idcaixa = caixa.id
     JOIN pdv ON caixa.idpdv = pdv.id
     JOIN ecf ON ecf.id = pdv.idecf
  WHERE itemcupomfiscal.cancelado = false AND cupomfiscal.cancelado = false
  GROUP BY caixa.numeroloja, caixa.datamovimento, itemcupomfiscal.iditem, aliquota.percentual, item.percentual_reducao, ecf.tipo;

ALTER TABLE public.vw_venda_diaria
    OWNER TO postgres;
