--pruebas sobre las tablas de staging para identificar y corregir problemas de duplicidad,
--integridad referencial, consistencia, valores nulos y anomalías en los datos.

--productos duplicados
SELECT ID_producto, COUNT(*)
FROM StagingJardineria.dbo.stg_producto
GROUP BY ID_producto
HAVING COUNT(*) > 1;

--consistencia de referencia
SELECT sv.*
FROM StagingJardineria.dbo.stg_ventas sv
LEFT JOIN StagingJardineria.dbo.stg_producto sp ON sv.id_stg_producto = sp.id_stg_producto
WHERE sp.id_stg_producto IS NULL;

--comparacion entre origen y stagin
SELECT 
    (SELECT COUNT(*) FROM Jardineria1.dbo.producto) AS originales,
    (SELECT COUNT(*) FROM StagingJardineria.dbo.stg_producto) AS staging;


-- verificar transformaciones realizadas
SELECT TOP 10 *
FROM StagingJardineria.dbo.stg_producto
WHERE Dimensiones = 'No especificado';

--Categoría fuera del rango positivo esperado
SELECT *
FROM StagingJardineria.dbo.stg_producto
WHERE Categoria <= 0;

--buscar nulos 
SELECT COUNT(*) FROM StagingJardineria.dbo.stg_producto WHERE Nombre IS NULL OR CodigoProducto IS NULL;

-- Validación de rangos y formatos
-- Precios y cantidades deben ser positivos
SELECT COUNT(*) AS PreciosNegativos
FROM  StagingJardineria.dbo.stg_ventas
WHERE Precio_unidad <= 0;

SELECT COUNT(*) AS CantidadesInvalidas
FROM  StagingJardineria.dbo.stg_ventas
WHERE Cantidad_vendida <= 0;

-- Duplicados en combinación Nombre + Proveedor (ejemplo clave natural)
SELECT Nombre, Proveedor, COUNT(*)
FROM StagingJardineria.dbo.stg_producto
GROUP BY Nombre, Proveedor
HAVING COUNT(*) > 1;


--Verificar valores atípicos (ejemplo, precios mucho mayores que promedio)
WITH PrecioStats AS (
  SELECT AVG(Precio_unidad) AS Promedio, STDEV(Precio_unidad) AS Desviacion
  FROM StagingJardineria.dbo.stg_ventas
)
SELECT *
FROM StagingJardineria.dbo.stg_ventas, PrecioStats
WHERE Precio_unidad > Promedio + 3 * Desviacion;


-- Ventas con id_stg_fecha que no existen en fechas
SELECT sv.*
FROM StagingJardineria.dbo.stg_ventas sv
LEFT JOIN stg_fecha sf ON sv.id_stg_fecha = sf.id_stg_fecha
WHERE sf.id_stg_fecha IS NULL;

-- Ventas con id_stg_producto que no existan en productos
SELECT sv.*
FROM StagingJardineria.dbo.stg_ventas sv
LEFT JOIN stg_producto sp ON sv.id_stg_producto = sp.id_stg_producto
WHERE sp.id_stg_producto IS NULL;
