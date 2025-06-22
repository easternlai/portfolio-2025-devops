#!/bin/bash
set -e

apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

sudo sed -i "s/^#\\?listen_addresses *=.*/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
systemctl restart postgresql

sudo -u postgres psql <<EOSQL

CREATE DATABASE ${db_name};

CREATE USER ${db_user} WITH PASSWORD '${db_password}';

GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};

GRANT ALL PRIVILEGES ON SCHEMA public TO ${db_user};

\\c ${db_name}

CREATE TABLE contacts (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255),
  message TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts TO ${db_user};

GRANT USAGE, SELECT ON SEQUENCE contacts_id_seq TO ${db_user};

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${db_user};

EOSQL
