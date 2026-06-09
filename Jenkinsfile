pipeline {
    agent any

    tools {
        maven 'mvn'
        jdk   'jdk21-amazon'
    }

    environment {
        AWS_REGION    = 'ap-south-1'
        PROJECT_NAME  = 'loginapp'
        ENVIRONMENT   = 'dev'
        TF_DIR        = 'terraform'
        APP_DIR       = 'backend'
    }

    stages {
        stage('1. Load Schema Secret') {
            steps {
                checkout scm
                script {
                    // Read schema.sql & encode to base64
                    withCredentials([string(credentialsId: 'loginapp-schema-sql', variable: 'SCHEMA_RAW')]) {
                        env.SCHEMA_B64 = sh(script: 'echo -n "$SCHEMA_RAW" | base64 -w0', returnStdout: true).trim()
                    }
                }
            }
        }

        stage('2. Terraform Apply') {
            steps {
                dir(env.TF_DIR) {
                    sh 'terraform init -input=false'
                    sh "terraform plan -var-file=terraform.tfvars -var='mysql_schema_b64=${env.SCHEMA_B64}' -out=tfplan"
                    sh 'terraform apply -auto-approve tfplan'
                    // Capture ALB DNS for the health check
                    script {
                        env.ALB_DNS = sh(script: 'terraform output -raw alb_dns_name', returnStdout: true).trim()
                    }
                }
            }
        }

        stage('3. Build App') {
            steps {
                dir(env.APP_DIR) {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('4. Build & Push Docker Image') {
            steps {
                dir(env.APP_DIR) {
                    script {
                        def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        def ecrRepoUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.PROJECT_NAME}-backend"
                        def imageTag = "build-${env.BUILD_ID}"

                        // ECR Login (uses Jenkins EC2 IAM role automatically)
                        sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"

                        // Build & Push
                        sh "docker build -t ${env.PROJECT_NAME}-backend:${imageTag} ."
                        sh "docker tag ${env.PROJECT_NAME}-backend:${imageTag} ${ecrRepoUrl}:${imageTag}"
                        sh "docker tag ${env.PROJECT_NAME}-backend:${imageTag} ${ecrRepoUrl}:latest"
                        sh "docker push ${ecrRepoUrl}:latest"
                    }
                }
            }
        }
        
        stage('5. Deploy to ECS') {
            steps {
                sh """
                    aws ecs update-service \\
                        --cluster ${env.PROJECT_NAME}-${env.ENVIRONMENT}-cluster \\
                        --service ${env.PROJECT_NAME}-backend-service \\
                        --force-new-deployment \\
                        --region ${env.AWS_REGION}
                """
            }
        }

        stage('6. Health Check') {
            steps {
                script {
                    sleep 60 // Wait for ECS to pull image & start containers
                    sh "curl -f --max-time 10 http://${env.ALB_DNS}/api/auth/health || exit 1"
                    echo "Health check passed!"
                }
            }
        }
    }

    post {
        always {
            echo "🏁 Pipeline finished. Status: ${currentBuild.result}"
        }
    }
}