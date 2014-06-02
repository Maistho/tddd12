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


