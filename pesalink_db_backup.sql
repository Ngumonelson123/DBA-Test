-- Dump of database pesalink_db
-- Generated on: 2025-02-20

-- Drop existing tables
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(12) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create transactions table
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'KES',
    transaction_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_transaction_user ON transactions(user_id);
CREATE INDEX idx_transaction_date ON transactions(transaction_date);

-- Sample Data
INSERT INTO users (name, email, phone) VALUES 
('John Doe', 'johndoe@example.com', '254712345678'),
('Jane Smith', 'janesmith@example.com', '254798765432');

INSERT INTO transactions (user_id, amount, transaction_type, status) VALUES 
(1, 500.00, 'deposit', 'completed'),
(1, 250.75, 'withdrawal', 'failed'),
(2, 1000.00, 'payment', 'completed');
