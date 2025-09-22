# Utility function: get available copies (robust NULL handling)
DELIMITER $$
CREATE FUNCTION Get_Book_Availability(p_book_id INT, p_isbn VARCHAR(20))
RETURNS INT DETERMINISTIC //return type
BEGIN
  DECLARE v_available INT;
  SELECT AvailableCopies INTO v_available
    FROM Books
    WHERE (BookID = p_book_id OR (p_isbn IS NOT NULL AND ISBN = p_isbn))
    LIMIT 1;
  IF v_available IS NULL THEN
    RETURN 0;
  END IF;
  RETURN v_available;
END$$
DELIMITER ;


#Procedures
# Procedure 1 : Add Student 
DELIMITER $$
CREATE PROCEDURE Add_Student(
  IN p_student_id VARCHAR(100),
  IN p_name VARCHAR(100),
  IN p_email VARCHAR(100),
  IN p_phone VARCHAR(15)
)
BEGIN
  INSERT INTO Students(Student_ID, Name_of_Student, Email, Phone)
  VALUES (p_student_id, p_name, p_email, p_phone);
END$$
DELIMITER ;

#Procedure 2 : Add Book 
DELIMITER $$
CREATE PROCEDURE Add_Book(
  IN b_title VARCHAR(150),
  IN b_author VARCHAR(100),
  IN b_isbn VARCHAR(20),
  IN b_genre VARCHAR(50),
  IN b_published_year INT,
  IN b_total_copies INT,
  IN b_available_copies INT
)
BEGIN
  INSERT INTO Books (Title, Author, ISBN, Genre, PublishedYear, TotalCopies, AvailableCopies)
  VALUES (b_title, b_author, b_isbn, b_genre, b_published_year, b_total_copies, b_available_copies);
END$$
DELIMITER ;

#Procedure 3 : Issue Book
#(uses Get_Book_Availability)
DELIMITER $$
CREATE PROCEDURE Issue_Book(
  IN p_roll_no INT,
  IN p_book_id INT,
  IN p_isbn VARCHAR(20),
  IN p_due_date DATE
)
BEGIN
  DECLARE v_available INT;
  SET v_available = Get_Book_Availability(p_book_id, p_isbn);

  IF v_available > 0 THEN
    INSERT INTO Borrow (Roll_No, BookID, IssueDate, DueDate, Status)
    VALUES (p_roll_no, p_book_id, CURRENT_DATE, p_due_date, 'Issued');

    UPDATE Books
    SET AvailableCopies = AvailableCopies – 1 
    WHERE (BookID = p_book_id OR (p_isbn IS NOT NULL AND ISBN = p_isbn));

    SELECT CONCAT('Book issued successfully. Remaining copies: ', v_available - 1) AS Message;
  ELSE
    SELECT 'Book not available or invalid BookID/ISBN' AS Message;
  END IF;
END$$
DELIMITER ;

#Procedure 4 : Return Book 
DELIMITER $$
CREATE PROCEDURE Return_Book(
  IN p_borrow_id INT,
  IN p_return_date DATE
)
BEGIN
  DECLARE v_book_id INT;
  DECLARE v_waitlist_roll INT;
  DECLARE v_not_found INT DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

  START TRANSACTION;

  # Lock borrow record
  SELECT BookID INTO v_book_id
  FROM Borrow
  WHERE BorrowID = p_borrow_id AND Status = 'Issued'
  FOR UPDATE;

  IF v_not_found = 1 OR v_book_id IS NULL THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Borrow record not found or already returned';
  END IF;

  # Mark returned
  UPDATE Borrow
  SET ReturnDate = p_return_date,
      Status = 'Returned'
  WHERE BorrowID = p_borrow_id;

  # Increase available copies
  UPDATE Books
  SET AvailableCopies = AvailableCopies + 1
  WHERE BookID = v_book_id;

  # Check waitlist for earliest member (using Roll_No)
  SET v_not_found = 0;
  SELECT Roll_No INTO v_waitlist_roll
  FROM Waitlist
  WHERE BookID = v_book_id AND Status = 'Pending'
  ORDER BY AddedDate ASC
  LIMIT 1
  FOR UPDATE;

  IF v_not_found = 0 AND v_waitlist_roll IS NOT NULL THEN
    # mark waitlist entry as notified
    UPDATE Waitlist
    SET Status = 'Notified'
    WHERE BookID = v_book_id AND Roll_No = v_waitlist_roll;

#create a prebook with 2-day hold window
    INSERT INTO Prebook (BookID, Roll_No, PrebookDate, Status, NotifiedAt, ExpiresAt)
    VALUES (v_book_id, v_waitlist_roll, NOW(), 'Notified', NOW(), NOW() + INTERVAL 2 DAY);

#reserve the copy (decrement back)
    UPDATE Books
    SET AvailableCopies = AvailableCopies - 1
    WHERE BookID = v_book_id;
  END IF;

  COMMIT;
END$$
DELIMITER ;

#Procedure 5 : Prebook
DELIMITER $$

CREATE PROCEDURE Prebook_Book(
    IN p_roll_no INT,
    IN p_book_id INT
)
BEGIN
    DECLARE v_available INT;

    # Check how many copies are available
    SELECT AvailableCopies INTO v_available
    FROM Books
    WHERE BookID = p_book_id;

    IF v_available = 0 THEN
        # Insert into Prebook table
        INSERT INTO Prebook (Roll_No, BookID, PrebookDate, Status)
        VALUES (p_roll_no, p_book_id, NOW(), 'Waiting');

        # Insert into Waitlist table
        INSERT INTO Waitlist (BookID, Roll_No, Position, AddedDate, Status)
        VALUES (
          p_book_id,
          p_roll_no,
          COALESCE(
            (SELECT MAX(Position) FROM Waitlist WHERE BookID = p_book_id),
            0) + 1,
          CURRENT_DATE,
          'Pending'
        );

        SELECT 'Prebook request added successfully. You will be notified when the book is available.' AS Message;

    ELSE
        SELECT 'Book is currently available. You can issue it directly.' AS Message;
    END IF;
