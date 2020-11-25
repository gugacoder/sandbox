select top 20 sped.tbjob_auditoria.*
  from sped.tbjob_auditoria
 inner join sped.tbjob
         on sped.tbjob.dfid_job = sped.tbjob_auditoria.dfid_job
 where sped.tbjob.dfevento = 'sincronizacao'
 order by sped.tbjob_auditoria.dfid_job_auditoria desc
