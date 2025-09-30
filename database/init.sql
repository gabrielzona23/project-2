-- Database initialization script for Laravel Benchmark
-- PostgreSQL 17

-- Create benchmark database if it doesn't exist
-- (This is handled by Docker environment variables)

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified_at TIMESTAMP NULL,
    password VARCHAR(255) NOT NULL,
    remember_token VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create posts table for testing relationships
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content TEXT NOT NULL,
    published_at TIMESTAMP NULL,
    views_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create post_categories pivot table
CREATE TABLE IF NOT EXISTS post_categories (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, category_id)
);

-- Create benchmark_data table for performance testing
CREATE TABLE IF NOT EXISTS benchmark_data (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    value JSONB NOT NULL,
    metadata JSONB NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_slug ON posts(slug);
CREATE INDEX IF NOT EXISTS idx_posts_published_at ON posts(published_at);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_post_categories_post_id ON post_categories(post_id);
CREATE INDEX IF NOT EXISTS idx_post_categories_category_id ON post_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_benchmark_data_name ON benchmark_data(name);
CREATE INDEX IF NOT EXISTS idx_benchmark_data_status ON benchmark_data(status);
CREATE INDEX IF NOT EXISTS idx_benchmark_data_value ON benchmark_data USING GIN(value);

-- Insert sample data for testing

-- Sample users
INSERT INTO users (name, email, password) VALUES
('John Doe', 'john@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Jane Smith', 'jane@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Bob Johnson', 'bob@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Alice Brown', 'alice@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Charlie Wilson', 'charlie@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi')
ON CONFLICT (email) DO NOTHING;

-- Sample categories
INSERT INTO categories (name, slug, description) VALUES
('Technology', 'technology', 'Posts about technology and programming'),
('Laravel', 'laravel', 'Posts about Laravel framework'),
('Performance', 'performance', 'Posts about application performance'),
('Benchmarks', 'benchmarks', 'Posts about benchmark results'),
('PHP', 'php', 'Posts about PHP programming language')
ON CONFLICT (slug) DO NOTHING;

-- Sample posts
INSERT INTO posts (user_id, title, slug, content, published_at, views_count) VALUES
(1, 'Introduction to Laravel Performance', 'intro-laravel-performance', 'This is a comprehensive guide to Laravel performance optimization...', CURRENT_TIMESTAMP - INTERVAL '7 days', 150),
(2, 'Swoole vs PHP-FPM Comparison', 'swoole-vs-php-fpm', 'A detailed comparison between Swoole and PHP-FPM runtimes...', CURRENT_TIMESTAMP - INTERVAL '5 days', 89),
(3, 'FrankenPHP: The Future of PHP', 'frankenphp-future-php', 'Exploring the capabilities of FrankenPHP in modern applications...', CURRENT_TIMESTAMP - INTERVAL '3 days', 234),
(1, 'Database Optimization Techniques', 'database-optimization', 'Learn how to optimize your database queries for better performance...', CURRENT_TIMESTAMP - INTERVAL '2 days', 178),
(3, 'Caching Strategies in Laravel', 'caching-strategies-laravel', 'Different caching approaches to improve application speed...', CURRENT_TIMESTAMP - INTERVAL '1 day', 92)
ON CONFLICT (slug) DO NOTHING;

-- Sample comments
INSERT INTO comments (post_id, user_id, content) VALUES
(1, 2, 'Great article! Very informative.'),
(1, 3, 'Thanks for sharing these tips.'),
(2, 1, 'Interesting comparison. I prefer Swoole.'),
(2, 4, 'PHP-FPM still has its place in many scenarios.'),
(3, 2, 'FrankenPHP looks promising!'),
(4, 5, 'These optimization techniques really work.'),
(5, 1, 'Cache invalidation is always tricky.');

-- Sample post categories
INSERT INTO post_categories (post_id, category_id) VALUES
(1, 1), (1, 2), (1, 3),
(2, 1), (2, 3), (2, 4), (2, 5),
(3, 1), (3, 5),
(4, 1), (4, 3),
(5, 2), (5, 3);

-- Sample benchmark data for testing
INSERT INTO benchmark_data (name, value, metadata, status) 
SELECT 
    'test_record_' || generate_series,
    jsonb_build_object(
        'score', random() * 100,
        'duration', random() * 1000,
        'memory_usage', random() * 50
    ),
    jsonb_build_object(
        'test_type', 'performance',
        'environment', 'docker',
        'timestamp', CURRENT_TIMESTAMP
    ),
    CASE WHEN random() > 0.1 THEN 'active' ELSE 'inactive' END
FROM generate_series(1, 1000);

-- Create a function to generate more test data if needed
CREATE OR REPLACE FUNCTION generate_benchmark_data(count INTEGER)
RETURNS void AS $$
BEGIN
    INSERT INTO benchmark_data (name, value, metadata, status) 
    SELECT 
        'generated_record_' || generate_series,
        jsonb_build_object(
            'score', random() * 100,
            'duration', random() * 1000,
            'memory_usage', random() * 50,
            'cpu_usage', random() * 100
        ),
        jsonb_build_object(
            'test_type', 'load_test',
            'environment', 'docker',
            'timestamp', CURRENT_TIMESTAMP,
            'batch_id', 'batch_' || extract(epoch from CURRENT_TIMESTAMP)
        ),
        CASE WHEN random() > 0.15 THEN 'active' ELSE 'inactive' END
    FROM generate_series(1, count);
END;
$$ LANGUAGE plpgsql;

-- Grant permissions (if needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO laravel;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO laravel;