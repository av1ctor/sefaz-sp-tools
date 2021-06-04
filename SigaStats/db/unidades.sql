CREATE TABLE unidades (
    id BIGINT PRIMARY KEY NOT NULL UNIQUE, 
    sigla STRING (32) NOT NULL, 
    descricao TEXT (512)
);

CREATE INDEX idx_unidades_sigla ON unidades (sigla ASC);
