--DROP DATABASE IF EXISTS JardineriaDataMart;
CREATE DATABASE JardineriaDataMart;
use JardineriaDataMart;
CREATE TABLE Dim_producto(
	Product_key int identity(1,1) primary KEY , 
	ID_producto int not null,
	CodigoProducto VARCHAR(15) NOT NULL,
	nombre VARCHAR(70) NOT NULL,
	Categoria int NOT NULL,
	dimensiones VARCHAR(25) NULL,
	proveedor VARCHAR(50) DEFAULT NULL
);
CREATE TABLE  Dim_fecha(
	Fecha_key int primary KEY,
	fecha date not null,
	anio int not null,
	mes int not null,
	dia int not null
);
CREATE TABLE Fact_venta(
	ID_venta_key int identity(1,1) primary key,
	Product_key int not null,
	Fecha_key int not null,
	cantidad_vendida int not null,
	precio_unidad int not null,
	total_venta numeric(15,2) not null,
	FOREIGN KEY (Product_key) REFERENCES Dim_producto (Product_key),
	FOREIGN KEY (Fecha_key) REFERENCES Dim_fecha(Fecha_key)
);
-- Cargar Dim_producto desde staging
INSERT INTO Dim_producto (
    ID_producto,
    CodigoProducto,
    nombre,
    Categoria,
    dimensiones,
    proveedor
)SELECT
    ID_producto,
    CodigoProducto,
    Nombre,
    Categoria, 
    Dimensiones,
    Proveedor
FROM
    StagingJardineria.dbo.stg_producto sp ;
-- Cargar Dim_fecha desde staging
INSERT INTO Dim_fecha (
    Fecha_key,
    fecha,
    anio,
    mes,
    dia
)
SELECT DISTINCT
    YEAR(sf.Fecha) * 10000 + MONTH(sf.Fecha) * 100 + DAY(sf.Fecha) AS Fecha_key,
    sf.Fecha AS fecha,
    sf.Anio AS anio,
    sf.Mes AS mes,
    sf.Dia AS dia
FROM StagingJardineria.dbo.stg_fecha sf 
WHERE sf.Fecha  IS NOT NULL;
--Tomamos la informacon de la base staging para Fac_venta
INSERT INTO Fact_venta (
    Product_key,
    Fecha_key,
    cantidad_vendida,
    precio_unidad,
    total_venta
)
SELECT
    dp.Product_key,         -- Clave surrogate estable
    df.Fecha_key,
    sv.Cantidad_vendida,
    sv.Precio_unidad,
    sv.Total_venta
FROM StagingJardineria.dbo.stg_ventas sv
JOIN StagingJardineria.dbo.stg_producto sp 
    ON sv.id_stg_producto = sp.id_stg_producto  -- usar staging para mapear
JOIN Dim_producto dp 
    ON sp.ID_producto = dp.ID_producto          -- aquí obtienes el surrogate
JOIN StagingJardineria.dbo.stg_fecha sf 
    ON sv.id_stg_fecha = sf.id_stg_fecha
JOIN Dim_fecha df 
    ON sf.Fecha = df.fecha;
--optenemos informacion en cada tabla 
SELECT * from Dim_fecha  
SELECT * from Dim_producto 
SELECT * FROM Fact_venta
