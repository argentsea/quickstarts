/*
WARNING: Run the ShardSetup SQL script first!

This walkthrough creates 4 databases (shards), roughly corresponding to EU (Europe), US (North America), ZH (Asia),  and BR (South America).
After you have executed ServerSetup, and then run ShardSetup on each database, run this script on the ZH database.
*/
USE CustomerShardZH;
GO
-- CREATE FUNCTIONS
CREATE OR ALTER FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 4;
END;
GO
DELETE FROM shd.ContactCustomers;
DELETE FROM shd.CustomerContacts;
DELETE FROM shd.Locations;
DELETE FROM shd.Customers;
DELETE FROM shd.Contacts;
GO
INSERT INTO shd.Customers (CustomerId, CustomerTypeId, Name)
VALUES (1, 1, N'段飞机零件'),
	(2, 1, N'杭州汽车打捞'),
	(3, 1, N'最好的早餐咖啡馆'),
	(4, 2, N'美国健身房'),
	(5, 1, N'设计师鲜花'),
	(6, 4, N'금속 가공 회사'),
	(7, 1, N'종이 가게'),
	(8, 1, N'장난감 및 학습 도구'),
	(9, 1, N'庭の供給店'), --jp
	(10, 4, N'ผลิตภัณฑ์กระดาษไทย'); --th
GO
INSERT INTO shd.Contacts (ContactId, FullName)
VALUES (1, N'段留贤'),
	(2, N'王若刚'),
	(3, N'霍海'),
	(4, N'董文'),
	(5, N'秦德'),
	(6, N'宣芬'),
	(7, N'曾泽民'),
	(8, N'高达'),
	(9, N'冯周'),
	(10, N'罗忠'),
	(11, N'학 광혁'),
	(12, N'윤영재'),
	(13, N'화승현'), 
	(14, N'매대정'), --jp
	(15, N'솔상훈'), --jp
	(16, N'เนติบัณฑิตชินวัตร'), --thai
	(17, N'คุณหมั่นไพบูลย์');
GO
INSERT INTO shd.ContactCustomers (CustomerId, CustomerShardId, ContactId)
VALUES (1, 4, 1),
	(2, 4, 1),
	(2, 3, 1), --foreign
	(3, 4, 2),
	(4, 4, 2),
	(5, 4, 3), --
	(6, 4, 4), --
	(7, 4, 4), --
	(8, 4, 4),
	(9, 4, 5),
	(10, 4, 5), --
	(11, 4, 6),
	(12, 4, 6),
	(13, 4, 7), --
	(14, 4, 8),
	(15, 4, 8),
	(16, 4, 9),
	(17, 4, 10);
GO
INSERT INTO shd.CustomerContacts (ContactId, ContactShardId, CustomerId)
VALUES (1, 4, 1),
	(2, 4, 1),
	(3, 4, 2),
	(4, 4, 2),
	(5, 2, 3), --foreign
	(5, 4, 3),
	(6, 1, 4), --foreign
	(6, 4, 4),
	(7, 3, 4), --foreign
	(7, 4, 4),
	(8, 4, 4),
	(9, 4, 5),
	(10, 4, 5),
	(10, 3, 5), --foreign
	(11, 4, 6),
	(12, 4, 6),
	(13, 1, 7), --foreign
	(13, 4, 7),
	(14, 4, 8),
	(15, 4, 8),
	(16, 4, 9),
	(17, 4, 10);
GO
INSERT INTO shd.Locations(CustomerId, LocationId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
VALUES (1, 1, 4, N'24楼416', N'哈尔滨市-南岗区', N'黑龙江省', N'150080', N'ZH', 0.0, 0.0),
(1, 2, 1, N'', N'', N'', N'', N'ZH', 0.0, 0.0),
(1, 3, 2, N'青年路西里二号院五号楼三单元501室', N'市区-朝阳区', N'北京市', N'100123', N'ZH', 39.932229, 116.323272),
(2, 1, 1, N'万航渡路83号金航大厦22楼', N'市区-静安区', N'上海市', N'200040', N'ZH', 31.233550, 121.449087),
(2, 2, 4, N'4-5-401', N'市区-西城区', N'北京市', N'100055', N'ZH', 39.912480, 116.351133),
(3, 1, 1, N'金沙江路875弄23号602室', N'市区-普陀区', N'上海市', N'200062', N'ZH', 31.267605, 121.399066),
(3, 2, 2, N'湖南路55号A座17层', N'青岛市', N'山东省', N'266041', N'ZH', 36.141706, 120.366180),
(3, 3, 4, N'沙井大道华南城招商中心广西北部湾银行华南城支行', N'南宁市-江南区', N'广西壮族自治区', N'530031', N'ZH', 22.616268, 108.201032),
(3, 4, 2, N'总府路2号时代广场A座20层', N'成都市-锦江区', N'四川省', N'610016', N'ZH', 30.622447, 104.103105),
(4, 1, 4, N'东方路573弄4号907室', N'市辖区', N'上海市', N'200092', N'ZH', 31.203378, 121.401340),
(4, 2, 1, N'五一北路110号海鑫大厦7楼', N'福州市-鼓楼区', N'福建省', N'350001', N'ZH', 26.080195, 119.281127),
(5, 1, 1, N'49 토기로 18 길 남산동 2 (i) -가', N'중구', N'서울', N'', N'KO', 37.551750, 126.978887),
(6, 1, 4, N'신길로41가길 ', N'영등포구', N'서울', N'', N'KO', 37.507870, 126.909282),
(7, 1, 4, N'창동 657-119', N'도봉구', N'서울', N'', N'KO', 37.647579, 127.036123),
(7, 2, 3, N'상도로47마길', N'동학구', N'서울', N'', N'KO', 37.501784, 126.950414),
(8, 1, 1, N'송림길', N'전주', N'강원도', N'', N'KO', 35.836534, 139.468500),
(9, 1, 4, N'1丁目 - 34-17めぐり町', N'東村山市', N'東京都', N'189-0025', N'JP', 35.745289, 139.439890),
(9, 2, 1, N'東洋汽缶工業所', N'大坂市', N'浪和区', N'', N'JP', 34.662983, 135.490868),
(10, 1, 4, N'148 ซอยแจ้งวัฒนะ 29', N'วัดวาอาราม, เขตบางกอกใหญ่', N'กรุงเทพมหานคร', N'10600', N'TH', 13.741124, 100.479173);
GO
