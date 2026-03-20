DROP DATABASE IF EXISTS transporte;
CREATE DATABASE transporte;
USE transporte;

CREATE TABLE USUARIO (
	CPF CHAR(14)  NOT NULL UNIQUE,   
    telefone CHAR(12) NOT NULL UNIQUE,
    nome VARCHAR(20)  NOT NULL,
    sobrenome VARCHAR(20) NOT NULL,
    data_nasc DATE NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY(CPF)
);

CREATE TABLE PASSAGEIRO (
	id_passageiro INT AUTO_INCREMENT,
    CPF_passageiro CHAR(14) NOT NULL UNIQUE,
    PRIMARY KEY(id_passageiro),
    FOREIGN KEY(CPF_passageiro) REFERENCES USUARIO(CPF)
);

CREATE TABLE MOTORISTA (
	id_motorista INT AUTO_INCREMENT,
    carteira_hab CHAR(11) NOT NULL UNIQUE,
    CPF_motorista CHAR(14) NOT NULL UNIQUE,
    PRIMARY KEY (id_motorista),
    FOREIGN KEY (CPF_motorista) REFERENCES USUARIO (CPF)
);

CREATE TABLE TIPO_SERVICO (
	id_servico INT AUTO_INCREMENT UNIQUE,
    nomeservico VARCHAR(20) NOT NULL,
    descricao VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_servico)
);

CREATE TABLE VEICULO (
	id_veiculo INT AUTO_INCREMENT,
    cor VARCHAR(20) NOT NULL,
    placa CHAR(7) NOT NULL UNIQUE,
    ano YEAR NOT NULL,
    modelo VARCHAR(20) NOT NULL,
    id_motorista INT NOT NULL,
    UNIQUE(id_veiculo, id_motorista),
    PRIMARY KEY (id_veiculo),
    FOREIGN KEY (id_motorista) REFERENCES MOTORISTA(id_motorista)
);

CREATE TABLE PRESTA(
	id_motorista INT NOT NULL,
    id_servico INT NOT NULL,
    PRIMARY KEY (id_motorista, id_servico),
    FOREIGN KEY (id_motorista) REFERENCES MOTORISTA (id_motorista),
    FOREIGN KEY (id_servico) REFERENCES TIPO_SERVICO (id_servico)
);

CREATE TABLE ENDERECO (
	id_endereco INT AUTO_INCREMENT,
    bairro VARCHAR(40) NOT NULL,
    rua VARCHAR(40) NOT NULL,
    numero INT NOT NULL,
    PRIMARY KEY(id_endereco)
);

CREATE TABLE CORRIDA (
	id_corrida INT AUTO_INCREMENT,
    data_corrida DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fim TIME,
    id_motorista INT NOT NULL,
    id_veiculo INT NOT NULL,
    id_passageiro INT NOT NULL,
    id_endereco_origem INT NOT NULL,
    id_servico INT NOT NULL,
    PRIMARY KEY(id_corrida),
    FOREIGN KEY(id_passageiro) REFERENCES PASSAGEIRO(id_passageiro),
    FOREIGN KEY(id_endereco_origem) REFERENCES ENDERECO(id_endereco),
    FOREIGN KEY(id_servico) REFERENCES TIPO_SERVICO(id_servico),
    FOREIGN KEY(id_motorista) REFERENCES MOTORISTA(id_motorista),
    FOREIGN KEY(id_veiculo, id_motorista) REFERENCES VEICULO(id_veiculo, id_motorista)
);

CREATE TABLE DESTINO_CORRIDA (
	id_endereco INT NOT NULL,
    id_corrida INT NOT NULL,
    ordem INT NOT NULL,
    PRIMARY KEY(id_corrida, ordem),
    FOREIGN KEY(id_corrida) REFERENCES CORRIDA(id_corrida),
    FOREIGN KEY(id_endereco) REFERENCES ENDERECO(id_endereco)
);

