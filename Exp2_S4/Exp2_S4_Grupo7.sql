/*============================================================
CASO 1: LISTADO DE TRABAJADORES
============================================================*/
SELECT
    UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "Nombre Completo Trabajador",
    REGEXP_REPLACE(LPAD(TO_CHAR(t.numrut), 8, '0'), '([0-9]{1,2})([0-9]{3})([0-9]{3})', '\1.\2.\3') || '-' || t.dvrut AS "RUT Trabajador",
    tt.desc_categoria AS "Tipo trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad trabajador",
    TO_CHAR(t.sueldo_base, '$999G999G999') AS "Sueldo base"
    
FROM trabajador t

JOIN tipo_trabajador tt 
    ON t.id_categoria_t = tt.id_categoria
    
JOIN comuna_ciudad cc 
    ON t.id_ciudad = cc.id_ciudad
    
WHERE t.sueldo_base BETWEEN 650000 AND 3000000

ORDER BY 
    cc.nombre_ciudad DESC, 
    t.sueldo_base ASC;

/*============================================================
CASO 2: LISTADO CAJEROS
============================================================*/
SELECT
    REGEXP_REPLACE(LPAD(TO_CHAR(t.numrut), 8, '0'), '([0-9]{1,2})([0-9]{3})([0-9]{3})', '\1.\2.\3') || '-' || t.dvrut AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || UPPER(t.appaterno) AS "Nombre Trabajador",
    COUNT(tc.nro_ticket) AS "Cantidad Tickets Vendidos",
    TO_CHAR(SUM(tc.monto_ticket), '$999G999G999') AS "Total Vendido",
    TO_CHAR(SUM(ct.valor_comision), '$999G999G999') AS "Comisión Total",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Comuna Trabajador"

FROM trabajador t
JOIN tipo_trabajador tt 
    ON t.id_categoria_t = tt.id_categoria
    
JOIN comuna_ciudad cc 
    ON t.id_ciudad = cc.id_ciudad
    
JOIN tickets_concierto tc 
    ON tc.numrut_t = t.numrut
    
JOIN comisiones_ticket ct 
    ON ct.nro_ticket = tc.nro_ticket

WHERE UPPER(tt.desc_categoria) = 'CAJERO'

GROUP BY
  t.numrut,
  t.dvrut,
  t.nombre,
  t.appaterno,
  tt.desc_categoria,
  cc.nombre_ciudad

HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC;

/*============================================================
CASO 3: LISTADO DE BONIFICACIONES
============================================================*/
SELECT
    TO_CHAR(FLOOR(t.numrut / 1000000)) || '.' ||
    TO_CHAR(MOD(FLOOR(t.numrut / 1000), 1000), 'FM000') || '.' ||
    TO_CHAR(MOD(t.numrut, 1000), 'FM000') || '-' || t.dvrut AS "Rut Trabajador", --Aqui quisimos probar otra forma de formatear el RUT
    INITCAP(t.nombre || ' ' || t.appaterno) AS "Trabajador Nombre",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing) AS "Años Antigüedad",
    -- TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) AS "Años Antigüedad", metodo alternativo que considera el calculo en meses 
    COUNT(af.numrut_carga) AS "Num. Cargas Familiares",
    INITCAP(i.nombre_isapre) AS "Nombre Isapre",
    TO_CHAR(t.sueldo_base, '$999G999G999') AS "Sueldo Base",

    CASE
        WHEN i.nombre_isapre = 'FONASA' THEN TO_CHAR(t.sueldo_base * 0.01, '$999G999G999')
        ELSE LPAD('0', 12)
    END AS "Bono Fonasa",

    TO_CHAR(CASE 
        WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing) <= 10 THEN t.sueldo_base * 0.10
        WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing) > 11 THEN t.sueldo_base * 0.15
    END, '$999G999G999') AS "Bono Antigüedad",

    INITCAP(a.nombre_afp) AS "Nombre AFP",
    UPPER(ecv.desc_estcivil) AS "Estado Civil"

FROM trabajador t
LEFT JOIN isapre i 
    ON t.cod_isapre = i.cod_isapre
    
LEFT JOIN afp a 
    ON t.cod_afp = a.cod_afp
    
LEFT JOIN asignacion_familiar af 
    ON t.numrut = af.numrut_t
    
LEFT JOIN est_civil ec 
    ON ec.numrut_t = t.numrut
    
LEFT JOIN estado_civil ecv 
    ON ec.id_estcivil_est = ecv.id_estcivil

WHERE (ec.fecter_estcivil IS NULL OR ec.fecter_estcivil > SYSDATE)

GROUP BY
  t.numrut,
  t.dvrut,
  t.nombre,
  t.appaterno,
  t.fecing,
  t.sueldo_base,
  i.nombre_isapre,
  a.nombre_afp,
  ecv.desc_estcivil

ORDER BY t.numrut ASC;