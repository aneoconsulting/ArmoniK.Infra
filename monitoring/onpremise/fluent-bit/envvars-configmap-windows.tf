# configmap with all the variables
resource "kubernetes_config_map" "fluent_bit_envvars_config_windows" {
  count = (length(var.node_selector_windows) > 0 ? 1 : 0)
  metadata {
    name      = "fluent-bit-envvars-config-windows"
    namespace = var.namespace
  }
  data = {
    FLUENT_CONTAINER_NAME                        = local.fluent_bit_windows_container_name
    FLUENT_HTTP_SEQ_HOST                         = local.seq_host
    FLUENT_HTTP_SEQ_PORT                         = local.seq_port
    HTTP_SERVER                                  = local.fluent_bit_windows_http_server
    HTTP_PORT                                    = local.fluent_bit_windows_http_port
    READ_FROM_HEAD                               = local.fluent_bit_windows_read_from_head
    READ_FROM_TAIL                               = local.fluent_bit_windows_read_from_tail
    AWS_REGION_CLOUDWATCH                        = local.cloudwatch_region
    APPLICATION_CLOUDWATCH_LOG_GROUP             = local.cloudwatch_name
    APPLICATION_CLOUDWATCH_AUTO_CREATE_LOG_GROUP = (local.cloudwatch_name == "" && local.cloudwatch_enabled)
    AWS_S3_NAME                                  = local.s3_name
    AWS_REGION_S3                                = local.s3_region
    S3_KEY_FORMAT                                = local.s3_key_format
    PARSER                                       = local.fluent_bit_windows_parser
    KUBE_CA_FILE                                 = local.fluent_bit_kube_ca_file_windows
    KUBE_TOKEN_FILE                              = local.fluent_bit_kube_token_file_windows
    INPUT_KUBE_PATH                              = local.fluent_bit_input_kube_path_windows
    INPUT_APPLICATION_PATH                       = local.fluent_bit_input_application_path_windows
    INPUT_S3_PATH                                = local.fluent_bit_input_s3_path_windows
    INPUT_PATH                                   = local.fluent_bit_input_path_windows
  }
}