CREATE TABLE PAGAMENTO (
	id_pagamento INT AUTO_INCREMENT,
    valor_pago DECIMAL (8, 2) NOT NULL,
    forma_pagamento VARCHAR(20) NOT NULL,
    data_pagamento DATE NOT NULL,
    hora_pagamento TIME NOT NULL,
    id_corrida INT NOT NULL UNIQUE,
    PRIMARY KEY(id_pagamento),
    FOREIGN KEY(id_corrida) REFERENCES CORRIDA(id_corrida)
);

/*
======================================
ALTERAÇAO DE TABELAS(DESATIVA USUARIO)
======================================
*/

ALTER TABLE USUARIO   ADD COLUMN ativo TINYINT NOT NULL DEFAULT 1;
ALTER TABLE MOTORISTA ADD COLUMN ativo TINYINT NOT NULL DEFAULT 1;
ALTER TABLE VEICULO   ADD COLUMN ativo TINYINT NOT NULL DEFAULT 1;
ALTER TABLE PASSAGEIRO ADD COLUMN ativo TINYINT NOT NULL DEFAULT 1;


/*
==============================================================
VERIFICA SE O CARRO DA CORRIDA PODE PERTENCER AO SERVICO BLACK
==============================================================
*/

DROP PROCEDURE IF EXISTS smp_validar_corrida;
DELIMITER $$

CREATE PROCEDURE smp_validar_corrida(
    in p_id_motorista INT,
    in p_id_servico  INT,
    in p_id_veiculo  INT
)

begin
    declare v_ano YEAR;
    declare v_nome_servico VARCHAR(50);

    if not exists (
        select 1
        from PRESTA pr
        where pr.id_motorista = p_id_motorista
          and pr.id_servico  = p_id_servico
    ) then
        signal sqlstate '45000'
        set message_text = 'Motorista não presta esse tipo de serviço (PRESTA).';
    end if;

    select nomeservico into v_nome_servico
    from TIPO_SERVICO
    where id_servico = p_id_servico
    limit 1;

    
    select ano into v_ano
    from VEICULO
    where id_veiculo = p_id_veiculo
    limit 1;

    -- UberBlack só com carro >= 2023
    if (v_nome_servico = 'UberBlack' and v_ano < 2023) then
        signal sqlstate '45000'
        set message_text = 'Este veículo é muito antigo para prestar UberBlack.';
    end if;

end $$

DELIMITER ;

drop trigger if exists validar_regra_servico;
DELIMITER //

create trigger validar_regra_servico
before insert on CORRIDA
for each row
begin
    call smp_validar_corrida(new.id_motorista, new.id_servico, new.id_veiculo);
end//

DELIMITER ;




/*
==============================
Inserção  e consulta - USUARIO
==============================
*/

insert into USUARIO (CPF, nome, sobrenome, telefone, data_nasc, email)
     values('03720803082', 'Lemoel', 'Costa', '5399247300', '2005-04-06',  'limaosico14@gmail.com'),
     ('77777777', 'Leandro', 'Silva', '539898989', '2000-02-18', 'ganso90@gmail.com'),('61451452004', 'Claudiomiro', 'Praz', '53999676356', '1995-08-09', 'claudiomiroPraz@gmail.com'), 
     ('33333333333', 'Ana', 'Caroline', '539913489', '1999-02-07', 'anacosta@gmail.com'), ('555555555', 'Luciano', 'Costa', '5399934598', '1993-03-17', 'lucianosico@gmail.com');

select * from USUARIO;


insert into PASSAGEIRO (CPF_passageiro) values ('77777777'), ('33333333333'), ('555555555');
select * from PASSAGEIRO;


/*
===================================
Inserção  e consulta - TIPO_SERVICO
===================================
*/

insert into TIPO_SERVICO (nomeservico, descricao) values ('UberX', 'Corridas com preços acessiveis');
insert into TIPO_SERVICO (nomeservico, descricao) values ('UberBlack', 'Corridas com maior conforto e atendimento');
select * from TIPO_SERVICO;

/*
================================
Inserção  e consulta - MOTORISTA
================================
*/

insert into MOTORISTA (carteira_hab, CPF_motorista) values ('12121212121', '03720803082');
insert into MOTORISTA (carteira_hab, CPF_motorista) values ('99999999999', '61451452004');
select * from MOTORISTA;


