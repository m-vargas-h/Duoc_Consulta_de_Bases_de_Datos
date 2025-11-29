/*============================================================
ACTIVIDAD SUMATIVA 2:
INSERTANDO, ELIMINANDO Y MANIPULANDO DATOS

- Miguel Angel Vargas Huenul
============================================================*/

/*============================================================
CASO 1: REPORTARÍA DE ASESORÍAS
============================================================*/
SELECT 
    p.id_profesional                                                                         AS "ID",
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre                                     AS "PROFESIONAL",
    banca.nro_asesorias_banca                                                                AS "NRO ASESORIA BANCA",
    TO_CHAR(banca.total_honorarios_banca, '$999G999G999')                                    AS "MONTO_TOTAL_BANCA",
    retail.nro_asesorias_retail                                                              AS "NRO ASESORIA RETAIL",
    TO_CHAR(retail.total_honorarios_retail, '$999G999G999')                                  AS "MONTO_TOTAL_RETAIL",
    (banca.nro_asesorias_banca + retail.nro_asesorias_retail)                                AS "TOTAL ASESORIAS",
    TO_CHAR((banca.total_honorarios_banca + retail.total_honorarios_retail), '$999G999G999') AS "TOTAL HONORARIOS"

FROM profesional p

-- join con subconsulta para obtener las asesorías del sector banca
JOIN (
    SELECT 
        a.id_profesional,
        COUNT(*) AS nro_asesorias_banca,
        ROUND(SUM(a.honorario)) AS total_honorarios_banca
    FROM asesoria a
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 3
    GROUP BY a.id_profesional
) banca ON p.id_profesional = banca.id_profesional

-- Join con subconsulta para obtener las asesorías del sector retail
JOIN (
    SELECT 
        a.id_profesional,
        COUNT(*) AS nro_asesorias_retail,
        ROUND(SUM(a.honorario)) AS total_honorarios_retail
    FROM asesoria a
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 4
    GROUP BY a.id_profesional
) retail ON p.id_profesional = retail.id_profesional

ORDER BY p.id_profesional;

/*============================================================
CASO 2: RESUMEN DE HONORARIOS
============================================================*/
-- 1. Creación de la tabla REPORTE_MES
DROP TABLE REPORTE_MES; -- Ejecutar en caso de que la tabla ya exista

CREATE TABLE REPORTE_MES (
    ID_PROF                 NUMBER(3),
    NOMBRE_COMPLETO         VARCHAR2(60),
    NOMBRE_PROFESION        VARCHAR2(35),
    NOM_COMUNA              VARCHAR2(20),
    NRO_ASESORIAS           NUMBER(3),
    MONTO_TOTAL_HONORARIOS  NUMBER(8),
    PROMEDIO_HONORARIO      NUMBER(8),
    HONORARIO_MINIMO        NUMBER(8),
    HONORARIO_MAXIMO        NUMBER(8)
);

-- 2. Insertar los datos en REPORTE_MES
INSERT INTO REPORTE_MES

SELECT 
    p.id_profesional                                                    AS "ID_PROF",
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre)       AS "NOMBRE_COMPLETO",
    INITCAP(pr.nombre_profesion)                                        AS "NOMBRE_PROFESION",
    INITCAP(c.nom_comuna)                                               AS "NOM_COMUNA",
    COUNT(*)                                                            AS "NRO_ASESORIAS",
    ROUND(SUM(a.honorario))                                             AS "MONTO_TOTAL_HONORARIOS",
    ROUND(AVG(a.honorario))                                             AS "PROMEDIO_HONORARIO",
    ROUND(MIN(a.honorario))                                             AS "HONORARIO_MINIMO",
    ROUND(MAX(a.honorario))                                             AS "HONORARIO_MAXIMO"

FROM profesional p

JOIN profesion pr ON p.cod_profesion = pr.cod_profesion

JOIN comuna c ON p.cod_comuna = c.cod_comuna

JOIN asesoria a ON p.id_profesional = a.id_profesional

WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 4
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))

GROUP BY 
    p.id_profesional, 
    p.appaterno, 
    p.apmaterno, 
    p.nombre, 
    pr.nombre_profesion, 
    c.nom_comuna

ORDER BY p.id_profesional;

-- 3. Confirmar cambios
COMMIT;

-- 4. Visualizamos los datos insertados en la tabla REPORTE_MES ordenados por ID_PROF
SELECT * FROM REPORTE_MES ORDER BY ID_PROF;

/*============================================================
CASO 3: MODIFICACIÓN DE HONORARIOS
============================================================*/
-- 1. Reporte ANTES de la actualización
SELECT 
    ROUND(SUM(a.honorario)) AS HONORARIO,
    p.id_profesional AS ID_PROFESIONAL,
    p.numrun_prof AS NUMRUN_PROF,
    p.sueldo AS SUELDO

FROM profesional p

JOIN asesoria a ON p.id_profesional = a.id_profesional

WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))

GROUP BY 
    p.id_profesional, 
    p.numrun_prof, 
    p.sueldo

ORDER BY p.id_profesional;

-- 2. Actualizamos los sueldos de los profesionales según el criterio indicado
UPDATE profesional p
SET p.sueldo = p.sueldo *
    CASE
        WHEN (SELECT ROUND(SUM(a.honorario))
                FROM asesoria a
                WHERE a.id_profesional = p.id_profesional
                    AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
                    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))
             ) < 1000000
        THEN 1.10
        ELSE 1.15
    END

WHERE EXISTS (
    SELECT 1
    FROM asesoria a
    WHERE a.id_profesional = p.id_profesional
        AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
        AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))
);

-- 3. confirmamos los cambios antes de hacer la nueva consulta
COMMIT;

-- 4. Reporte DESPUÉS de la actualización
SELECT 
    ROUND(SUM(a.honorario)) AS HONORARIO,
    p.id_profesional AS ID_PROFESIONAL,
    p.numrun_prof AS NUMRUN_PROF,
    p.sueldo AS SUELDO

FROM profesional p

JOIN asesoria a ON p.id_profesional = a.id_profesional

WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))

GROUP BY 
    p.id_profesional, 
    p.numrun_prof, 
    p.sueldo

ORDER BY p.id_profesional;
