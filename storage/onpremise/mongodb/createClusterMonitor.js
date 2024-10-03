use admin;
db.createUser({
  user: "mongodb_exporter",
  pwd: "mongodb_exporter",
  roles: [
    { role: "clusterMonitor", db: "admin"},
    { role: "read", db: "local"}
  ]
});
