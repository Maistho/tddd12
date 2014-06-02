# Drop all tables
ALTER TABLE Airplane
DROP FOREIGN KEY fk_Airplane_model;

ALTER TABLE Route
DROP FOREIGN KEY fk_Route_departure,
DROP FOREIGN KEY fk_Route_destination;

ALTER TABLE Flight
DROP FOREIGN KEY fk_Flight_route,
DROP FOREIGN KEY fk_Flight_airplane;

ALTER TABLE Passenger
DROP FOREIGN KEY fk_Passenger_booking;

ALTER TABLE Contact
DROP FOREIGN KEY fk_Contact_id;

ALTER TABLE Booking
DROP FOREIGN KEY fk_Booking_flight,
DROP FOREIGN KEY fk_Booking_payment,
DROP FOREIGN KEY fk_Booking_contact;

DROP TABLE
Booking,
Contact,
Passenger,
Payment,
Flight,
Route,
Airport,
Airplane,
AirplaneModel,
WeekdayPriceFactor;
test


# Create all tables and views
CREATE TABLE AirplaneModel
(
	id INT NOT NULL AUTO_INCREMENT,
	seats INT NOT NULL,
	name VARCHAR(32) NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Airplane
(
	id INT NOT NULL AUTO_INCREMENT,
	model INT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Airport
(
	id INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(32) NOT NULL,
	short_name VARCHAR(3) NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Route
(
	id INT NOT NULL AUTO_INCREMENT,
	price_factor DOUBLE NOT NULL,
	departure INT NOT NULL,
	destination INT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Flight
(
	id INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(8) NOT NULL,
	departure_datetime DATETIME NOT NULL,
	arrival_datetime DATETIME NOT NULL,
	route INT NOT NULL,
	airplane INT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Payment
(
	id INT NOT NULL AUTO_INCREMENT,
	card_holder VARCHAR(256) NOT NULL,

	# Must encrypt PA-DSS Version 3
	card_number INT NOT NULL,

	card_expiry DATE NOT NULL,
	amount INT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Passenger
(
	id INT NOT NULL AUTO_INCREMENT,
	fullname VARCHAR(256) NOT NULL,
	ticket_number VARCHAR(16) UNIQUE,
	birthdate DATE NOT NULL,
	booking INT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Contact
(
	id INT NOT NULL AUTO_INCREMENT,
	email VARCHAR(254) NOT NULL,
	phone_number INT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE Booking
(
	id INT NOT NULL AUTO_INCREMENT,
	flight INT NOT NULL,
	payment INT,
	contact INT,
	PRIMARY KEY(id)
);

CREATE TABLE WeekdayPriceFactor
(
	weekday INT NOT NULL,
	price_factor DOUBLE NOT NULL,
	PRIMARY KEY(weekday)
);


# Add all foreign key constraints
ALTER TABLE Airplane ADD
	CONSTRAINT fk_Airplane_model
		FOREIGN KEY(model) REFERENCES AirplaneModel(id);

ALTER TABLE Route
ADD CONSTRAINT fk_Route_departure
	FOREIGN KEY(departure) REFERENCES Airport(id),
ADD CONSTRAINT fk_Route_destination
	FOREIGN KEY(destination) REFERENCES Airport(id);

ALTER TABLE Flight
ADD CONSTRAINT fk_Flight_route
	FOREIGN KEY(route) REFERENCES Route(id),
ADD CONSTRAINT fk_Flight_airplane
	FOREIGN KEY(airplane) REFERENCES Airplane(id);

ALTER TABLE Passenger
ADD CONSTRAINT fk_Passenger_booking
	FOREIGN KEY(booking) REFERENCES Booking(id);

ALTER TABLE Contact
ADD CONSTRAINT fk_Contact_id
	FOREIGN KEY(id) REFERENCES Passenger(id);

ALTER TABLE Booking
ADD CONSTRAINT fk_Booking_flight
	FOREIGN KEY(flight)  REFERENCES Flight(id),
ADD CONSTRAINT fk_Booking_payment
	FOREIGN KEY(payment) REFERENCES Payment(id),
ADD CONSTRAINT fk_Booking_contact
	FOREIGN KEY(contact) REFERENCES Contact(id);

CREATE VIEW Seats AS
SELECT Flight.id, AirplaneModel.seats - COUNT(Passenger.id) AS available_seats
FROM Flight
JOIN Airplane
ON Flight.airplane = Airplane.id
JOIN AirplaneModel
ON AirplaneModel.id = Airplane.model
LEFT JOIN Booking
ON Booking.flight = Flight.id
AND Booking.payment IS NOT NULL
LEFT JOIN Passenger
ON Passenger.booking = Booking.id
GROUP BY Flight.id;

CREATE VIEW FlightSearch AS
SELECT Seats.id, Seats.available_seats, Destination.short_name AS destination, Departure.short_name AS departure, Flight.departure_datetime
FROM Seats
JOIN Flight
ON Flight.id = Seats.id
JOIN Route
ON Route.id = Flight.route
JOIN Airport AS Destination
ON Destination.id = Route.destination
JOIN Airport AS Departure
ON Departure.id = Route.departure;

CREATE VIEW FlightPrices AS
SELECT (
	Route.price_factor * WeekdayPriceFactor.price_factor * (
		Seats.available_seats + 1
	) / AirplaneModel.seats * 1.2
) AS price,
Flight.id AS id
FROM Flight
JOIN Route
ON Route.id = Flight.route
JOIN WeekdayPriceFactor
ON WeekdayPriceFactor.weekday = DAY(Flight.departure_datetime)
JOIN Seats
ON Seats.id = Flight.id
JOIN Airplane
ON Airplane.id = Flight.airplane
JOIN AirplaneModel
ON AirplaneModel.id = Airplane.model;

# Add procedures
DROP PROCEDURE IF EXISTS create_reservation;
DROP PROCEDURE IF EXISTS add_passenger;
DROP PROCEDURE IF EXISTS add_contact;
DROP PROCEDURE IF EXISTS add_passenger_as_contact;
DROP PROCEDURE IF EXISTS add_payment;
DROP PROCEDURE IF EXISTS search_flights;
DROP FUNCTION IF EXISTS check_seats;
DROP FUNCTION IF EXISTS check_booking_seats;

DELIMITER //

CREATE FUNCTION check_seats
(flight INT, no_seats INT)
RETURNS BOOL
READS SQL DATA
BEGIN
	IF no_seats < 1 THEN
		RETURN 0;
	ELSE
		RETURN (
			(
				SELECT available_seats FROM Seats
				WHERE id = flight
			) - no_seats >= 0
		);
	END IF;
END //

CREATE FUNCTION check_booking_seats
(booking INT, extra INT)
RETURNS BOOL
READS SQL DATA
BEGIN
	RETURN check_seats(
		(
			SELECT Booking.flight FROM Booking
			WHERE Booking.id = booking
		),
		(
			SELECT COUNT(*) FROM Passenger
			WHERE Passenger.booking = booking
		)+extra
	);
END //

CREATE FUNCTION calc_price
(booking INT)
RETURNS INT
READS SQL DATA
BEGIN
	RETURN (
		SELECT price*(
			SELECT COUNT(Passenger.id) FROM Passenger
			WHERE Passenger.booking = booking)
		FROM FlightPrices
		WHERE id = (
			SELECT flight FROM Booking
			WHERE id = booking)
	);
END //
CREATE PROCEDURE create_reservation
(IN flight INT)
BEGIN
	INSERT INTO Booking(flight)
	VALUES(flight);
END //

CREATE PROCEDURE add_passenger
(
	IN booking INT, name VARCHAR(256), birth DATE,
	OUT passenger INT)
BEGIN
	IF check_booking_seats(booking, 1) AND (SELECT payment FROM Booking WHERE id = booking) IS NULL THEN
		INSERT INTO Passenger(fullname, birthdate, booking)
		VALUES(name, birth, booking);
		SET passenger = LAST_INSERT_ID();
	ELSE
		SET passenger = -1;
	END IF;

END //

CREATE PROCEDURE add_contact
(IN booking INT, passenger INT, email VARCHAR(254), phone INT)
BEGIN
	INSERT INTO Contact(id, email, phone_number)
	VALUES(passenger, email, phone);
	UPDATE Booking
	SET Contact = passenger
	WHERE id = booking;
END //

CREATE PROCEDURE add_passenger_as_contact
(IN booking INT, name VARCHAR(256), birth DATE, email VARCHAR(254), phone INT)
BEGIN
	CALL add_passenger(booking, name, birth, @passenger);
	CALL add_contact(booking, @passenger, email, phone);
END //

CREATE PROCEDURE add_payment
(IN booking INT, card_holder VARCHAR(256),
	card_number INT, card_expiry DATE)
BEGIN
	IF (
		SELECT Booking.contact FROM Booking
		JOIN Passenger
		ON Passenger.id = Booking.contact
		WHERE Booking.id = booking AND Passenger.booking = booking
		) IS NOT NULL
		AND
		check_booking_seats(booking, 0)
		THEN
		INSERT INTO Payment ( card_holder, card_number, card_expiry, amount)
		VALUES              ( card_holder, card_number, card_expiry, (
			CALL calc_price(booking)
			)
		);
		UPDATE Booking
		SET payment = LAST_INSERT_ID()
		WHERE id = booking;
	ELSE
		SIGNAL SQLSTATE '99999'
		SET MESSAGE_TEXT = 'Payment not completed';
	END IF;
END //

CREATE PROCEDURE search_flights
(
	IN departure VARCHAR(3),
	destination VARCHAR(3),
	no_passengers INT,
	flight_date DATE
)
BEGIN
	SELECT * FROM FlightSearch
	WHERE FlightSearch.departure = departure
	AND FlightSearch.destination = destination
	AND FlightSearch.available_seats >= no_passengers
	AND DATE(FlightSearch.departure_datetime) = flight_date;
END //

DELIMITER ;


# Create triggers
DROP FUNCTION IF EXISTS generate_ticket;
DROP TRIGGER IF EXISTS add_ticket;

DELIMITER //

CREATE FUNCTION generate_ticket
(flight INT, booking INT)
RETURNS VARCHAR(22)
READS SQL DATA
BEGIN
	RETURN (
		SELECT CONCAT(
			name,
			'-',
			LPAD(flight,4,'0'),
			LPAD(booking,4,'0'),
			(FLOOR(RAND() * 100001) + 999999)
		)
		FROM Flight WHERE id = flight);
END //

CREATE TRIGGER add_ticket
AFTER UPDATE
ON Booking
FOR EACH ROW
BEGIN
	IF OLD.payment <> NEW.payment THEN
		SET @i = 0;
		SET @booking_ticket = generate_ticket(NEW.flight, NEW.id);
		UPDATE Passenger
		SET ticket_number = CONCAT(@booking_ticket, LPAD((@i := @i + ),2,'0'))
		WHERE Passenger.booking = NEW.id;
	END IF;

END //

DELIMITER ;


# Insert test data
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
VALUES(60, 'Boing 313');

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


