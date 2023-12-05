-- MYSQL VIEWS
select * from VW_CPU_KOTLIN_CHART;
select * from VW_TEMP_CHART;
select * from VW_TEMPXCPU_CHART;
select * from VW_DESEMPENHO_CHART_TEMP;
select * from VW_RAM_CHART;

CREATE VIEW VW_CPU_KOTLIN_CHART AS
SELECT
	id_monitoramento,
    ROUND(dado_coletado,2) as dado_coletado,
    Representacao,
    DATE_FORMAT(data_hora, "%Y-%m-%d %H:%i:%s") as data_hora,
    nome_componente,
    descricao,
    id_maquina,
    empresa.id_empresa,
    hostname,
    razao_social
FROM
    monitoramento
JOIN unidade_medida ON fk_unidade_medida = id_unidade
JOIN componente ON fk_componentes_monitoramento = id_componente
JOIN maquina as M on fk_maquina_monitoramento = M.id_maquina
JOIN empresa on M.fk_empresaM = empresa.id_empresa
WHERE nome_componente = 'CPU' and descricao="uso de cpu kt";


CREATE VIEW VW_TEMP_CHART AS
SELECT
	id_monitoramento, 
    dado_coletado,
    Representacao,
    DATE_FORMAT(data_hora, "%Y-%m-%d %H:%i:%s") as data_hora,
    nome_componente,
    descricao,
    id_maquina,
    hostname,
    razao_social
FROM
    monitoramento
JOIN unidade_medida ON fk_unidade_medida = id_unidade
JOIN componente ON fk_componentes_monitoramento = id_componente
JOIN maquina as M on fk_maquina_monitoramento = M.id_maquina
JOIN empresa on M.fk_empresaM = empresa.id_empresa
WHERE nome_componente = 'CPU' and descricao="temperatura cpu";


CREATE VIEW VW_RAM_CHART AS
SELECT
	DISTINCT DATE_FORMAT(M1.data_hora, "%Y-%m-%d %H:%i:%s") AS data_hora,
	M2.id_monitoramento, 
    ROUND(((1 - M1.dado_coletado / M2.dado_coletado) * 100), 2) AS "usado",
    ROUND((M1.dado_coletado / M2.dado_coletado) * 100, 2) AS "livre",
    M2.dado_coletado AS "total",
    componente.nome_componente,
    M.id_maquina,
    M.hostname,
    empresa.razao_social
FROM
    monitoramento AS M1
JOIN monitoramento AS M2 ON M1.fk_maquina_monitoramento = M2.fk_maquina_monitoramento
JOIN componente ON M1.fk_componentes_monitoramento = componente.id_componente
JOIN maquina AS M ON M1.fk_maquina_monitoramento = M.id_maquina
JOIN empresa ON M.fk_empresaM = empresa.id_empresa
WHERE
    componente.nome_componente = 'RAM'
    AND M2.descricao = 'memoria total'
    AND M1.descricao = 'memoria disponivel';
    
    CREATE VIEW VW_DESEMPENHO_CHART_TEMP AS
SELECT
	id_monitoramento, 
    data_hora AS data_hora,
    'CPU' AS recurso,
    id_maquina AS id_maquina,
    dado_coletado AS uso
FROM (
    SELECT
        data_hora,
        id_maquina,
        dado_coletado,
        ROW_NUMBER() OVER (PARTITION BY id_maquina ORDER BY data_hora DESC) AS rn
    FROM VW_CPU_KOTLIN_CHART
) AS C
WHERE C.rn = 1
UNION ALL
SELECT
    data_hora AS data_hora,
    'RAM' AS recurso,
    id_maquina AS id_maquina,
    usado AS uso
FROM (
    SELECT
        data_hora,
        id_maquina,
        usado,
        ROW_NUMBER() OVER (PARTITION BY id_maquina ORDER BY data_hora DESC) AS rn
    FROM VW_RAM_CHART
) AS R
WHERE R.rn = 1
UNION ALL
SELECT
    data_hora AS data_hora,
    'TEMPERATURA' AS recurso,
    id_maquina AS id_maquina,
    dado_coletado AS uso
