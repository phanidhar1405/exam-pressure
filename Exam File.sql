use practice;

create database falcon

use falcon

CREATE TABLE artists (
    artist_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    birth_year INT NOT NULL
);

CREATE TABLE artworks (
    artwork_id INT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    artist_id INT NOT NULL,
    genre VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    artwork_id INT NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (artwork_id) REFERENCES artworks(artwork_id)
);

INSERT INTO artists (artist_id, name, country, birth_year) VALUES
(1, 'Vincent van Gogh', 'Netherlands', 1853),
(2, 'Pablo Picasso', 'Spain', 1881),
(3, 'Leonardo da Vinci', 'Italy', 1452),
(4, 'Claude Monet', 'France', 1840),
(5, 'Salvador Dalí', 'Spain', 1904);

INSERT INTO artworks (artwork_id, title, artist_id, genre, price) VALUES
(1, 'Starry Night', 1, 'Post-Impressionism', 1000000.00),
(2, 'Guernica', 2, 'Cubism', 2000000.00),
(3, 'Mona Lisa', 3, 'Renaissance', 3000000.00),
(4, 'Water Lilies', 4, 'Impressionism', 500000.00),
(5, 'The Persistence of Memory', 5, 'Surrealism', 1500000.00);

INSERT INTO sales (sale_id, artwork_id, sale_date, quantity, total_amount) VALUES
(1, 1, '2024-01-15', 1, 1000000.00),
(2, 2, '2024-02-10', 1, 2000000.00),
(3, 3, '2024-03-05', 1, 3000000.00),
(4, 4, '2024-04-20', 2, 1000000.00);

select * from sales

select * from artists

select * from artworks

section 3

--Write a query to find the artworks that have the highest sale total for each genre.

select genre ,title ,  max(total_amount)
from artworks a 
left join sales s
on a.artist_id = s.artwork_id
group by genre , title


--Write a query to find artworks that have a higher price than the average price of artworks by the same artist.

select awo.title from artworks awo 
where awo.price > (
            select AVG(price) from artworks awi
			where awi.artist_id = awo.artist_id
)


--Write a query to find the average price of artworks for each artist and only include artists whose average artwork price is 4
--higher than the overall average artwork price.


with hellcte 
as
(
select name , AVG(price) as p from artists a
join artworks aw on a.artist_id = aw.artist_id
join sales s on s.artwork_id = aw.artwork_id
group by a.name)
select name from hellcte where p > (select avg(price) from artworks)


-- Write a query to create a view that shows artists who have created artworks in multiple genres.

create view vw_artists 
as
SELECT artists.name FROM artists JOIN artworks
ON artists.artist_id = artworks.artist_id 
GROUP BY artists.name 
HAVING COUNT(DISTINCT artworks.genre) > 1;

select * from vw_artists;


section 5

Create a trigger to log changes to the artworks table into an artworks_log table, capturing the artwork_id, title, and a change description.

CREATE TABLE artworks_log (
    log_id INT PRIMARY KEY,
    artwork_id INT NOT NULL,
    title VARCHAR(25) NOT NULL,
    change_description VARCHAR(500),
    change_date DATETIME
);

CREATE TRIGGER artworks_log_trigger
AFTER UPDATE
ON artworks
BEGIN
    DECLARE change_desc VARCHAR(50);
    IF OLD.title != NEW.title THEN
        SET change_desc = CONCAT('Title changed from ', OLD.title, NEW.title);
    INSERT INTO artworks_log (artwork_id, title, change_description)
    VALUES (NEW.artwork_id, NEW.title, change_desc);
END;

Create a scalar function to calculate the average sales amount for artworks in a given genre and write a query to use this function for 'Impressionism'.

CREATE FUNCTION fn_average_sales_amount_by_genre(@genre VARCHAR(50))
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @avg_sales DECIMAL(10, 2);
    SELECT @avg_sales = AVG(total_amount)
    FROM sales s
    JOIN artworks a ON s.artwork_id = a.artwork_id
    WHERE a.genre = @genre;
    RETURN @avg_sales
END;


Create a stored procedure to add a new sale and update the total sales for the artwork. Ensure the quantity is positive, and use transactions to maintain data integrity.


CREATE PROCEDURE sp_add_sale
    @artwork_id INT,
    @sale_date DATE,
    @quantity INT,
    @total_amount DECIMAL(10, 2)
