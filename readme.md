# ProShop eCommerce Platform (v2) - CloudWeb Edition

> eCommerce platform built with the MERN stack & Redux.

This project is based on the [MERN Stack From Scratch | eCommerce Platform](https://www.traversymedia.com/mern-stack-from-scratch) course. It is a full-featured shopping cart with PayPal & credit/debit payments.

This is version 2.0 of the app, which uses Redux Toolkit. The original course version can be found [here](https://proshopdemo.dev)

**CloudWeb Edition:** This version has been enhanced with production-grade AWS infrastructure including ECS Fargate, ALB, RDS, MongoDB Atlas integration, and automated deployment pipelines.

<!-- toc -->

- [Features](#features)
- [Usage](#usage)
  - [Env Variables](#env-variables)
  - [Install Dependencies (frontend & backend)](#install-dependencies-frontend--backend)
  - [Run](#run)
- [Build & Deploy](#build--deploy)
  - [Local Docker Deployment](#local-docker-deployment)
  - [Seed Database](#seed-database)
  - [AWS Deployment](#aws-deployment)
- [License](#license)

<!-- tocstop -->

## Features

- Full featured shopping cart
- Product reviews and ratings
- Top products carousel
- Product pagination
- Product search feature
- User profile with orders
- Admin product management
- Admin user management
- Admin Order details page
- Mark orders as delivered option
- Checkout process (shipping, payment method, etc)
- PayPal / credit card integration
- Database seeder (products & users)
- **AWS ECS Fargate deployment with ALB**
- **MongoDB Atlas integration**
- **VPC with public/private subnets**
- **Secrets Manager integration**
- **CloudWatch logging**
- **AWS Config compliance monitoring**

## Usage

- Create a MongoDB database and obtain your `MongoDB URI` - [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register)
- Create a PayPal account and obtain your `Client ID` - [PayPal Developer](https://developer.paypal.com/)

### Env Variables

Rename the `.env.example` file to `.env` and add the following

```
NODE_ENV = development
PORT = 5000
MONGO_URI = your mongodb uri
JWT_SECRET = 'abc123'
PAYPAL_CLIENT_ID = your paypal client id
PAGINATION_LIMIT = 8
```

Change the JWT_SECRET and PAGINATION_LIMIT to what you want

### Install Dependencies (frontend & backend)

```
npm install
cd frontend
npm install
```

### Run

```
# Run frontend (:3000) & backend (:5000)
npm run dev

# Run backend only
npm run server

# Run frontend only (from frontend directory)
npm run dev
```

## Build & Deploy

### Local Docker Deployment

```
# Build and run with Docker Compose
docker-compose up --build

# Containers will start:
# - Frontend: http://localhost:3000
# - Backend: http://localhost:5000
# - Mock API: http://localhost:3001
```

### Seed Database

You can use the following commands to seed the database with some sample users and products as well as destroy all data

```
# Import data
npm run data:import

# Destroy data
npm run data:destroy
```

```
Sample User Logins

admin@email.com (Admin)
123456

john@email.com (Customer)
123456

jane@email.com (Customer)
123456
```

### AWS Deployment

This project includes production-grade AWS infrastructure defined with Terraform.

#### Prerequisites

- AWS Account (account ID: 085953615294)
- AWS CLI configured with appropriate credentials
- Terraform installed (>= 1.0)
- Docker & Docker Compose

#### AWS Resources Deployed

- **VPC**: Custom VPC with 4 subnets (2 public, 2 private) across 2 AZs
- **Application Load Balancer**: Routes traffic to frontend and backend
- **ECS Fargate**: Containerized services for frontend and backend
- **RDS**: Relational database support (configured via variables)
- **Secrets Manager**: Secure storage for MongoDB URI, JWT Secret, PayPal Client ID
- **ECR**: Private container registries for frontend and backend images
- **CloudWatch**: Centralized logging for all services
- **AWS Config**: Compliance monitoring and tagging enforcement
- **NAT Gateways**: Outbound internet access from private subnets

#### Deployment Steps

1. **Setup Terraform Variables**
   ```
   cd infra
   # Edit terraform.tfvars with your AWS account details
   vim terraform.tfvars
   ```

2. **Create AWS Secrets** (if not already created)
   ```
   # MongoDB URI
   aws secretsmanager create-secret \
     --name proshop/MONGO_URI \
     --secret-string "mongodb+srv://..." \
     --region us-west-2

   # JWT Secret
   aws secretsmanager create-secret \
     --name proshop/JWT_SECRET \
     --secret-string "your-jwt-secret" \
     --region us-west-2

   # PayPal Client ID
   aws secretsmanager create-secret \
     --name proshop/PAYPAL_CLIENT_ID \
     --secret-string "your-paypal-client-id" \
     --region us-west-2
   ```

3. **Build and Push Docker Images to ECR**
   ```
   # Authenticate with ECR
   aws ecr get-login-password --region us-west-2 | \
     docker login --username AWS --password-stdin 085953615294.dkr.ecr.us-west-2.amazonaws.com

   # Build and push backend
   cd ../backend
   docker build -t proshop-backend:latest .
   docker tag proshop-backend:latest \
     085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-backend:latest
   docker push 085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-backend:latest

   # Build and push frontend
   cd ../frontend
   docker build -t proshop-frontend:latest .
   docker tag proshop-frontend:latest \
     085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-frontend:latest
   docker push 085953615294.dkr.ecr.us-west-2.amazonaws.com/proshop-frontend:latest
   ```

4. **Deploy Infrastructure with Terraform**
   ```
   cd ../infra
   terraform init
   terraform plan
   terraform apply
   ```

5. **Access the Application**
   ```
   # Get the ALB DNS name
   aws elbv2 describe-load-balancers \
     --names proshop-alb \
     --region us-west-2 \
     --query 'LoadBalancers[0].DNSName' \
     --output text
   ```

#### Infrastructure Highlights

- **Highly Available**: Deployed across 2 Availability Zones
- **Auto-Scaling**: ECS services configured for auto-scaling based on CPU/Memory
- **Secure**: Secrets Manager for sensitive data, Security Groups for network isolation, VPC Endpoints for private access to AWS services
- **Observable**: CloudWatch logs for all services, AWS Config for compliance
- **Scalable**: Load Balanced architecture, containerized workloads

#### Architecture Diagram

```
Internet → ALB (public subnet) → ECS Services (private subnets) → RDS / MongoDB Atlas
                                        ↓
                              Secrets Manager (VPC Endpoint)
                              CloudWatch Logs
                              AWS Config
```

---

## License

The MIT License

Copyright (c) 2023 Traversy Media https://traversymedia.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
