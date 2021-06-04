CREATE TABLE usuarios (
    id BIGINT PRIMARY KEY NOT NULL UNIQUE, 
    sigla STRING (32) NOT NULL, 
    nome TEXT (512)
);

CREATE INDEX idx_usuarios_sigla ON usuarios (sigla);
