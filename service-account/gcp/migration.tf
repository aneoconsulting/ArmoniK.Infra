# The resources created before create_service_account and iam_service_account existed keep their state: they only
# gained a count.
moved {
  from = google_service_account.pods
  to   = google_service_account.pods[0]
}

moved {
  from = kubernetes_service_account.pods
  to   = kubernetes_service_account.pods[0]
}

moved {
  from = google_service_account_iam_member.pods
  to   = google_service_account_iam_member.pods[0]
}
