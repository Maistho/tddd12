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


