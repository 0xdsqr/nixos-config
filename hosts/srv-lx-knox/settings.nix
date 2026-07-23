_: {
  services.postgresql.settings = {
    # Connections
    max_connections = 100; # Temporary migration ceiling
    superuser_reserved_connections = 5;

    # Memory
    shared_buffers = "4 GB";
    effective_cache_size = "11 GB";
    work_mem = "8 MB";
    maintenance_work_mem = "1 GB";
    autovacuum_work_mem = "512 MB";
    huge_pages = "try";
    temp_file_limit = "16 GB"; # Per backend

    # Proxmox SSD
    effective_io_concurrency = 100;
    maintenance_io_concurrency = 100;
    random_page_cost = 1.25;

    # Statistics and logging
    shared_preload_libraries = "pg_stat_statements";
    compute_query_id = "auto";
    track_io_timing = "on";
    track_wal_io_timing = "on";
    track_functions = "pl";
    log_min_duration_statement = "500ms";
    log_lock_waits = "on";
    log_autovacuum_min_duration = "1s";
    idle_in_transaction_session_timeout = "60s";

    # Autovacuum
    autovacuum_max_workers = 4;
    autovacuum_naptime = "30s";
    autovacuum_vacuum_scale_factor = 0.05;
    autovacuum_vacuum_insert_scale_factor = 0.05;
    autovacuum_analyze_scale_factor = 0.02;

    # Checkpoints and WAL
    checkpoint_timeout = "15 min";
    checkpoint_completion_target = 0.9;
    max_wal_size = "8 GB";
    min_wal_size = "2 GB";
    wal_compression = "on";
    wal_buffers = -1;
    full_page_writes = "on";
    synchronous_commit = "on";

    # Parallelism
    max_worker_processes = 8;
    max_parallel_workers = 4;
    max_parallel_workers_per_gather = 2;
    max_parallel_maintenance_workers = 2;
    parallel_leader_participation = "on";

    password_encryption = "scram-sha-256";
  };
}
