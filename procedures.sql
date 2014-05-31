DROP PROCEDURE IF EXISTS create_reservation;
DROP PROCEDURE IF EXISTS add_passenger;
DROP PROCEDURE IF EXISTS add_contact;
DROP PROCEDURE IF EXISTS add_passenger_as_contact;

DELIMITER //

CREATE PROCEDURE create_reservation
(IN flight_id INT)
BEGIN
INSERT INTO Booking(flight)
VALUES(flight_id);
END //

CREATE PROCEDURE add_passenger
(
	IN booking_id INT, name VARCHAR(256), birth DATE,
	OUT passenger_id INT)
BEGIN
	INSERT INTO Passenger(fullname, birthdate, booking)
	VALUES(name, birth, booking_id);
	SET passenger_id = LAST_INSERT_ID();
END //

CREATE PROCEDURE add_contact
(IN booking_id INT, passenger_id INT, email VARCHAR(254), phone INT)
BEGIN
	INSERT INTO Contact(id, email, phone_number)
	VALUES(passenger_id, email, phone);
	UPDATE Booking SET Contact = passenger_id
	WHERE id = booking_id;
END //

CREATE PROCEDURE add_passenger_as_contact
(IN booking_id INT, name VARCHAR(256), birth DATE, email VARCHAR(254), phone INT)
BEGIN
	CALL add_passenger(booking_id, name, birth, @passenger_id);
	CALL add_contact(booking_id, @passenger_id, email, phone);
END //

DELIMITER ;
