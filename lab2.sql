
/* This resets our changes if one wants to run the file several times */
ALTER TABLE jbmanager
DROP FOREIGN KEY fk_manager_id;

ALTER TABLE jbemployee
DROP FOREIGN KEY fk_employee_mgr;

ALTER TABLE jbdept
DROP FOREIGN KEY fk_dept_mgr;

ALTER TABLE jbtransaction
DROP FOREIGN KEY fk_transaction_account;

DROP TABLE IF EXISTS jbmanager CASCADE;
DROP TABLE IF EXISTS jbaccount CASCADE;
DROP TABLE IF EXISTS jbcustomer CASCADE;


/*
	#3: Implementation of jbmanager
*/

CREATE TABLE jbmanager (
	id INT PRIMARY KEY,
	bonus INT
);

INSERT INTO jbmanager(id)
SELECT jbemployee.id from jbemployee
JOIN jbdept
ON jbdept.manager = jbemployee.id
UNION
SELECT id from jbemployee
WHERE id IN (
	SELECT manager FROM jbemployee
);


/*
Foreign key constraints. Since these have been removed earlier, we don't need to remove them now.

ALTER TABLE jbmanager
DROP FOREIGN KEY fk_manager_id;

ALTER TABLE jbemployee
DROP FOREIGN KEY fk_employee_mgr;

*/

ALTER TABLE jbdept
ADD CONSTRAINT fk_dept_mgr
FOREIGN KEY (manager) REFERENCES jbmanager(id);

ALTER TABLE jbemployee
ADD CONSTRAINT fk_employee_mgr
FOREIGN KEY (manager) REFERENCES jbmanager(id);

ALTER TABLE jbmanager
ADD CONSTRAINT fk_manager_id
FOREIGN KEY (id) REFERENCES jbemployee(id);


/*
	#4: This adds 10,000 to bonuses.
		Since we might have some NULL Values, we must check with IFNULL
*/
UPDATE jbmanager
SET bonus=(IFNULL(bonus,0) + 10000)
WHERE id IN (
	SELECT manager FROM jbdept
);


/*
	#5b: Adding the jbaccount and jbcustomer.
*/

CREATE TABLE jbaccount (
	id INT PRIMARY KEY,
	balance INT,
	credit INT,
	customer INT NOT NULL,
	FOREIGN KEY (customer) REFERENCES jbcustomer(id)
);

CREATE TABLE jbcustomer (
	id INT PRIMARY KEY,
	name VARCHAR(30),
	adress VARCHAR(30),
	city INT,
	FOREIGN KEY (city) REFERENCES jbcity(id)
);


/*
	We need to delete all items from jbsale and jbdebit before changing anything
*/

DELETE FROM jbsale;
ALTER TABLE jbdebit
RENAME TO jbtransaction;

DELETE FROM jbtransaction;
ALTER TABLE jbtransaction
ADD CONSTRAINT fk_transaction_account
FOREIGN KEY (account) REFERENCES jbaccount(id);

