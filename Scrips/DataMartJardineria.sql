CREATE DATABASE DataMartJardineria;
use DataMartJardineria;

CREATE TABLE Dim_producto(
Product_key int identity(1,1) primary KEY , 
ID_producto int not null,
CodigoProducto VARCHAR(15) NOT NULL,
nombre VARCHAR(70) NOT NULL,
Categoria int NOT NULL,
dimensiones VARCHAR(25) NULL,
proveedor VARCHAR(50) DEFAULT NULL,
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


/*
INSERT INTO DataMartJardineria.dbo.Dim_producto (
    ID_producto,
    CodigoProducto,
    nombre,
    Categoria,
    dimensiones,
    proveedor
)SELECT
    ID_producto,
    CodigoProducto,
    nombre,
    Categoria, 
    dimensiones,
    proveedor
FROM
    Jardineria.dbo.producto;

INSERT INTO Dim_fecha (
    Fecha_key,
    fecha,
    anio,
    mes,
    dia
)
SELECT DISTINCT
    YEAR(fecha_pedido) * 10000 + MONTH(fecha_pedido) * 100 + DAY(fecha_pedido) AS Fecha_key,
    fecha_pedido AS fecha,
    YEAR(fecha_pedido) AS anio,
    MONTH(fecha_pedido) AS mes,
    DAY(fecha_pedido) AS dia
FROM Jardineria.dbo.pedido
WHERE fecha_pedido IS NOT NULL;


--Tomamos la informacon de la base de datos principal
INSERT INTO DataMartJardineria.dbo.Fact_venta (
    Product_key,
    Fecha_key,
    cantidad_vendida,
    precio_unidad,
    total_venta
)
SELECT
    dp.Product_key,
    df.Fecha_key,
    ddp.cantidad AS cantidad_vendida,
    ddp.precio_unidad AS precio_por_unidad,
    (ddp.cantidad * ddp.precio_unidad) AS total_venta
FROM
    Jardineria.dbo.detalle_pedido AS ddp
JOIN
    Jardineria.dbo.pedido AS p ON ddp.ID_pedido = p.ID_pedido
JOIN
    DataMartJardineria.dbo.Dim_producto AS dp ON ddp.ID_producto = dp.ID_producto
JOIN
    DataMartJardineria.dbo.Dim_fecha AS df ON p.fecha_pedido = df.fecha
WHERE
    ddp.precio_unidad IS  NOT NULL; -- ignora filas con datos null
    
   */
 -- procducto mas vendido   
SELECT TOP 1
    p.nombre,
    SUM(f.cantidad_vendida) AS total_vendido
FROM Fact_venta f
JOIN Dim_producto p ON f.Product_key = p.Product_key
GROUP BY p.nombre
ORDER BY total_vendido DESC;

-- categoria con mas productos
SELECT TOP 1
	p.Categoria,
	COUNT(*) AS total_productos
FROM Dim_producto p
GROUP BY p.Categoria
ORDER BY total_productos DESC;



--año con mas ventas
SELECT TOP 1
	p.anio,
	COUNT(*) AS anio_mas_venta
FROM Dim_fecha p
GROUP BY p.anio
ORDER BY anio_mas_venta DESC;
	

--optenemos informacion en cada tabla 
SELECT * from Dim_fecha  


SELECT * from Dim_producto 


SELECT * FROM Fact_venta  

