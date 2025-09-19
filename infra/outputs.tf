output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "developer_access_key_id" {
  description = "Access Key ID for developer user"
  value       = aws_iam_access_key.developer.id
}

output "developer_secret_access_key" {
  description = "Secret Access Key for developer user"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}