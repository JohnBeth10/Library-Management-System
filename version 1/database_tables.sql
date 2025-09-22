#Database library
# database : name = library
CREATE DATABASE library;
USE library;

#Tables
#Table 1 : Books
CREATE TABLE Books (
  BookID INT PRIMARY KEY AUTO_INCREMENT,
  Title VARCHAR(150) NOT NULL,
  Author VARCHAR(100),
  ISBN VARCHAR(20) UNIQUE,
  Genre VARCHAR(50),
  PublishedYear INT,
  TotalCopies INT NOT NULL,
  AvailableCopies INT NOT NULL
);




#Table 2 : Students
CREATE TABLE Students (
  Student_ID VARCHAR(100),
  Name_of_Student VARCHAR(100) NOT NULL,
  Roll_No INT AUTO_INCREMENT PRIMARY KEY,
  Email VARCHAR(100) UNIQUE NOT NULL,
  Phone VARCHAR(15),
  Join_Date DATE DEFAULT (CURRENT_DATE)
);

#Table 3 : Borrow
CREATE TABLE Borrow (
  BorrowID INT PRIMARY KEY AUTO_INCREMENT,
  Roll_No INT NOT NULL,
  BookID INT NOT NULL,
  IssueDate DATE NOT NULL,
  DueDate DATE NOT NULL,
  ReturnDate DATE,
  Status ENUM('Issued','Returned') DEFAULT 'Issued',
  FOREIGN KEY (Roll_No) REFERENCES Students(Roll_No),
  FOREIGN KEY (BookID) REFERENCES Books(BookID)
);

#Table 4 : prebook
CREATE TABLE Prebook (
  PrebookID INT PRIMARY KEY AUTO_INCREMENT,
  Roll_No INT NOT NULL,
  BookID INT NOT NULL,
  PrebookDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  NotifiedAt DATETIME NULL,
  ExpiresAt DATETIME NULL,
  Status ENUM('Waiting','Notified','Completed','Expired') DEFAULT 'Waiting',
  Fulfilled_BorrowID INT NULL,
  FOREIGN KEY (Roll_No) REFERENCES Students(Roll_No),
  FOREIGN KEY (BookID) REFERENCES Books(BookID),
  FOREIGN KEY (Fulfilled_BorrowID) REFERENCES Borrow(BorrowID)
);

#Table 5 : waitlist 
CREATE TABLE Waitlist (
  WaitlistID INT PRIMARY KEY AUTO_INCREMENT,
  BookID INT NOT NULL,
  Roll_No INT NOT NULL,
  Position INT NOT NULL,
  AddedDate DATE DEFAULT (CURRENT_DATE),
  Status ENUM('Pending','Notified') DEFAULT 'Pending',
  FOREIGN KEY (BookID) REFERENCES Books(BookID),
  FOREIGN KEY (Roll_No) REFERENCES Students(Roll_No)
);
