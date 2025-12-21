/*============================================================
EVALUACION FINAL TRANSVERSAL

- Miguel Angel Vargas Huenul
============================================================*/

/*
Para el desarrollo de este caso se trabajara con 4 usuarios, ADMIN, PRY2205_EFT, PRY2205_EFT_DES y
PRY2205_EFT_CON. Se indicara el inicio de cada sección de código que usuario debe ejecutar cada 
acción, para ello se utilizara el siguiente comentario:
***** ESTA SECCION DEBE SER EJECUTADA COMO USUARIO XXXXXX *****

Ademas de lo anterior, en cada bloque de código se indicara en el comentario respectivo que usuario 
debe ejecutar el bloque mediante las siguientes etiquetas:
- ADMIN             : EFT_A
- PRY2205_EFT       : EFT_O
- PRY2205_EFT_DES   : EFT_D
- PRY2205_EFT_CON   : EFT_C
*/

/*============================================================
CASO 1: ESTRATEGIA DE SEGURIDAD

Crear los usuarios necesarios, considerando la eficiencia en la asignación de privilegios a los 
diferentes usuarios.
============================================================*/
-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO ADMIN *****

-- ========== SECCION OPCIONAL PARA LIMPIAR USUARIOS Y ASEGURAR EJECUCION LIMPIA ==========
-- Eliminar usuarios y todos sus objetos (EFT_A)
DROP USER PRY2205_EFT CASCADE;
DROP USER PRY2205_EFT_DES CASCADE;
DROP USER PRY2205_EFT_CON CASCADE;

-- Eliminar roles creados (EFT_A)
DROP ROLE PRY2205_ROL_D;
DROP ROLE PRY2205_ROL_C;

-- Eliminar sinonimos publicos (EFT_A)
DROP PUBLIC SYNONYM syn_profesional;
DROP PUBLIC SYNONYM syn_profesion;
DROP PUBLIC SYNONYM syn_isapre;
DROP PUBLIC SYNONYM syn_tipo_contrato;
DROP PUBLIC SYNONYM syn_rangos_sueldos;
DROP PUBLIC SYNONYM syn_empresa;
DROP PUBLIC SYNONYM syn_asesoria;
DROP PUBLIC SYNONYM syn_cartola;
-- ========== SECCION OPCIONAL PARA LIMPIAR USUARIOS Y ASEGURAR EJECUCION LIMPIA ==========

-- Verificamos con que usuario se esta trabajando 
SHOW USER;

-- Creación de usuarios (EFT_A)
CREATE USER PRY2205_EFT
IDENTIFIED BY "OwnerDuoc2025"
DEFAULT TABLESPACE DATA 
TEMPORARY TABLESPACE TEMP 
QUOTA 10M ON DATA;

CREATE USER PRY2205_EFT_DES 
IDENTIFIED BY "DesarrolloDuoc2025"
DEFAULT TABLESPACE DATA 
TEMPORARY TABLESPACE TEMP 
QUOTA 10M ON DATA;

CREATE USER PRY2205_EFT_CON 
IDENTIFIED BY "ConsultaDuoc2025"
DEFAULT TABLESPACE DATA 
TEMPORARY TABLESPACE TEMP 
QUOTA 10M ON DATA;

-- Creación y asignacion de roles (EFT_A)
CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_C;

GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;

-- Permisos basios de conexion (EFT_A)
GRANT CREATE SESSION TO PRY2205_EFT;
GRANT CREATE SESSION TO PRY2205_EFT_DES;
GRANT CREATE SESSION TO PRY2205_EFT_CON;

-- Permiso especifico para que el usuario PRY2205_EFT pueda crear sinonimos publicos (EFT_A)
GRANT CREATE PUBLIC SYNONYM TO PRY2205_EFT;

-- Privilegios de creación de objetos para el owner (EFT_A)
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO PRY2205_EFT;

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_EFT  *****

-- Verificamos con que usuario se esta trabajando 
SHOW USER;

-- Sinónimos públicos para tablas compartidas (EFT_O)
CREATE PUBLIC SYNONYM syn_profesional       FOR profesional;
CREATE PUBLIC SYNONYM syn_profesion         FOR profesion;
CREATE PUBLIC SYNONYM syn_isapre            FOR isapre;
CREATE PUBLIC SYNONYM syn_tipo_contrato     FOR tipo_contrato;
CREATE PUBLIC SYNONYM syn_rangos_sueldos    FOR rangos_sueldos;
CREATE PUBLIC SYNONYM syn_cartola           FOR cartola_profesionales;
CREATE PUBLIC SYNONYM syn_empresa           FOR empresa;
CREATE PUBLIC SYNONYM syn_asesoria          FOR asesoria;

