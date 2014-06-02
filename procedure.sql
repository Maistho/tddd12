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


