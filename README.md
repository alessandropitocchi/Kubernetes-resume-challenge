# Cloud Resume Challenge - Kubernetes Challenge

## Introduction

The **Cloud Resume Challenge - Kubernetes Challenge** is an advanced extension of the Cloud Resume Challenge, designed for individuals who want to demonstrate their skills in Kubernetes and cloud-native technologies. This challenge aims to deepen your understanding of container orchestration, infrastructure as code, and CI/CD pipelines by deploying your resume as a Kubernetes-based application.

## Objectives

- Deploy a static resume website using Kubernetes.
- Use Infrastructure as Code (IaC) to manage Kubernetes resources.
- Implement a CI/CD pipeline for automated deployments.
- Secure and scale the application following best practices.

## Prerequisites

- Familiarity with Kubernetes concepts (pods, services, deployments, etc.).
- Experience with cloud providers (AWS, Azure, GCP) and Kubernetes clusters.
- Basic knowledge of CI/CD and infrastructure automation tools.

## Why Take This Challenge?

By completing this challenge, you will:

- Gain hands-on experience with Kubernetes and DevOps workflows.
- Showcase your expertise with a tangible project.
- Improve your skills in cloud infrastructure and automation.

For more details, visit the official [Cloud Resume Challenge - Kubernetes Challenge](https://cloudresumechallenge.dev/docs/extensions/kubernetes-challenge/).

## Step 1: Certification

I obtained the CKA certification at the end of December 2024, which provided me with the necessary knowledge to take on the challenge.

## Step 2: Containerize Your E-Commerce Website and Database

### A. Web Application Containerization

I cloned the repository containing the website and created a Dockerfile to set up a PHP 7.4 Apache-based container. The Dockerfile installs the necessary MySQL extensions (mysqli, pdo, and pdo_mysql), copies the website files into the container, and exposes port 80 for Apache. After defining the Dockerfile, I built the Docker image using docker build -t alessandropitocchi/ecommerce-frontend:v1 . and tested it locally by running the container with docker run -d -p 8080:80 --name ecommerce-frontend alessandropitocchi/ecommerce-frontend:v1. Finally, I pushed the image to Docker Hub with docker push alessandropitocchi/ecommerce-frontend:v1, making it available for deployment.

### B. Database Containerization

I have decided to use the official MariaDB image and manage its configuration via ConfigMap in Kubernetes.

## Step 3. Manifests creation

I have created backend and frontend manifest files to deploy the web application.
I have tested these files locally using Kind.
I have updated the SQL script to create and assign permissions to the user ecomuser.

### STEP 4. (To-Do)  Set Up Kubernetes on a Public Cloud Provider

- Cluster Creation: Choose AWS (EKS), Azure (AKS), or GCP (GKE) and follow their documentation to create a Kubernetes cluster. Ensure you have kubectl configured to interact with your cluster.
- Outcome: A fully operational Kubernetes cluster ready for deployment.

