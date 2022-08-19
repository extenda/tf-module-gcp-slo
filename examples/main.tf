module "slo" {
  source                = "../"
  monitoring_project_id = "monitoring-project-id"
  service_name          = "my-awesome-service"
  telemetry_resource_name = "//container.googleapis.com/projects/project-id/locations/location/clusters/k8s-cluster/k8s/namespaces/example"
  slos                  = yamldecode(file("slos.yaml"))
}