-- Privilegios sobre tablas para roles (EFT_O)
GRANT SELECT ON profesional             TO PRY2205_ROL_D;
GRANT SELECT ON profesion               TO PRY2205_ROL_D;
GRANT SELECT ON isapre                  TO PRY2205_ROL_D;
GRANT SELECT ON tipo_contrato           TO PRY2205_ROL_D;
GRANT SELECT ON rangos_sueldos          TO PRY2205_ROL_D;
GRANT INSERT ON cartola_profesionales   TO PRY2205_ROL_D;

GRANT SELECT ON cartola_profesionales   TO PRY2205_ROL_C;

/*============================================================
CASO 2: CREACION DE INFORME

Generar un informe consolidado sobre las remuneraciones de los profesionales incluyendo el sueldo 
base, comisiones, honorarios y bonos según el tipo de contrato.
============================================================*/

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_EFT_DES  *****

-- Verificamos con que usuario se esta trabajando 
SHOW USER;
 
-- Construcción del informe (EFT_D)
INSERT INTO syn_cartola (
    rut_profesional,
    nombre_profesional,
    profesion,
    isapre,
    sueldo_base,
    porc_comision_profesional,
    valor_total_comision,
    porcentate_honorario,
    bono_movilizacion,
    total_pagar
)
SELECT 
    p.rutprof                                                   AS RUT_PROFESIONAL,
    INITCAP(p.nompro || ' ' || p.apppro || ' ' || p.apmpro)     AS NOMBRE_PROFESIONAL,
    (SELECT INITCAP(pr.nomprofesion) FROM syn_profesion pr
     WHERE pr.idprofesion = p.idprofesion)                      AS PROFESION,
    (SELECT INITCAP(i.nomisapre) FROM syn_isapre i
     WHERE i.idisapre = p.idisapre)                             AS ISAPRE,
    p.sueldo                                                    AS SUELDO_BASE,
    NVL(p.comision,0)                                           AS PORC_COMISION_PROFESIONAL,
    NVL(p.sueldo * p.comision,0)                                AS VALOR_TOTAL_COMISION,
    NVL(rs.honor_pct * p.sueldo/100,0)                          AS PORCENTAJE_HONORARIO,
    -- el bono dependera del tipo de contrato de cada profesional
    CASE tc.nomtcontrato
        WHEN 'Indefinido Jornada Completa' THEN 150000
        WHEN 'Indefinido Jornada Parcial'  THEN 120000
        WHEN 'Plazo fijo'                  THEN 60000
        WHEN 'Honorarios'                  THEN 50000
        ELSE 0
    END                                                         AS BONO_MOVILIZACION,
    p.sueldo 
      + NVL(p.sueldo * p.comision/100,0)
      + NVL(rs.honor_pct * p.sueldo/100,0)
      + CASE tc.nomtcontrato
            WHEN 'Indefinido Jornada Completa' THEN 150000
            WHEN 'Indefinido Jornada Parcial'  THEN 120000
            WHEN 'Plazo fijo'                  THEN 60000
            WHEN 'Honorarios'                  THEN 50000
            ELSE 0
        END                                                     AS TOTAL_PAGAR

FROM syn_profesional p
-- join para obtener el tipo de contrato del profesional
JOIN syn_tipo_contrato tc ON p.idtcontrato = tc.idtcontrato
-- join para obtener los rangos de sueldo
JOIN syn_rangos_sueldos rs ON p.sueldo 
    BETWEEN rs.s_min AND rs.s_max
-- se ordena por profesion, sueldo base, comision y rut del profesional
ORDER BY 
    PROFESION, 
    p.sueldo DESC, 
    p.comision, 
    p.rutprof;

COMMIT;

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_EFT_CON  *****

-- Verificamos con que usuario se esta trabajando 
SHOW USER;

-- Usuario PRY2205_EFT_CON consulta la tabla (EFT_C)
SELECT * FROM syn_cartola;

/*============================================================
CASO 3: OPTIMIZACION DE SENTENCIAS SQL

Generar una vista de empresas asesoradas que permita conocer información clave sobre la relación con
cada cliente, el nivel de asesorías recibidas, devoluciones de IVA estimadas y categorización de los 
clientes según su nivel de participación
============================================================*/

-- ====== CASO 3.1: Vista Empresas Asesoradas ======

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_EFT  *****

-- Verificamos con que usuario se esta trabajando 
SHOW USER;