AS
BEGIN
    BEGIN TRANSACTION;
    If @quantity > 0
    BEGIN
        INSERT INTO sales (artwork_id, sale_date, quantity, total_amount)
        VALUES (@artwork_id, @sale_date, @quantity, @total_amount);
        
        -- Update total sales for the artwork
        UPDATE artworks
        SET total_sales = total_sales + @quantity
        WHERE artwork_id = @artwork_id;
    END
    COMMIT TRANSACTION;
END;



Create a multi-statement table-valued function (MTVF) to return the total quantity sold for each genre and use it in a query to display the results.

CREATE FUNCTION fn_total_quantity_sold_by_genre()
RETURNS @TotalQuantitySold TABLE
(
    genre VARCHAR(50),
    total_quantity_sold INT
)
AS
BEGIN
    INSERT INTO @TotalQuantitySold
    SELECT a.genre, SUM(s.quantity) AS total_quantity_sold
    FROM sales s
    JOIN artworks a ON s.artwork_id = a.artwork_id
    GROUP BY a.genre;
    
    RETURN;
END;

select * from fn_total_quantity_sold_by_genre();



Write a query to create an NTILE distribution of artists based on their total sales, divided into 4 tiles.

WITH ArtistSales AS (
    SELECT a.artist_id, a.name, SUM(s.total_amount) AS total_sales
    FROM artists a
    LEFT JOIN artworks aw ON a.artist_id = aw.artist_id
    JOIN sales s ON aw.artwork_id = s.artwork_id
    GROUP BY a.artist_id, a.name
)
SELECT name, total_sales,
       NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_ntile
FROM ArtistSales;



Section 1

Write a query to display the artist names in uppercase.

SELECT UPPER(name) FROM artists;

Write a query to find the top 2 highest-priced artworks and the total quantity sold for each.

SELECT TOP 2 title, price,
(SELECT SUM(quantity) FROM sales s WHERE s.artwork_id = a.artwork_id) AS total_quantity_sold 
FROM artworks a ORDER BY price DESC;

Write a query to find the total amount of sales for the artwork 'Mona Lisa'.


SELECT SUM(total_amount) 
FROM sales
WHERE artwork_id = (SELECT artwork_id FROM artworks WHERE title = 'Mona Lisa');

Write a query to extract the year from the sale date of 'Guernica'.


SELECT YEAR(sale_date) FROM sales 
WHERE artwork_id = 
(SELECT artwork_id FROM artworks WHERE title = 'Guernica');


section 2 

Write a query to find the artworks that have the highest sale total for each genre.

SELECT title, genre, MAX(total_amount)
FROM sales
JOIN artworks ON sales.artwork_id = artworks.artwork_id 
GROUP BY genre;

Write a query to rank artists by their total sales amount and display the top 3 artists.


SELECT TOP 3 artists.name, SUM(sales.total_amount) AS total_sales
FROM artists
JOIN artworks ON artists.artist_id = artworks.artist_id 
JOIN sales ON artworks.artwork_id = sales.artwork_id
GROUP BY artists.name 
ORDER BY total_sales DESC;

Write a query to display artists who have artworks in multiple genres.


SELECT artists.name FROM artists JOIN artworks
ON artists.artist_id = artworks.artist_id 
GROUP BY artists.name 
HAVING COUNT(DISTINCT artworks.genre) > 1;


Write a query to find the average price of artworks for each artist.

Write a query to create a non-clustered index on the sales table to improve query performance for queries filtering by artwork_id.

CREATE NONCLUSTERED INDEX idx_artwork_id ON sales (artwork_id);
*
Write a query to find the artists who have sold more artworks than the average number of artworks sold per artist.

SELECT artists.name FROM artists
JOIN artworks ON artists.artist_id = artworks.artist_id 
JOIN (SELECT artwork_id, SUM(quantity) AS total_sold FROM sales GROUP BY artwork_id) AS sales_summary 
ON artworks.artwork_id = sales_summary.artwork_id GROUP BY artists.name HAVING SUM(sales_summary.total_sold) > 
(SELECT AVG(total_sold) FROM (SELECT SUM(quantity) AS total_sold FROM sales JOIN artworks ON sales.artwork_id = artworks.artwork_id GROUP BY artworks.artist_id) AS avg_sales)


Write a query to find the artists who have created artworks in both 'Cubism' and 'Surrealism' genres.

SELECT DISTINCT a1.name FROM artists a1 
JOIN artworks aw1 ON a1.artist_id = aw1.artist_id 
JOIN artworks aw2 ON a1.artist_id = aw2.artist_id 
WHERE aw1.genre = 'Cubism' AND aw2.genre = 'Surrealism';