FROM (
    SELECT
        data_hora,
        id_maquina,
        dado_coletado,
        ROW_NUMBER() OVER (PARTITION BY id_maquina ORDER BY data_hora DESC) AS rn
    FROM VW_TEMP_CHART
) AS T
WHERE T.rn = 1;


CREATE VIEW VW_TEMPXCPU_CHART AS
SELECT
    DATE_FORMAT(monitoramento.data_hora, "%Y-%m-%d %H:%i:%s") as data_hora,
    ROUND(MAX(CASE WHEN monitoramento.descricao = 'uso de cpu kt' THEN monitoramento.dado_coletado END),2) AS uso_cpu_kt,
    MAX(CASE WHEN monitoramento.descricao = 'temperatura cpu' THEN monitoramento.dado_coletado END) AS temperatura_cpu,
    componente.nome_componente,
    componente.fk_maquina_componente as id_maquina,
    MAX(maquina.hostname) AS hostname,
    MAX(empresa.razao_social) AS razao_social
FROM
    monitoramento
JOIN componente ON monitoramento.fk_componentes_monitoramento = componente.id_componente
JOIN maquina ON monitoramento.fk_maquina_monitoramento = maquina.id_maquina
JOIN empresa ON maquina.fk_empresaM = empresa.id_empresa
WHERE
    componente.nome_componente = 'CPU'
    AND monitoramento.descricao IN ('uso de cpu kt', 'temperatura cpu')
GROUP BY
    DATE_FORMAT(monitoramento.data_hora, "%Y-%m-%d %H:%i:%s"), componente.nome_componente, componente.fk_maquina_componente;
    
    
INSERT INTO unidade_medida VALUES
(null, 'Bytes', 'B'),
(null, 'Porcentagem', '%'),
(null, 'MegaBytes', 'MB'), 
(null, 'Graus Celsius', '°C'), -- temperatura
(null, 'Milissegundos', 'MS'), -- tempo de inicialização
(null, 'Hora', 'H'); 
select * from unidade_medida;

INSERT INTO componente (id_componente,nome_componente,fk_maquina_componente,fk_empresa_componente,fk_metrica_componente) VALUES
(null, 'RAM', 1, 1, 1),
(null, 'CPU', 1, 1, 2),
(null, 'SISTEMA', 1, 1, NULL);
select * from componente;



-- SQL SERVER VIEWS
CREATE VIEW VW_CPU_KOTLIN_CHART AS
SELECT
    id_monitoramento,
    ROUND(dado_coletado, 2) as dado_coletado,
    Representacao,
    FORMAT(data_hora, 'yyyy-MM-dd HH:mm:ss') as data_hora,
    nome_componente,
    descricao,
    id_maquina,
    empresa.id_empresa,
    hostname,
    razao_social
FROM
    monitoramento
JOIN unidade_medida ON fk_unidade_medida = id_unidade
JOIN componente ON fk_componentes_monitoramento = id_componente
JOIN maquina as M on fk_maquina_monitoramento = M.id_maquina
JOIN empresa on M.fk_empresaM = empresa.id_empresa
WHERE nome_componente = 'CPU' and descricao = 'uso de cpu kt';


CREATE VIEW VW_TEMP_CHART AS
SELECT
    id_monitoramento,
    dado_coletado,
    Representacao,
    FORMAT(data_hora, 'yyyy-MM-dd HH:mm:ss') as data_hora,
    nome_componente,
    descricao,
    id_maquina,
    hostname,
    razao_social
FROM
    monitoramento
JOIN unidade_medida ON fk_unidade_medida = id_unidade
JOIN componente ON fk_componentes_monitoramento = id_componente
JOIN maquina as M on fk_maquina_monitoramento = M.id_maquina
JOIN empresa on M.fk_empresaM = empresa.id_empresa
WHERE nome_componente = 'CPU' and descricao = 'temperatura cpu';


