/*============================================================
ACTIVIDAD SUMATIVA 3:
APLICANDO CONTROL DE ACCESO A BASES DE DATOS

- Miguel Angel Vargas Huenul
============================================================*/

/*
Para el desarrollo de este caso se trabajara con 3 usuarios, ADMIN, PRY2205_USER1 y PRY2205_USER2.
Se indicara el inicio de cada sección de código que usuario debe ejecutar cada acción, para ello se
utilizara el siguiente comentario:
***** ESTA SECCION DEBE SER EJECUTADA COMO USUARIO XXXXXX *****

Ademas de lo anterior, en cada bloque de código se indicara en el comentario respectivo que usuario 
debe ejecutar el bloque mediante las siguientes etiquetas:
- ADMIN         : A
- PRY2205_USER1 : U1
- PRY2205_USER2 : U2
*/

/*============================================================
CASO 1: ESTRATEGIA DE SEGURIDAD
============================================================*/
-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO ADMIN *****

-- ========== SECCION OPCIONAL PARA LIMPIAR USUARIOS Y ASEGURAR EJECUCION LIMPIA ==========
-- Eliminar usuarios y todos sus objetos (A)
DROP USER PRY2205_USER1 CASCADE;
DROP USER PRY2205_USER2 CASCADE;

-- Eliminar roles creados (A)
DROP ROLE PRY2205_ROL_D;
DROP ROLE PRY2205_ROL_P;
-- ========== SECCION OPCIONAL PARA LIMPIAR USUARIOS Y ASEGURAR EJECUCION LIMPIA ==========

-- Creación de usuarios (A)
CREATE USER PRY2205_USER1 IDENTIFIED BY "Usuario1_2025"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION TO PRY2205_USER1;
GRANT RESOURCE TO PRY2205_USER1;

CREATE USER PRY2205_USER2 IDENTIFIED BY "Usuario2_2025"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION TO PRY2205_USER2;

-- Creación de roles (A)
CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_P;

-- Asignación de privilegios a roles (A)
GRANT CREATE TABLE TO PRY2205_ROL_D;
GRANT CREATE VIEW TO PRY2205_ROL_D;
GRANT CREATE SYNONYM TO PRY2205_ROL_D;

GRANT CREATE SEQUENCE TO PRY2205_ROL_P;
GRANT CREATE TRIGGER TO PRY2205_ROL_P;
GRANT CREATE TABLE TO PRY2205_ROL_P;

-- Privilegios de User1 para poder crear sinónimos públicos
GRANT CREATE PUBLIC SYNONYM TO PRY2205_USER1;

-- Asignación de roles a usuarios (A)
GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_USER1 *****

-- Creación de tablas del modelo relacional (U1)
-- Utilizar script "PRY2205_Exp3_S8_CreaEsquemaPoblado (forma C).sql"

-- Creación de sinónimos privados (U1)
CREATE SYNONYM alumno_syn FOR alumno; -- se crea como privado ya que solo lo necesita user1

-- Sinónimos Públicos (necesarios para USER2) (U1)
CREATE PUBLIC SYNONYM libro_syn FOR libro;
CREATE PUBLIC SYNONYM ejemplar_syn FOR ejemplar;
CREATE PUBLIC SYNONYM prestamo_syn FOR prestamo;

-- Otorgar privilegios de acceso a USER2 sobre los objetos necesarios (U1)
GRANT SELECT ON prestamo TO PRY2205_USER2;
GRANT SELECT ON ejemplar TO PRY2205_USER2;
GRANT SELECT ON libro TO PRY2205_USER2;
GRANT SELECT ON alumno TO PRY2205_USER2;

/*============================================================
CASO 2: Creación de Informe CONTROL_STOCK_LIBROS
============================================================*/
-- ***** ESTA SECCION DEBE SER EJECUTADA POR EL USUARIO PRY2205_USER2 *****

-- ========== SECCION OPCIONAL PARA LIMPIAR LA TABLA Y SECUENCIA DE SER NECESARIO ==========
DROP TABLE CONTROL_STOCK_LIBROS CASCADE CONSTRAINTS;
DROP SEQUENCE SEQ_CONTROL_STOCK;
-- ========== SECCION OPCIONAL PARA LIMPIAR LA TABLA Y SECUENCIA DE SER NECESARIO ==========

-- Creación de secuencia para correlativo (U2)
CREATE SEQUENCE SEQ_CONTROL_STOCK START WITH 1 INCREMENT BY 1;

-- Creación de tabla CONTROL_STOCK_LIBROS (U2)
CREATE TABLE CONTROL_STOCK_LIBROS (
    ID_CONTROL NUMBER,
    LIBRO_ID NUMBER,
    NOMBRE_LIBRO VARCHAR2(200),
    TOTAL_EJEMPLARES NUMBER,
    EN_PRESTAMO NUMBER,
    DISPONIBLES NUMBER,
    PORCENTAJE_PRESTAMO NUMBER,
    STOCK_CRITICO CHAR(1)
);

-- Inserción de datos en la tabla usando la secuencia (U2)
INSERT INTO CONTROL_STOCK_LIBROS (
    ID_CONTROL,
    LIBRO_ID,
    NOMBRE_LIBRO,
    TOTAL_EJEMPLARES,
    EN_PRESTAMO,
    DISPONIBLES,
    PORCENTAJE_PRESTAMO,
    STOCK_CRITICO
)
SELECT 
    SEQ_CONTROL_STOCK.NEXTVAL AS ID_CONTROL,
    t.LIBRO_ID,
    t.NOMBRE_LIBRO,
    t.TOTAL_EJEMPLARES,
    t.EN_PRESTAMO,
    t.DISPONIBLES,
    t.PORCENTAJE_PRESTAMO,
    t.STOCK_CRITICO
