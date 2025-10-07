CREATE DATABASE StagingJardineria;
use StagingJardineria;

CREATE TABLE stg_ventas(
   id_stg_ventas INT IDENTITY (1,1) PRIMARY KEY,
   id_stg_producto INT,
   id_stg_fecha INT,
   Cantidad_vendida INT,
   Precio_unidad INT,
   Total_venta numeric(15,2)
  );

CREATE TABLE stg_producto(
	id_stg_producto INT IDENTITY(1,1) PRIMARY KEY,
	ID_producto INT,
	CodigoProducto VARCHAR(15),
	Nombre VARCHAR(70),
	Categoria INT,
	Dimensiones VARCHAR(25),
	Proveedor VARCHAR(50)
);

CREATE TABLE stg_fecha(
	id_stg_fecha INT IDENTITY(1,1) PRIMARY KEY,
	Fecha DATE,
	Anio INT,
	Mes INT,
	Dia INT

);

--cargar informacion staging producto
TRUNCATE TABLE stg_producto;--limpiamos tabla 
insert into stg_producto (
	ID_producto ,
	CodigoProducto,
	Nombre,
	Categoria,
	Dimensiones,
	Proveedor
)SELECT 
	p.ID_producto,
	p.codigoProducto,
	LTRIM(RTRIM(p.nombre))AS  nombre,
	p.Categoria,
	p.dimensiones,
	p.proveedor
FROM jardineria1.dbo.producto p 
WHERE p.CodigoProducto is not null 
AND p.nombre is not null 
AND p.precio_proveedor >0 
AND p.precio_venta >0
AND p.cantidad_en_stock >=1;

-- cargar informacion staging fecha 
TRUNCATE TABLE stg_fecha;--limpiamos tabla 
INSERT INTO stg_fecha (
	Fecha,
	Anio,
	Mes,
	Dia
)
SELECT DISTINCT 
	CAST(fecha_pedido AS DATE ) AS Fecha,
	YEAR(fecha_pedido) AS Anio,
    MONTH(fecha_pedido) AS Mes,
    DAY(fecha_pedido) AS Dia
FROM jardineria1.dbo.pedido p 
WHERE p.fecha_pedido is not null 
and p.fecha_entrega is not null ;
------------------------
-- cargar informacion staging ventas
TRUNCATE TABLE stg_ventas;--limpiamos tabla 
INSERT INTO stg_ventas (
	id_stg_producto,
	id_stg_fecha,
	Cantidad_vendida,
	Precio_unidad,
	Total_venta
)
SELECT 
	sp.id_stg_producto,
	sf.id_stg_fecha,
	dp.cantidad,
	dp.precio_unidad,
	dp.cantidad * dp.precio_unidad AS Total_venta
FROM jardineria1.dbo.detalle_pedido dp 
JOIN jardineria1.dbo.pedido p on dp.ID_pedido = p.ID_pedido
JOIN stg_producto sp on dp.ID_producto = sp.ID_producto 
JOIN stg_fecha sf on CAST (p.fecha_pedido AS DATE) = sf.Fecha 
WHERE dp.precio_unidad is not null and dp.cantidad >0;
		



--Mostramos valores que sean invalidos
SELECT 'Códigos inválidos' AS problema, COUNT(*) AS cantidad
FROM stg_producto 
WHERE CodigoProducto IS NULL
	OR LEN(CodigoProducto)<3 
	OR LEN (CodigoProducto)>15 
	OR PATINDEX('%[^A-Za-z0-9-]%', CodigoProducto)>0
UNION ALL
SELECT 'Duplicados productos', COUNT(*)
FROM (
		SELECT ID_producto 
		FROM stg_producto 
		GROUP BY ID_producto 
		HAVING COUNT(*) > 1)d
UNION ALL
SELECT 'Duplicados fechas', COUNT(*)
FROM (
		SELECT Fecha 
		FROM stg_fecha 
		GROUP BY Fecha 
		HAVING COUNT(*) > 1) d;

-- normalizacion de valores vacio para columna dimensiones
UPDATE stg_producto
SET Dimensiones = 'No especificado'
WHERE Dimensiones IS NULL OR LTRIM(RTRIM(Dimensiones)) = '';


