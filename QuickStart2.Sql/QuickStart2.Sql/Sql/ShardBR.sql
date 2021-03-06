﻿/*
WARNING: Run the ShardSetup SQL script first!

This walkthrough creates 4 databases (shards), roughly corresponding to EU (Europe), US (North America), ZH (Asia),  and BR (South America).
After you have executed ServerSetup, and then run ShardSetup on each database, run this script on the BR database.
*/
USE CustomerShardBR;
GO
-- CREATE FUNCTIONS
CREATE OR ALTER FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 3;
END;
GO
DELETE FROM shd.ContactCustomers;
DELETE FROM shd.CustomerContacts;
DELETE FROM shd.Locations;
DELETE FROM shd.Customers;
DELETE FROM shd.Contacts;
GO
SET IDENTITY_INSERT shd.Customers ON;
GO
INSERT INTO shd.Customers (CustomerId, CustomerTypeId, Name)
VALUES (1, 1, N'Recursos de Liquidação Financeira'),
	(2, 3, N'Especialistas em Restaurantes'),
	(3, 1, N'Especialistas em Automação'),
	(4, 3, N'Grupo de Consultoria Financeira'),
	(5, 3, N'Junta Internacional de Viajes'),
	(6, 1, N'El Club para el Servicio Juvenil'),
	(7, 2, N'Los Especialistas en Ventas y Marketing.'),
	(8, 2, N'La Tienda de Autopartes'),
	(9, 2, N'El Banco de la Paz');
GO
SET IDENTITY_INSERT shd.Customers OFF;
GO
SET IDENTITY_INSERT shd.Contacts ON;
GO
INSERT INTO shd.Contacts (ContactId, FullName)
VALUES (1, N'Modesto Fernandes'),
	(2, N'Dênis Palmeiro'),
	(3, N'Estefânia Mateus'),
	(4, N'Toni Alves'),
	(5, N'Bernardo David'),
	(6, N'Maristela Mata'),
	(7, N'Serafina Cardoso'),
	(8, N'Octávio Henriques'),
	(9, N'Herminio Santos'),
	(10, N'Eberardo Duarte'),
	(11, N'Raymundo Villanueva'),
	(12, N'Genoveva Cabrera'),
	(13, N'Laura Cruz'),
	(14, N'Basilio Nieves'),
	(15, N'Eric Ortega'),
	(16, N'Basilio Nieves'),
	(17, N'Griselda Giménez'),
	(18, N'Roberta Castellano');
GO
SET IDENTITY_INSERT shd.Contacts OFF;
GO
INSERT INTO shd.ContactCustomers (CustomerId, CustomerShardId, ContactId)
VALUES (1, 3, 1),
	(2, 3, 1),
	(3, 3, 1),
	(4, 3, 2),
	(4, 2, 7), --foreign
	(5, 3, 2),
	(5, 2, 10), --foreign
	(6, 3, 3),
	(6, 2, 9), --foreign
	(7, 3, 3),
	(7, 4, 4), 
	(8, 3, 4),
	(9, 3, 4),
	(10, 3, 5),
	(11, 3, 5),
	(12, 3, 5),
	(13, 3, 6),
	(14, 3, 7),
	(15, 3, 8),
	(16, 3, 8),
	(17, 3, 9),
	(18, 3, 9);
GO
INSERT INTO shd.CustomerContacts (ContactId, ContactShardId, CustomerId)
VALUES (1, 3, 1),
	(2, 3, 1),
	(2, 4, 1), --foreign
	(3, 3, 1),
	(4, 2, 2), --foreign
	(4, 3, 2),
	(5, 3, 2),
	(6, 3, 3),
	(7, 3, 3),
	(8, 3, 4),
	(9, 3, 4),
	(10, 3, 5),
	(11, 3, 5),
	(12, 3, 5),
	(13, 3, 6),
	(14, 3, 7),
	(15, 3, 8),
	(16, 3, 8),
	(17, 3, 9),
	(18, 3, 9);
GO
INSERT INTO shd.Locations(LocationId, CustomerId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
VALUES (1, 1, 1, N'Rua Palmares 271', N'Teresina', N'Piauí', N'64017-760', N'BR', -5.093374, -42.751256),
	(1, 2, 4, N'Avenida Geraldo Hilário da Silva 1161', N'Araraquara', N'São Paulo', N'14805-290', N'BR', -21.779457, -48.178341),
	(2, 1, 1, N'Alameda A 703', N'Vila Velha', N'Espírito Santo', N'29129-654', N'BR', -20.370124, -40.316256),
	(2, 2, 4, N'Avenida Sebastião Eugênio de Camargo 489', N'São Paulo', N'São Paulo', N'05360-010', N'BR', -23.592837, -46.662626),
	(3, 1, 1, N'Rua Nova Palma 1505', N'Santa Maria', N'Rio Grande do Sul', N'97040-350', N'BR', -29.673561, -53.817593),
	(4, 1, 1, N'Rua José Bandeira 337', N'São Paulo', N'São Paulo', N'03480-110', N'BR', -23.669583, -46.680479),
	(4, 2, 4, N'Rua Ana Miranda Jesus de Souza 679', N'Itapecerica da Serra', N'São Paulo', N'06864-196', N'BR', -23.707634, -46.857147),
	(4, 3, 2, N'Rua João Rocha 219', N'São Paulo', N'São Paulo', N'04437-030', N'BR', -23.475744, -46.702451),
	(4, 4, 2, N'Rua Pedro Furlan 419', N'Indaiatuba', N'São Paulo', N'13345-445', N'BR', -23.081925, -47.210416),
	(5, 1, 4, N'J Morganti 8885', N'Loma Hermosa', N'Buenos Aires', N'', N'AR', -34.568455, -58.605372),
	(5, 2, 1, N'Bme Mitre 150', N'San Carlos de Bariloche', N'Río Negro', N'', N'AR', -41.126716, -71.370820),
	(6, 1, 4, N'Irlanda 172', N'San Pedro', N'Buenos Aires', N'', N'AR', -33.679337, -59.663550),
	(6, 2, 1, N'P Lagrave 828', N'Pilar', N'Buenos Aires', N'', N'AR', -34.478305, -58.923777),
	(6, 3, 2, N'Rioja 82', N'Mendoza', N'Mendoza', N'', N'AR', -32.873815, -68.836375),
	(6, 4, 3, N'15 1136', N'La Plata', N'Buenos Aires', N'', N'AR', -34.913767, -57.962784),
	(7, 1, 4, N'Jr. Torres Paz 1252 - Sta Beatriz', N'Lima', N'', N'Lima', N'PE', -12.058166, -77.052333),
	(7, 2, 1, N'Jirón Petronila Álvarez, 2323', N'El Cercado', N'Lima', N'', N'PE', -12.064880, -77.127864),
	(7, 3, 2, N'Av. Isabel La Católica 103-La Victoria', N'Lima', N'Lima y Callao', N'', N'PE', -12.054137, -77.055767),
	(8, 1, 2, N'Avenida Pablo Neruda, 02461', N'IX Región', N'Temuco', N'', N'CL', -38.738442, -72.618172),
	(9, 1, 3, N'Av. Chacaltaya final # 4', N'', N'La Paz', N'', N'BO', -16.496424, -68.129659);
GO
