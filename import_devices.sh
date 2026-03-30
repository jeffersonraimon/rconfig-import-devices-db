#!/bin/bash

DB_CONTAINER="rconfig_db"
DB_NAME="XXXXXXX"
DB_USER="rconfig"
DB_PASS="XXXXXXXX"
CSV_FILE="olts.csv"

# IDs fixos (precisa validar dentro do DB os IDs para seu cenário
TEMPLATE_ID=5
VENDOR_ID=8
COMMAND_GROUP_ID=4  # category_command
TAGS=("XXXXX" "XXXXXXX")

DEVICE_PORT=22
DEVICE_CREDID=1
DEVICE_USERNAME=XXXX
DEVICE_MAINPROMPT=#
DEVICE_CAT_ID=4
DEVICE_MODEL=XXXXXXXX


# Copiar CSV para dentro do container
docker cp $CSV_FILE $DB_CONTAINER:/tmp/olts.csv

echo ">> Inserindo devices do CSV..."
docker exec -i $DB_CONTAINER mysql --local-infile=1 -u$DB_USER -p$DB_PASS $DB_NAME <<EOF
LOAD DATA LOCAL INFILE '/tmp/olts.csv'
INTO TABLE devices
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(device_name, device_ip)
SET
device_port_override='$DEVICE_PORT',
device_cred_id=$DEVICE_CREDID,
device_username='$DEVICE_USERNAME',
device_main_prompt='$DEVICE_MAINPROMPT',
device_category_id=$DEVICE_CAT_ID,
device_model='$DEVICE_MODEL',
status=1,
created_at=NOW(),
updated_at=NOW();
EOF

echo ">> Aplicando template..."
docker exec -i $DB_CONTAINER mysql -u$DB_USER -p$DB_PASS $DB_NAME <<EOF
INSERT INTO device_template (device_id, template_id)
SELECT d.id, $TEMPLATE_ID
FROM devices d
LEFT JOIN device_template dt ON dt.device_id=d.id
WHERE dt.device_id IS NULL;
UPDATE devices SET device_template = $TEMPLATE_ID WHERE device_template IS NULL;
EOF

echo ">> Aplicando tags..."
for tag in "${TAGS[@]}"; do
docker exec -i $DB_CONTAINER mysql -u$DB_USER -p$DB_PASS $DB_NAME <<EOF
INSERT INTO device_tag (device_id, tag_id)
SELECT d.id, t.id
FROM devices d
JOIN tags t ON t.tagname='$tag'
LEFT JOIN device_tag dt ON dt.device_id=d.id AND dt.tag_id=t.id
WHERE dt.device_id IS NULL;
EOF
done

echo ">> Aplicando vendor..."
docker exec -i $DB_CONTAINER mysql -u$DB_USER -p$DB_PASS $DB_NAME <<EOF
INSERT INTO device_vendor (device_id, vendor_id)
SELECT d.id, $VENDOR_ID
FROM devices d
LEFT JOIN device_vendor dv ON dv.device_id=d.id
WHERE dv.device_id IS NULL;
EOF

#ainda bugado
echo ">> Aplicando command group..."
docker exec -i $DB_CONTAINER mysql -u$DB_USER -p$DB_PASS $DB_NAME <<EOF
INSERT INTO category_device (category_id, device_id)
SELECT $COMMAND_GROUP_ID, d.id
FROM devices d
LEFT JOIN category_device cd ON cd.device_id = d.id
WHERE cd.device_id IS NULL;
EOF

echo "✅ Importação completa para qualquer CSV com qualquer device!"
