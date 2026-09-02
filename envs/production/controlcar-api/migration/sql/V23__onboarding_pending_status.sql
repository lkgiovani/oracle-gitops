-- V23: onboarding pending status (D-01, ONB-02) -- 3o valor do CHECK de
-- companies.status, exclusivo do self-signup publico (D-06: o provisionamento
-- pelo master continua criando a empresa ja 'active'). Uma empresa nasce
-- 'pending' no self-signup e so vira 'active' quando o dono confirma o
-- e-mail (planos 23-02..23-04 desta fase); o login trata 'pending' com uma
-- mensagem propria ("confirme seu e-mail"), distinta de 'suspended'.
--
-- Nome real da constraint confirmado ao vivo (SELECT conname FROM
-- pg_constraint WHERE conrelid='companies'::regclass AND contype='c';) antes
-- de escrever esta migration: companies_status_check (convencao padrao do
-- Postgres para CHECK inline de coluna sem nome explicito -- mesma
-- disciplina de verificacao da V20/V22). So ESTENDE o conjunto permitido --
-- 'active'/'suspended' permanecem intactos, nenhuma linha existente e
-- afetada.
ALTER TABLE companies DROP CONSTRAINT companies_status_check;
ALTER TABLE companies ADD CONSTRAINT companies_status_check
    CHECK (status IN ('active', 'suspended', 'pending'));
