CREATE TABLE files (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    path VARCHAR(255),
    size INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE file_readers (
    id SERIAL PRIMARY KEY,
    file_id INTEGER,
    status VARCHAR(50),
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id)
);

CREATE TABLE file_read_tasks (
    id SERIAL PRIMARY KEY,
    file_id INTEGER,
    reader_id INTEGER,
    chunk_size INTEGER,
    chunk_start INTEGER,
    chunk_end INTEGER,
    status VARCHAR(50),
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id),
    FOREIGN KEY (reader_id) REFERENCES file_readers(id)
);

CREATE INDEX idx_file_readers_file_id ON file_readers(file_id);
CREATE INDEX idx_file_read_tasks_file_id ON file_read_tasks(file_id);
CREATE INDEX idx_file_read_tasks_reader_id ON file_read_tasks(reader_id);

INSERT INTO files (name, path, size) VALUES ('file1.txt', '/path/to/file1.txt', 1024);
INSERT INTO files (name, path, size) VALUES ('file2.txt', '/path/to/file2.txt', 2048);
INSERT INTO files (name, path, size) VALUES ('file3.txt', '/path/to/file3.txt', 4096);

INSERT INTO file_readers (file_id, status, started_at) VALUES (1, 'started', CURRENT_TIMESTAMP);
INSERT INTO file_readers (file_id, status, started_at) VALUES (2, 'started', CURRENT_TIMESTAMP);
INSERT INTO file_readers (file_id, status, started_at) VALUES (3, 'started', CURRENT_TIMESTAMP);

INSERT INTO file_read_tasks (file_id, reader_id, chunk_size, chunk_start, chunk_end, status, started_at) VALUES (1, 1, 1024, 0, 1024, 'started', CURRENT_TIMESTAMP);
INSERT INTO file_read_tasks (file_id, reader_id, chunk_size, chunk_start, chunk_end, status, started_at) VALUES (1, 1, 1024, 1024, 2048, 'pending', NULL);
INSERT INTO file_read_tasks (file_id, reader_id, chunk_size, chunk_start, chunk_end, status, started_at) VALUES (2, 2, 2048, 0, 2048, 'started', CURRENT_TIMESTAMP);
INSERT INTO file_read_tasks (file_id, reader_id, chunk_size, chunk_start, chunk_end, status, started_at) VALUES (3, 3, 4096, 0, 4096, 'started', CURRENT_TIMESTAMP);

SELECT * FROM files;
SELECT * FROM file_readers;
SELECT * FROM file_read_tasks;

UPDATE file_read_tasks SET status = 'finished', finished_at = CURRENT_TIMESTAMP WHERE id = 1;
UPDATE file_read_tasks SET status = 'started', started_at = CURRENT_TIMESTAMP WHERE id = 2;
UPDATE file_readers SET status = 'finished', finished_at = CURRENT_TIMESTAMP WHERE id = 1;

SELECT * FROM files;
SELECT * FROM file_readers;
SELECT * FROM file_read_tasks;

CREATE OR REPLACE FUNCTION read_file_chunk(p_file_id INTEGER, p_reader_id INTEGER, p_chunk_size INTEGER, p_chunk_start INTEGER, p_chunk_end INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_file_size INTEGER;
    v_file_path VARCHAR(255);
    v_chunk_data BYTEA;
BEGIN
    SELECT size, path INTO v_file_size, v_file_path FROM files WHERE id = p_file_id;
    IF v_file_size IS NULL THEN
        RETURN 0;
    END IF;
    IF p_chunk_end > v_file_size THEN
        p_chunk_end := v_file_size;
    END IF;
    v_chunk_data := pg_read_file(v_file_path, p_chunk_start, p_chunk_size);
    INSERT INTO file_read_tasks (file_id, reader_id, chunk_size, chunk_start, chunk_end, status, started_at) VALUES (p_file_id, p_reader_id, p_chunk_size, p_chunk_start, p_chunk_end, 'started', CURRENT_TIMESTAMP);
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

SELECT read_file_chunk(1, 1, 1024, 0, 1024);
SELECT read_file_chunk(2, 2, 2048, 0, 2048);
SELECT read_file_chunk(3, 3, 4096, 0, 4096);