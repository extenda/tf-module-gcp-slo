module "slo" {
  source       = "../"
  service_name = "Demo Service"
  project      = "hiiretail-monitoring-prod-6500"
  slos         = yamldecode(file("slos.yaml"))
}
