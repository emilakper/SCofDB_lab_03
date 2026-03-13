\timing on
\echo '=== AFTER PARTITIONING ==='

SET max_parallel_workers_per_gather = 0;
SET work_mem = '32MB';
ANALYZE orders_partitioned_demo;

-- TODO:
-- Выполните ANALYZE для партиционированной таблицы/таблиц
-- Пример:
-- ANALYZE orders;

-- ============================================
-- TODO:
-- Скопируйте сюда те же запросы, что в:
--   02_explain_before.sql
--   04_explain_after_indexes.sql
-- и выполните EXPLAIN (ANALYZE, BUFFERS) после партиционирования.
-- ============================================

\echo '--- Q1: Фильтрация + сортировка (пример класса запроса) ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, total_amount, created_at
FROM orders_partitioned_demo
WHERE user_id = (SELECT id FROM users WHERE email = 'user00001@example.com')
  AND created_at >= NOW() - INTERVAL '1 month'
ORDER BY created_at DESC
LIMIT 20;

\echo '--- Q2: Фильтрация по статусу + диапазону дат ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*) as order_count, SUM(total_amount) as total_revenue
FROM orders_partitioned_demo
WHERE created_at >= '2025-01-01' 
  AND created_at < '2025-04-01'
GROUP BY status
ORDER BY order_count DESC;

\echo '--- Q3: JOIN + GROUP BY ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT oi.product_name, 
       COUNT(DISTINCT o.id) as order_count,
       SUM(oi.quantity) as total_quantity,
       SUM(oi.price * oi.quantity) as total_revenue
FROM order_items oi
JOIN orders_partitioned_demo o ON o.id = oi.order_id
WHERE o.created_at >= '2025-01-01'
  AND o.created_at < '2025-04-01'
GROUP BY oi.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- (Опционально) Q4: полный агрегат по периоду, который сложно ускорить индексами
\echo '--- Q4: Заказы в статусе "paid" которые долго не становятся "shipped" ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.id, o.user_id, o.total_amount, o.created_at,
       (SELECT changed_at FROM order_status_history osh 
        WHERE osh.order_id = o.id AND osh.status = 'paid' 
        ORDER BY changed_at DESC LIMIT 1) as paid_at
FROM orders_partitioned_demo o
WHERE o.status = 'paid'
  AND EXISTS (
    SELECT 1 FROM order_status_history osh 
    WHERE osh.order_id = o.id AND osh.status = 'paid'
  )
  AND NOT EXISTS (
    SELECT 1 FROM order_status_history osh 
    WHERE osh.order_id = o.id AND osh.status = 'shipped'
  )
  AND o.created_at < NOW() - INTERVAL '1 day'
ORDER BY o.created_at;