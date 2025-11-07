/*============================================================
CASO 1:
============================================================*/
SELECT
    -- Formato RUT con puntos y guion
    SUBSTR(TO_CHAR(NUMRUT_CLI), 1, LENGTH(TO_CHAR(NUMRUT_CLI)) - 6) || '.' ||
    SUBSTR(TO_CHAR(NUMRUT_CLI), LENGTH(TO_CHAR(NUMRUT_CLI)) - 5, 3) || '.' ||
    SUBSTR(TO_CHAR(NUMRUT_CLI), LENGTH(TO_CHAR(NUMRUT_CLI)) - 2, 3) || '-' || DVRUT_CLI AS "RUT cliente",

    -- Nombre completo con formato capitalizado
    INITCAP(NOMBRE_CLI || ' ' || APPATERNO_CLI || ' ' || APMATERNO_CLI) AS "Nombre Completo Cliente",

    -- Dirección tal como está registrada
    DIRECCION_CLI AS "Dirección Cliente",

    -- Renta redondeada a entero
    ROUND(RENTA_CLI) AS "Renta Cliente",
    
    SUBSTR('0' || TO_CHAR(CELULAR_CLI, 'FM00000000'), 1, 2) || '-' ||
    SUBSTR('0' || TO_CHAR(CELULAR_CLI, 'FM00000000'), 3, 3) || '-' ||
    SUBSTR('0' || TO_CHAR(CELULAR_CLI, 'FM00000000'), 6, 4) AS "Celular Cliente",

    -- Clasificación por tramo de renta
    CASE
        WHEN RENTA_CLI > 500000 THEN 'TRAMO 1'
        WHEN RENTA_CLI BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN RENTA_CLI BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END AS "Tramo Renta Cliente"

FROM CLIENTE
WHERE RENTA_CLI BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
    AND CELULAR_CLI IS NOT NULL
ORDER BY INITCAP(NOMBRE_CLI || ' ' || APPATERNO_CLI || ' ' || APMATERNO_CLI);

/*============================================================
CASO 2: 
============================================================*/