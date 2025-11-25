/*============================================================
ACTIVIDAD FORMATIVA 4:
UTILIZANDO SUBCONSULTAS PARA RESOLVER REQUERIMIENTOS

Grupo 7:
- Elizabeth Arevalo Alarcón
- Miguel Angel Vargas Huenul
============================================================*/

/*============================================================
CASO 1: LISTADO DE TRABAJADORES
============================================================*/
SELECT
    REGEXP_REPLACE(
        LPAD(TO_CHAR(c.numrun), 8, '0'), '([0-9]{1,2})([0-9]{3})([0-9]{3})', '\1.\2.\3'
    ) || '-' || c.dvrun AS "RUT Cliente", -- Formateo de RUT con puntos y guion
    INITCAP(c.pnombre) || ' ' || INITCAP(c.appaterno) AS "Nombre Cliente",
    UPPER(p.nombre_prof_ofic) AS "Profesión Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD/MM/YYYY') AS "Fecha de Inscripción",
    INITCAP(c.direccion) AS "Dirección Cliente"

FROM cliente c

JOIN profesion_oficio p -- unión con tabla de profesiones (contiene id y nombre de profesión)
    ON c.cod_prof_ofic = p.cod_prof_ofic 

JOIN tipo_cliente tc -- unión con tabla de tipos de clientes (contiene id, tipo de cliente)
    ON c.cod_tipo_cliente = tc.cod_tipo_cliente 

WHERE c.cod_tipo_cliente = 10 --codigo correspondiente a los trabajadores dependientes 
    AND UPPER(p.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
    AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
        (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion))) -- promedio redondeado de los años de inscripción
        FROM cliente)

ORDER BY c.numrun ASC; -- Orden ascendente por RUT del cliente

/*============================================================
CASO 2: AUMENTO DE CRÉDITO 
============================================================*/
DROP TABLE CLIENTES_CUPOS_COMPRA; --drop opcional para evitar error si la tabla ya existe

CREATE TABLE CLIENTES_CUPOS_COMPRA AS -- creación de tabla con los clientes que cumplen el requisito

SELECT 
    c.numrun || '-' || c.dvrun AS "RUT_CLIENTE",
    ROUND(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12) AS "EDAD", -- cálculo de edad en años
    TO_CHAR(tc.cupo_disp_compra, '$999G999G999') AS "CUPO_DISPONIBLE_COMPRA",
    UPPER(tc2.nombre_tipo_cliente) AS "TIPO_CLIENTE"

FROM cliente c

JOIN tarjeta_cliente tc
    ON c.numrun = tc.numrun -- unión con tabla de tarjetas de clientes (contiene cupo disponible)

JOIN tipo_cliente tc2
    ON c.cod_tipo_cliente = tc2.cod_tipo_cliente -- unión con tabla de tipos de clientes

WHERE tc.cupo_disp_compra >= ( -- subconsulta para obtener el cupo máximo del año anterior
        SELECT MAX(tc3.cupo_disp_compra)
        FROM tarjeta_cliente tc3
        WHERE EXTRACT(YEAR FROM tc3.fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) - 1 -- obtención del año anterior
    )

ORDER BY "EDAD" ASC;

SELECT * FROM CLIENTES_CUPOS_COMPRA; -- visualización de la tabla creada
