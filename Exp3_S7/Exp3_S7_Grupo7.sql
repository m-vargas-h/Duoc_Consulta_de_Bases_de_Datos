/*============================================================
ACTIVIDAD FORMATIVA 5:
OPTIMIZANDO CONSULTAS SQL

Grupo 7:
- Elizabeth Arevalo Alarcón
- Miguel Angel Vargas Huenul
============================================================*/

/*============================================================
CASO 1: BONIFICACIÓN DE TRABAJADORES
============================================================*/

-- Limpieza de tabla y reinicio de secuencia de ser necesario
DELETE FROM detalle_bonificaciones_trabajador;
COMMIT;

DROP SEQUENCE seq_det_bonif;

CREATE SEQUENCE seq_det_bonif START WITH 100 INCREMENT BY 10;

-- Inserción de datos en la tabla detalle_bonificaciones_trabajador
INSERT INTO detalle_bonificaciones_trabajador
    (num, rut, nombre_trabajador, sueldo_base, num_ticket, direccion,
     sistema_salud, monto, bonif_x_ticket, simulacion_x_ticket, simulacion_antiguedad)

SELECT
    seq_det_bonif.NEXTVAL,
    TO_CHAR(t.numrut) || '-' || t.dvrut,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno),
    TO_CHAR(t.sueldo_base),
    NVL(TO_CHAR(tc.nro_ticket), 'No hay info'),
    t.direccion,
    i.nombre_isapre,
    TO_CHAR(NVL(tc.monto_ticket, 0)),
    TO_CHAR(
        CASE
            WHEN tc.monto_ticket IS NULL THEN 0
            WHEN tc.monto_ticket <= 50000 THEN 0
            WHEN tc.monto_ticket > 50000 AND tc.monto_ticket <= 100000
                THEN ROUND(tc.monto_ticket * 0.05)
            WHEN tc.monto_ticket > 100000
                THEN ROUND(tc.monto_ticket * 0.07)
        END
    ),
    TO_CHAR(
        CASE
            WHEN tc.monto_ticket IS NULL THEN t.sueldo_base
            WHEN tc.monto_ticket <= 50000 THEN t.sueldo_base
            WHEN tc.monto_ticket > 50000 AND tc.monto_ticket <= 100000
                THEN t.sueldo_base + ROUND(tc.monto_ticket * 0.05)
            WHEN tc.monto_ticket > 100000
                THEN t.sueldo_base + ROUND(tc.monto_ticket * 0.07)
        END
    ),
    TO_CHAR(ROUND(t.sueldo_base * (1 + b.porcentaje)))

FROM s_trabajador t

LEFT JOIN s_tickets tc ON t.numrut = tc.numrut_t

JOIN isapre i ON t.cod_isapre = i.cod_isapre

JOIN s_bono_antiguedad b ON (FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecing)/12)
    BETWEEN b.limite_inferior AND b.limite_superior)

WHERE i.porc_descto_isapre > 4
    AND FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecnac)/12) < 50;

COMMIT;

-- Vista con formato
CREATE OR REPLACE VIEW v_detalle_bonificaciones AS
SELECT
    num,
    rut,
    nombre_trabajador,
    TO_CHAR(TO_NUMBER(sueldo_base), '$999G999G999G999')             AS sueldo_base,
    num_ticket,
    direccion,
    sistema_salud,
    TO_CHAR(TO_NUMBER(monto), '$999G999G999G999')                   AS monto,
    TO_CHAR(TO_NUMBER(bonif_x_ticket), '$999G999G999G999')          AS bonif_x_ticket,
    TO_CHAR(TO_NUMBER(simulacion_x_ticket), '$999G999G999G999')     AS simulacion_x_ticket,
    TO_CHAR(TO_NUMBER(simulacion_antiguedad), '$999G999G999G999')   AS simulacion_antiguedad
FROM detalle_bonificaciones_trabajador;

-- Consulta de validación
SELECT *
FROM v_detalle_bonificaciones
ORDER BY (SELECT TO_NUMBER(monto)
            FROM detalle_bonificaciones_trabajador d
            WHERE d.num = v_detalle_bonificaciones.num) DESC,
         nombre_trabajador;

/*============================================================
CASO 2: VISTAS
============================================================*/

-- Sinónimos privados
CREATE OR REPLACE SYNONYM t_trab FOR trabajador;
CREATE OR REPLACE SYNONYM b_esco FOR bono_escolar;

-- Vista V_AUMENTOS_ESTUDIOS
CREATE OR REPLACE VIEW v_aumentos_estudios AS
SELECT
    REGEXP_REPLACE(LPAD(TO_CHAR(t.numrut), 8, '0'),
        '([0-9]{1,2})([0-9]{3})([0-9]{3})', '\1.\2.\3') || '-' || t.dvrut                   AS rut_trabajador,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)                           AS nombre_completo,
    b.descrip                                                                               AS nivel_educacion,
    NVL(b.porc_bono, 0)                                                                     AS porc_bono_estudio,
    t.sueldo_base                                                                           AS sueldo_actual,
    ROUND(t.sueldo_base * (NVL(b.porc_bono, 0) / 100))                                      AS aumento_por_estudios,
    TO_CHAR(ROUND(t.sueldo_base * (1 + NVL(b.porc_bono, 0) / 100)), '$999G999G999G999')     AS sueldo_con_aumento
    
FROM t_trab t

JOIN b_esco b ON b.id_escolar = t.id_escolaridad_t

LEFT JOIN (
    SELECT af.numrut_t, COUNT(*) AS cantidad_cargas
    FROM asignacion_familiar af
    GROUP BY af.numrut_t
) c ON c.numrut_t = t.numrut

LEFT JOIN tipo_trabajador tt ON tt.id_categoria = t.id_categoria_t

WHERE tt.desc_categoria = 'CAJERO' OR NVL(c.cantidad_cargas, 0) BETWEEN 1 AND 2

ORDER BY porc_bono_estudio ASC, nombre_completo ASC;

-- Validación
SELECT * FROM v_aumentos_estudios;

-- Consulta original (exacta por apellido materno)
SELECT numrut, fecnac, t.nombre, appaterno, t.apmaterno

FROM trabajador t

JOIN isapre i ON i.cod_isapre = t.cod_isapre

WHERE t.apmaterno = 'CASTILLO'

ORDER BY t.nombre;

-- Consulta ajustada con UPPER
SELECT numrut, fecnac, t.nombre, appaterno, t.apmaterno

FROM trabajador t

JOIN isapre i ON i.cod_isapre = t.cod_isapre

WHERE UPPER(t.apmaterno) = 'CASTILLO'

ORDER BY t.nombre;

-- Índices para optimización
CREATE INDEX idx_trabajador_apm ON trabajador (apmaterno);
CREATE INDEX idx_trabajador_upper_apm ON trabajador (UPPER(apmaterno));
