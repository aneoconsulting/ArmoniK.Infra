resource "kubernetes_config_map" "fluent_bit_entrypoint" {
  metadata {
    name      = "fluent-bit-entrypoint"
    namespace = var.namespace
  }

  data = {
    "entrypoint.ps1" = <<-EOT
      # Copy and install certificate
      #Copy-Item C:/certs/AmazonRootCA1.cer C:/fluent-bit/AmazonRootCA1.cer
      $AmazonRootCA1 = 'https://www.amazontrust.com/repository/AmazonRootCA1.cer'
      Invoke-WebRequest -URI $AmazonRootCA1 -OutFile C:/fluent-bit/AmazonRootCA1.cer
      certutil -addstore -f Root C:/fluent-bit/AmazonRootCA1.cer

      # Verify certificate installation
      $cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { 
          $_.Subject -like "*Amazon*" 
      }

      if ($cert) {
          Write-Host "Certificate installed successfully"
      } else {
          Write-Error "Certificate installation failed"
      }

      # Launch Fluent Bit
      & C:/fluent-bit/bin/fluent-bit.exe -c C:/fluent-bit/etc/fluent-bit.conf
    EOT
  }
}
