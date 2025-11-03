/*============================================================
CASO 1: ANALISIS DE FACTURAS
============================================================*/
SELECT
    NUMFACTURA AS "N° Factura",
    TO_CHAR(FECHA, 'DD "de" Month yyyy') AS "Fecha de Emisión",
    LPAD(RUTCLIENTE, 10, '0') AS "RUT Cliente",
    TO_CHAR(NETO, 'L999G999') AS "Monto Neto",
    TO_CHAR(IVA, 'L999G999') AS "Monto Iva",
    TO_CHAR(TOTAL, 'L999G999') AS "Total Factura",
    CASE
        WHEN TOTAL BETWEEN 0 AND 50000 THEN 'BAJO'
        WHEN TOTAL BETWEEN 50001 AND 100000 THEN 'MEDIO'
        ELSE 'ALTO'
    END AS "Categoría Monto",
    CASE
        WHEN CODPAGO = 1 THEN 'EFECTIVO'
        WHEN CODPAGO = 2 THEN 'TARJETA DEBITO'
        WHEN CODPAGO = 3 THEN 'TARJETA CREDITO'
        ELSE 'CHEQUE'
    END AS "Forma de pago"
FROM FACTURA
WHERE EXTRACT(YEAR FROM FECHA) = EXTRACT(YEAR FROM SYSDATE) - 1
ORDER BY
    FECHA DESC,
    NETO DESC;

/*============================================================
CASO 2: CLASIFICACION DE CLIENTES
============================================================*/ 
SELECT
    LPAD(RUTCLIENTE, 12, '*') AS "RUT",
    NOMBRE AS "Cliente",
    NVL(TO_CHAR(TELEFONO), 'Sin teléfono') AS "TELÉFONO",
    NVL(TO_CHAR(CODCOMUNA), 'Sin comuna') AS "COMUNA",
    ESTADO,
    CASE
        WHEN CREDITO = 0 THEN 'Sin crédito'
        WHEN SALDO / CREDITO < 0.5 THEN 'Bueno (' || TO_CHAR(CREDITO - SALDO, 'L999G999G999') || ')'
        WHEN SALDO / CREDITO BETWEEN 0.5 AND 0.8 THEN 'Regular (' || TO_CHAR(SALDO, 'L999G999G999') || ')'
        ELSE 'Crítico'
    END AS "Estado Crédito",
    NVL(SUBSTR(MAIL, INSTR(MAIL, '@') + 1), 'Correo no registrado') AS "Dominio Correo"
FROM CLIENTE
WHERE ESTADO = 'A' AND CREDITO > 0
ORDER BY NOMBRE ASC;

/*============================================================ 
CASO 3: STOCK DE PRODUCTOS
============================================================*/

/* Definimos el valor de las variables una vez al inicio, de esta forma si la consulta usa alguna de 
ellas multiples veces no sera necesario ingresar el valor cada vez */
DEFINE TIPOCAMBIO_DOLAR = &TIPOCAMBIO_DOLAR
DEFINE UMBRAL_BAJO = &UMBRAL_BAJO
DEFINE UMBRAL_ALTO = &UMBRAL_ALTO

SELECT
    CODPRODUCTO AS ID,
    INITCAP(DESCRIPCION) AS "Descrición de Producto",
    CASE 
        WHEN VALORCOMPRADOLAR IS NOT NULL THEN
            TO_CHAR(VALORCOMPRADOLAR, '999G999D00','NLS_NUMERIC_CHARACTERS='',.''') || ' USD'
        ELSE  'Sin registro'
    END AS "Compra en USD",
    CASE 
        WHEN VALORCOMPRADOLAR IS NOT NULL THEN 
            TO_CHAR(ROUND(VALORCOMPRADOLAR * &TIPOCAMBIO_DOLAR), 'L999G999', 'NLS_NUMERIC_CHARACTERS='',.''') || ' PESOS'
        ELSE  'Sin registro'
    END AS "USD convertido",
    TOTALSTOCK AS Stock,
    CASE
        WHEN TOTALSTOCK IS NULL THEN 'Sin datos'
        WHEN TOTALSTOCK < &UMBRAL_BAJO THEN '¡ALERTA stock muy bajo!'
        WHEN TOTALSTOCK BETWEEN &UMBRAL_BAJO AND &UMBRAL_ALTO THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END AS "Alerta Stock",
    CASE
        WHEN TOTALSTOCK > 80 THEN TO_CHAR(ROUND(VUNITARIO * 0.9), 'L999G999')
        ELSE 'N/A'
    END AS "Precio Oferta"
FROM PRODUCTO
WHERE
    LOWER(DESCRIPCION) LIKE '%zapato%'
    AND LOWER(PROCEDENCIA) = 'i'
ORDER BY CODPRODUCTO DESC;
    
/* Limpiamos los valores almacenados para que sean solicitados en cada ejecucion de la consulta en 
caso de que valores como el tipo de cambio hayan variado o se hayan definido nuevos umbrales de stock */
UNDEFINE TIPOCAMBIO_DOLAR
UNDEFINE UMBRAL_BAJO
UNDEFINE UMBRAL_ALTO