insert into PRESTA (id_motorista, id_servico) values (1, 1), (2, 2);
select * from PRESTA;

/*
==============================
Inserção  e consulta - VEICULO
==============================
*/

insert into VEICULO(cor, placa, ano, modelo, id_motorista) values ('Cinza', 'ZBY4T', 2018, 'Onix', 1),
('Amarelo', 'OJ89VC', 2023, 'Byd', 1), ('Preto', 'X89YB', 2024, 'Volvo X', 2);
select * from VEICULO;

/*
===============================
Inserção  e consulta - ENDERECO
===============================
*/

insert into ENDERECO (bairro, rua, numero) values 
('Centro', 'Rua Marechal Deodoro', 123),
('Fragata', 'Avenida Duque de Caxias', 450),
('Areal', 'Rua Ferreira Viana', 1000),
('Laranjal', 'Avenida Antônio Augusto Assumpção', 50);
select * from ENDERECO;

/*
==============================
Inserção  e consulta - CORRIDA
==============================
*/

insert into CORRIDA (data_corrida, hora_inicio, hora_fim, id_passageiro, id_servico, id_endereco_origem, id_veiculo, id_motorista) 
values ('2026-02-15', '19:30:00', '19:36:00', 1, 1, 1, 2, 1);
select * from CORRIDA;

insert into DESTINO_CORRIDA (id_corrida, id_endereco, ordem) values 
(1, 2, 1),
(1, 4, 2);

/*
====================================
Inserção do pagamento em uma corrida
====================================
*/


insert into PAGAMENTO (valor_pago, forma_pagamento, data_pagamento, hora_pagamento, id_corrida)
values (35.90, 'Cartao', CURDATE(), CURTIME(), 1);

/*
==================================================
JOIN: Para saber Motorista e Passageiro na corrida
==================================================
*/

select 
    c.data_corrida as 'Data da corrida',
	um.nome as Motorista,
    v.modelo as Modelo,
    up.nome as Passageiro
    from CORRIDA c
    join VEICULO v on c.id_veiculo = v.id_veiculo
    join MOTORISTA m on c.id_motorista = m.id_motorista
    join USUARIO um on m.CPF_motorista = um.CPF
    join PASSAGEIRO p on c.id_passageiro = p.id_passageiro
    join USUARIO up on p.CPF_passageiro = up.CPF
    ORDER BY c.data_corrida DESC;
    
/*
===============================
JOIN: Para histórico de viagens
===============================
*/

select 
	u.nome as Passageiro,
    c.data_corrida,
    e.rua as Origem, ed.rua as Destino,
    v.modelo, v.cor, v.placa,
    t.nomeservico
    from CORRIDA c
    join PASSAGEIRO pa on c.id_passageiro = pa.id_passageiro
    join USUARIO u on pa.CPF_passageiro = u.CPF
    join ENDERECO e on c.id_endereco_origem = e.id_endereco
    join DESTINO_CORRIDA d on c.id_corrida = d.id_corrida
    join ENDERECO ed on d.id_endereco = ed.id_endereco
    join VEICULO v on c.id_veiculo = v.id_veiculo
    join TIPO_SERVICO t on  c.id_servico = t.id_servico;
    
/*
=============================================
JOIN: Saber qual tipo de serviço pode prestar
=============================================
*/

select s.nomeservico as servico, u.nome as motorista, v.modelo as modelo
from PRESTA pr
join MOTORISTA m on pr.id_motorista = m.id_motorista
join USUARIO u on m.CPF_motorista = u.CPF
join TIPO_SERVICO s on pr.id_servico = s.id_servico
join VEICULO v on v.id_motorista = m.id_motorista;

/*
===============================ri
JOIN: Bairros com maior demanda
===============================
*/

select 
	e.bairro,
    count(c.id_corrida) as Total_viagens,
    t.nomeservico
    from CORRIDA  c
    join ENDERECO e on c.id_endereco_origem = e.id_endereco
    join TIPO_SERVICO t on c.id_servico = t.id_servico
    group by e.bairro, t.nomeservico
    order by Total_viagens DESC;