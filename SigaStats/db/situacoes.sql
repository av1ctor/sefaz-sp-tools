create table situacoes(
    id smallint not null,
    nome varchar(256) not null,
    primary key(id)
);

insert into situacoes (id, nome) values (0, '[Todos]');
insert into situacoes (id, nome) values (3, 'A Receber (Físico)');
insert into situacoes (id, nome) values (56, 'A devolver');
insert into situacoes (id, nome) values (58, 'A devolver (Fora do prazo)');
insert into situacoes (id, nome) values (2, 'Aguardando Andamento');
insert into situacoes (id, nome) values (57, 'Aguardando devolução');
insert into situacoes (id, nome) values (59, 'Aguardando devolução (Fora do prazo)');
insert into situacoes (id, nome) values (30, 'Anexo Pendente Assinatura/Conferência');
insert into situacoes (id, nome) values (26, 'Apensado');
insert into situacoes (id, nome) values (6, 'Arquivo Corrente');
insert into situacoes (id, nome) values (14, 'Caixa de Entrada (Digital)');
insert into situacoes (id, nome) values (10, 'Cancelado');
insert into situacoes (id, nome) values (27, 'Como Gestor');
insert into situacoes (id, nome) values (28, 'Como Interessado');
insert into situacoes (id, nome) values (29, 'Despacho Pendente de Assinatura');
insert into situacoes (id, nome) values (22, 'Disponibilizado');
insert into situacoes (id, nome) values (62, 'Documento Assinado com Senha');
insert into situacoes (id, nome) values (67, 'Elaborar Parte de Documento Colaborativo');
insert into situacoes (id, nome) values (1, 'Elaboração');
insert into situacoes (id, nome) values (68, 'Finalizar Documento Colaborativo');
insert into situacoes (id, nome) values (9, 'Juntado');
insert into situacoes (id, nome) values (16, 'Juntado a Documento Externo');
insert into situacoes (id, nome) values (63, 'Movimentação Assinada com Senha');
insert into situacoes (id, nome) values (64, 'Movimentação Conferida com Senha');
insert into situacoes (id, nome) values (60, 'Pendente de Anexação');
insert into situacoes (id, nome) values (15, 'Pendente de Assinatura');
insert into situacoes (id, nome) values (73, 'Portal da Transparência');
insert into situacoes (id, nome) values (20, 'Publicado');
insert into situacoes (id, nome) values (21, 'Publicação solicitada');
insert into situacoes (id, nome) values (18, 'Remetido para Publicação');
insert into situacoes (id, nome) values (25, 'Responsável pela Assinatura');
insert into situacoes (id, nome) values (39, 'Revisar');
insert into situacoes (id, nome) values (32, 'Sem Efeito');
insert into situacoes (id, nome) values (31, 'Sobrestado');
insert into situacoes (id, nome) values (23, 'Transferido');
insert into situacoes (id, nome) values (24, 'Transferido (Digital)');
insert into situacoes (id, nome) values (11, 'Transferido para Órgão Externo');
insert into situacoes (id, nome) values (1006, 'COVID-19');
insert into situacoes (id, nome) values (72, 'Como Revisor');
insert into situacoes (id, nome) values (2005, 'Demanda Judicial Prioridade Alta');
insert into situacoes (id, nome) values (2006, 'Demanda Judicial Prioridade Baixa');
insert into situacoes (id, nome) values (2007, 'Demanda Judicial Prioridade Média');
insert into situacoes (id, nome) values (1005, 'Documento Analisado');
insert into situacoes (id, nome) values (1001, 'Idoso');
insert into situacoes (id, nome) values (1007, 'Nota de Empenho');
insert into situacoes (id, nome) values (1003, 'Prioritário');
insert into situacoes (id, nome) values (71, 'Pronto para Assinar');
insert into situacoes (id, nome) values (1004, 'Restrição de Acesso');
insert into situacoes (id, nome) values (1000, 'Urgente');
