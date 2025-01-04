-- drift:migrate
CREATE TABLE IF NOT EXISTS jokes (
    id INTEGER PRIMARY KEY NOT NULL,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- drift:rollback
DROP TABLE IF EXISTS jokes;
