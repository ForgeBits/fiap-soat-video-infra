resource "aws_db_subnet_group" "db_net" {
  # Adicionamos o ID aleatório ao nome
  name       = "fiapx-db-net-${random_id.id.hex}"
  subnet_ids = [aws_subnet.pub_a.id, aws_subnet.pub_b.id]

  tags = { Name = "fiapx-db-subnet-group" }
}

resource "aws_db_instance" "shared_rds" {
  identifier           = "fiapx-db"
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = "postgres_admin"
  password             = var.db_password
  db_name              = "auth_db"
  skip_final_snapshot  = true
  publicly_accessible  = true

  db_subnet_group_name   = aws_db_subnet_group.db_net.name

  vpc_security_group_ids = [aws_security_group.fiapx_sg.id]
}