resource "aws_security_group" "fiapx_sg" {
  name        = "fiapx-common-sg"
  description = "Permitir trafego para os recursos do projeto"
  vpc_id      = aws_vpc.fiapx_vpc.id

  # Porta do Postgres
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Porta do Redis
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}