CREATE VIEW VW_RAM_CHART AS
SELECT
    DISTINCT FORMAT(M1.data_hora, 'yyyy-MM-dd HH:mm:ss') AS data_hora,
    M2.id_monitoramento,
    ROUND(((1 - M1.dado_coletado / M2.dado_coletado) * 100), 2) AS usado,
    ROUND((M1.dado_coletado / M2.dado_coletado) * 100, 2) AS livre,
    M2.dado_coletado AS total,
    componente.nome_componente,
    M.id_maquina,
    M.hostname,
    empresa.razao_social
FROM
    monitoramento AS M1
JOIN monitoramento AS M2 ON M1.fk_maquina_monitoramento = M2.fk_maquina_monitoramento
JOIN componente ON M1.fk_componentes_monitoramento = componente.id_componente
JOIN maquina AS M ON M1.fk_maquina_monitoramento = M.id_maquina
JOIN empresa ON M.fk_empresaM = empresa.id_empresa
WHERE
    componente.nome_componente = 'RAM'
    AND M2.descricao = 'memoria total'
    AND M1.descricao = 'memoria disponivel';


CREATE VIEW VW_DESEMPENHO_CHART_TEMP AS
SELECT
    id_monitoramento,
    data_hora AS data_hora,
    'CPU' AS recurso,
    id_maquina AS id_maquina,
    dado_coletado AS uso
FROM (
    SELECT
        data_hora,
        id_maquina,
        dado_coletado,
        ROW_NUMBER() OVER (PARTITION BY id_maquina ORDER BY id_monitoramento DESC) AS rn
    FROM VW_CPU_KOTLIN_CHART
) AS C
WHERE C.rn = 1
UNION ALL
SELECT
    data_hora AS data_hora,
    'RAM' AS recurso,
    id_maquina AS id_maquina,
    usado AS uso
FROM (
    SELECT
        data_hora,
        id_maquina,
        usado,
        ROW_NUMBER() OVER (PARTITION BY id_maquina ORDER BY id_monitoramento DESC) AS rn
    FROM VW_RAM_CHART
) AS R
WHERE R.rn = 1
UNION ALL
SELECT
    data_hora AS data_hora,
    'TEMPERATURA' AS recurso,
    id_maquina AS id_maquina,
    dado_coletado AS uso
FROM (
    SELECT
        data_hora,
        id_maquina,
        dado_coletado,
        ROW_NUMBER() OVER (PARTITION BY id_maquina ORDER BY id_monitoramento DESC) AS rn
    FROM VW_TEMP_CHART
) AS T
WHERE T.rn = 1;


CREATE VIEW VW_TEMPXCPU_CHART AS
SELECT
    FORMAT(monitoramento.data_hora, 'yyyy-MM-dd HH:mm:ss') as data_hora,
    ROUND(MAX(CASE WHEN monitoramento.descricao = 'uso de cpu kt' THEN monitoramento.dado_coletado END), 2) AS uso_cpu_kt,
    MAX(CASE WHEN monitoramento.descricao = 'temperatura cpu' THEN monitoramento.dado_coletado END) AS temperatura_cpu,
    componente.nome_componente,
    componente.fk_maquina_componente as id_maquina,
    MAX(maquina.hostname) AS hostname,
    MAX(empresa.razao_social) AS razao_social
FROM
    monitoramento
JOIN componente ON monitoramento.fk_componentes_monitoramento = componente.id_componente
JOIN maquina ON monitoramento.fk_maquina_monitoramento = maquina.id_maquina
JOIN empresa ON maquina.fk_empresaM = empresa.id_empresa
WHERE
    componente.nome_componente = 'CPU'
    AND monitoramento.descricao IN ('uso de cpu kt', 'temperatura cpu')
GROUP BY
    FORMAT(monitoramento.data_hora, 'yyyy-MM-dd HH:mm:ss'), componente.nome_componente, componente.fk_maquina_componente;