Write a query to display artists whose birth year is earlier than the average birth year of artists from their country.


SELECT a1.name FROM artists a1 ,
(SELECT name, country, birth_year, AVG(birth_year) OVER (PARTITION BY country) AS avg_birth_year 
FROM artists) AS a2
ON a1.name = a2.name AND a1.country = a2.country 
WHERE a1.birth_year < a2.avg_birth_year;

Write a query to find the artworks that have been sold in both January and February 2024.


SELECT DISTINCT artwork_id FROM sales WHERE sale_date BETWEEN '2024-01-01' AND '2024-01-31' 
INTERSECT 
SELECT DISTINCT artwork_id FROM sales WHERE sale_date BETWEEN '2024-02-01' AND '2024-02-29';



Write a query to calculate the price of 'Starry Night' plus 10% tax.


SELECT price * 1.1 AS price_with_tax FROM artworks WHERE title = 'Starry Night';

Write a query to display the artists whose average artwork price is higher than every artwork price in the 'Renaissance' genre.

SELECT a1.name FROM artists a1 
JOIN artworks aw1 ON a1.artist_id = aw1.artist_id JOIN 
(SELECT AVG(price) AS avg_price FROM artworks WHERE genre = 'Renaissance') 
AS r ON aw1.price > r.avg_price
GROUP BY a1.name HAVING AVG(aw1.price) > ALL (SELECT price FROM artworks WHERE genre = 'Renaissance');


-------------------------------------------------------------------------------------------------

-- Section 4


Write a query to export the artists and their artworks into XML format.

--[XML]
SELECT 
    artists.artist_id,
    artists.name,
    artists.country,
    artists.birth_year,
    (
        SELECT 
            artworks.artwork_id,
            artworks.title,
            artworks.genre,
            artworks.price
        FROM 
            artworks
        WHERE 
            artworks.artist_id = artists.artist_id
        FOR XML PATH('artwork')
    ) AS artworks
FROM 
    artists
FOR XML PATH('artist'), ROOT('artists');

--------------------------------------------

--Normalize the table

Normalization (5 Marks)
Question: Given the denormalized table ecommerce_data with sample data:
id	customer_name	customer_email	product_name	product_category	product_price	order_date	order_quantity	order_total_amount
1	Alice Johnson	alice@example.com	Laptop	Electronics	1200.00	2023-01-10	1	1200.00
2	Bob Smith	bob@example.com	Smartphone	Electronics	800.00	2023-01-15	2	1600.00
3	Alice Johnson	alice@example.com	Headphones	Accessories	150.00	2023-01-20	2	300.00
4	Charlie Brown	charlie@example.com	Desk Chair	Furniture	200.00	2023-02-10	1	200.00
Normalize this table into 3NF (Third Normal Form). Specify all primary keys, foreign key constraints, unique constraints, not null constraints, and check constraints.


CREATE TABLE order_details (
    order_detail_id INT PRIMARY KEY identity(1,1),
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    order_quantity INT NOT NULL,
    order_total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
	check otd order_total_amount >= 0
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY identity(1,1),
    customer_name VARCHAR(50) NOT NULL,
    customer_email VARCHAR(20) NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY identity(1,1),
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
	check o order_quantity > 0
);

CREATE TABLE products (
    product_id INT PRIMARY KEY identity(1,1),
    product_name VARCHAR(23) NOT NULL,
    product_category VARCHAR(25) NOT NULL,
    product_price DECIMAL(10, 2) NOT NULL
	check  c product_price >= 0
);


-- Insert Customers
INSERT INTO customers (customer_name, customer_email) VALUES
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com');

-- Insert Products
INSERT INTO products (product_name, product_category, product_price) VALUES
('Laptop', 'Electronics', 1200.00),
('Smartphone', 'Electronics', 800.00),
('Headphones', 'Accessories', 150.00),
('Desk Chair', 'Furniture', 200.00);

-- Insert Orders
INSERT INTO orders (customer_id, order_date) VALUES
((SELECT customer_id FROM customers WHERE customer_name = 'Alice Johnson'), '2023-01-10'),
((SELECT customer_id FROM customers WHERE customer_name = 'Bob Smith'), '2023-01-15'),
((SELECT customer_id FROM customers WHERE customer_name = 'Alice Johnson'), '2023-01-20'),
((SELECT customer_id FROM customers WHERE customer_name = 'Charlie Brown'), '2023-02-10');










