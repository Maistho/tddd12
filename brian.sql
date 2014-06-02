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


