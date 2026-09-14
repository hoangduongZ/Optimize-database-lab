---
Mục đích: đây là file chứa các lệnh liên quan đến postgres và docker
---

docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
> Chỉ định chạy file trong container