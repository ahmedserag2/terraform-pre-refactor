resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.env == "dev" ? "dev_vpc" : "prod_vpc"
  }
}


## GATEWAYS START HERE

resource "aws_eip" "eip" {
  count = var.env == "dev" ? 1 : 2
  domain   = "vpc"

}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.env == "dev" ? "dev_gw" : "prod_gw"
  }
}

resource "aws_nat_gateway" "nat" {
  count  = var.env == "dev" ? 1 : 2
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = element(aws_subnet.public_sub.*.id, count.index)
  tags = {
    Name = var.env == "dev" ? "${format("dev_nat%s", count.index + 1)}" : "${format("prod_nat%s", count.index + 1)}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

#
## GATEWAYS END HERE
#



resource "aws_route_table" "public-routeTable" {
  count  = var.env == "dev" ? 1 : 2
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = var.env == "dev" ? "${format("dev_public_routetable%s", count.index + 1)}" : "${format("prod_public_routetable%s", count.index + 1)}"
  }
}

resource "aws_route_table" "private-routeTable" {
  count  = var.env == "dev" ? 1 : 2
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"                # same pattern as the private sub
    gateway_id = aws_nat_gateway.nat[count.index].id # nat gateway id #danger
  }
  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = var.env == "dev" ? "${format("dev_private_routetable%s", count.index + 1)}" : "${format("prod_private_routetable%s", count.index + 1)}"
  }
}

resource "aws_route_table" "iso-routeTable" {
  count  = var.env == "dev" ? 1 : 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = var.env == "dev" ? "${format("dev_iso_routetable%s", count.index + 1)}" : "${format("prod_iso_routetable%s", count.index + 1)}"
  }
}

##
# ROUTETABLE ASSOCIATION START
##

resource "aws_route_table_association" "associate_public" {
  count          = var.env == "dev" ? 1 : 2
  subnet_id      = element(aws_subnet.public_sub.*.id, count.index)
  route_table_id = element(aws_route_table.public-routeTable.*.id, count.index)
}

resource "aws_route_table_association" "associate_private" {
  count          = var.env == "dev" ? 1 : 2
  subnet_id      = element(aws_subnet.private_sub.*.id, count.index)
  route_table_id = element(aws_route_table.private-routeTable.*.id, count.index)
}

resource "aws_route_table_association" "associate_iso" {
  count          = var.env == "dev" ? 1 : 2
  subnet_id      = element(aws_subnet.iso_sub.*.id, count.index)
  route_table_id = element(aws_route_table.iso-routeTable.*.id, count.index)
}

##
# ROUTETABLE ASSOCIATION END
##


##
# SUBNETS START
##
resource "aws_subnet" "public_sub" {
  count             = var.env == "dev" ? 1 : 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = format("10.0.%s.0/24", count.index + 1) # ends at 2
  availability_zone = count.index == 0 ? "us-east-1a" : "us-east-1b"

}

resource "aws_subnet" "private_sub" {
  count             = var.env == "dev" ? 1 : 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = format("10.0.%s.0/24", count.index + 3) # ends at 4
  availability_zone = count.index == 0 ? "us-east-1a" : "us-east-1b"

}


resource "aws_subnet" "iso_sub" {
  count             = var.env == "dev" ? 1 : 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = format("10.0.%s.0/24", count.index + 5) # ends at 6
  availability_zone = count.index == 0 ? "us-east-1a" : "us-east-1b"

}

##
# SUBNETS END
##




