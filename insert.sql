INSERT INTO Airport(name, short_name)
VALUES('Arlanda', 'ARN');
INSERT INTO Airport(name, short_name)
VALUES('Umea', 'UME');
INSERT INTO Airport(name, short_name)
VALUES('Stockholm Skavsta', 'NYO');

INSERT INTO Route(departure, destination, price_factor)
VALUES
(
	(SELECT id FROM Airport WHERE short_name = 'ARN'),
	(SELECT id FROM Airport WHERE short_name = 'UME'),
	0.5
);

INSERT INTO Route(departure, destination, price_factor)
VALUES
(
	(SELECT id FROM Airport WHERE short_name = 'UME'),
	(SELECT id FROM Airport WHERE short_name = 'ARN'),
	0.7
);

INSERT INTO AirplaneModel(seats, name)
VALUES(140, 'Boing 474');
INSERT INTO AirplaneModel(seats, name)
VALUES(180, 'Boing 313');

INSERT INTO Airplane(model)
VALUES
(
	(SELECT id FROM AirplaneModel WHERE name = 'Boing 474')
);
INSERT INTO Airplane(model)
VALUES
(
	(SELECT id FROM AirplaneModel WHERE name = 'Boing 474')
);
INSERT INTO Airplane(model)
VALUES
(
	(SELECT id FROM AirplaneModel WHERE name = 'Boing 474')
);
INSERT INTO Airplane(model)
VALUES
(
	(SELECT id FROM AirplaneModel WHERE name = 'Boing 313')
);

INSERT INTO Flight(name, departure_datetime,
	arrival_datetime, route, airplane)
VALUES
(
	'BS001',
	'2014-05-31 13:15:00',
	'2014-05-31 14:20:00',
	(SELECT id FROM Route WHERE departure = (
			SELECT id FROM Airport WHERE short_name = 'UME'
		) AND
		destination = (
			SELECT id FROM Airport WHERE short_name = 'ARN'
		)
	),
	(SELECT MAX(id) FROM Airplane)
);

INSERT INTO Flight(name, departure_datetime,
	arrival_datetime, route, airplane)
VALUES
(
	'BS002',
	'2014-05-31 15:15:00',
	'2014-05-31 16:20:00',
	(SELECT id FROM Route WHERE departure = (
			SELECT id FROM Airport WHERE short_name = 'UME'
		) AND
		destination = (
			SELECT id FROM Airport WHERE short_name = 'ARN'
		)
	),
	(SELECT MIN(id) FROM Airplane)
);

INSERT INTO Flight(name, departure_datetime,
	arrival_datetime, route, airplane)
VALUES
(
	'BS003',
	'2014-05-31 14:40:00',
	'2014-05-31 15:50:00',
	(SELECT id FROM Route WHERE departure = (
			SELECT id FROM Airport WHERE short_name = 'ARN'
		) AND
		destination = (
			SELECT id FROM Airport WHERE short_name = 'UME'
		)
	),
	(SELECT MAX(id) FROM Airplane)
);
