-- SQL Project - Library Management System N2

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members with overdue books (assuming a 30-day return period).
-- Display the member's_id, member's name, book title, issue date, and days overdue.

-- issued_status == members == books == return_status
-- filter books which is return
-- overdue > 30 days


SELECT 
      ist.issued_member_id,
	  m.member_name,
	  bk.book_title,
	  ist.issued_date,
	  --rs.return_date,
	  CURRENT_DATE - ist.issued_date AS over_due_days
FROM issued_status AS ist
JOIN 
members AS m
    ON m.member_id = ist.issued_member_id
JOIN 
books AS bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status AS rs
ON rs.issued_id = ist.issued_id
WHERE
      rs.return_date IS NULL
      AND
	  (CURRENT_DATE - ist.issued_date) > 30
ORDER BY ist.issued_member_id


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" 
-- when they are returned (based on entries in the return_status table).

--WITHOUT STORED PROCEDURES

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-451-52994-2';

SELECT * FROM books
WHERE isbn = '978-0-451-52994-2';

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2';

SELECT * FROM return_status
WHERE issued_id = 'IS130';

DELETE FROM return_status
WHERE issued_id = 'IS130';

--
INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
VALUES
('RS125', 'IS130', CURRENT_DATE, 'Good');
SELECT * FROM return_status
WHERE issued_id = 'IS130';



UPDATE books
SET status = 'yes'
WHERE isbn = '978-0-451-52994-2';
SELECT * FROM books
WHERE isbn = '978-0-451-52994-2';


-- STORED PROCEDURES SYNTAX
CREATE OR REPLACE PROCEDURES --name(parameter datatype, )
LANGUAGE plpgsql
AS $$

DECLARE
-- hey im expecting a variable here V-- datatype

BEGIN   

-- ALL YOUR LOGIC

END;


$$


-- WITH STORED PROCEDURES

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$

CALL add_return_records();

-- 1 Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';


CALL add_return_records('RS138', 'IS135', 'Good');

-- Testing FUNCTION add_return_records

issued_id = IS140
ISBN = WHERE isbn = '978-0-330-25864-8'

SELECT * FROM books
WHERE isbn = '978-0-330-25864-8';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-330-25864-8'; 

SELECT * FROM return_status
WHERE issued_id = 'IS140';


    UPDATE books
	SET status = 'no'
    WHERE isbn = '978-0-330-25864-8';



CALL add_return_records('RS148', 'IS140', 'Good')



-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, 
-- showing the number of books issued, 
-- the number of books returned and 
-- the total revenue generated from book rentals.

SELECT * FROM branch;

SELECT * FROM issued_status;

SELECT * FROM employees;

SELECT * FROM books;

SELECT * FROM return_status;
--

CREATE TABLE branch_reports
AS
SELECT 
      b.branch_id,
	  b.manager_id,
	  COUNT(ist.issued_id) AS number_of_book_issued,
	  COUNT(rs.return_id) AS number_of_book_return,
      SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN
employees AS e
ON 
e.emp_id = ist.issued_emp_id
JOIN
branch AS b
ON 
e.branch_id = b.branch_id
LEFT JOIN
return_status AS rs
ON
rs.issued_id = ist.issued_id
JOIN
books AS bk
ON 
ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

--
SELECT * FROM branch_reports
--

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a 
-- new table active_members containing members who have issued at least one book in the last 2 months.



CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN 
     (
SELECT 
	  DISTINCT issued_member_id
FROM issued_status
WHERE 
     issued_date > CURRENT_DATE - INTERVAL '2 month'
	 )

-- SELECT CURRENT_DATE - INTERVAL '2 month'

SELECT * FROM active_members

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

SELECT 
     e.emp_name,
	 COUNT(ist.issued_id) AS number_of_books_processed,
	 e.branch_id
FROM employees AS e
JOIN issued_status AS ist
ON e.emp_id = ist.issued_emp_id
GROUP BY 1, 3
ORDER BY COUNT(ist.issued_id) DESC
LIMIT 3


/*
Task 19: Stored Procedure Objective:

Create a stored procedure to manage the status of books in a library system.

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 

The procedure should function as follows:

The stored procedure should take the book_id as an input parameter. 

The procedure should first check if the book is available (status = 'yes'). 

If the book is available, it should be issued, and the status in the books table should be updated to 'no'.

If the book is not available (status = 'no'), the procedure should return an error message indicating that 
the book is currently not available.
*/

SELECT * FROM books

SELECT * FROM issued_status

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
-- ALL THE VARIABLES
    v_status VARCHAR(10);
BEGIN
-- ALL THE LOGIC
-- checking if book is available 'yes'
   SELECT 
        status
		INTO
		v_status
   FROM books
   WHERE isbn = p_issued_book_isbn;

   IF v_status = 'yes' THEN

      INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
      VALUES
      (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn , p_issued_emp_id);
	  
       UPDATE books
       SET status = 'no'
	   WHERE isbn = p_issued_book_isbn;



      RAISE NOTICE 'Book Records added successfully for books isbn: %', p_issued_book_isbn;
  
  ELSE
      RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable : %',p_issued_book_isbn;
   END IF;
   

END;
$$

(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10)

SELECT * FROM books;
-- 978-0-553-29698-2 YES
-- 978-0-375-41398-8 NO

SELECT * FROM issued_status;


CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104' )

CALL issue_book('IS155', 'C108', '978-0-375-41398-8', 'E104' )


SELECT * FROM books                 -- now it shows no because just now it is issued
WHERE isbn = '978-0-553-29698-2'

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8'


hi













