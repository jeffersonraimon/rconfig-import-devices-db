# RConfig Device Importer

Este script importa devices de um CSV para o banco de dados do RConfig via Docker.

## Como usar

1. Faça backup antes

docker exec rconfig_db mysqldump -u rconfig -p rconfig8db > backup.sql

2. Valide os IDs para seu cenário:
   - Crie um device da forma que deseja no GUI
   - Acesso o DB (docker exec -it rconfig_db mysql -u rconfig -p)
   - Acesse o o DB do rconfig (USE rconfig8db;)
   - Veja o device (SELECT * FROM devices LIMIT 5;)
   - Anotes os IDs de:
      - device_cred_id
      - device_category_id
      - device_template
      - categories (para o Commands Groups)
      - device_vendor

3. Configure `import_devices.sh` com:
   - Nome do container MySQL
   - DB_USER / DB_PASS / DB_NAME
   - IDs de template, vendor, command group, categoria e credencial
   - Usuário e *senha do device

4. Coloque o CSV `XXXX.csv` na mesma pasta e adicione seus hosts.

5. Execute:
```bash
chmod +x import_devices.sh
./import_devices.sh
````

*senha é o cadastro em Device Credentials e não senha direta do equipamento