FROM (
    SELECT
        l.libroid                                                                                    AS LIBRO_ID,
        l.nombre_libro                                                                               AS NOMBRE_LIBRO,
        COUNT(DISTINCT e.ejemplarid)                                                                 AS TOTAL_EJEMPLARES,
        SUM(CASE WHEN p.empleadoid IN (190,180,150)
            AND TO_CHAR(p.fecha_inicio,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE,-24),'YYYY')
            AND p.fecha_entrega > p.fecha_termino
            THEN 1 ELSE 0 END)                                                                       AS EN_PRESTAMO,
        COUNT(DISTINCT e.ejemplarid) -
        SUM(CASE WHEN p.empleadoid IN (190,180,150)
            AND TO_CHAR(p.fecha_inicio,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE,-24),'YYYY')
            AND p.fecha_entrega > p.fecha_termino
            THEN 1 ELSE 0 END)                                                                       AS DISPONIBLES,
        ROUND( (SUM(CASE WHEN p.empleadoid IN (190,180,150)
                        AND TO_CHAR(p.fecha_inicio,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE,-24),'YYYY')
                        AND p.fecha_entrega > p.fecha_termino
                        THEN 1 ELSE 0 END) / COUNT(DISTINCT e.ejemplarid)) * 100 )                   AS PORCENTAJE_PRESTAMO,
        CASE WHEN (COUNT(DISTINCT e.ejemplarid) - SUM(CASE WHEN p.empleadoid IN (190,180,150) 
                        AND TO_CHAR(p.fecha_inicio,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE,-24),'YYYY')
                        AND p.fecha_entrega > p.fecha_termino
                        THEN 1 ELSE 0 END)) >= 2
            THEN 'S' ELSE 'N' END                                                                    AS STOCK_CRITICO
    FROM libro_syn l
    JOIN ejemplar_syn e ON l.libroid = e.libroid
    LEFT JOIN prestamo_syn p ON e.ejemplarid = p.ejemplarid AND e.libroid = p.libroid
    WHERE EXISTS (
        SELECT 1
        FROM prestamo_syn p2
        WHERE p2.libroid = l.libroid
            AND p2.empleadoid IN (190,180,150)
            AND TO_CHAR(p2.fecha_inicio,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE,-24),'YYYY')
    )
    GROUP BY 
        l.libroid, 
        l.nombre_libro
    ORDER BY l.libroid
) t;

-- Confirmar cambios (U2)
COMMIT;

-- revision de tabla creada (U2)
SELECT * FROM CONTROL_STOCK_LIBROS
ORDER BY ID_CONTROL;

/*============================================================
CASO 3: Optimización de Sentencias SQL
============================================================*/
-- ***** ESTA SECCION DEBE SER EJECUTADA CON EL USUARIO PRY2205_USER1 *****

-- ========== SECCION OPCIONAL PARA LIMPIAR LOS INDICES CREADOS SI ES NECESARIO ==========
DROP INDEX IDX_PRESTAMO_FECHA;
DROP INDEX IDX_ALUMNO_CARRERA;
DROP INDEX IDX_LIBRO;
-- ========== SECCION OPCIONAL PARA LIMPIAR LOS INDICES CREADOS SI ES NECESARIO ==========

-- Creación de vista VW_DETALLE_MULTAS (U1)
CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT 
    p.prestamoid                                                                                AS ID_PRESTAMO,
    INITCAP(a.nombre || ' ' || a.apaterno)                                                      AS NOMBRE_ALUMNO,
    c.descripcion                                                                               AS NOMBRE_CARRERA,
    l.libroid                                                                                   AS ID_LIBRO,
    TO_CHAR(l.precio, '$999G999G999G999')                                                       AS VALOR_LIBRO,
    TO_CHAR(p.fecha_termino, 'DD/MM/YYYY')                                                      AS FECHA_TERMINO,
    TO_CHAR(p.fecha_entrega, 'DD/MM/YYYY')                                                      AS FECHA_ENTREGA,
    (p.fecha_entrega - p.fecha_termino)                                                         AS DIAS_ATRASO,
    TO_CHAR(ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino)), '$999G999G999G999')   AS VALOR_MULTA,
    NVL(rm.porc_rebaja_multa/100, 0)                                                            AS PORCENTAJE_REBAJA_MULTA,
    TO_CHAR(ROUND(
        NVL((l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino)) * 
            (1 - (rm.porc_rebaja_multa/100)), 
            (l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino)))
    ), '$999G999G999G999')                                                                      AS VALOR_REBAJADO
FROM prestamo_syn p
JOIN alumno_syn a ON p.alumnoid = a.alumnoid
JOIN carrera c ON a.carreraid = c.carreraid
JOIN libro_syn l ON p.libroid = l.libroid
LEFT JOIN rebaja_multa rm ON c.carreraid = rm.carreraid
WHERE p.fecha_entrega > p.fecha_termino
    AND TO_CHAR(p.fecha_termino,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE,-24),'YYYY')
ORDER BY p.fecha_entrega DESC;

-- Ver todas las filas de la vista (U1)
SELECT * FROM VW_DETALLE_MULTAS;

-- Creación de índices para optimizar la vista (U1)
CREATE INDEX IDX_PRESTAMO_FECHA ON prestamo(fecha_termino, fecha_entrega);
CREATE INDEX IDX_ALUMNO_CARRERA ON alumno(carreraid);
CREATE INDEX IDX_LIBRO ON libro(libroid, precio);

-- Ver todas las filas de la vista (U1)
SELECT * FROM VW_DETALLE_MULTAS;



