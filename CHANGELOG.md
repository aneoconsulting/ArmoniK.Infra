# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0](https://github.com/aneoconsulting/ArmoniK.Infra/compare/0.0.2...1.0.0) (2023-08-08)


### ⚠ BREAKING CHANGES

* MAJOR.

### Features

* add artifact registry to ArmoniK GCP ([fd58a53](https://github.com/aneoconsulting/ArmoniK.Infra/commit/fd58a53b369d98061803c2c58552b8f214f08c35))
* add artifact registry to ArmoniK GCP ([bbe56b2](https://github.com/aneoconsulting/ArmoniK.Infra/commit/bbe56b2d9b470504f0a3a79347164a0d7f6025a4))
* Add module for AWS VPC endpoints ([#23](https://github.com/aneoconsulting/ArmoniK.Infra/issues/23)) ([586ac19](https://github.com/aneoconsulting/ArmoniK.Infra/commit/586ac1924e0b0285ccb23a07f1fc4d415a730977))
* Add module for AWS VPC endpoints ([#23](https://github.com/aneoconsulting/ArmoniK.Infra/issues/23)) ([c4ae89e](https://github.com/aneoconsulting/ArmoniK.Infra/commit/c4ae89ecc9163ecfbe8a4fb9e202520e738196ef))
* Add module of GCP Artifact Registry for Docker ([#52](https://github.com/aneoconsulting/ArmoniK.Infra/issues/52)) ([93b759e](https://github.com/aneoconsulting/ArmoniK.Infra/commit/93b759e7df2b67c908f8dce75d95092527bdc6e5))
* Add static file to ingress ([#38](https://github.com/aneoconsulting/ArmoniK.Infra/issues/38)) ([016a0c1](https://github.com/aneoconsulting/ArmoniK.Infra/commit/016a0c1af0c638f918888167e40508a8425f53bc))
* expose validity_period_hours_variable_tls_certificate_for_mongo ([#50](https://github.com/aneoconsulting/ArmoniK.Infra/issues/50)) ([9a0b992](https://github.com/aneoconsulting/ArmoniK.Infra/commit/9a0b992710679c5ebfbc4b170b9ebc3ec2297a79))
* first version of GCP VPC ([#48](https://github.com/aneoconsulting/ArmoniK.Infra/issues/48)) ([2535f94](https://github.com/aneoconsulting/ArmoniK.Infra/commit/2535f94b24ea3976be15730f15960edb37e01688))
* include onprem cluster depl modules in new infra infra v2 ([#22](https://github.com/aneoconsulting/ArmoniK.Infra/issues/22)) ([b2c4fc3](https://github.com/aneoconsulting/ArmoniK.Infra/commit/b2c4fc368e06cdc3ceea6f380d5c98dd6d739730))
* Support for headless services ([#63](https://github.com/aneoconsulting/ArmoniK.Infra/issues/63)) ([f0fdfab](https://github.com/aneoconsulting/ArmoniK.Infra/commit/f0fdfaba43f711d287634ec892b8e0132344e926))
* validity period of activemq and redis ([#65](https://github.com/aneoconsulting/ArmoniK.Infra/issues/65)) ([d56b35f](https://github.com/aneoconsulting/ArmoniK.Infra/commit/d56b35f103d59cad2dc9a59eae7f82ebb19ec0ec))


### Bug Fixes

* add example complex and simple + IAM binding ([050c99a](https://github.com/aneoconsulting/ArmoniK.Infra/commit/050c99a8a41f03fc4bee2cf6fb00d58a552779a8))
* add examples folder and move locals inside main ([a5d71a8](https://github.com/aneoconsulting/ArmoniK.Infra/commit/a5d71a846daf589c2843ce995ff894fd4392e0de))
* add IAM on registry and fix examples ([af785b4](https://github.com/aneoconsulting/ArmoniK.Infra/commit/af785b4a4b7957406c1ad27617b59d9175ddfa35))
* add locals + versions and transform aws struct to gcp one ([8f534a2](https://github.com/aneoconsulting/ArmoniK.Infra/commit/8f534a2d00c9faebef51e1724567c641545067c0))
* add missing bracket ([eee3126](https://github.com/aneoconsulting/ArmoniK.Infra/commit/eee3126e2de72d01d782e56b996ffb44488d2d21))
* change complex to complete example + change location to data google client config + add provider google and associated vars inside examples ([ce072f1](https://github.com/aneoconsulting/ArmoniK.Infra/commit/ce072f17e6e6aed62ae6e2032df5393c302a6ab8))
* change path to credentials inside examples into a generic one ([49c8d8d](https://github.com/aneoconsulting/ArmoniK.Infra/commit/49c8d8de2c032c0b934f0fbdc136c7535cf6f26b))
* changes after reviews ([bded798](https://github.com/aneoconsulting/ArmoniK.Infra/commit/bded798b267b5d965ce385cc3710ea8b13c2113c))
* changes to create only one registry at once ([6c85f5e](https://github.com/aneoconsulting/ArmoniK.Infra/commit/6c85f5ed2eb17022a2a5cd31982161667f297e5e))
* conf semantic-Release ([#27](https://github.com/aneoconsulting/ArmoniK.Infra/issues/27)) ([83d1ac8](https://github.com/aneoconsulting/ArmoniK.Infra/commit/83d1ac8ab309376923d935974c58913d5a9be6f9))
* correction of code for CI validation ([920a282](https://github.com/aneoconsulting/ArmoniK.Infra/commit/920a2829d3554ecc777f211ec786b5fcbcbf5fb0))
* remove vpc resource and add credential var for provider google ([9d5c3ca](https://github.com/aneoconsulting/ArmoniK.Infra/commit/9d5c3ca3cc91b8c1b436a0db5276871928ed391c))
* Replace set by list ([#59](https://github.com/aneoconsulting/ArmoniK.Infra/issues/59)) ([65c523e](https://github.com/aneoconsulting/ArmoniK.Infra/commit/65c523e3b723da5aa9d179ca82fb880d6d1b4c9b))
* Set serve_from_sub_path to false in Grafana ([#49](https://github.com/aneoconsulting/ArmoniK.Infra/issues/49)) ([917bec7](https://github.com/aneoconsulting/ArmoniK.Infra/commit/917bec7949fcbbf314f13de0afb2d1d86ae6a0b8))
* Update documentation workflow ([#21](https://github.com/aneoconsulting/ArmoniK.Infra/issues/21)) ([4e8a76d](https://github.com/aneoconsulting/ArmoniK.Infra/commit/4e8a76db0f79a3a1ae1a0678a727c9c941fc274c))
* update var names + change validation for credentials ([42a51f5](https://github.com/aneoconsulting/ArmoniK.Infra/commit/42a51f5fe742df35970da82308bee524723e53c9))

## [1.0.0](https://github.com/aneoconsulting/ArmoniK.Infra/compare/0.0.2...1.0.0) (2023-06-21)


### ⚠ BREAKING CHANGES

* MAJOR.

### Features

* Add module for AWS VPC endpoints ([#23](https://github.com/aneoconsulting/ArmoniK.Infra/issues/23)) ([586ac19](https://github.com/aneoconsulting/ArmoniK.Infra/commit/586ac1924e0b0285ccb23a07f1fc4d415a730977))
* Add module for AWS VPC endpoints ([#23](https://github.com/aneoconsulting/ArmoniK.Infra/issues/23)) ([c4ae89e](https://github.com/aneoconsulting/ArmoniK.Infra/commit/c4ae89ecc9163ecfbe8a4fb9e202520e738196ef))
* include onprem cluster depl modules in new infra infra v2 ([#22](https://github.com/aneoconsulting/ArmoniK.Infra/issues/22)) ([b2c4fc3](https://github.com/aneoconsulting/ArmoniK.Infra/commit/b2c4fc368e06cdc3ceea6f380d5c98dd6d739730))


### Bug Fixes

* conf semantic-Release ([#27](https://github.com/aneoconsulting/ArmoniK.Infra/issues/27)) ([83d1ac8](https://github.com/aneoconsulting/ArmoniK.Infra/commit/83d1ac8ab309376923d935974c58913d5a9be6f9))
* Update documentation workflow ([#21](https://github.com/aneoconsulting/ArmoniK.Infra/issues/21)) ([4e8a76d](https://github.com/aneoconsulting/ArmoniK.Infra/commit/4e8a76db0f79a3a1ae1a0678a727c9c941fc274c))

## [main](https://github.com/aneoconsulting/ArmoniK.Infra/tree/main)

Changed
-

* From version `10.x` of Grafana, set the parameter `serve_from_sub_path` to `false`.
* Parameterize the hard coded validity period of the autogenerated MongoDB certificate.

Added
-

* Module of AWS VPC endpoints

Breaking changes
-

* Refactor module of AWS VPC
* Refactor module of AWS ECR

## [0.0.2](https://github.com/aneoconsulting/ArmoniK.Infra/releases/tag/0.0.2) (2023-05-11)

Changed
-

* Rename and reorganize folders of Terraform modules.

## [0.0.1](https://github.com/aneoconsulting/ArmoniK.Infra/releases/tag/0.0.1) (2023-05-11)

Changed
-

* First release: Terraform modules moved from GitHub repository [ArmoniK](https://github.com/aneoconsulting/ArmoniK).
