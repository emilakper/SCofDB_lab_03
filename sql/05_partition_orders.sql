\timing on
\echo '=== PARTITION ORDERS BY DATE ==='

-- ============================================
-- TODO: Реализуйте партиционирование orders по дате
-- ============================================

-- Вариант A (рекомендуется): RANGE по created_at (месяц/квартал)
-- Вариант B: альтернативная разумная стратегия

-- Шаг 1: Подготовка структуры
-- TODO:
-- - создайте partitioned table (или shadow-таблицу для безопасной миграции)
-- - определите partition key = created_at

-- Шаг 2: Создание партиций
-- TODO:
-- - создайте набор партиций по диапазонам дат
-- - добавьте DEFAULT partition (опционально)

-- Шаг 3: Перенос данных
-- TODO:
-- - перенесите данные из исходной таблицы
-- - проверьте количество строк до/после

-- Шаг 4: Индексы на партиционированной таблице
-- TODO:
-- - создайте нужные индексы (если требуется)

-- Шаг 5: Проверка
-- TODO:
-- - ANALYZE
-- - проверка partition pruning на запросах по диапазону дат

CREATE TABLE orders_partitioned_demo (
    id UUID,
    user_id UUID,
    status VARCHAR(20),
    total_amount NUMERIC(15, 2),
    created_at TIMESTAMP WITH TIME ZONE
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_demo_2024_q1 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_demo_2024_q2 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE orders_demo_2024_q3 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE orders_demo_2024_q4 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

CREATE TABLE orders_demo_2025_q1 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE orders_demo_2025_q2 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

CREATE TABLE orders_demo_2025_q3 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');

CREATE TABLE orders_demo_2025_q4 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

CREATE TABLE orders_demo_2026_q1 PARTITION OF orders_partitioned_demo
FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');

CREATE TABLE orders_demo_default PARTITION OF orders_partitioned_demo DEFAULT;

\echo '=== COPYING DATA TO DEMO TABLE... ==='
INSERT INTO orders_partitioned_demo (id, user_id, status, total_amount, created_at)
SELECT id, user_id, status, total_amount, created_at FROM orders;

\echo '=== CREATING INDEXES ON DEMO TABLE ==='
CREATE INDEX idx_orders_demo_created_at ON orders_partitioned_demo USING BTREE (created_at);
CREATE INDEX idx_orders_demo_status_created ON orders_partitioned_demo USING BTREE (status, created_at);
CREATE INDEX idx_orders_demo_user_id ON orders_partitioned_demo USING BTREE (user_id);

ANALYZE orders_partitioned_demo;

\echo '=== DEMO: Запрос на оригинальной таблице (без партиций) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), AVG(total_amount)
FROM orders
WHERE created_at >= '2025-01-01' AND created_at < '2025-04-01';

\echo '=== DEMO: Тот же запрос на таблице с партициями ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), AVG(total_amount)
FROM orders_partitioned_demo
WHERE created_at >= '2025-01-01' AND created_at < '2025-04-01';

\echo '=== PARTITION SIZES ==='
SELECT
    table_name,
    n_live_tup as rows
FROM pg_stat_user_tables
WHERE table_name LIKE 'orders_demo_2025%'
ORDER BY table_name;

\echo '=== PARTITIONING DEMO COMPLETE ==='