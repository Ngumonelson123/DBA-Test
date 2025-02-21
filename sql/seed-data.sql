INSERT INTO users (name, email, phone)
VALUES
    ('Alice Johnson', 'alice@example.com', '254712345678'),
    ('Bob Smith', 'bob@example.com', '254798765432'),
    ('Charlie Brown', 'charlie@example.com', '254723456789');

INSERT INTO transactions (user_id, amount, transaction_type, status)
VALUES
    (1, 1000, 'deposit', 'completed'),
    (2, 500, 'withdrawal', 'pending'),
    (3, 2000, 'transfer', 'failed');