-- Creacion de vista empresas asesoradas (EFT_O)
CREATE OR REPLACE VIEW vw_empresas_asesoradas AS
SELECT 
    REGEXP_REPLACE(
        LPAD(TO_CHAR(e.rut_empresa), 8, '0'), '([0-9]{1,2})([0-9]{3})([0-9]{3})',
        '\1.\2.\3') || '-' || e.dv_empresa                                          AS RUT_EMPRESA,
    UPPER(e.nomempresa)                                                             AS NOMBRE_EMPRESA,
    e.iva_declarado                                                                 AS IVA,
    TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecha_iniciacion_actividades)/12)               AS ANIOS_EXISTENCIA,
    ROUND(COUNT(a.idempresa)/12)                                                    AS TOTAL_ASESORIAS_ANUALES,
    ROUND((e.iva_declarado * (COUNT(a.idempresa)/12))/100)                          AS DEVOLUCION_IVA,
    -- clasificacion de clientes segun las asesorias contratadas en el periodo
    CASE 
        WHEN ROUND(COUNT(a.idempresa)/12) >= 6 THEN 'CLIENTE PREMIUM'
        WHEN ROUND(COUNT(a.idempresa)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
        ELSE 'CLIENTE POCO CONCURRIDO'
    END                                                                             AS TIPO_CLIENTE,
    -- promocion correspondiente segun el tipo de cliente y la cantidad de asesorias contratadas en el año 
    CASE 
        -- CLIENTE PREMIUM con ≥ 7 asesorías
        WHEN ROUND(COUNT(a.idempresa)/12) >= 7 
             AND (CASE 
                    WHEN ROUND(COUNT(a.idempresa)/12) >= 6 THEN 'CLIENTE PREMIUM'
                    WHEN ROUND(COUNT(a.idempresa)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
                    ELSE 'CLIENTE POCO CONCURRIDO'
                  END) = 'CLIENTE PREMIUM'
             THEN '1 ASESORÍA GRATIS'
        -- CLIENTE PREMIUM con < 7 asesorías
        WHEN ROUND(COUNT(a.idempresa)/12) < 7 
             AND (CASE 
                    WHEN ROUND(COUNT(a.idempresa)/12) >= 6 THEN 'CLIENTE PREMIUM'
                    WHEN ROUND(COUNT(a.idempresa)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
                    ELSE 'CLIENTE POCO CONCURRIDO'
                  END) = 'CLIENTE PREMIUM'
             THEN '1 ASESORÍA 40% DE DESCUENTO'
        -- CLIENTE con = 5 asesorías
        WHEN ROUND(COUNT(a.idempresa)/12) >= 5 
             AND (CASE 
                    WHEN ROUND(COUNT(a.idempresa)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
                    ELSE 'CLIENTE POCO CONCURRIDO'
                  END) = 'CLIENTE'
             THEN '1 ASESORÍA 30% DE DESCUENTO'
        -- CLIENTE con < 5 asesorías
        WHEN ROUND(COUNT(a.idempresa)/12) < 5 
             AND (CASE 
                    WHEN ROUND(COUNT(a.idempresa)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
                    ELSE 'CLIENTE POCO CONCURRIDO'
                  END) = 'CLIENTE'
             THEN '1 ASESORÍA 20% DE DESCUENTO'
        -- CLIENTE POCO CONCURRIDO
        WHEN (CASE 
                WHEN ROUND(COUNT(a.idempresa)/12) >= 6 THEN 'CLIENTE PREMIUM'
                WHEN ROUND(COUNT(a.idempresa)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
                ELSE 'CLIENTE POCO CONCURRIDO'
              END) = 'CLIENTE POCO CONCURRIDO'
             THEN 'CAPTAR CLIENTE'
        ELSE 'SIN PROMOCIÓN'
    END                                                                             AS CORRESPONDE 
FROM syn_empresa e
JOIN syn_asesoria a ON e.idempresa = a.idempresa
-- filtro para considerar solo los datos del año anterior
WHERE EXTRACT(YEAR FROM a.fin) = EXTRACT(YEAR FROM SYSDATE)-1
GROUP BY 
    e.rut_empresa, 
    e.dv_empresa, 
    e.nomempresa, 
    e.fecha_iniciacion_actividades, 
    e.iva_declarado
ORDER BY e.nomempresa ASC;

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_EFT  *****

-- Permiso de consulta sobre la vista para el rol de consulta (EFT_O)
GRANT SELECT ON vw_empresas_asesoradas TO PRY2205_ROL_C;

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_EFT_CON  *****

-- Resultado consulta (EFT_C)
SELECT * FROM PRY2205_EFT.vw_empresas_asesoradas;

-- ====== CASO 3.2: Creación de Índices ======

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_EFT  *****

-- Índices para optimizar la vista (EFT_O)
CREATE INDEX idx_asesoria_year ON asesoria(EXTRACT(YEAR FROM fin));
