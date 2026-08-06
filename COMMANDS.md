docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
> Chỉ định chạy file trong container