resource "aws_security_group" "global-rdsSG" {
    name = "global-rdsSG"
    description = "RDS security group"
    vpc_id = "${aws_vpc.prod-vpc.id}"  
    tags = {
      Name = "global-rdsSG"
    }
    ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      security_groups = ["${aws_security_group.Global-EC2.id}"]
     # cidr_blocks = ["${aws_vpc.prod-vpc.cidr_block}"]
   }
   egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "global-rds-group" {
  name       = "global"

  subnet_ids = [
     aws_subnet.prod-subnet-a-1.id,
     aws_subnet.prod-subnet-b-1.id
  ]

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_db_instance" "global-rds" {
  identifier           = "global-rds"
# Allocating the storage for database instance.
  allocated_storage    = 20
  storage_type = "gp2"
# Declaring the database engine and engine_version
  engine               = var.RDS_Engine
  engine_version       = var.RDS_Engine-Version	
# Declaring the instance class
  instance_class       = var.RDS_Instance-Class  
# User to connect the database instance
  username             = var.RDS_Username
# Password to connect the database instance
  password             = var.RDS_Password
  skip_final_snapshot  = "true"
  publicly_accessible = false  
  parameter_group_name = var.RDS_Parameter_Group_Name
  tags = {
        Name = "Global-RDS"
    }
  vpc_security_group_ids = ["${aws_security_group.global-rdsSG.id}"]
  db_subnet_group_name = aws_db_subnet_group.global-rds-group.name
}