--eliminar valores que no sean validos
DELETE p1
FROM stg_producto p1
INNER JOIN stg_producto p2 
ON p1.ID_producto = p2.ID_producto
WHERE p1.id_stg_producto < p2.id_stg_producto;

DELETE f1
FROM stg_fecha f1
INNER JOIN stg_fecha f2
ON f1.Fecha = f2.Fecha
WHERE f1.id_stg_fecha > f2.id_stg_fecha;



--Identificacion de anomalias en precio provedor
SELECT ID_producto, precio_proveedor, precio_venta 
FROM jardineria1.dbo.producto
WHERE precio_proveedor <= 0 OR precio_venta <= 0 OR precio_venta < precio_proveedor 

-- Cargar datos a Datamart

INSERT INTO DataMartJardineria.dbo.dim_producto (
	ID_producto, 
	CodigoProducto, 
	Nombre, 
	Categoria, 
	Dimensiones, 
	Proveedor)
SELECT ID_producto, CodigoProducto, Nombre, Categoria, Dimensiones, Proveedor
FROM StagingJardineria.dbo.stg_producto;

INSERT INTO DataMartJardineria.dbo.dim_fecha (
	fecha_key,
	fecha, 
	anio, 
	mes, 
	dia)
SELECT id_stg_fecha, Fecha, Anio, Mes, Dia
FROM stg_fecha;


INSERT INTO DataMartJardineria.dbo.Fact_venta (
    Product_key,
    Fecha_key,
    cantidad_vendida,
    precio_unidad,
    total_venta
)
SELECT 
    dp.Product_key,       -- surrogate key de producto en la dimensión
    df.Fecha_key,         -- surrogate key de fecha en la dimensión
    sv.Cantidad_vendida,
    sv.Precio_unidad,
    sv.Total_venta
FROM StagingJardineria.dbo.stg_ventas sv
JOIN StagingJardineria.dbo.stg_producto sp
    ON sv.id_stg_producto = sp.id_stg_producto
JOIN DataMartJardineria.dbo.Dim_producto dp 
    ON sp.ID_producto = dp.ID_producto
JOIN StagingJardineria.dbo.stg_fecha sf
    ON sv.id_stg_fecha = sf.id_stg_fecha
JOIN DataMartJardineria.dbo.Dim_fecha df
    ON sf.Fecha = df.Fecha;









-- Ver datos cargados
SELECT 'Productos' AS tabla, COUNT(*) AS registros FROM stg_producto
UNION ALL
SELECT 'Fechas', COUNT(*) FROM stg_fecha
UNION ALL
SELECT 'Ventas', COUNT(*) FROM stg_ventas;
-- Validar visualmente algunas filas
SELECT * FROM stg_producto;
SELECT  * FROM stg_fecha;
SELECT TOP 10 * FROM stg_ventas;

-- Productos originales vs staging
SELECT 
    'Conteo' AS Descripcion,
    (SELECT COUNT(*) FROM Jardineria1.dbo.producto) AS Original,
    (SELECT COUNT(*) FROM StagingJardineria.dbo.stg_producto) AS Staging;

-- Fechas originales vs staging
SELECT COUNT(DISTINCT CAST(fecha_pedido AS DATE)) AS OriginalFechas FROM Jardineria1.dbo.pedido;
SELECT COUNT(*) AS StagingFechas FROM StagingJardineria.dbo.stg_fecha;

-- Ventas originales vs staging
SELECT COUNT(*) AS OriginalVentas FROM Jardineria1.dbo.detalle_pedido;
SELECT COUNT(*) AS StagingVentas FROM StagingJardineria.dbo.stg_ventas;









-- Crear backup completo
BACKUP DATABASE [StagingJardineria] 
TO DISK = '/var/opt/mssql/data/StagingJardineria_backup.bak'
WITH FORMAT, INIT;

-- En DBeaver, ejecuta esto para ver el resultado del backup
SELECT * FROM msdb.dbo.backupset 
WHERE database_name = 'JardineriaDataMart' 
ORDER BY backup_start_date DESC;
