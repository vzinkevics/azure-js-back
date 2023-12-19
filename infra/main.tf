# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "product_service_rg" {
  location = "northeurope"
  name     = "rg-product-service-sand-ne-002"
}

resource "azurerm_storage_account" "products_service_fa" {
  name     = "stgsangproductsfane888"
  location = "northeurope"

  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"

  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_storage_share" "products_service_fa" {
  name  = "fa-products-service-share"
  quota = 2

  storage_account_name = azurerm_storage_account.products_service_fa.name
}

resource "azurerm_service_plan" "product_service_plan" {
  name     = "asp-product-service-sand-ne-001"
  location = "northeurope"

  os_type  = "Windows"
  sku_name = "Y1"

  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_application_insights" "products_service_fa" {
  name             = "appins-fa-products-service-sand-ne-001"
  application_type = "web"
  location         = "northeurope"


  resource_group_name = azurerm_resource_group.product_service_rg.name
}


resource "azurerm_windows_function_app" "products_service" {
  name     = "fa-products-service-ne-999"
  location = "northeurope"

  service_plan_id     = azurerm_service_plan.product_service_plan.id
  resource_group_name = azurerm_resource_group.product_service_rg.name

  storage_account_name       = azurerm_storage_account.products_service_fa.name
  storage_account_access_key = azurerm_storage_account.products_service_fa.primary_access_key

  functions_extension_version = "~4"
  builtin_logging_enabled     = false

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.products_service_fa.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.products_service_fa.connection_string

    # For production systems set this to false
    use_32_bit_worker = false

    # Enable function invocations from Azure Portal.
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }

    application_stack {
      node_version = "~16"
    }
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.products_service_fa.primary_connection_string
    WEBSITE_CONTENTSHARE                     = azurerm_storage_share.products_service_fa.name
  }

  # The app settings changes cause downtime on the Function App. e.g. with Azure Function App Slots
  # Therefore it is better to ignore those changes and manage app settings separately off the Terraform.
  lifecycle {
    ignore_changes = [
      app_settings,
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"]
    ]
  }
}

resource "azurerm_windows_function_app_slot" "products_service_slot" {
  name     = "non-prod"
  function_app_id      = azurerm_windows_function_app.products_service.id
  storage_account_name       = azurerm_storage_account.products_service_fa.name

  functions_extension_version = "~4"
  builtin_logging_enabled     = false

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.products_service_fa.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.products_service_fa.connection_string

    # For production systems set this to false
    use_32_bit_worker = false

    # Enable function invocations from Azure Portal.
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }

    application_stack {
      node_version = "~16"
    }
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.products_service_fa.primary_connection_string
    WEBSITE_CONTENTSHARE                     = azurerm_storage_share.products_service_fa.name
    FUNCTIONS_WORKER_RUNTIME                 = 'node'
  }

  # The app settings changes cause downtime on the Function App. e.g. with Azure Function App Slots
  # Therefore it is better to ignore those changes and manage app settings separately off the Terraform.
  lifecycle {
    ignore_changes = [
      app_settings,
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"]
    ]
  }
}

#data "azurerm_api_management_api" "products_service_api" {
#  name                = "products-service-api"
#  api_management_name = "products-service-api-management"
#  resource_group_name = azurerm_resource_group.product_service_rg.name
#  revision            = "2"
#}
#
#resource "azurerm_api_management_api_operation" "get_products_operation" {
#  operation_id        = "get-products"
#  api_name            = data.azurerm_api_management_api.products_service_api.name
#  api_management_name = data.azurerm_api_management_api.products_service_api.api_management_name
#  resource_group_name = data.azurerm_api_management_api.products_service_api.resource_group_name
#  display_name        = "Get Products"
#  method              = "GET"
#  url_template        = "/products"
#}
#
#resource "azurerm_api_management_api_operation" "get_product_operation" {
#  operation_id        = "get-product"
#  api_name            = data.azurerm_api_management_api.products_service_api.name
#  api_management_name = data.azurerm_api_management_api.products_service_api.api_management_name
#  resource_group_name = data.azurerm_api_management_api.products_service_api.resource_group_name
#  display_name        = "Get Products"
#  method              = "GET"
#  url_template        = "/product/{id}"
#
#  template_parameter {
#    name     = "id"
#    type     = "string"
#    required = true
#  }
#}
#
#resource "azurerm_api_management_api_policy" "payment_service_api_policy" {
#  api_name            = data.azurerm_api_management_api.products_service_api.name
#  api_management_name = data.azurerm_api_management_api.products_service_api.api_management_name
#  resource_group_name = data.azurerm_api_management_api.products_service_api.resource_group_name
#
#  xml_content = <<XML
#    <policies>
#        <inbound>
#            <base />
#            <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="none" must-revalidate="true" caching-type="internal" >
#                <vary-by-query-parameter>version</vary-by-query-parameter>
#            </cache-lookup>
#        </inbound>
#        <outbound>
#            <cache-store duration="seconds" />
#            <base />
#        </outbound>
#    </policies>
#  XML
#}
