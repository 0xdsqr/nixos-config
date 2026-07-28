{
  schemaVersion = 1;

  ownership = {
    hosts = "nix";
    kubernetes = "gitops";
    applications = "application-repositories";
    secrets = [
      "agenix"
      "vault"
      "external-secrets"
    ];
  };

  identity = {
    requiredResourceAttributes = [
      "service.name"
      "service.namespace"
      "service.version"
      "service.instance.id"
      "deployment.environment.name"
    ];

    infrastructureResourceAttributes = [
      "host.name"
      "k8s.cluster.name"
    ];

    lowCardinalityRoutingLabels = [
      "cluster"
      "environment"
      "host"
      "instance"
      "job"
      "level"
      "namespace"
      "role"
      "service_name"
      "unit"
    ];
  };

  privacy = {
    forbiddenFields = [
      "api_key"
      "authorization"
      "cookie"
      "password"
      "request.body"
      "response.body"
      "secret"
      "set-cookie"
      "token"
      "url.query"
      "user.email"
      "user.id"
      "user.ip"
    ];

    forbiddenIndexedLogLabels = [
      "container_id"
      "object_key"
      "pod_uid"
      "request_id"
      "trace_id"
      "url"
      "user_id"
    ];

    rawSql = "forbidden";
    sensitiveValues = "redact-before-export";
    userIdentity = "omit-or-pseudonymize";
  };

  sampling = {
    successfulHealthChecks = "drop";
    failedHealthChecks = "keep";
    errors = "keep";
    slowRequests = "keep";
    successfulRequests = "sample";
  };

  retentionDays = {
    metrics = 30;
    logs = 14;
    traces = 14;
    profiles = 14;
  };

  budgets = {
    activeSeries = 75000;
    spanMetricSeries = 10000;
    spanNames = 250;
    sustainedExportDrops = 0;
    targetDiskUsagePercent = 70;
    targetMemoryUsagePercent = 60;
  };

  backends = {
    metrics = {
      current = "prometheus";
      target = "mimir";
    };
    logs = {
      current = "loki";
      target = "loki";
    };
    traces = {
      current = "tempo";
      target = "tempo";
    };
    profiles = {
      current = null;
      target = "pyroscope";
    };
  };

  hosts = {
    dev-mbp-personal = {
      baseline = false;
      class = "darwin";
      collector = "disabled";
      integrations = [ ];
      role = "workstation";
    };

    dev-mbp-stablecore = {
      baseline = false;
      class = "darwin";
      collector = "disabled";
      integrations = [ ];
      role = "workstation";
    };

    srv-lx-beacon = {
      baseline = true;
      class = "nixos";
      collector = "nixos-alloy";
      integrations = [
        "alertmanager"
        "grafana"
        "loki"
        "mimir"
        "prometheus"
        "pyroscope"
        "tempo"
      ];
      role = "observability";
    };

    srv-lx-gateway = {
      baseline = true;
      class = "nixos";
      collector = "nixos-alloy";
      integrations = [
        "caddy"
        "cloudflared"
      ];
      role = "gateway";
    };

    srv-lx-k8s-master-01 = {
      baseline = true;
      class = "nixos";
      collector = "kubernetes-gitops";
      integrations = [ "kubernetes-control-plane" ];
      role = "k8s-control-plane";
    };

    srv-lx-k8s-node-01 = {
      baseline = true;
      class = "nixos";
      collector = "kubernetes-gitops";
      integrations = [ "kubernetes-node" ];
      role = "k8s-worker";
    };

    srv-lx-k8s-node-02 = {
      baseline = true;
      class = "nixos";
      collector = "kubernetes-gitops";
      integrations = [ "kubernetes-node" ];
      role = "k8s-worker";
    };

    srv-lx-khaos = {
      baseline = true;
      class = "nixos";
      collector = "nixos-alloy";
      integrations = [
        "rustfs"
        "temporal"
        "vault"
      ];
      role = "application-services";
    };

    srv-lx-knox = {
      baseline = true;
      class = "nixos";
      collector = "nixos-alloy";
      integrations = [ "postgresql" ];
      role = "database";
    };

    srv-lx-mailbox = {
      baseline = true;
      class = "nixos";
      collector = "nixos-alloy";
      integrations = [ "stalwart" ];
      role = "mail";
    };

    srv-mini-master = {
      baseline = true;
      class = "darwin";
      collector = "darwin-alloy";
      integrations = [ "exo" ];
      role = "inference";
    };

    srv-mini-node-01 = {
      baseline = true;
      class = "darwin";
      collector = "darwin-alloy";
      integrations = [ "exo" ];
      role = "inference";
    };
  };
}
