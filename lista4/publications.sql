--- DATABASE CREATION ---

DROP DATABASE IF EXISTS publicationsdb;

CREATE DATABASE publicationsdb;

USE publicationsdb;

--- ADMIN CREATION

CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin';

GRANT ALL ON publicationsdb.* TO 'admin'@'localhost';

GRANT GRANT OPTION ON publicationsdb.* TO 'admin'@'localhost';

GRANT CREATE USER ON *.* TO 'admin'@'localhost';

--- TABLES CREATION

DPOP TABLE IF EXISTS Author;

CREATE TABLE Author (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 first_name VARCHAR(30) NOT NULL,
 last_name VARCHAR(30) NOT NULL,
 birth_date DATE NOT NULL
);

DROP TABLE IF EXISTS Category;

CREATE TABLE Category (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(30) NOT NULL
);

DROP TABLE IF EXISTS Account;

CREATE TABLE Account (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 first_name VARCHAR(30) NOT NULL,
 last_name VARCHAR(30) NOT NULL,
 login VARCHAR(50) NOT NULL,
 password VARCHAR(100) NOT NULL,
 birth_date DATE NOT NULL,
 creation_date DATE NOT NULL,
 type ENUM ('Client', 'Employee', 'Admin') NOT NULL DEFAULT 'Client'
);

DROP TABLE IF EXISTS Language;

CREATE TABLE Language (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(30) NOT NULL
);

DROP TABLE IF EXISTS Publication;

CREATE TABLE Publication (
 id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 title VARCHAR(50) NOT NULL,
 category_id INT UNSIGNED NOT NULL,
 author_id INT UNSIGNED NOT NULL,
 publication_date DATE NOT NULL,
 publication_place VARCHAR(50) NOT NULL,
 no_pages INT UNSIGNED NOT NULL,
 added_by INT UNSIGNED NOT NULL,
 FOREIGN KEY (category_id) REFERENCES Category(id),
 FOREIGN KEY (author_id) REFERENCES Author(id),
 FOREIGN KEY (added_by) REFERENCES Account(id)
);

DROP TABLE IF EXISTS Client_publication;

CREATE TABLE Client_publication (
 client_id INT UNSIGNED NOT NULL,
 publication_id INT UNSIGNED NOT NULL,
 date_opened DATE NOT NULL,
 opened_page INT UNSIGNED DEFAULT 0,
 FOREIGN KEY (client_id) REFERENCES Account(id),
 FOREIGN KEY (publication_id) REFERENCES Publication(id)
);

DROP TABLE IF EXISTS Publication_language;

CREATE TABLE Publication_language (
 publication_id INT UNSIGNED NOT NULL,
 language_id INT UNSIGNED NOT NULL,
 FOREIGN KEY (publication_id) REFERENCES Publication(id),
 FOREIGN KEY (language_id) REFERENCES Language(id)
);

CREATE VIEW PublicationPreview AS (
 SELECT id, title FROM Publication WHERE no_pages <= 100
);

--- OTHER USERS CREATION

CREATE USER 'employee'@'localhost' IDENTIFIED BY 'employee';

GRANT SELECT ON publicationsdb.* TO 'employee'@'localhost';
GRANT DELETE, INSERT, UPDATE ON publicationsdb.Publication TO 'employee'@'localhost';
GRANT DELETE, INSERT, UPDATE ON publicationsdb.Author TO 'employee'@'localhost';
GRANT DELETE, INSERT, UPDATE ON publicationsdb.Category TO 'employee'@'localhost';
GRANT DELETE, INSERT, UPDATE ON publicationsdb.Publication_language TO 'employee'@'localhost';
GRANT DELETE, INSERT, UPDATE ON publicationsdb.Language TO 'employee'@'localhost';
GRANT DELETE, INSERT, UPDATE ON publicationsdb.Client_publication TO 'employee'@'localhost';

CREATE USER 'client'@'localhost' IDENTIFIED BY 'client';

GRANT SELECT (id, title, category_id, author_id, publication_date, publication_place, no_pages) ON publicationsdb.Publication TO 'client'@'localhost';
GRANT SELECT ON publicationsdb.Publication_language TO 'client'@'localhost';
GRANT SELECT ON publicationsdb.Client_publication TO 'client'@'localhost';
GRANT SELECT ON publicationsdb.Language TO 'client'@'localhost';
GRANT SELECT ON publicationsdb.Author TO 'client'@'localhost';
GRANT SELECT ON publicationsdb.Category TO 'client'@'localhost';
GRANT UPDATE (opened_page) ON publicationsdb.Client_publication TO 'client'@'localhost';

CREATE USER 'logger'@'localhost' IDENTIFIED BY 'logger';

GRANT SELECT (id, login, password, type) ON publicationsdb.Account TO 'logger'@'localhost';

CREATE USER 'unlogged'@'localhost' IDENTIFIED BY 'unlogged';

GRANT SELECT ON publicationsdb.PublicationPreview TO 'unlogged'@'localhost';

--- TRIGGERS CREATION

DELIMITER $$
CREATE TRIGGER setCreationDate
BEFORE INSERT ON Account
FOR EACH ROW
BEGIN
 SET NEW.creation_date = DATE(NOW());
END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION getLoginCount(l VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
 RETURN (SELECT COUNT(*) FROM Account WHERE login = l);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER checkLoginUniqueness
BEFORE INSERT ON Account
FOR EACH ROW
BEGIN
 IF getLoginCount(NEW.login) = 1
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'login must be unique';
 END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER checkOpenedPage
BEFORE INSERT ON Client_publication
FOR EACH ROW
BEGIN
 IF NEW.opened_page < 0
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'opened page must be nonnegative';
 END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER checkOpenedDate
BEFORE INSERT ON Client_publication
FOR EACH ROW
BEGIN
 IF NEW.date_opened < (SELECT publication_date FROM Publication WHERE id = NEW.publication_id)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incorrect opened date';
 END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER checkPublicationDate
BEFORE INSERT ON Publication
FOR EACH ROW
BEGIN
 IF NEW.publication_date < (SELECT birth_date FROM Author WHERE id = NEW.author_id)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incorrect publication date';
 END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER checkAddedBy
BEFORE INSERT ON Publication
FOR EACH ROW
BEGIN
 IF 'Client' = (SELECT type FROM Account WHERE id = NEW.added_by)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'publications cannot be added by clients';
 END IF;
END$$
DELIMITER ;



SELECT Publication.id, Publication.title, Category.name, Author.first_name, Author.last_name, Publication.publication_date, Publication.publication_place, Language.name, Publication.no_pages FROM Publication INNER JOIN Category ON Category.id = Publication.category_id INNER JOIN Author ON Author.id = Publication.author_id INNER JOIN Publication_language ON Publication.id = Publication_language.publication_id INNER JOIN Language ON Language.id = Publication_language.language_id ORDER BY Publication.title;

SELECT * FROM Publication INNER JOIN Category ON Category.id = Publication.category_id INNER JOIN Author ON Author.id = Publication.author_id INNER JOIN Publication_language ON Publication.id = Publication_language.publication_id INNER JOIN Language ON Language.id = Publication_language.language_id ORDER BY Publication.title;
