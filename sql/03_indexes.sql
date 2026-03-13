\timing on
\echo '=== APPLY INDEXES ==='

-- ============================================
-- TODO: Создайте индексы на основе ваших EXPLAIN ANALYZE
-- ============================================

-- Индекс 1
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders USING BTREE (created_at);
-- Обоснование: 
-- - Ускорит Q1 (фильтр по дате) и Q2 (группировка по дате)
-- - B-tree оптимален для диапазонных запросов и сортировки по дате

-- Индекс 2
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at ON orders USING BTREE (status, created_at);
-- Обоснование:
-- - Ускорит Q2 и Q4 (фильтрация по статусу + дата)
-- - Составной индекс позволит сразу отсекать по статусу, потом по дате
-- - Покрывающий индекс для некоторых запросов

-- Индекс 3
-- TODO:
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id_status ON order_status_history 
USING BTREE (order_id, status, changed_at DESC);
-- Обоснование:
-- - Кардинально ускорит Q4 (последовательное сканирование для каждого заказа)
-- - Покрывающий индекс: содержит все нужные поля (order_id, status, changed_at)
-- - ORDER BY changed_at DESC уже учтено в индексе

-- (Опционально) Частичный индекс / BRIN / составной индекс
CREATE INDEX IF NOT EXISTS idx_orders_recent ON orders USING BTREE (created_at, id)
WHERE created_at >= '2024-01-01';
-- Обоснование:
-- - Частичный индекс будет меньше по размеру
-- - Все наши запросы идут по 2025 году, поэтому старые данные не нужны
-- - Ускорит JOIN в Q3, так как отфильтрует сразу по дате

-- Не забудьте обновить статистику после создания индексов
-- TODO:
ANALYZE orders;
ANALYZE order_status_history;
ANALYZE order_items;

\echo '=== INDEXES CREATED ==='