// This is the recommended cluster deployment of sealed-secrets.
// See controller-norbac.jsonnet for the bare minimum functionality.

local kube = import "kube.libsonnet";
local controller = import "controller-norbac.jsonnet";

controller + {
  account: kube.ServiceAccount("sealed-secrets-controller") + $.namespace,

  unsealerRole: kube.ClusterRole("secrets-unsealer") {
    rules: [
      {
        apiGroups: ["bitnami.com"],
        resources: ["sealedsecrets"],
        verbs: ["get", "list", "watch"],
      },
      {
        apiGroups: [""],
        resources: ["secrets"],
        verbs: ["create", "update", "delete", "get"],
      },
    ],
  },

  unsealKeyRole: kube.Role("sealed-secrets-key-admin") + $.namespace {
    rules: [
      {
        apiGroups: [""],
        resources: ["secrets"],
        // Can't limit create by resource name as keys are produced on the fly
        verbs: ["create", "list"],
      },
    ],
  },

  unsealerBinding: kube.ClusterRoleBinding("sealed-secrets-controller") {
    roleRef_: $.unsealerRole,
    subjects_+: [$.account],
  },

  unsealKeyBinding: kube.RoleBinding("sealed-secrets-controller") + $.namespace {
    roleRef_: $.unsealKeyRole,
    subjects_+: [$.account],
  },

  controller+: {
    spec+: {
      template+: {
        spec+: {
          serviceAccountName: $.account.metadata.name,
        },
      },
    },
  },
}
