locals {
  application_id = var.create ? (
    length(azuread_application.lacework) > 0 ? azuread_application.lacework[0].application_id : ""
  ) : ""
  application_password = var.create ? (
    length(azuread_application_password.client_secret) > 0 ? azuread_application_password.client_secret[0].value : ""
  ) : ""
  service_principal_id = var.create ? (
    length(azuread_service_principal.lacework) > 0 ? azuread_service_principal.lacework[0].object_id : ""
  ) : ""
}

data "azuread_client_config" "current" {}

## Create a service principal and assigned Directory Reader role in Azure AD
resource "azuread_application" "lacework" {
  count         = var.create ? 1 : 0
  display_name  = var.application_name
  owners        = length(var.application_owners) == 0 ? [data.azuread_client_config.current.object_id] : var.application_owners
  logo_image    = filebase64("${path.module}/imgs/lacework_logo.png")
  marketing_url = "https://www.lacework.com/"
  web {
    homepage_url = "https://www.lacework.com/"
  }
}

resource "azuread_directory_role" "dir_reader" {
  display_name = "Directory Readers"
}

resource "azuread_service_principal" "lacework" {
  count          = var.create ? 1 : 0
  application_id = local.application_id
}

resource "azuread_application_password" "client_secret" {
  count                 = var.create ? 1 : 0
  application_object_id = azuread_application.lacework[count.index].object_id
  end_date              = "2299-12-31T01:02:03Z"
  depends_on            = [azuread_service_principal.lacework]
}

# When to use this role? When Granting service principals access to directory where
# Directory.Read.All is not an option. This way we avoid Grant Admin Consent issue.
#
# => https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#directory-readers 
resource "azuread_directory_role_member" "lacework_dir_reader" {
  count            = var.create ? 1 : 0
  role_object_id   = azuread_directory_role.dir_reader.object_id
  member_object_id = local.service_principal_id
  depends_on       = [azuread_service_principal.lacework]
}