END$$

DELIMITER ;
#Procedure 6 : Notify next waitlist user 
#(uses PrebookDate ordering)
DELIMITER $$
CREATE PROCEDURE Notify_Next_Waitlist_User(IN p_book_id INT)
BEGIN
  DECLARE v_prebook_id INT DEFAULT NULL;
  DECLARE v_current_ts TIMESTAMP;

  SET v_current_ts = CURRENT_TIMESTAMP;
  START TRANSACTION;

  SELECT PrebookID INTO v_prebook_id
  FROM Prebook
  WHERE BookID = p_book_id AND Status = 'Waiting'
  ORDER BY PrebookDate ASC
  LIMIT 1
  FOR UPDATE;

  IF v_prebook_id IS NOT NULL THEN
    UPDATE Prebook
    SET Status = 'Notified',
        NotifiedAt = v_current_ts,
        ExpiresAt = v_current_ts + INTERVAL 2 DAY
    WHERE PrebookID = v_prebook_id;

    UPDATE Books
    SET AvailableCopies = AvailableCopies - 1
    WHERE BookID = p_book_id AND AvailableCopies > 0;

    SELECT CONCAT('User with PrebookID ', v_prebook_id, ' has been notified for BookID ', p_book_id) AS NotificationMessage;
  ELSE
    SELECT 'No users in the waitlist for this book.' AS NotificationMessage;
  END IF;

  COMMIT;
END$$
DELIMITER ;

# Procedure 7 : Fulfil Reservation 
DELIMITER $$
CREATE PROCEDURE Fulfil_Reservation(
  IN p_prebook_id INT,
  IN p_roll_no INT,
  IN p_due_date DATE
)
BEGIN
  DECLARE v_book_id INT;
  DECLARE v_expiry DATETIME;
  DECLARE v_status VARCHAR(20);
  DECLARE v_available INT;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_book_id = NULL;

  START TRANSACTION;

  # lock prebook row
  SELECT BookID, ExpiresAt, Status INTO v_book_id, v_expiry, v_status
  FROM Prebook
  WHERE PrebookID = p_prebook_id
  FOR UPDATE;

  IF v_book_id IS NULL THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Prebook row not found.';
  END IF;

  IF v_status <> 'Notified' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation not valid (status not Notified).';
  END IF;

  IF v_expiry < NOW() THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation has expired.';
  END IF;

  SELECT AvailableCopies INTO v_available FROM Books WHERE BookID = v_book_id;
  IF v_available IS NULL OR v_available <= 0 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available copies to allocate.';
  END IF;

  # allocate copy and insert borrow
  UPDATE Books SET AvailableCopies = AvailableCopies - 1 WHERE BookID = v_book_id;

  INSERT INTO Borrow (Roll_No, BookID, IssueDate, DueDate, Status)
  VALUES (p_roll_no, v_book_id, CURRENT_DATE, p_due_date, 'Issued');

#update prebook as completed and attach borrow id
  UPDATE Prebook
  SET Status = 'Completed',
      Fulfilled_BorrowID = LAST_INSERT_ID()
  WHERE PrebookID = p_prebook_id;

  COMMIT;

  SELECT CONCAT('Reservation fulfilled. Book issued under BorrowID ', LAST_INSERT_ID()) AS Message;
END$$
DELIMITER ;

#Event: Expire Reservations (runs hourly
# Ensure event scheduler is enabled in server before creating event.
SET GLOBAL event_scheduler = ON;

DELIMITER $$
CREATE EVENT IF NOT EXISTS Expire_Reservations
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_prebook_id INT;
  DECLARE v_book_id INT;

  DECLARE cur CURSOR FOR
    SELECT PrebookID, BookID FROM Prebook WHERE Status = 'Notified' AND ExpiresAt < NOW();

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_prebook_id, v_book_id;
    IF done = 1 THEN
      LEAVE read_loop;
    END IF;

    UPDATE Prebook SET Status = 'Expired' WHERE PrebookID = v_prebook_id;

#call to notify next user (this will attempt to notify next waiting #Prebook row)
    CALL Notify_Next_Waitlist_User(v_book_id);
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;

#change to add to waitlist
#Procedure 8 : Renew Loan 
DELIMITER $$
CREATE PROCEDURE Renew_Loan(IN p_borrow_id INT)
BEGIN
  DECLARE v_book_id INT;
  DECLARE v_due_date DATE;
  DECLARE v_status VARCHAR(20);
  DECLARE v_waitlist_count INT DEFAULT 0;

  START TRANSACTION;

  SELECT BookID, DueDate, Status INTO v_book_id, v_due_date, v_status
  FROM Borrow
  WHERE BorrowID = p_borrow_id
  FOR UPDATE;

  IF v_status <> 'Issued' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Renewal not allowed. Book is not currently issued.';
  END IF;

  SELECT COUNT(*) INTO v_waitlist_count
  FROM Prebook
  WHERE BookID = v_book_id AND Status IN ('Waiting','Notified');

  IF v_waitlist_count > 0 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Renewal denied. There is a waitlist for this book.';
  END IF;

  UPDATE Borrow
  SET DueDate = DATE_ADD(v_due_date, INTERVAL 14 DAY)
  WHERE BorrowID = p_borrow_id;

  COMMIT;
