create table documentos(
    numero varchar(16) not null,
    usuario varchar(128) not null,
    data varchar(10) null,
    descricao varchar(2048) not null,
    pai varchar(16) null REFERENCES documentos (numero) ON DELETE CASCADE,
    primary key(numero, usuario)
);

CREATE INDEX idx_documentos_numero ON documentos (numero ASC);