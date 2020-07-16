resource "random_string" "unique_configuration_identifier" {
  length = 5
  special = false
}

resource "aws_kms_key" "kms" {
  description = "inventory_key"
}

resource "aws_msk_configuration" "debezium_msk_configuration" {
  kafka_versions = ["2.4.1"]
  name           = "debezium${random_string.unique_configuration_identifier.result}"

  server_properties = <<PROPERTIES
min.insync.replicas = 1
default.replication.factor = 1
auto.create.topics.enable = true
delete.topic.enable = true
PROPERTIES
}

resource "aws_msk_cluster" "inventory_stream" {
  cluster_name           = "inventorystream"
  kafka_version          = "2.4.1"
  number_of_broker_nodes = 3

  configuration_info {
    arn = aws_msk_configuration.debezium_msk_configuration.arn
    revision = aws_msk_configuration.debezium_msk_configuration.latest_revision
  }

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    ebs_volume_size = 10
    client_subnets = [
      aws_default_subnet.default_az1.id,
      aws_default_subnet.default_az2.id,
      aws_default_subnet.default_az3.id
    ]
    security_groups = [
      aws_security_group.internal_sg.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
    }
  }
}